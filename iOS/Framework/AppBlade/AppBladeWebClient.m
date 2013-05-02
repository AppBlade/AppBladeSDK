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


@interface AppBladeWebClient ()

@property (nonatomic, readwrite) AppBladeWebClientAPI api;

@property (nonatomic, readonly) NSString* osVersionBuild;
@property (nonatomic, readonly) NSString* platform;


@property (nonatomic, readonly) NSString *executableUUID;

@property (nonatomic, retain) NSURLConnection *activeConnection;

// Request helper methods.

//
- (NSString *)executable_uuid;
- (NSString *)ios_version_sanitized;


- (NSMutableURLRequest *)requestForURL:(NSURL *)url;
- (void)addSecurityToRequest:(NSMutableURLRequest *)request;

// Crypto helper methods.

- (NSString *)HMAC_SHA256_Base64:(NSString *)data with_key:(NSString *)key;
- (NSString *)SHA_Base64:(NSString *)raw;
- (NSString *)encodeBase64WithData:(NSData *)objData;
- (NSString *)genRandStringLength:(int)len;
- (NSString *)genRandNumberLength:(int)len;
- (NSString *)urlEncodeValue:(NSString*)string;

- (NSString *)hashFile:(NSString*)filePath;
- (NSString *)hashExecutable;
- (NSString *)hashInfoPlist;

//other device info methods
- (NSString *)genExecutableUUID;

@end

@implementation AppBladeWebClient

@synthesize osVersionBuild = _osVersionBuild;
@synthesize platform = _platform;

@synthesize delegate = _delegate;
@synthesize api = _api;
@synthesize responseHeaders = _responseHeaders;
@synthesize userInfo = _userInfo;
@synthesize executableUUID = _executableUUID;


@synthesize activeConnection = _activeConnection;

const int kNonceRandomStringLength = 74;

#pragma mark - Fairplay

/* The encryption info struct and constants are missing from the iPhoneSimulator SDK, but not from the iPhoneOS or
 * Mac OS X SDKs. Since one doesn't ever ship a Simulator binary, we'll just provide the definitions here. */
#if TARGET_IPHONE_SIMULATOR && !defined(LC_ENCRYPTION_INFO)
#define LC_ENCRYPTION_INFO 0x21
struct encryption_info_command {
uint32_t cmd;
uint32_t cmdsize;
uint32_t cryptoff;
uint32_t cryptsize;
uint32_t cryptid;
};
#endif

int main (int argc, char *argv[]);

static BOOL is_encrypted () {
    const struct mach_header *header;
    Dl_info dlinfo;
    
    /* Fetch the dlinfo for main() */
    if (dladdr(main, &dlinfo) == 0 || dlinfo.dli_fbase == NULL) {
        NSLog(@"Could not find main() symbol (very odd)");
        return NO;
    }
    header = dlinfo.dli_fbase;
    
    /* Compute the image size and search for a UUID */
    struct load_command *cmd = (struct load_command *) (header+1);
    
    for (uint32_t i = 0; cmd != NULL && i < header->ncmds; i++) {
        /* Encryption info segment */
        if (cmd->cmd == LC_ENCRYPTION_INFO) {
            struct encryption_info_command *crypt_cmd = (struct encryption_info_command *) cmd;
            /* Check if binary encryption is enabled */
            if (crypt_cmd->cryptid < 1) {
                /* Disabled, probably pirated */
                return NO;
            }
            
            /* Probably not pirated? */
            return YES;
        }
        
        cmd = (struct load_command *) ((uint8_t *) cmd + cmd->cmdsize);
    }
    
    /* Encryption info not found */
    return NO;
}

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
            osBuildVersion = [[[NSString alloc] initWithBytes:buildBuffer length:bufferSize encoding:NSUTF8StringEncoding] autorelease];
        }
        _osVersionBuild = [osBuildVersion retain];
    }
    return _osVersionBuild;
}

- (NSString *) platform{
    if(_platform == nil){
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *machine = malloc(size);
        sysctlbyname("hw.machine", machine, &size, NULL, 0);
        _platform = [[NSString stringWithCString:machine encoding:NSUTF8StringEncoding] retain];
        free(machine);
    }
    return _platform;
}

#pragma mark - Lifecycle

