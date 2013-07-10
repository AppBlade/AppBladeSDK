//
//  AppBladeWebClient.m
//  AppBlade
//
//  Created by Craig Spitzkoff on 6/18/11.
//  Copyright 2011 AppBlade. All rights reserved.
//

#import "AppBladeWebClient.h"
#import "PLCrashReporter.h"

#import "AppBlade.h"
#import "AppBladeLogging.h"

#import <CommonCrypto/CommonHMAC.h>
#include "FileMD5Hash.h"
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <TargetConditionals.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#import <mach-o/ldsyms.h>


NSString *defaultURLScheme           = @"https";
NSString *defaultAppBladeHostURL     = @"https://AppBlade.com";
NSString *tokenGenerateURLFormat     = @"%@/api/3/authorize/new";
NSString *tokenConfirmURLFormat      = @"%@/api/3/authorize"; //keeping these separate for readiblilty and possible editing later
NSString *authorizeURLFormat         = @"%@/api/3/authorize";
NSString *reportCrashURLFormat       = @"%@/api/3/crash_reports";
NSString *reportFeedbackURLFormat    = @"%@/api/3/feedback";
NSString *sessionURLFormat           = @"%@/api/3/user_sessions";
NSString *updateURLFormat            = @"%@/api/3/updates";

NSString *deviceSecretHeaderField    = @"X-device-secret";


@interface AppBladeWebClient ()

@property (nonatomic, readwrite) AppBladeWebClientAPI api;

@property (nonatomic, strong) NSString* osVersionBuild;
@property (nonatomic, strong) NSString* platform;
@property (nonatomic, strong) NSString *executableUUID;
@property (nonatomic, strong) NSURLConnection *activeConnection;

//NSOperation related
@property (nonatomic, assign) BOOL finished;
@property (nonatomic, assign) BOOL executing;
@property (nonatomic, assign) NSTimeInterval timeoutInterval;
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskId;
@property (nonatomic, strong) NSThread *connectionThread;
-(void)issueRequest;
-(void)scheduleTimeout;
-(void)cancelTimeout;

// Request builder methods.
- (NSMutableURLRequest *)requestForURL:(NSURL *)url;
- (void)addSecurityToRequest:(NSMutableURLRequest *)request;
// Crypto methods.
- (NSString *)HMAC_SHA256_Base64:(NSString *)data with_key:(NSString *)key;
- (NSString *)SHA_Base64:(NSString *)raw;
- (NSString *)encodeBase64WithData:(NSData *)objData;
- (NSString *)genRandStringLength:(int)len;
- (NSString *)genRandNumberLength:(int)len;
- (NSString *)urlEncodeValue:(NSString*)string; //no longer being used
- (NSString *)hashFile:(NSString*)filePath;
- (NSString *)hashExecutable;
- (NSString *)hashInfoPlist;
//Device info
- (NSString *)genExecutableUUID;
- (NSString *)executable_uuid;
- (NSString *)ios_version_sanitized;

@end

@implementation AppBladeWebClient


const int kNonceRandomStringLength = 74;

#pragma mark - Lifecycle

- (id)initWithDelegate:(id<AppBladeWebClientDelegate>)delegate
{
    if((self = [super init])) {
        self.delegate = delegate;
    }
    
    return self;
}


