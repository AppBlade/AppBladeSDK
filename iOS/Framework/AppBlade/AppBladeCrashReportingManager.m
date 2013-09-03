//
//  CrashReporting.m
//  AppBlade
//
//  Created by AndrewTremblay on 7/16/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "AppBladeCrashReportingManager.h"
#import "AppBlade.h"


#import "PLCrashReporter.h"
#import "PLCrashReport.h"
#import "PLCrashReportTextFormatter.h"

static NSString* const kCrashDictCrashReportString  = @"_crashReportString";
static NSString* const kCrashDictQueuedFilePath  = @"_queuedFilePath";
@interface AppBladeCrashReportingManager ()
- (AppBladeWebOperation*) generateCrashReport:(NSString *)crashReport withParams:(NSDictionary *)paramsDict;
@end


@implementation AppBladeCrashReportingManager
@synthesize delegate;

- (id)initWithDelegate:(id<AppBladeWebOperationDelegate>)webOpDelegate
{
    if((self = [super init])) {
        self.delegate = webOpDelegate;
    }
    
    return self;
}

#pragma mark - Web Request Generators
- (AppBladeWebOperation*) generateCrashReportFromDictionary:(NSDictionary *)crashDictionary withParams:(NSDictionary *)paramsDict
{
    AppBladeWebOperation *client = nil;
    NSString *crashReportString = [crashDictionary objectForKey:kCrashDictCrashReportString];
    NSString *queuedFilePath    = [crashDictionary objectForKey:kCrashDictQueuedFilePath];
    if(nil != crashReportString && nil != queuedFilePath){
        client = [self generateCrashReport:crashReportString  withParams:paramsDict];
        client.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:queuedFilePath,  kAppBladeCrashReportKeyFilePath, nil];
    }
    return client;
}