- (id)initWithDelegate:(id<AppBladeWebClientDelegate>)delegate
{
    if((self = [super init])) {
        _delegate = delegate;
    }
    
    return self;
}

- (void)dealloc
{
    [_request release];
    [_receivedData release];
    [_responseHeaders release];
    [_userInfo release];
    [_osVersionBuild release];
    [_platform release];
    [_executableUUID release];
    [_activeConnection release];
    [super dealloc];
}


+ (NSString *)buildHostURL:(NSString *)customURLString
{
    NSString* preparedHostName = nil;
    if(customURLString == nil){
        NSLog(@"No custom URL: defaulting to %@", defaultAppBladeHostURL);
        preparedHostName = defaultAppBladeHostURL;
    }
    else
    {
        //build a request to check if the supplied url is valid
        NSURL *requestURL = [[[NSURL alloc] initWithString:customURLString] autorelease];
        if(requestURL == nil)
        {
            NSLog(@"Could not parse given URL: %@ defaulting to %@", customURLString, defaultAppBladeHostURL);
            preparedHostName = defaultAppBladeHostURL;
        }
        else
        {
            NSLog(@"Found custom URL %@", customURLString);
            preparedHostName = customURLString;
        }
    }
    NSLog(@"built host URL: %@", preparedHostName);
    return preparedHostName;
}


#pragma mark - AppBlade API
- (void)refreshToken
{
    [self setApi:  AppBladeWebClientAPI_GenerateToken];
    BOOL hasFairplay = is_encrypted();
    if(hasFairplay){
        //we're signed by apple, skip authentication. Go straight to delegate.
        NSLog(@"Binary signed by Apple, skipping token generation");
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
        // Issue the request.
        self.activeConnection = [[[NSURLConnection alloc] initWithRequest:apiRequest delegate:self] autorelease];
    }
}

- (void)confirmToken
{
    NSLog(@"confirming token (client)");
    [self setApi: AppBladeWebClientAPI_ConfirmToken];
    BOOL hasFairplay = is_encrypted();
    if(hasFairplay){
        //we're signed by apple, skip authentication. Go straight to delegate.
        NSLog(@"Binary signed by Apple, skipping token confirmation");
//        [self.delegate appBladeWebClient:self receivedPermissions: ];
    }
    else
    {
        NSString *storedSecret = [[AppBlade sharedManager] appBladeDeviceSecret];
        NSLog(@"storedSecret %@", storedSecret);

        if(nil != storedSecret && ![storedSecret isEqualToString:@""]){
            // Create the request.
            NSString* urlString = [NSString stringWithFormat:tokenConfirmURLFormat, [self.delegate appBladeHost]];
            NSURL* projectUrl = [NSURL URLWithString:urlString];
            NSMutableURLRequest* apiRequest = [self requestForURL:projectUrl];
            [apiRequest setHTTPMethod:@"POST"];
            [self addSecurityToRequest:apiRequest];
            [apiRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"]; //we want json
            // Issue the request.
            self.activeConnection = [[[NSURLConnection alloc] initWithRequest:apiRequest delegate:self] autorelease];
        }
        else
        {
            NSLog(@"We have no stored secret");
        }
    }
}


- (void)checkPermissions
{
    [self setApi: AppBladeWebClientAPI_Permissions];
    BOOL hasFairplay = is_encrypted();
    if(hasFairplay){
        //we're signed by apple, skip authentication. Go straight to delegate.
        NSLog(@"Binary signed by Apple, skipping permissions check forever");
        NSDictionary *fairplayPermissions = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:INT_MAX], @"ttl", nil];
        [self.delegate appBladeWebClient:self receivedPermissions:fairplayPermissions];
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
        // Issue the request.
        self.activeConnection = [[[NSURLConnection alloc] initWithRequest:apiRequest delegate:self] autorelease];
    }
}