#pragma mark - NSOperation functions
- (void)start
{
    if (self.isCancelled) {
        // If it's already been cancelled, mark the operation as finished and don't start the connection.
        [self willChangeValueForKey:@"isFinished"];
        self.finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
    [self willChangeValueForKey:@"isExecuting"];
    [NSThread detachNewThreadSelector:@selector(issueRequest) toTarget:self withObject:nil];    // Issue the request. That's all
}

- (void) issueRequest
{
    if((nil != self.request) && !self.isCancelled){
            ABDebugLog_internal(@"Success_IssueRequest: Starting API call.");
            self.executing = YES;
            [self didChangeValueForKey:@"isExecuting"];
            [self willChangeValueForKey:@"isFinished"];
            self.finished = NO;
            [self didChangeValueForKey:@"isFinished"];
            self.activeConnection = [[NSURLConnection alloc] initWithRequest:_request delegate:self startImmediately:YES] ;
        
        
        
        // Keep track of the current thread
        self.connectionThread = [NSThread currentThread];
        
        // setup our timeout callback.
        if(self.timeoutInterval <= 0)
            self.timeoutInterval = 60;
        [self scheduleTimeout];
        
        while (!self.finished && !self.isCancelled) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
        
        @synchronized(self){
            
            // end the background task
            if (self.backgroundTaskId != UIBackgroundTaskInvalid){
                [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskId];
                self.backgroundTaskId = UIBackgroundTaskInvalid;
            }
            
            self.connectionThread = nil;
            
            [self willChangeValueForKey:@"isFinished"];
            [self willChangeValueForKey:@"isExecuting"];
            
            self.finished = YES;
            self.executing = NO;
            
            [self didChangeValueForKey:@"isExecuting"];
            [self didChangeValueForKey:@"isFinished"];
        }
        
    } else {
        ABErrorLog(@"Error_IssueRequest: API request was cancelled or did not initialize properly. Did not perform an API call.");
        self.executing = NO;
        [self didChangeValueForKey:@"isExecuting"];
        [self willChangeValueForKey:@"isFinished"];
        self.finished = YES;
        [self didChangeValueForKey:@"isFinished"];
    }
}

-(void) cancel
{
    if ([NSThread currentThread] != self.connectionThread && self.connectionThread){
        [self performSelector:@selector(cancelOperation) onThread:self.connectionThread withObject:nil waitUntilDone:NO];
    }
    else{
        [self cancelOperation];
    }
}

-(void) cancelOperation
{
    @synchronized(self){
        if (self.isFinished) return;
        [super cancel];
        [self cancelTimeout];
    }
}


- (BOOL)isConcurrent {
    return YES;
}

// Flags
- (BOOL)isExecuting {
    return self.executing;
}

- (BOOL)isFinished {
    return self.finished;
}

-(void) scheduleTimeout
{
    @synchronized(self){
        if (self.isCancelled) return;
        [self cancelTimeout];
        [self performSelector:@selector(timeout) withObject:nil afterDelay:self.timeoutInterval];
    }
}

-(void)cancelTimeout
{
    // if we never assigned the connection thread property, we never will have scheduled a timeout
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if (self.isCancelled) {
        ABDebugLog_internal(@"API Call cancelled. didReceiveResponse, but can't ignore yet.");
    }
	// Reset the data object.
    self.receivedData = [[NSMutableData alloc] init];
    NSMutableDictionary* headers = [NSMutableDictionary dictionaryWithDictionary:[(NSHTTPURLResponse *)response allHeaderFields]];
    [headers setObject:[NSNumber numberWithInteger:[(NSHTTPURLResponse *)response statusCode]] forKey:@"statusCode"];
    self.responseHeaders = headers;
}


- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)aRequest redirectResponse:(NSURLResponse *)redirectResponse;
{
    if (self.isCancelled) {
        ABDebugLog_internal(@"API Call cancelled. willSendRequest, but can't ignore yet.");
    }
    
    if (redirectResponse) {
		// Clone and retarget request to new URL.
        NSMutableURLRequest *redirectRequest = [self.request mutableCopy] ;
        [redirectRequest setURL: [aRequest URL]];
        return [redirectRequest copy];
    }
    else
    {
        return self.request;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[self.receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.receivedData = nil;
    
    if (self.isCancelled) {
        ABDebugLog_internal(@"API Call cancelled. didFailWithError, but Ignoring.");
        [self willChangeValueForKey:@"isFinished"];
        self.executing = NO;
        [self didChangeValueForKey:@"isExecuting"];
        [self willChangeValueForKey:@"isFinished"];
        self.finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
    
    
    ABErrorLog(@"AppBlade failed with error: %@", error.localizedDescription);
    
    AppBladeWebClient *selfReference = self;
    id<AppBladeWebClientDelegate> delegateReference = self.delegate;
    dispatch_async(dispatch_get_main_queue(), ^{
        [delegateReference appBladeWebClientFailed:selfReference];
    });
    
    [self willChangeValueForKey:@"isFinished"];
    self.executing = NO;
    [self didChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    self.finished = YES;
    [self didChangeValueForKey:@"isFinished"];

    self.request = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (self.isCancelled) {
        ABDebugLog_internal(@"API Call cancelled. connectionDidFinishLoading, but Ignoring.");
        [self willChangeValueForKey:@"isFinished"];
        self.executing = NO;
        [self didChangeValueForKey:@"isExecuting"];
        [self willChangeValueForKey:@"isFinished"];
        self.finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
    
    if (self.api == AppBladeWebClientAPI_GenerateToken) {
        NSError *error = nil;
        //NSString* string = [[[NSString alloc] initWithData:self.receivedData encoding:NSUTF8StringEncoding] autorelease];
        //ABDebugLog_internal(@"Received Device Secret Refresh Response from AppBlade: %@", string);
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:self.receivedData options:nil error:&error];
        AppBladeWebClient *selfReference = self;
        id<AppBladeWebClientDelegate> delegateReference = self.delegate;
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegateReference appBladeWebClient:selfReference receivedGenerateTokenResponse:json];
        });
    }
    else if (self.api == AppBladeWebClientAPI_ConfirmToken) {
        NSError *error = nil;
        //NSString* string = [[[NSString alloc] initWithData:self.receivedData encoding:NSUTF8StringEncoding] autorelease];
        //ABDebugLog_internal(@"Received Device Secret Confirm Response from AppBlade: %@", string);
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:self.receivedData options:nil error:&error];
        self.receivedData = nil;
        AppBladeWebClient *selfReference = self;
        id<AppBladeWebClientDelegate> delegateReference = self.delegate;
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegateReference appBladeWebClient:selfReference receivedConfirmTokenResponse:json];
        });
    }
    else if(self.api == AppBladeWebClientAPI_Permissions) {
        NSError *error = nil;
        //NSString* string = [[[NSString alloc] initWithData:self.receivedData encoding:NSUTF8StringEncoding] autorelease];
        NSDictionary *plist = [NSJSONSerialization JSONObjectWithData:self.receivedData options:nil error:&error];
        //BOOL showUpdatePrompt = [self.request valueForHTTPHeaderField:@"SHOULD_PROMPT"];
        
        
        if (plist && error == NULL) {
            AppBladeWebClient *selfReference = self;
            id<AppBladeWebClientDelegate> delegateReference = self.delegate;
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegateReference appBladeWebClient:selfReference receivedPermissions:plist];
            });

        }
        else
        {
            ABErrorLog(@"Error parsing permisions json: %@", [error debugDescription]);
            AppBladeWebClient *selfReference = self;
            id<AppBladeWebClientDelegate> delegateReference = self.delegate;
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegateReference appBladeWebClientFailed:selfReference withErrorString:@"An invalid response was received from AppBlade; please contact support"];
            });

        }
        
    }
    else if (self.api == AppBladeWebClientAPI_ReportCrash) {
        AppBladeWebClient *selfReference = self;
        id<AppBladeWebClientDelegate> delegateReference = self.delegate;
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegateReference appBladeWebClientCrashReported:selfReference];
        });
    }
    else if (self.api == AppBladeWebClientAPI_Feedback) {
        int status = [[self.responseHeaders valueForKey:@"statusCode"] intValue];
        BOOL success = (status == 201 || status == 200);
        AppBladeWebClient *selfReference = self;
        id<AppBladeWebClientDelegate> delegateReference = self.delegate;
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegateReference appBladeWebClientSentFeedback:selfReference withSuccess:success];
        });        
    }
    else if (self.api == AppBladeWebClientAPI_Sessions) {
        //NSString* receivedDataString = [[[NSString alloc] initWithData:self.receivedData encoding:NSUTF8StringEncoding] autorelease];
        //ABDebugLog_internal(@"Received Response from AppBlade Sessions %@", receivedDataString);
        int status = [[self.responseHeaders valueForKey:@"statusCode"] intValue];
        BOOL success = (status == 201 || status == 200);
        AppBladeWebClient *selfReference = self;
        id<AppBladeWebClientDelegate> delegateReference = self.delegate;
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegateReference appBladeWebClientSentSessions:selfReference withSuccess:success];
        });
    }
    else if(self.api == AppBladeWebClientAPI_UpdateCheck) {
        NSError *error = nil;
        //NSString* string = [[[NSString alloc] initWithData:self.receivedData encoding:NSUTF8StringEncoding] autorelease];
        //ABDebugLog_internal(@"Received Update Response from AppBlade: %@", string);
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:_receivedData options:nil error:&error];
        self.receivedData = nil;
        
        if (json && error == NULL) {
            AppBladeWebClient *selfReference = self;
            id<AppBladeWebClientDelegate> delegateReference = self.delegate;
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegateReference appBladeWebClient:selfReference receivedUpdate:json];
            });
        }
        else
        {
            ABErrorLog(@"Error parsing update plist: %@", [error debugDescription]);
            AppBladeWebClient *selfReference = self;
            id<AppBladeWebClientDelegate> delegateReference = self.delegate;
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegateReference appBladeWebClientFailed:selfReference withErrorString:@"An invalid update response was received from AppBlade; please contact support"];
            });
        }
    }
    else
    {
        ABErrorLog(@"Unhandled connection with AppBladeWebClientAPI value %d", self.api);
    }
    
    [self willChangeValueForKey:@"isFinished"];
    self.executing = NO;
    [self didChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    self.finished = YES;
    [self didChangeValueForKey:@"isFinished"];
    self.request = nil;
}


