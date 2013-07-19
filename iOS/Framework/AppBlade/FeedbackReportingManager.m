//
//  FeedbackReporting
//  AppBlade
//
//  Created by AndrewTremblay on 7/15/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "FeedbackReportingManager.h"
#import "AppBlade.h"


@interface FeedbackReportingManager ()

@end

@implementation FeedbackReportingManager

- (id)initWithDelegate:(id<AppBladeWebOperationDelegate>)delegate
{
    if((self = [super init])) {
        self.delegate = delegate;
    }
    
    return self;
}

#pragma mark - Web Request Generators

- (AppBladeWebOperation*) generateFeedbackWithScreenshot:(NSString*)screenshot note:(NSString*)note console:(NSString*)console params:(NSDictionary*)paramsDict
{
    
    AppBladeWebOperation *client = [[AppBladeWebOperation alloc] initWithDelegate:self.delegate];
    [client setApi: AppBladeWebClientAPI_Feedback];

    NSString* screenshotPath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:screenshot];
    // Build report URL.
    NSString* reportString = [NSString stringWithFormat:reportFeedbackURLFormat, [client.delegate appBladeHost]];
    NSURL* reportURL = [NSURL URLWithString:reportString];
    
    NSString *multipartBoundary = [NSString stringWithFormat:@"---------------------------%@", [client genRandNumberLength:64]];
    
    // Create the API request.
    NSMutableURLRequest* apiRequest = [client requestForURL:reportURL];
    [apiRequest setValue:[@"multipart/form-data; boundary=" stringByAppendingString:multipartBoundary] forHTTPHeaderField:@"Content-Type"];
    [apiRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [apiRequest setHTTPMethod:@"POST"];
    
    NSMutableData* body = [NSMutableData dataWithData:[[NSString stringWithFormat:@"--%@\r\n",multipartBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Disposition: form-data; name=\"feedback[notes]\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[note dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",multipartBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"feedback[screenshot]\"; filename=\"base64:%@\"\r\n", screenshot] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSData* screenshotData = [[client encodeBase64WithData:[NSData dataWithContentsOfFile:screenshotPath]] dataUsingEncoding:NSUTF8StringEncoding];
    [body appendData:screenshotData];
    
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
    
    //set our weak/block references
    __weak AppBladeWebOperation *weakClient = client;
    //set our blocks
    [client setPrepareBlock:^(NSMutableURLRequest * apiRequest){
        NSLog(@"WOO WE'RE IN A BLOCK %@", apiRequest);
        [weakClient addSecurityToRequest:apiRequest];
    }];
 
    
    NSDictionary *blockFeedbackDictionary = [[[NSDictionary alloc] initWithObjectsAndKeys:note, kAppBladeFeedbackKeyNotes, screenshot, kAppBladeFeedbackKeyScreenshot, nil] copy];
    [client setSuccessBlock:^(id data, NSError* error){
        ABDebugLog_internal(@"feedback Successful");
        
        NSDictionary* feedback = [weakClient.userInfo objectForKey:kAppBladeFeedbackKeyFeedback];
        // Clean up
        NSString* screenshotPath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:[feedback objectForKey:kAppBladeFeedbackKeyScreenshot]];
        [[NSFileManager defaultManager] removeItemAtPath:screenshotPath error:nil];
        
        NSString* backupFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeBacklogFileName];
        NSMutableArray* backups = [NSMutableArray arrayWithContentsOfFile:backupFilePath];
        
        NSString* fileName = [weakClient.userInfo objectForKey:kAppBladeFeedbackKeyBackup];
        
        NSString* filePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:fileName];
        ABDebugLog_internal(@"Removing supporting feedback files and the feedback file herself");
        [self removeIntermediateFeedbackFiles:filePath];
        
        ABDebugLog_internal(@"Removing Successful feedback object from main feedback list");
        [backups removeObject:fileName];
        if (backups.count > 0) {
            ABDebugLog_internal(@"writing pending feedback objects back to file");
            [backups writeToFile:backupFilePath atomically:YES];
        }
        
        ABDebugLog_internal(@"checking for more pending feedback");
        if ([self hasPendingFeedbackReports]) {
            ABDebugLog_internal(@"more pending feedback");
            [[AppBlade sharedManager] handleBackloggedFeedback];
        }
        else
        {
            ABDebugLog_internal(@"no more pending feedback");
        }

    }];
    [client setFailBlock:^(id data, NSError* error){
        @synchronized (self){
            ABErrorLog(@"ERROR sending feedback");
            NSString* backupFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeBacklogFileName];
            NSMutableArray* backupFiles = [NSMutableArray arrayWithContentsOfFile:backupFilePath];
            NSString *fileName = [weakClient.userInfo objectForKey:kAppBladeFeedbackKeyBackup];
            BOOL isBacklog = ([[backupFiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF == %@",fileName]] count] > 0);
            if (!isBacklog) {
                NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
                NSString* newFeedbackName = [[NSString stringWithFormat:@"%0.0f", now] stringByAppendingPathExtension:@"plist"];
                NSString* feedbackPath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:newFeedbackName];
                [blockFeedbackDictionary writeToFile:feedbackPath atomically:YES];
                
                if (!backupFiles) {
                    backupFiles = [NSMutableArray array];
                }
                
                [backupFiles addObject:newFeedbackName];
                
                BOOL success = [backupFiles writeToFile:backupFilePath atomically:YES];
                if(!success){
                    ABErrorLog(@"Error writing backup file to %@", backupFilePath);
                }
            }
            else {
                
            }
        }

    }];
    
    [client setRequestCompletionBlock:^(NSMutableURLRequest *request, id rawSentData, NSDictionary* responseHeaders, NSMutableData* receivedData, NSError *error){
        int status = [[responseHeaders valueForKey:@"statusCode"] intValue];
        BOOL succeeded = (status == 201 || status == 200);
        
        BOOL isBacklog = [[weakClient delegate] containsOperationInPendingRequests:weakClient];
        if (succeeded){
            NSLog(@"Success!");
            if(weakClient.successBlock != nil) {
                NSLog(@"successBlock!");
                weakClient.successBlock(receivedData, nil);
            }
        }
        else if (!isBacklog) {
            ABDebugLog_internal(@"Unsuccesful feedback not found in backLog");
            
            // If we fail sending, add to backlog
            // We do not remove backlogged files unless the request is sucessful
            
            NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
            NSString* newFeedbackName = [[NSString stringWithFormat:@"%0.0f", now] stringByAppendingPathExtension:@"plist"];
            NSString* feedbackPath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:newFeedbackName];
            
            [blockFeedbackDictionary writeToFile:feedbackPath atomically:YES];
            
            NSString* backupFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeBacklogFileName];
            NSMutableArray* backupFiles = [NSMutableArray arrayWithContentsOfFile:backupFilePath];
            if (!backupFiles) {
                backupFiles = [NSMutableArray array];
            }
            
            [backupFiles addObject:newFeedbackName];
            
            BOOL success = [backupFiles writeToFile:backupFilePath atomically:YES];
            if(!success){
                ABErrorLog(@"Error writing backup file to %@", backupFilePath);
            }
        } //else it's failed and already in the backlog. Keep it there.
    }];
    

    
    return client;
}