- (void)checkForUpdates
{
    BOOL hasFairplay = is_encrypted();
    if(hasFairplay){
        //we're signed by apple, skip updating. Go straight to delegate.
        NSLog(@"Binary signed by Apple, skipping update check forever");
        NSDictionary *fairplayPermissions = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:INT_MAX], @"ttl", nil];
        [self.delegate appBladeWebClient:self receivedUpdate:fairplayPermissions];
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
        NSLog(@"Update call %@", urlString);
        // Issue the request.
        self.activeConnection = [[[NSURLConnection alloc] initWithRequest:apiRequest delegate:self] autorelease];
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
            NSLog(@"Parsed params! They were included.");
        }
        else
        {
            NSLog(@"Error parsing params. They weren't included. %@ ",error.debugDescription);
        }
    }
    
    [body appendData:[[[@"\r\n--" stringByAppendingString:multipartBoundary] stringByAppendingString:@"--"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [apiRequest setHTTPBody:body];
    [apiRequest setValue:[NSString stringWithFormat:@"%d", [body length]] forHTTPHeaderField:@"Content-Length"];

    [self addSecurityToRequest:apiRequest];

    // Issue the request.
   self.activeConnection = [[[NSURLConnection alloc] initWithRequest:_request delegate:self] autorelease];
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
                NSLog(@"Parsed params! They were included.");
            }
            else
            {
                NSLog(@"Error parsing params. They weren't included. %@ ",error.debugDescription);
            }
        }
        
        [body appendData:[[[@"\r\n--" stringByAppendingString:multipartBoundary] stringByAppendingString:@"--"] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [apiRequest setHTTPBody:body];
        [apiRequest setValue:[NSString stringWithFormat:@"%d", [body length]] forHTTPHeaderField:@"Content-Length"];
        
        [self addSecurityToRequest:apiRequest];
        
        // Issue the request.
        self.activeConnection = [[[NSURLConnection alloc] initWithRequest:_request delegate:self] autorelease];
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
        self.activeConnection = [[[NSURLConnection alloc] initWithRequest:_request delegate:self] autorelease];
    }
    else {
        NSLog(@"Error parsing session data");
        if(error)
            NSLog(@"Error %@", [error debugDescription]);
        
        //we may have to remove the sessions file in extreme cases
        
        [self.delegate appBladeWebClientFailed:self];
        [_request release];
    }
    
}


#pragma mark - Request helper methods.

- (NSString *)executable_uuid
{
#if TARGET_IPHONE_SIMULATOR
    return @"00000-0000-0000-0000-00000000";
#else
    return [self genExecutableUUID];
#endif
}

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
    NSMutableURLRequest* apiRequest = [[[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10] autorelease];
    
    // set up various headers on the request.
    [apiRequest addValue:[[NSBundle mainBundle] bundleIdentifier] forHTTPHeaderField:@"bundle_identifier"];
    [apiRequest addValue:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] forHTTPHeaderField:@"bundle_version"];
    
    [apiRequest addValue:[self ios_version_sanitized] forHTTPHeaderField:@"IOS_RELEASE"];

    [apiRequest addValue:[self platform] forHTTPHeaderField:@"DEVICE_MODEL"];
    [apiRequest addValue:[[UIDevice currentDevice] name] forHTTPHeaderField:@"MONIKER"];
    [apiRequest addValue:[AppBlade sdkVersion] forHTTPHeaderField:@"sdk_version"];
    

    [apiRequest addValue:[[AppBlade sharedManager] appBladeProjectSecret] forHTTPHeaderField:@"project_secret"];
    [apiRequest addValue:[[AppBlade sharedManager] appBladeDeviceSecret] forHTTPHeaderField:@"device_secret"];
    
    [apiRequest addValue:[self executable_uuid] forHTTPHeaderField:@"executable_UUID"];
    [apiRequest addValue:[self hashExecutable] forHTTPHeaderField:@"bundleexecutable_hash"];
    [apiRequest addValue:[self hashInfoPlist] forHTTPHeaderField:@"infoplist_hash"];
    
    BOOL hasFairplay = is_encrypted();
    [apiRequest addValue:(hasFairplay ? @"1" : @"0") forHTTPHeaderField:@"fairplay_encrypted"];
    
    [_request release];
    _request = [apiRequest retain];
    
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
        NSString* dataString = [[[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding] autorelease];
        [requestBodyRaw appendFormat:@"?%@", dataString];
    }
    
    
    // Construct the nonce (salt). First part of the salt is the delta of the current time and the stored time the
    // version was issued at, then a colon, then a random string of a certain length.
    NSString* randomString = [self genRandStringLength:kNonceRandomStringLength];
    NSString* nonce = [NSString stringWithFormat:@"%@:%@", [self.delegate appBladeProjectSecret], randomString];
    NSString* ext = [self.delegate appBladeDeviceSecret];
    
    NSString *requestBodyHash = [self SHA_Base64:requestBodyRaw];
    NSLog(@"%d", [requestBodyRaw length]);
    
    // Compose the normalized request body.
    NSMutableString* request_body = [NSMutableString stringWithFormat:@"%@\n%@\n%@\n%@\n%@\n%@\n%@\n",
                                     nonce,
                                     [request HTTPMethod],
                                     requestBodyRaw,
                                     [[request URL] host],
                                     port,
                                     requestBodyHash,
                                     ext];
    NSLog(@"%@", requestBodyHash);
    NSLog(@"%@", [requestBodyRaw substringToIndex:MIN([requestBodyRaw length], 1000)]);
    
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


- (NSString *)urlEncodeValue:(NSString *)str
{
    NSString *result = (NSString *) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)str, NULL, CFSTR("?=&+"), kCFStringEncodingUTF8);
    return [result autorelease];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{    
	// Reset the data object.
	[_receivedData release];
    _receivedData = [[NSMutableData alloc] init];
    NSMutableDictionary* headers = [NSMutableDictionary dictionaryWithDictionary:[(NSHTTPURLResponse *)response allHeaderFields]];
    [headers setObject:[NSNumber numberWithInteger:[(NSHTTPURLResponse *)response statusCode]] forKey:@"statusCode"];
     self.responseHeaders = headers;
}


- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)aRequest redirectResponse:(NSURLResponse *)redirectResponse;
{
    if (redirectResponse) {
		// Clone and retarget request to new URL.
        NSMutableURLRequest *r = [[_request mutableCopy] autorelease];
        [r setURL: [aRequest URL]];
        return [[r copy] autorelease];
    }
    else
    {
        return _request;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{

	[_receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [_receivedData release];
    _receivedData = nil;
    
    NSLog(@"AppBlade failed with error: %@", error.localizedDescription);
    [self.delegate appBladeWebClientFailed:self];
    
    [_request release];
    _request = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (_api == AppBladeWebClientAPI_GenerateToken) {
        NSError *error = nil;
        //NSString* string = [[[NSString alloc] initWithData:_receivedData encoding:NSUTF8StringEncoding] autorelease];
        //NSLog(@"Received Device Secret Refresh Response from AppBlade: %@", string);
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:_receivedData options:nil error:&error];
        [_receivedData release];
        _receivedData = nil;
        
        [self.delegate appBladeWebClient:self receivedTokenResponse:json];
    }
    else if (_api == AppBladeWebClientAPI_ConfirmToken) {
        NSError *error = nil;
        //NSString* string = [[[NSString alloc] initWithData:_receivedData encoding:NSUTF8StringEncoding] autorelease];
        //NSLog(@"Received Device Secret Confirm Response from AppBlade: %@", string);
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:_receivedData options:nil error:&error];
        [_receivedData release];
        _receivedData = nil;
        
        [self.delegate appBladeWebClient:self receivedTokenResponse:json];
    }
    else if(_api == AppBladeWebClientAPI_Permissions) {
        NSError *error = nil;
        //NSString* string = [[[NSString alloc] initWithData:_receivedData encoding:NSUTF8StringEncoding] autorelease];
        //NSLog(@"Received Security Response from AppBlade: %@", string);
        NSDictionary *plist = [NSJSONSerialization JSONObjectWithData:_receivedData options:nil error:&error];
        //BOOL showUpdatePrompt = [_request valueForHTTPHeaderField:@"SHOULD_PROMPT"];

        [_receivedData release];
        _receivedData = nil;
        
        if (plist && error == NULL) {
            [self.delegate appBladeWebClient:self receivedPermissions:plist];
        }
        else
        {
            NSLog(@"Error parsing permisions json: %@", [error debugDescription]);
            [self.delegate appBladeWebClientFailed:self withErrorString:@"An invalid response was received from AppBlade; please contact support"];
        }
        
    }
    else if (_api == AppBladeWebClientAPI_ReportCrash) {
        [self.delegate appBladeWebClientCrashReported:self];
    
    }
    else if (_api == AppBladeWebClientAPI_Feedback) {
        int status = [[self.responseHeaders valueForKey:@"statusCode"] intValue];
        BOOL success = (status == 201 || status == 200);
        [self.delegate appBladeWebClientSentFeedback:self withSuccess:success];

    }
    else if (_api == AppBladeWebClientAPI_Sessions) {
        NSString* receivedDataString = [[[NSString alloc] initWithData:_receivedData encoding:NSUTF8StringEncoding] autorelease];
        NSLog(@"Received Response from AppBlade Sessions %@", receivedDataString);
        int status = [[self.responseHeaders valueForKey:@"statusCode"] intValue];
        BOOL success = (status == 201 || status == 200);
        [self.delegate appBladeWebClientSentSessions:self withSuccess:success];

    }
    else if(_api == AppBladeWebClientAPI_UpdateCheck) {
        NSError *error = nil;
        NSString* string = [[[NSString alloc] initWithData:_receivedData encoding:NSUTF8StringEncoding] autorelease];
        NSLog(@"Received Update Response from AppBlade: %@", string);
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:_receivedData options:nil error:&error];
        [_receivedData release];
        _receivedData = nil;
        
        if (json && error == NULL) {
            [self.delegate appBladeWebClient:self receivedUpdate:json];
        }
        else
        {
            NSLog(@"Error parsing update plist: %@", [error debugDescription]);
            [self.delegate appBladeWebClientFailed:self withErrorString:@"An invalid update response was received from AppBlade; please contact support"];
        }
    }
    else
    {
        NSLog(@"Unhandled connection with AppBladeWebClientAPI value %d", _api);
    }
    
    [_request release];
    _request = nil;
}

