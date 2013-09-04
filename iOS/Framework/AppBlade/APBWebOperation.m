//
//  AppBladeWebClient.m
//  AppBlade
//
//  Created by Craig Spitzkoff on 6/18/11.
//  Copyright 2011 AppBlade. All rights reserved.
//

#import "APBWebOperation.h"
#import "PLCrashReporter.h"

#import "AppBlade.h"
#import "AppBladeLogging.h"
#import "APBWebOperation+PrivateMethods.h"

#import "APBDeviceInfoManager.h"
#import "APBApplicationInfoManager.h"

#import <CommonCrypto/CommonHMAC.h>
#include "APBFileMD5Hash.h"
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <TargetConditionals.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#import <mach-o/ldsyms.h>


NSString *defaultURLScheme           = @"https";
NSString *defaultAppBladeHostURL     = @"https://AppBlade.com";

NSString *deviceSecretHeaderField    = @"X-device-secret";

@interface APBWebOperation ()

@property (nonatomic, strong) NSURLConnection *activeConnection;

//NSOperation related
@property (nonatomic, assign) BOOL finished;
@property (nonatomic, assign) BOOL executing;
@property (nonatomic, assign) NSTimeInterval timeoutInterval;
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskId;
@property (nonatomic, strong) NSThread *connectionThread;

@end

@implementation APBWebOperation

const int kNonceRandomStringLength = 74;

#pragma mark - Lifecycle

- (id)initWithDelegate:(id<APBWebOperationDelegate>)delegate
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

-(void) timeout
{
    if (self.isFinished || self.isCancelled) {
        return;
    }

    ABDebugLog_internal(@"AppBlade Timeout for %@", self.request.URL);
    
    APBWebOperation *selfReference = self;
    id<APBWebOperationDelegate> delegateReference = self.delegate;
    dispatch_async(dispatch_get_main_queue(), ^{
        [delegateReference appBladeWebClientFailed:selfReference];
    });
    [self cancel];
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
        [self willChangeValueForKey:@"isExecuting"];
        self.executing = NO;
        [self didChangeValueForKey:@"isExecuting"];
        [self willChangeValueForKey:@"isFinished"];
        self.finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
    
    if(error){
        ABErrorLog(@"AppBlade failed with error: %@ for %@", error.localizedDescription, self.request.URL);
    }
    
    APBWebOperation *selfReference = self;
    id<APBWebOperationDelegate> delegateReference = self.delegate;
    dispatch_async(dispatch_get_main_queue(), ^{
        [delegateReference appBladeWebClientFailed:selfReference];
    });
    
    [self willChangeValueForKey:@"isExecuting"];
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
        [self willChangeValueForKey:@"isExecuting"];
        self.executing = NO;
        [self didChangeValueForKey:@"isExecuting"];
        [self willChangeValueForKey:@"isFinished"];
        self.finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }    
    
    if(self.requestCompletionBlock){
        APBWebOperation *selfReference = self;
        dispatch_async(dispatch_get_main_queue(), ^(void){
              self.requestCompletionBlock(selfReference.request, selfReference.sentDeviceSecret, selfReference.responseHeaders, selfReference.receivedData, nil);
        });
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

// Creates a preformatted request with appblade headers.
- (NSMutableURLRequest *)requestForURL:(NSURL *)url
{
    // create the request
    NSMutableURLRequest* apiRequest = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10];
    
    // set up various headers on the request.
    [apiRequest addValue:[[NSBundle mainBundle] bundleIdentifier] forHTTPHeaderField:@"X-bundle-identifier"];
    [apiRequest addValue:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] forHTTPHeaderField:@"X-bundle-version"];
    [apiRequest addValue:[[AppBlade sharedManager] iosVersionSanitized] forHTTPHeaderField:@"X-ios-release"];

    [apiRequest addValue:[[AppBlade sharedManager] platform] forHTTPHeaderField:@"X-device-model"];
    [apiRequest addValue:[AppBlade sdkVersion] forHTTPHeaderField:@"X-sdk-version"];
    if([[[AppBlade sharedManager] appBladeDeviceSecret] length] == 0) {
        [apiRequest addValue:[[AppBlade sharedManager] appBladeProjectSecret] forHTTPHeaderField:@"X-project-secret"];
    }
    [apiRequest addValue:[[AppBlade sharedManager] appBladeDeviceSecret] forHTTPHeaderField:deviceSecretHeaderField]; //@"X-device-secret"
    
    [apiRequest addValue:[[AppBlade sharedManager] executableUUID] forHTTPHeaderField:@"X-executable-UUID"];
    [apiRequest addValue:[[AppBlade sharedManager] hashExecutable] forHTTPHeaderField:@"X-bundle-executable-hash"];
    [apiRequest addValue:[[AppBlade sharedManager] hashInfoPlist] forHTTPHeaderField:@"X-info-plist-hash"];
    
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

@end