#pragma mark - AppBlade API calls
- (void)refreshToken:(NSString *)tokenToConfirm
{
    [self setApi:  AppBladeWebClientAPI_GenerateToken];
    BOOL hasFairplay = [[AppBlade sharedManager] isAppStoreBuild];
    if(hasFairplay){
        //we're signed by apple, skip authentication. Go straight to delegate.
        ABDebugLog_internal(@"Binary signed by Apple, skipping token generation");
 //        [self.delegate appBladeWebClient:self receivedPermissions: ];
    }
    else
    {
        // Create the request.
        NSString* urlString = [NSString stringWithFormat:tokenGenerateURLFormat, [self.delegate appBladeHost]];
        NSURL* projectUrl = [NSURL URLWithString:urlString];
        NSMutableURLRequest* apiRequest = [self requestForURL:projectUrl];
        [apiRequest setHTTPMethod:@"GET"];
        [self addSecurityToRequest:apiRequest];
        [apiRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"]; //we want json
    }
}

- (void)confirmToken:(NSString *)tokenToConfirm
{
    ABDebugLog_internal(@"confirming token (client)");
    [self setApi: AppBladeWebClientAPI_ConfirmToken];
    BOOL hasFairplay = [[AppBlade sharedManager] isAppStoreBuild];
    if(hasFairplay){
        //we're signed by apple, skip authentication. Go straight to delegate.
        ABDebugLog_internal(@"Binary signed by Apple, skipping token confirmation");
//        [self.delegate appBladeWebClient:self receivedPermissions: ];
    }
    else
    {
        //NSString *storedSecret = [[AppBlade sharedManager] appBladeDeviceSecret];
        //ABDebugLog_internal(@"storedSecret %@", storedSecret);
        ABDebugLog_internal(@"tokenToConfirm %@", tokenToConfirm);
        

        if(nil != tokenToConfirm && ![tokenToConfirm isEqualToString:@""]){
            // Create the request.
            NSString* urlString = [NSString stringWithFormat:tokenConfirmURLFormat, [self.delegate appBladeHost]];
            NSURL* projectUrl = [NSURL URLWithString:urlString];
            NSMutableURLRequest* apiRequest = [self requestForURL:projectUrl];
            [apiRequest setHTTPMethod:@"POST"];
            [self addSecurityToRequest:apiRequest];
            [apiRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"]; //we want json
            //apiRequest is a retained reference to the _request ivar.
        }
        else
        {
            ABDebugLog_internal(@"We have no stored secret");
        }
    }
}


- (void)checkPermissions
{
    [self setApi: AppBladeWebClientAPI_Permissions];
    BOOL hasFairplay = [[AppBlade sharedManager] isAppStoreBuild];
    if(hasFairplay){
        //we're signed by apple, skip authentication. Go straight to delegate.
        ABDebugLog_internal(@"Binary signed by Apple, skipping permissions check forever");
        NSDictionary *fairplayPermissions = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:INT_MAX], @"ttl", nil];
        AppBladeWebClient *selfReference = self;
        id<AppBladeWebClientDelegate> delegateReference = self.delegate;
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegateReference appBladeWebClient:selfReference receivedPermissions:fairplayPermissions];
        });
    }
    else
    {
        // Create the request.
        NSString* urlString = [NSString stringWithFormat:authorizeURLFormat, [self.delegate appBladeHost]];
        NSURL* projectUrl = [NSURL URLWithString:urlString];
        NSMutableURLRequest* apiRequest = [self requestForURL:projectUrl];
        [apiRequest setHTTPMethod:@"GET"];
        [apiRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"]; //we want json
        [self addSecurityToRequest:apiRequest];
        //apiRequest is a retained reference to the _request ivar.
    }
}


