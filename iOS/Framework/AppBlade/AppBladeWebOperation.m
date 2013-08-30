//
//  AppBladeWebClient.m
//  AppBlade
//
//  Created by Craig Spitzkoff on 6/18/11.
//  Copyright 2011 AppBlade. All rights reserved.
//

#import "AppBladeWebOperation.h"
#import "PLCrashReporter.h"

#import "AppBlade.h"
#import "AppBladeLogging.h"
#import "AppBladeWebOperation+PrivateMethods.h"

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

@interface AppBladeWebOperation ()

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

@end

@implementation AppBladeWebOperation

const int kNonceRandomStringLength = 74;

#pragma mark - Lifecycle

- (id)initWithDelegate:(id<AppBladeWebOperationDelegate>)delegate
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
        
        if (self.prepareBlock) {
            self.prepareBlock(self.request);
        }
        
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
    
    AppBladeWebOperation *selfReference = self;
    id<AppBladeWebOperationDelegate> delegateReference = self.delegate;
    dispatch_async(dispatch_get_main_queue(), ^{
        [delegateReference appBladeWebClientFailed:selfReference];
    });

    
    if(self.failBlock != nil){
        self.failBlock(selfReference, error);
    }
    
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
    
    if(self.requestCompletionBlock){
//        NSMutableURLRequest *requestLocal = [self.request copy];
//        NSDictionary* responseHeadersLocal = [self.responseHeaders copy];
        AppBladeWebOperation *selfReference = self;
        dispatch_async(dispatch_get_main_queue(), ^(void){
              self.requestCompletionBlock(selfReference.request, selfReference.sentDeviceSecret, selfReference.responseHeaders, selfReference.receivedData, nil);
        });
    }
    
    if (self.api == AppBladeWebClientAPI_GenerateToken) {
        NSError *error = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:self.receivedData options:nil error:&error];
        ABDebugLog_internal(@"Parsed JSON: %@", json);
        AppBladeWebOperation *selfReference = self;
        id<AppBladeWebOperationDelegate> delegateReference = self.delegate;
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegateReference appBladeWebClient:selfReference receivedGenerateTokenResponse:json];
        });
    }
    else if (self.api == AppBladeWebClientAPI_ConfirmToken) {
        NSError *error = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:self.receivedData options:nil error:&error];
        self.receivedData = nil;
        AppBladeWebOperation *selfReference = self;
        id<AppBladeWebOperationDelegate> delegateReference = self.delegate;
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegateReference appBladeWebClient:selfReference receivedConfirmTokenResponse:json];
        });
    }
    else if(self.api == AppBladeWebClientAPI_Permissions) {
        
    }
    else if (self.api == AppBladeWebClientAPI_ReportCrash) {
        AppBladeWebOperation *selfReference = self;
        id<AppBladeWebOperationDelegate> delegateReference = self.delegate;
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegateReference appBladeWebClientCrashReported:selfReference];
        });
    }
    else if (self.api == AppBladeWebClientAPI_Feedback) {
    }
    else if (self.api == AppBladeWebClientAPI_Sessions) {
        //NSString* receivedDataString = [[[NSString alloc] initWithData:self.receivedData encoding:NSUTF8StringEncoding] autorelease];
        //ABDebugLog_internal(@"Received Response from AppBlade Sessions %@", receivedDataString);
        int status = [[self.responseHeaders valueForKey:@"statusCode"] intValue];
        BOOL success = (status == 201 || status == 200);
        AppBladeWebOperation *selfReference = self;
        id<AppBladeWebOperationDelegate> delegateReference = self.delegate;
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
            AppBladeWebOperation *selfReference = self;
            if(self.successBlock){
                self.successBlock(selfReference, error);
            }
        }
        else
        {
            ABErrorLog(@"Error parsing update plist: %@", [error debugDescription]);
            AppBladeWebOperation *selfReference = self;
            id<AppBladeWebOperationDelegate> delegateReference = self.delegate;
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegateReference appBladeWebClientFailed:selfReference withErrorString:@"An invalid update response was received from AppBlade; please contact support"];
            });
            
            if(self.failBlock != nil){
                self.failBlock(selfReference, error);
            }
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
    NSString *result = (__bridge NSString *)(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)str, NULL, CFSTR("?=&+"), kCFStringEncodingUTF8));
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
    FileMD5HashCreateWithPath((__bridge CFStringRef)(filePath), FileHashDefaultChunkSizeForReadingData);
    if (executableFileMD5Hash) {
        returnString = (__bridge NSString *)(executableFileMD5Hash);
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
#if TARGET_IPHONE_SIMULATOR
    return @"00000-0000-0000-0000-00000000";
#else
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
#endif
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