#pragma mark - Crypto utilities

// Generates an HMAC digest using SHA-256 and base 64.
- (NSString *)HMAC_SHA256_Base64:(NSString*)data with_key:(NSString *)key
{
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, [key UTF8String], [key lengthOfBytesUsingEncoding:NSASCIIStringEncoding], [data UTF8String], [data lengthOfBytesUsingEncoding:NSASCIIStringEncoding], cHMAC);
    NSData *HMAC = [[[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)] autorelease];
    return [self encodeBase64WithData:HMAC];
}

- (NSString*)SHA_Base64:(NSString*)raw
{
    unsigned char hashedChars[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256([raw UTF8String], [raw lengthOfBytesUsingEncoding:NSASCIIStringEncoding], hashedChars);
    NSData *toEncode = [[[NSData alloc] initWithBytes:hashedChars length:sizeof(hashedChars)] autorelease];
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
    return [[randomString copy] autorelease];
}

// Derived from http://stackoverflow.com/q/2633801/2633948#2633948
- (NSString *)genRandNumberLength:(int)len
{
    NSString *letters = @"123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random()%[letters length]] ];
    }
    return [[randomString copy] autorelease];
}

#pragma mark - MD5 Hashing

- (NSString*)hashFile:(NSString *)filePath
{
    NSString* returnString = nil;
    CFStringRef executableFileMD5Hash = 
    FileMD5HashCreateWithPath((CFStringRef)filePath, 
                              FileHashDefaultChunkSizeForReadingData);
    if (executableFileMD5Hash) {
        returnString = [(NSString *)executableFileMD5Hash retain];
        CFRelease(executableFileMD5Hash);
    }
    
    return [returnString autorelease];
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


#pragma mark Executable UUID
//_mh_execute_header is declared in mach-o/ldsyms.h (and not an iVar as you might have thought). 
-(NSString *)genExecutableUUID //will break in simulator, please be careful
{
  if(_executableUUID == nil){
        const uint8_t *command = (const uint8_t *)(&_mh_execute_header + 1);
        for (uint32_t idx = 0; idx < _mh_execute_header.ncmds; ++idx) {
            if (((const struct load_command *)command)->cmd == LC_UUID) {
                command += sizeof(struct load_command);
                _executableUUID = [[NSString stringWithFormat:@"%02X%02X%02X%02X-%02X%02X-%02X%02X-%02X%02X-%02X%02X%02X%02X%02X%02X",
                        command[0], command[1], command[2], command[3],
                        command[4], command[5],
                        command[6], command[7],
                        command[8], command[9],
                        command[10], command[11], command[12], command[13], command[14], command[15]] retain];
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


@end