- (void)checkForUpdates
{
    BOOL hasFairplay = [[AppBlade sharedManager] isAppStoreBuild];
    if(hasFairplay){
        //we're signed by apple, skip updating. Go straight to delegate.
        ABDebugLog_internal(@"Binary signed by Apple, skipping update check forever");
        NSDictionary *fairplayPermissions = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:INT_MAX], @"ttl", nil];
        AppBladeWebClient *selfReference = self;
        id<AppBladeWebClientDelegate> delegateReference = self.delegate;
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegateReference appBladeWebClient:selfReference receivedUpdate:fairplayPermissions];
        });
    }
    else
    {
        // Create the request.
        [self setApi: AppBladeWebClientAPI_UpdateCheck];
        NSString* urlString = [NSString stringWithFormat:updateURLFormat, [self.delegate appBladeHost]];
        NSURL* projectUrl = [NSURL URLWithString:urlString];
        NSMutableURLRequest* apiRequest = [self requestForURL:projectUrl];
        [apiRequest setHTTPMethod:@"GET"];
        [apiRequest addValue:@"true" forHTTPHeaderField:@"USE_ANONYMOUS"];
        [self addSecurityToRequest:apiRequest]; //don't need security, but we could do better with it.
        [apiRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"]; //we want json
        ABDebugLog_internal(@"Update call %@", urlString);
        //apiRequest is a retained reference to the _request ivar.
    }
}

