//
//  SessionTracking.m
//  AppBlade
//
//  Created by AndrewTremblay on 7/16/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "APBSessionTrackingManager.h"
#import "AppBlade+PrivateMethods.h"

@implementation APBSessionTrackingManager
@synthesize delegate;
@synthesize sessionStartDate;


- (id)initWithDelegate:(id<APBWebOperationDelegate>)webOpDelegate
{
    if((self = [super init])) {
        self.delegate = webOpDelegate;
    }
    
    return self;
}

- (void)logSessionStart
{
    NSString* sessionFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeSessionFile];
    ABDebugLog_internal(@"Checking Session Path: %@", sessionFilePath);
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:sessionFilePath]) {
        NSArray* sessions = (NSArray*)[[AppBlade sharedManager] readFile:sessionFilePath];
        ABDebugLog_internal(@"%d Sessions Exist, posting them", [sessions count]);
        
        if(![self hasPendingSessions]){
            APBWebOperation * client = [[AppBlade sharedManager] generateWebOperation];
            [client postSessions:sessions];
            [[AppBlade sharedManager] addPendingRequest:client];
        }
    }
    self.sessionStartDate = [NSDate date];
}

- (void)logSessionEnd
{
    NSDictionary* sessionDict = [NSDictionary dictionaryWithObjectsAndKeys:[self  sessionStartDate], @"started_at", [NSDate date], @"ended_at", [[AppBlade sharedManager] getCustomParams], @"custom_params", nil];
    
    NSMutableArray* pastSessions = nil;
    NSString* sessionFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeSessionFile];
    if ([[NSFileManager defaultManager] fileExistsAtPath:sessionFilePath]) {
        NSArray* sessions = (NSArray*)[[AppBlade sharedManager] readFile:sessionFilePath];
        pastSessions = [sessions mutableCopy] ;
    }
    else {
        pastSessions = [NSMutableArray arrayWithCapacity:1];
    }
    
    [pastSessions addObject:sessionDict];
    
    NSData* sessionData = [NSKeyedArchiver archivedDataWithRootObject:pastSessions];
    [sessionData writeToFile:sessionFilePath atomically:YES];    
}


- (void)handleWebClientSentSessions:(APBWebOperation *)client withSuccess:(BOOL)success
{
}


- (void)sessionTrackingCallbackFailed:(APBWebOperation *)client withErrorString:(NSString*)errorString
{
    ABErrorLog(@"Failure sending Sessions");
}

- (BOOL)hasPendingSessions {
    //check active clients for API_Sessions
    NSInteger sessionClients = [[AppBlade sharedManager] pendingRequestsOfType:AppBladeWebClientAPI_Sessions];
    return sessionClients > 0;
}

@end


@implementation APBWebOperation (Sessiontracking)

- (void)postSessions:(NSArray *)sessions
{
    [self setApi: AppBladeWebClientAPI_Sessions];
    
    NSString* sessionString = [NSString stringWithFormat:sessionURLFormat, [self.delegate appBladeHost]];
    NSURL* sessionURL = [NSURL URLWithString:sessionString];
    
    NSError* error = nil;
    NSData* requestData = [NSPropertyListSerialization dataWithPropertyList:sessions format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
    
    if (requestData && error == nil) {
        NSString *multipartBoundary = [NSString stringWithFormat:@"---------------------------%@", [self genRandNumberLength:64]];
        
        NSMutableURLRequest* request = [self requestForURL:sessionURL];
        [request setHTTPMethod:@"PUT"];
        [request setValue:[@"multipart/form-data; boundary=" stringByAppendingString:multipartBoundary] forHTTPHeaderField:@"Content-Type"];
        
        NSMutableData* body = [NSMutableData dataWithData:[[NSString stringWithFormat:@"--%@\r\n",multipartBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Disposition: form-data; name=\"device_secret\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[[AppBlade sharedManager] appBladeDeviceSecret] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",multipartBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Disposition: form-data; name=\"project_secret\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[[AppBlade sharedManager] appBladeProjectSecret] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",multipartBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Disposition: form-data; name=\"sessions\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type: text/xml\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:requestData];
        [body appendData:[[[@"\r\n--" stringByAppendingString:multipartBoundary] stringByAppendingString:@"--"] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [request setHTTPBody:body];
        [request setValue:[NSString stringWithFormat:@"%d", [body length]] forHTTPHeaderField:@"Content-Length"];
        
        //request is a retained reference to the _request ivar.
    }
    else {
        ABErrorLog(@"Error parsing session data");
        if(error){
            ABErrorLog(@"Error %@", [error debugDescription]);
        }
    }
    
    APBWebOperation *selfReference = self;
    
    [self setPrepareBlock:^(NSMutableURLRequest *request){
        [selfReference addSecurityToRequest:request];
    }];
    
    [self setRequestCompletionBlock:^(NSMutableURLRequest *request, id rawSentData, NSDictionary* responseHeaders, NSMutableData* receivedData, NSError *webError){
        NSString* receivedDataString = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
        if(receivedDataString){ ABDebugLog_internal(@"Received Response from AppBlade Sessions %@", receivedDataString); }
        int status = [[responseHeaders valueForKey:@"statusCode"] intValue];
        BOOL success = (status == 201 || status == 200);
        if(success){
            selfReference.successBlock(nil, nil);
        }
        else
        {
            selfReference.failBlock(nil, nil);
        }

    }];
    
    [self setSuccessBlock:^(id data, NSError* error){
        //delete existing sessions, as we have reported them
        NSString* sessionFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeSessionFile];
        if ([[NSFileManager defaultManager] fileExistsAtPath:sessionFilePath]) {
            NSError *deleteError = nil;
            [[NSFileManager defaultManager] removeItemAtPath:sessionFilePath error:&deleteError];
            
            if(deleteError){
                ABErrorLog(@"Error deleting Session log: %@", deleteError.debugDescription);
            }
        }
    }];

    [self setFailBlock:^(id data, NSError* error){
        ABErrorLog(@"Error sending Session log");
    }];

}

@end

@implementation AppBlade (SessionTracking)
    @dynamic sessionTrackingManager;

    - (void)appBladeWebClientSentSessions:(APBWebOperation *)client withSuccess:(BOOL)success
    {
        [self.sessionTrackingManager handleWebClientSentSessions:client withSuccess:success];
    }
@end

