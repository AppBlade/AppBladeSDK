//
//  SessionTracking.m
//  AppBlade
//
//  Created by AndrewTremblay on 7/16/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "APBSessionTrackingManager.h"
#import "AppBlade+PrivateMethods.h"


NSString *sessionURLFormat           = @"%@/api/3/user_sessions";
NSString *kSessionStartDate           = @"session_started_at";
NSString *kSessionEndDate             = @"session_ended_at";
NSString *kSessionTimeElapsed         = @"session_time_elapsed";

@implementation APBSessionTrackingManager
@synthesize delegate;
@synthesize sessionStartDate;
@synthesize sessionEndDate;



- (id)initWithDelegate:(id<APBWebOperationDelegate>)webOpDelegate
{
    if((self = [super init])) {
        self.delegate = webOpDelegate;
    }
    
    return self;
}

- (void)logSessionStart
{
  [self checkForAndPostSessions];
    
    self.sessionStartDate = [NSDate date];
    self.sessionEndDate = nil;
}

- (void)logSessionEnd
{
    if (self.sessionStartDate != nil) { //check first if we even HAVE a session
        self.sessionEndDate = [NSDate date];
        NSDictionary* sessionDict = [NSDictionary dictionaryWithObjectsAndKeys:[self sessionStartDate], @"started_at", [self sessionEndDate], @"ended_at", [[AppBlade sharedManager] getCustomParams], @"custom_params", nil];
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
    
    [self checkForAndPostSessions];
}

-(void)checkForAndPostSessions
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
}


- (NSDictionary*)currentSession
{
    NSMutableDictionary *toRet = nil;
    if (self.sessionStartDate != nil) { //check first if we even HAVE a session
        toRet = [NSMutableDictionary dictionaryWithObjectsAndKeys:self.sessionStartDate, kSessionStartDate, nil];
    }
    if (toRet != nil && self.sessionEndDate != nil) {
        [toRet setObject:self.sessionEndDate forKey:kSessionEndDate];
    }
    return toRet;
}



- (void)handleWebClientSentSessions:(APBWebOperation *)client withSuccess:(BOOL)success
{
    ABDebugLog_internal(@"Success sending Sessions");
    //clean up sessions handled in the success block, let's not pass the buck too much here.
    self.sessionStartDate = nil;
    self.sessionEndDate = nil;
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
    
    __block NSArray* sessionsReference = sessions;
    [self setRequestCompletionBlock:^(NSMutableURLRequest *request, id rawSentData, NSDictionary* responseHeaders, NSMutableData* receivedData, NSError *webError){
        NSString* receivedDataString = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
        if(receivedDataString){ ABDebugLog_internal(@"Received Response from AppBlade Sessions %@", receivedDataString); }
        int status = [[responseHeaders valueForKey:@"statusCode"] intValue];
        BOOL success = (status == 201 || status == 200);
        if(success){
            selfReference.successBlock(sessionsReference, nil);
        }
        else
        {
            selfReference.failBlock(nil, nil);
        }

    }];
    
    [self setSuccessBlock:^(id data, NSError* error){
        [[AppBlade sharedManager] appBladeWebClientSentSessions:selfReference withSuccess:true];
        //delete existing sessions, as we have reported them
        NSString* sessionFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeSessionFile];
        if ([[NSFileManager defaultManager] fileExistsAtPath:sessionFilePath]) {
            //only keep our fresh, unsent sessions
            NSArray* sentSessions = (NSArray*)data;
            NSArray* allSessions = (NSArray*)[[AppBlade sharedManager] readFile:sessionFilePath];
            NSMutableArray* freshSessions = [allSessions mutableCopy]; //most we'll have is all sessions
            for(NSDictionary *sentSession in sentSessions){
                for (int i = freshSessions.count-1; i >= 0; i--) {
                    NSDictionary* session = (NSDictionary *)[freshSessions objectAtIndex:i];
                    if ([session isEqualToDictionary:sentSession]) {
                        [freshSessions removeObjectAtIndex:i];
                        //just in case there are duplicates, remove all matches
                    }
                }
            }

            NSError *deleteError = nil;
            [[NSFileManager defaultManager] removeItemAtPath:sessionFilePath error:&deleteError];
            if(deleteError){
                ABErrorLog(@"Error deleting Session log: %@", deleteError.debugDescription);
                //oh well, keep going I guess
            }
            
            NSData* sessionData = [NSKeyedArchiver archivedDataWithRootObject:freshSessions];
            [sessionData writeToFile:sessionFilePath atomically:YES];
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