- (void)reportCrash:(NSString *)crashReport withParams:(NSDictionary *)paramsDict {
    [self setApi: AppBladeWebClientAPI_ReportCrash];
    @synchronized (self)
    {
    // Build report URL.
    NSString* urlCrashReportString = [NSString stringWithFormat:reportCrashURLFormat, [self.delegate appBladeHost]];
    NSURL* urlCrashReport = [NSURL URLWithString:urlCrashReportString];    
        
        NSString *multipartBoundary = [NSString stringWithFormat:@"---------------------------%@", [self genRandNumberLength:64]];
    // Create the API request.
    NSMutableURLRequest* apiRequest = [self requestForURL:urlCrashReport];
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

    [self addSecurityToRequest:apiRequest];

        //apiRequest is a retained reference to the _request ivar.
    }
}

- (void)sendFeedbackWithScreenshot:(NSString*)screenshot note:(NSString*)note console:(NSString *)console params:(NSDictionary*)paramsDict
{
    [self setApi: AppBladeWebClientAPI_Feedback];
    
    @synchronized (self)
    {
        NSString* screenshotPath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:screenshot];
        
        // Build report URL.
        NSString* reportString = [NSString stringWithFormat:reportFeedbackURLFormat, [self.delegate appBladeHost]];
        NSURL* reportURL = [NSURL URLWithString:reportString];
    
        NSString *multipartBoundary = [NSString stringWithFormat:@"---------------------------%@", [self genRandNumberLength:64]];
        
        // Create the API request.
        NSMutableURLRequest* apiRequest = [self requestForURL:reportURL];
        [apiRequest setValue:[@"multipart/form-data; boundary=" stringByAppendingString:multipartBoundary] forHTTPHeaderField:@"Content-Type"];
        [apiRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [apiRequest setHTTPMethod:@"POST"];
        
        NSMutableData* body = [NSMutableData dataWithData:[[NSString stringWithFormat:@"--%@\r\n",multipartBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Disposition: form-data; name=\"feedback[notes]\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[note dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",multipartBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"feedback[screenshot]\"; filename=\"base64:%@\"\r\n", screenshot] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        
        NSData* screenshotData = [[self encodeBase64WithData:[NSData dataWithContentsOfFile:screenshotPath]] dataUsingEncoding:NSUTF8StringEncoding];
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
        
        [self addSecurityToRequest:apiRequest];
        
        //apiRequest is a retained reference to the _request ivar.
    }
}

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

        [self addSecurityToRequest:request];
        //request is a retained reference to the _request ivar.
    }
    else {
        ABErrorLog(@"Error parsing session data");
        if(error)
            ABErrorLog(@"Error %@", [error debugDescription]);
        
        //we may have to remove the sessions file in extreme cases
        AppBladeWebClient *selfReference = self;
        id<AppBladeWebClientDelegate> delegateReference = self.delegate;
        dispatch_async(dispatch_get_main_queue(), ^{
        [delegateReference appBladeWebClientFailed:selfReference];
        });
    }
    
}


#pragma mark - Request helper methods.
- (NSString *)ios_version_sanitized
{
    NSMutableString *asciiCharacters = [NSMutableString string];
    for (NSInteger i = 32; i < 127; i++)  {
        [asciiCharacters appendFormat:@"%c", i];
    }
    NSCharacterSet *nonAsciiCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:asciiCharacters] invertedSet];
    NSString *rawVersionString = [self osVersionBuild];
    return [[rawVersionString componentsSeparatedByCharactersInSet:nonAsciiCharacterSet] componentsJoinedByString:@""];
}