- (AppBladeWebOperation*) generateCrashReport:(NSString *)crashReport withParams:(NSDictionary *)paramsDict
{
    AppBladeWebOperation *client = [[AppBladeWebOperation alloc] initWithDelegate:self.delegate];
    [client setApi: AppBladeWebClientAPI_Feedback];

    @synchronized (self)
    {
        // Build report URL.
        NSString* urlCrashReportString = [NSString stringWithFormat:reportCrashURLFormat, [self.delegate appBladeHost]];
        NSURL* urlCrashReport = [NSURL URLWithString:urlCrashReportString];
        
        NSString *multipartBoundary = [NSString stringWithFormat:@"---------------------------%@", [client genRandNumberLength:64]];
        // Create the API request.
        NSMutableURLRequest* apiRequest = [client requestForURL:urlCrashReport];
        [apiRequest setValue:[@"multipart/form-data; boundary=" stringByAppendingString:multipartBoundary] forHTTPHeaderField:@"Content-Type"];
        [apiRequest setHTTPMethod:@"POST"];
        
        NSMutableData* body = [NSMutableData dataWithData:[[NSString stringWithFormat:@"--%@\r\n",multipartBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Disposition: form-data; name=\"file\"; filename=\"report.crash\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type: text/plain\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        
        NSData* data = [crashReport dataUsingEncoding:NSUTF8StringEncoding];
        [body appendData:data];
        
        if([NSPropertyListSerialization propertyList:paramsDict isValidForFormat:NSPropertyListXMLFormat_v1_0]){
            NSError* error = nil;
            NSData *paramsData = [NSPropertyListSerialization dataWithPropertyList:paramsDict format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
            if(error == nil){
                [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",multipartBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:[@"Content-Disposition: form-data; name=\"custom_params\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:[@"Content-Type: text/xml\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:paramsData];
                ABDebugLog_internal(@"Parsed params! They were included.");
            }
            else
            {
                ABErrorLog(@"Error parsing params. They weren't included. %@ ",error.debugDescription);
            }
        }
        
        [body appendData:[[[@"\r\n--" stringByAppendingString:multipartBoundary] stringByAppendingString:@"--"] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [apiRequest setHTTPBody:body];
        [apiRequest setValue:[NSString stringWithFormat:@"%d", [body length]] forHTTPHeaderField:@"Content-Length"];
        
        
        
        __block AppBladeWebOperation *blocksafeClient = client;
        [client setPrepareBlock:^(id preparationData){
            NSMutableURLRequest* castRequest = (NSMutableURLRequest*)preparationData;
            [blocksafeClient addSecurityToRequest:castRequest];
        }];

        [client setRequestCompletionBlock:^(NSMutableURLRequest *request, id rawSentData, NSDictionary* responseHeaders, NSMutableData* receivedData, NSError *webError){
            // purge the crash report that was just reported.
            int status = [[responseHeaders valueForKey:@"statusCode"] intValue];
            BOOL success = (status == 201 || status == 200);
            if(success){ //we don't need to hold onto this crash.
                blocksafeClient.successBlock(nil, nil);
            }
            else
            {
                blocksafeClient.failBlock(nil, nil);
            }

        }];
        
        [client setSuccessBlock:^(id data, NSError* error){
            ABDebugLog_internal(@"Appblade: success sending crash report, response status code: %d", status);
            [[PLCrashReporter sharedReporter] purgePendingCrashReport];
            NSString *pathOfCrashReport = [blocksafeClient.userInfo valueForKey:kAppBladeCrashReportKeyFilePath];
            [[NSFileManager defaultManager] removeItemAtPath:pathOfCrashReport error:nil];
            ABDebugLog_internal(@"Appblade: removed crash report, %@", pathOfCrashReport);
            
            if ([[PLCrashReporter sharedReporter] hasPendingCrashReport]){
                ABDebugLog_internal(@"Appblade: PLCrashReporter has more crash reports");
                [[AppBlade sharedManager] handleCrashReport];
            }
            else
            {
                ABDebugLog_internal(@"Appblade: PLCrashReporter has no more crash reports");
            }

        }];
        
        [client setFailBlock:^(id data, NSError* error){
            ABErrorLog(@"Appblade: error sending crash report, response status code: %d", status);
            //No more crash reports for now. We might have bad internet access.
        }];

        
    }
    return client;
}

- (void)handleWebClientCrashReported:(AppBladeWebOperation *)client
{
}

- (void)crashReportCallbackFailed:(AppBladeWebOperation *)client withErrorString:(NSString*)errorString
{
    if(errorString){
        ABErrorLog(@"ERROR sending crash %@", errorString);
    }
}

#pragma mark Stored Crash Handling

-(void) catchAndReportCrashes
{
    ABDebugLog_internal(@"Catch and report crashes");
    [self checkForExistingCrashReports];

    PLCrashReporter *crashReporter = [PLCrashReporter sharedReporter];
    NSError *error;
    // Enable the Crash Reporter
    if (![crashReporter enableCrashReporterAndReturnError: &error])
        ABErrorLog(@"Warning: Could not enable crash reporter: %@", error);
}

- (void) checkForExistingCrashReports
{
    PLCrashReporter *crashReporter = [PLCrashReporter sharedReporter];
    // Check if we previously crashed
    if ([crashReporter hasPendingCrashReport]){
        [[AppBlade sharedManager] handleCrashReport];
    }
}

- (NSDictionary *) handleCrashReportAsDictionary
{
    PLCrashReporter *crashReporter = [PLCrashReporter sharedReporter];
    NSData *crashData;
    NSError *error;
    NSString* reportString = nil;
    NSString *queuedFilePath = nil;
    // Try loading the crash report from the live file
    crashData = [crashReporter loadPendingCrashReportDataAndReturnError: &error];
    if (crashData != nil) {
        PLCrashReport *report = [[PLCrashReport alloc] initWithData: crashData error: &error];
        if (report != nil) {
            reportString = [PLCrashReportTextFormatter stringValueForCrashReport:report withTextFormat: PLCrashReportTextFormatiOS];
            //send pending crash report to a unique file name in the the queue
            queuedFilePath = [crashReporter saveCrashReportInQueue:reportString]; //file will stay in the queue until it's sent
            if(queuedFilePath == nil){
                ABErrorLog(@"error saving crash report");
            }
            else
            {
                ABDebugLog_internal(@"moved crash report to %@", queuedFilePath);
            }
        }
        else
        {
            ABErrorLog(@"Could not parse crash report");
        }
    }
    else
    {
        ABErrorLog(@"Could not load a crash report from live file");
    }
    [crashReporter purgePendingCrashReport]; //remove crash report from immediate file, we have it in the queue now
    
    if(queuedFilePath == nil){
        //we had no immediate crash, or an invalid save, grab any stored crash report
        queuedFilePath = [crashReporter getNextCrashReportPath];
        reportString = [NSString stringWithContentsOfFile:queuedFilePath encoding:NSUTF8StringEncoding error:&error];
    }
    if(queuedFilePath != nil){
        return [NSDictionary dictionaryWithObjectsAndKeys:queuedFilePath, kCrashDictQueuedFilePath, reportString, kCrashDictCrashReportString, nil];
    }
    else
    {
        ABDebugLog_internal(@"No crashes to report");
        return nil;
    }
}




@end