#pragma mark Stored Web Request Behavior

- (BOOL)hasPendingFeedbackReports
{
    BOOL toRet = NO;
    @synchronized (self){
        NSString *feedbackBacklogFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeBacklogFileName];
        if([[NSFileManager defaultManager] fileExistsAtPath:feedbackBacklogFilePath]){
            ABDebugLog_internal(@"found file at %@", feedbackBacklogFilePath);
            NSMutableArray* backupFiles = [NSMutableArray arrayWithContentsOfFile:feedbackBacklogFilePath];
            if (backupFiles.count > 0) {
                ABDebugLog_internal(@"found %d files at feedbackBacklogFilePath", backupFiles.count);
                toRet = YES;
            }
            else
            {
                ABDebugLog_internal(@"found NO files at feedbackBacklogFilePath");
                toRet = NO;
            }
        }
        else
        {
            ABDebugLog_internal(@"found nothing at %@", feedbackBacklogFilePath);
            toRet = NO;
        }
    }
    return toRet;
}


- (void)removeIntermediateFeedbackFiles:(NSString *)feedbackPath
{
    NSDictionary* feedback = [NSDictionary dictionaryWithContentsOfFile:feedbackPath];
    if (feedback) {
        ABDebugLog_internal(@"Cleaning Feedback %@", feedback);
        NSString *screenshotFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:[feedback objectForKey:kAppBladeFeedbackKeyScreenshot]];
        
        NSError *screenShotError = nil;
        [[NSFileManager defaultManager] removeItemAtPath:screenshotFilePath error:&screenShotError];
    }
    NSError *feedbackPathError = nil;
    [[NSFileManager defaultManager] removeItemAtPath:feedbackPath error:&feedbackPathError];
    
}



@end