// Creates a preformatted request with appblade headers.
- (NSMutableURLRequest *)requestForURL:(NSURL *)url
{
    // create the request
    NSMutableURLRequest* apiRequest = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10];
    
    // set up various headers on the request.
    [apiRequest addValue:[[NSBundle mainBundle] bundleIdentifier] forHTTPHeaderField:@"X-bundle-identifier"];
    [apiRequest addValue:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] forHTTPHeaderField:@"X-bundle-version"];
    [apiRequest addValue:[self ios_version_sanitized] forHTTPHeaderField:@"X-ios-release"];

    [apiRequest addValue:[self platform] forHTTPHeaderField:@"X-device-model"];
    [apiRequest addValue:[AppBlade sdkVersion] forHTTPHeaderField:@"X-sdk-version"];
    if([[[AppBlade sharedManager] appBladeDeviceSecret] length] == 0) {
        [apiRequest addValue:[[AppBlade sharedManager] appBladeProjectSecret] forHTTPHeaderField:@"X-project-secret"];
    }
    [apiRequest addValue:[[AppBlade sharedManager] appBladeDeviceSecret] forHTTPHeaderField:deviceSecretHeaderField]; //@"X-device-secret"
    
    [apiRequest addValue:[self executable_uuid] forHTTPHeaderField:@"X-executable-UUID"];
    [apiRequest addValue:[self hashExecutable] forHTTPHeaderField:@"X-bundle-executable-hash"];
    [apiRequest addValue:[self hashInfoPlist] forHTTPHeaderField:@"X-info-plist-hash"];
    
    BOOL hasFairplay = [[AppBlade sharedManager] isAppStoreBuild];
    [apiRequest addValue:(hasFairplay ? @"1" : @"0") forHTTPHeaderField:@"X-fairplay-encrypted"];
    if(!hasFairplay){
        [apiRequest addValue:[[UIDevice currentDevice] name] forHTTPHeaderField:@"X-moniker"];
    }
    if ([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)]) {
        [apiRequest addValue:[[[UIDevice currentDevice] identifierForVendor] UUIDString] forHTTPHeaderField:@"X-device-vendor-udid"];
    }
    
    self.request = apiRequest;
    return apiRequest;
}

- (void)addSecurityToRequest:(NSMutableURLRequest *)request
{    //determine http or https
    NSString* scheme = [[request URL] scheme];
    if(scheme == nil){
        scheme = defaultURLScheme;
    }
    else
    {
        scheme = [scheme lowercaseString]; //for string comparison sanity
    }
    NSString* preparedHostName = [NSString stringWithFormat:@"%@://%@", scheme, [[request URL] host] ];
    
    //find port number
    NSString* port = nil;
    if ([[request URL] port]) {
        port = [[[request URL] port] stringValue];
        preparedHostName = [preparedHostName stringByAppendingFormat:@":%@", port];
    }
    else
    {   // Set port number based on the scheme
        port = [scheme isEqualToString:@"https"] ? @"443" : @"80";
    }

    // Construct the relative URL path, followed by the body if POST.
    NSMutableString *requestBodyRaw = [NSMutableString stringWithString:[[[request URL] absoluteString] substringFromIndex:[preparedHostName length]]];
    if([request HTTPBody]) {
        // Append "?" and the HTTP body.
        NSString* dataString = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding] ;
        [requestBodyRaw appendFormat:@"?%@", dataString];
    }
    
    
    // Construct the nonce (salt). First part of the salt is the delta of the current time and the stored time the
    // version was issued at, then a colon, then a random string of a certain length.
    NSString* randomString = [self genRandStringLength:kNonceRandomStringLength];
    NSString* nonce = [NSString stringWithFormat:@"%@:%@", [self.delegate appBladeProjectSecret], randomString];
    NSString* ext = [self.delegate appBladeDeviceSecret];
    
    NSString *requestBodyHash = [self SHA_Base64:requestBodyRaw];
    ABDebugLog_internal(@"%d", [requestBodyRaw length]);
    
    // Compose the normalized request body.
    NSMutableString* request_body = [NSMutableString stringWithFormat:@"%@\n%@\n%@\n%@\n%@\n%@\n%@\n",
                                     nonce,
                                     [request HTTPMethod],
                                     requestBodyRaw,
                                     [[request URL] host],
                                     port,
                                     requestBodyHash,
                                     ext];
    ABDebugLog_internal(@"%@", requestBodyHash);
    ABDebugLog_internal(@"%@", [requestBodyRaw substringToIndex:MIN([requestBodyRaw length], 1000)]);
    
    // Digest the normalized request body.
    NSString* mac = [self HMAC_SHA256_Base64:request_body with_key:[self.delegate appBladeProjectSecret]];
    
    NSMutableString *authHeader = [NSMutableString stringWithString:@"HMAC "];
    [authHeader appendFormat:@"id=\"%@\"", [self.delegate appBladeProjectSecret]];
    [authHeader appendFormat:@", nonce=\"%@\"", nonce];
    [authHeader appendFormat:@", body-hash=\"%@\"", requestBodyHash];
    [authHeader appendFormat:@", ext=\"%@\"", ext];
    [authHeader appendFormat:@", mac=\"%@\"", mac];
    [request setValue:authHeader forHTTPHeaderField:@"Authorization"];
    
    // Request is now fully prepared and secure.
}


- (NSString *)urlEncodeValue:(NSString *)str //no longer being used
{
    NSString *result = (NSString *) CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)str, NULL, CFSTR("?=&+"), kCFStringEncodingUTF8));
    return result ;
}

#pragma mark - Crypto utilities

// Generates an HMAC digest using SHA-256 and base 64.
- (NSString *)HMAC_SHA256_Base64:(NSString*)data with_key:(NSString *)key
{
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, [key UTF8String], [key lengthOfBytesUsingEncoding:NSASCIIStringEncoding], [data UTF8String], [data lengthOfBytesUsingEncoding:NSASCIIStringEncoding], cHMAC);
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    return [self encodeBase64WithData:HMAC];
}

- (NSString*)SHA_Base64:(NSString*)raw
{
    unsigned char hashedChars[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256([raw UTF8String], [raw lengthOfBytesUsingEncoding:NSASCIIStringEncoding], hashedChars);
    NSData *toEncode = [[NSData alloc] initWithBytes:hashedChars length:sizeof(hashedChars)];
    return [self encodeBase64WithData:toEncode];
}

// Derived from QSUtilities.
- (NSString *)encodeBase64WithData:(NSData *)objData
{
    static const char _base64EncodingTable[64] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    const unsigned char * objRawData = [objData bytes];
	char * objPointer;
	char * strResult;
	// Get the Raw Data length and ensure we actually have data
	int intLength = [objData length];
	if (intLength == 0) return nil;
	// Setup the String-based Result placeholder and pointer within that placeholder
	strResult = (char *)calloc(((intLength + 2) / 3) * 4, sizeof(char));
	objPointer = strResult;
	// Iterate through everything
	while (intLength > 2) { // keep going until we have less than 24 bits
		*objPointer++ = _base64EncodingTable[objRawData[0] >> 2];
		*objPointer++ = _base64EncodingTable[((objRawData[0] & 0x03) << 4) + (objRawData[1] >> 4)];
		*objPointer++ = _base64EncodingTable[((objRawData[1] & 0x0f) << 2) + (objRawData[2] >> 6)];
		*objPointer++ = _base64EncodingTable[objRawData[2] & 0x3f];	
		// we just handled 3 octets (24 bits) of data
		objRawData += 3;
		intLength -= 3; 
	}
	// now deal with the tail end of things
	if (intLength != 0) {
		*objPointer++ = _base64EncodingTable[objRawData[0] >> 2];
		if (intLength > 1) {
			*objPointer++ = _base64EncodingTable[((objRawData[0] & 0x03) << 4) + (objRawData[1] >> 4)];
			*objPointer++ = _base64EncodingTable[(objRawData[1] & 0x0f) << 2];
			*objPointer++ = '=';
		}
        else
        {
			*objPointer++ = _base64EncodingTable[(objRawData[0] & 0x03) << 4];
			*objPointer++ = '=';
			*objPointer++ = '=';
		}
	}
	// Terminate the string-based result
	*objPointer = '\0';
    NSString *toRet = [NSString stringWithCString:strResult encoding:NSASCIIStringEncoding];
    free(strResult);
	// Return the results as an NSString object
	return toRet;
}

// Derived from http://stackoverflow.com/q/2633801/2633948#2633948
- (NSString *)genRandStringLength:(int)len
{
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];  
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random()%[letters length]] ];
    }      
    return [randomString copy];
}

// Derived from http://stackoverflow.com/q/2633801/2633948#2633948
- (NSString *)genRandNumberLength:(int)len
{
    NSString *letters = @"123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random()%[letters length]] ];
    }
    return [randomString copy];
}

#pragma mark - MD5 Hashing

- (NSString*)hashFile:(NSString *)filePath
{
    NSString* returnString = nil;
    CFStringRef executableFileMD5Hash = 
    FileMD5HashCreateWithPath((CFStringRef)CFBridgingRetain(filePath), 
                              FileHashDefaultChunkSizeForReadingData);
    if (executableFileMD5Hash) {
        returnString = (NSString *)CFBridgingRelease(executableFileMD5Hash);
        CFRelease(executableFileMD5Hash);
    }
    
    return returnString ;
}

- (NSString*)hashExecutable
{
    NSString *executablePath = [[NSBundle mainBundle] executablePath];
    return [self hashFile:executablePath];
}

- (NSString*)hashInfoPlist
{
    NSString *plistPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Info.plist"];
    return [self hashFile:plistPath];
}


#pragma mark - receivedStatusCode
-(int)getReceivedStatusCode
{
    int status = 500;
    if(self.responseHeaders){
       status = [[self.responseHeaders valueForKey:@"statusCode"] intValue];
    }
    return status;
}

#pragma mark - sentDeviceSecret

-(NSString *)sentDeviceSecret {
    if(self.request){
        _sentDeviceSecret = [self.request valueForHTTPHeaderField:deviceSecretHeaderField];
    }
    return _sentDeviceSecret;
}

#pragma mark buildHostURL

+ (NSString *)buildHostURL:(NSString *)customURLString
{
    NSString* preparedHostName = nil;
    if(customURLString == nil){
        ABDebugLog_internal(@"No custom URL: defaulting to %@", defaultAppBladeHostURL);
        preparedHostName = defaultAppBladeHostURL;
    }
    else
    {
        //build a request to check if the supplied url is valid
        NSURL *requestURL = [[NSURL alloc] initWithString:customURLString];
        if(requestURL == nil)
        {
            ABErrorLog(@"Could not parse given URL: %@ defaulting to %@", customURLString, defaultAppBladeHostURL);
            preparedHostName = defaultAppBladeHostURL;
        }
        else
        {
            ABDebugLog_internal(@"Found custom URL %@", customURLString);
            preparedHostName = customURLString;
        }
    }
    ABDebugLog_internal(@"built host URL: %@", preparedHostName);
    return preparedHostName;
}

#pragma mark ExecutableUUID


- (NSString *)executable_uuid
{
#if TARGET_IPHONE_SIMULATOR
    return @"00000-0000-0000-0000-00000000";
#else
    return [self genExecutableUUID];
#endif
}


//_mh_execute_header is declared in mach-o/ldsyms.h (and not an iVar as you might have thought).
-(NSString *)genExecutableUUID //will break in simulator, please be careful
{
    if(_executableUUID == nil){
        const uint8_t *command = (const uint8_t *)(&_mh_execute_header + 1);
        for (uint32_t idx = 0; idx < _mh_execute_header.ncmds; ++idx) {
            if (((const struct load_command *)command)->cmd == LC_UUID) {
                command += sizeof(struct load_command);
                _executableUUID = [NSString stringWithFormat:@"%02X%02X%02X%02X-%02X%02X-%02X%02X-%02X%02X-%02X%02X%02X%02X%02X%02X",
                                    command[0], command[1], command[2], command[3],
                                    command[4], command[5],
                                    command[6], command[7],
                                    command[8], command[9],
                                    command[10], command[11], command[12], command[13], command[14], command[15]];
                break;
            }
            else
            {
                command += ((const struct load_command *)command)->cmdsize;
            }
        }
    }
    return _executableUUID;
}



#pragma mark - Fairplay

// From: http://stackoverflow.com/questions/4857195/how-to-get-programmatically-ioss-alphanumeric-version-string
- (NSString *)osVersionBuild {
    if(_osVersionBuild == nil){
        int mib[2] = {CTL_KERN, KERN_OSVERSION};
        u_int namelen = sizeof(mib) / sizeof(mib[0]);
        size_t bufferSize = 0;
        
        NSString *osBuildVersion = nil;
        
        // Get the size for the buffer
        sysctl(mib, namelen, NULL, &bufferSize, NULL, 0);
        
        u_char buildBuffer[bufferSize];
        int result = sysctl(mib, namelen, buildBuffer, &bufferSize, NULL, 0);
        
        if (result >= 0) {
            osBuildVersion = [[NSString alloc] initWithBytes:buildBuffer length:bufferSize encoding:NSUTF8StringEncoding];
        }
        _osVersionBuild = osBuildVersion;
    }
    return _osVersionBuild;
}

- (NSString *) platform{
    if(_platform == nil){
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *machine = malloc(size);
        sysctlbyname("hw.machine", machine, &size, NULL, 0);
        self.platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
        free(machine);
    }
    return _platform;
}



@end
