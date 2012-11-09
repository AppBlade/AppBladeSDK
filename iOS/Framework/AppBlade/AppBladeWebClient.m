//
//  AppBladeWebClient.m
//  AppBlade
//
//  Created by Craig Spitzkoff on 6/18/11.
//  Copyright 2011 AppBlade. All rights reserved.
//

#import "AppBladeWebClient.h"
#import "AppBlade.h"
#import <CommonCrypto/CommonHMAC.h>
#include "FileMD5Hash.h"
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <TargetConditionals.h>
#include <sys/types.h>
#include <sys/sysctl.h>

static NSString *approvalURLFormat          = @"https://%@/api/projects/%@/devices/%@.plist";
static NSString *reportCrashURLFormat       = @"https://%@/api/projects/%@/devices/%@/crash_reports";
static NSString *reportFeedbackURLFormat    = @"https://%@/api/projects/%@/devices/%@/feedback";

static NSString* s_boundary = @"---------------------------14737809831466499882746641449";


@interface AppBladeWebClient ()

@property (nonatomic, readwrite) AppBladeWebClientAPI api;

@property (nonatomic, readonly) NSString* osVersionBuild;
@property (nonatomic, readonly) NSString* platform;


// Request helper methods.
- (NSString *)udid;
- (NSMutableURLRequest *)requestForURL:(NSURL *)url;
- (void)addSecurityToRequest:(NSMutableURLRequest *)request;

// Crypto helper methods.
- (NSString *)HMAC_SHA256_Base64:(NSString *)data with_key:(NSString *)key;
- (NSString *)SHA_Base64:(NSString *)raw;
- (NSString *)encodeBase64WithData:(NSData *)objData;
- (NSString *)genRandStringLength:(int)len;
- (NSString *)urlEncodeValue:(NSString*)string;

- (NSString *)hashFile:(NSString*)filePath;
- (NSString *)hashExecutable;
- (NSString *)hashInfoPlist;

@end

@implementation AppBladeWebClient

@synthesize osVersionBuild = _osVersionBuild;
@synthesize platform = _platform;

@synthesize delegate = _delegate;
@synthesize api = _api;
@synthesize responseHeaders = _responseHeaders;
@synthesize userInfo = _userInfo;

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
    
    return osBuildVersion;
}

- (NSString *) platform{
	size_t size;
	sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
    free(machine);
    return platform;
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
    [super dealloc];
}

#pragma mark - AppBlade API

- (void)checkPermissions
{
    _api = AppBladeWebClientAPI_Permissions;

    // Create the request.
    NSString* udid = [self udid];
    NSString* urlString = [NSString stringWithFormat:approvalURLFormat, [_delegate appBladeHost], [_delegate appBladeProjectID], udid];
    NSURL* projectUrl = [NSURL URLWithString:urlString];
    NSMutableURLRequest* apiRequest = [self requestForURL:projectUrl];
    [apiRequest setHTTPMethod:@"GET"];
    [self addSecurityToRequest:apiRequest];

    // Issue the request.
    [[[NSURLConnection alloc] initWithRequest:apiRequest delegate:self] autorelease];
}

- (void)reportCrash:(NSString *)crashReport {
    _api = AppBladeWebClientAPI_ReportCrash;

    // Retrieve UDID, used in URL.
    NSString* udid = [self udid];

    // Build report URL.
    NSString* urlCrashReportString = [NSString stringWithFormat:reportCrashURLFormat, [_delegate appBladeHost], [_delegate appBladeProjectID], udid];
    NSURL* urlCrashReport = [NSURL URLWithString:urlCrashReportString];    

    // Create the API request.
    NSMutableURLRequest* apiRequest = [self requestForURL:urlCrashReport];
    [apiRequest setHTTPMethod:@"POST"];       

    NSData* data = [crashReport dataUsingEncoding:NSUTF8StringEncoding];
    [apiRequest setHTTPBody:data];

    [self addSecurityToRequest:apiRequest];

    // Issue the request.
    [[[NSURLConnection alloc] initWithRequest:_request delegate:self] autorelease]; 
}

- (void)sendFeedbackWithScreenshot:(NSString*)screenshot note:(NSString*)note console:(NSString *)console
{
    _api = AppBladeWebClientAPI_Feedback;
    
    NSString* udid = [self udid];
    NSString* screenshotPath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:screenshot];
    NSData* consoleContent = [NSData dataWithContentsOfFile:[[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:console]];
    //    NSError* error = nil;
    //    NSData* paramsData = [NSPropertyListSerialization dataWithPropertyList:params format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
    
    // Build report URL.
    NSString* reportString = [NSString stringWithFormat:reportFeedbackURLFormat, [_delegate appBladeHost], [_delegate appBladeProjectID], udid];
    NSURL* reportURL = [NSURL URLWithString:reportString];
    
    // Create the API request.
    NSMutableURLRequest* apiRequest = [self requestForURL:reportURL];
    [apiRequest setValue:[@"multipart/form-data; boundary=" stringByAppendingString:s_boundary] forHTTPHeaderField:@"Content-Type"];
    [apiRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [apiRequest setHTTPMethod:@"POST"];
    
    NSMutableData* body = [NSMutableData dataWithData:[[NSString stringWithFormat:@"--%@\r\n",s_boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Disposition: form-data; name=\"feedback[notes]\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[note dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",s_boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Disposition: form-data; name=\"feedback[console]\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:consoleContent];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",s_boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"feedback[screenshot]\"; filename=\"base64:%@\"\r\n", screenshot] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSData* screenshotData = [[self encodeBase64WithData:[NSData dataWithContentsOfFile:screenshotPath]] dataUsingEncoding:NSUTF8StringEncoding];
    [body appendData:screenshotData];
    [body appendData:[[[@"\r\n--" stringByAppendingString:s_boundary] stringByAppendingString:@"--"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    [apiRequest setHTTPBody:body];
    [apiRequest setValue:[NSString stringWithFormat:@"%d", [body length]] forHTTPHeaderField:@"Content-Length"];
    
    [self addSecurityToRequest:apiRequest];
    
    // Issue the request.
    [[[NSURLConnection alloc] initWithRequest:_request delegate:self] autorelease];
}

#pragma mark - Request helper methods.

- (NSString *)udid
{
#if TARGET_IPHONE_SIMULATOR
    return @"0000000000000000000000000000000000000000";
#else
    return [[UIDevice currentDevice] uniqueIdentifier];
#endif
}

// Creates a preformatted request with appblade headers.
- (NSMutableURLRequest *)requestForURL:(NSURL *)url
{
    // create the request
    NSMutableURLRequest* apiRequest = [[[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10] autorelease];
    
    // set up various headers on the request.
    [apiRequest addValue:[[NSBundle mainBundle] bundleIdentifier] forHTTPHeaderField:@"bundle_identifier"];
    [apiRequest addValue:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] forHTTPHeaderField:@"bundle_version"];
    [apiRequest addValue:[self osVersionBuild] forHTTPHeaderField:@"IOS_RELEASE"];
    [apiRequest addValue:[self platform] forHTTPHeaderField:@"DEVICE_MODEL"];
    [apiRequest addValue:[[UIDevice currentDevice] name] forHTTPHeaderField:@"MONIKER"];
    [apiRequest addValue:[AppBlade sdkVersion] forHTTPHeaderField:@"sdk_version"];
    
    NSString* bundleHash = [self hashExecutable];
    NSString* plistHash = [self hashInfoPlist];
    [apiRequest addValue:bundleHash forHTTPHeaderField:@"bundleexecutable_hash"];
    [apiRequest addValue:plistHash forHTTPHeaderField:@"infoplist_hash"];
    
    BOOL hasFairplay = is_encrypted();
    [apiRequest addValue:hasFairplay ? @"0" : @"1" forHTTPHeaderField:@"fairplay_encrypted"];
    
    [_request release];
    _request = [apiRequest retain];
    
    return apiRequest;
}

- (void)addSecurityToRequest:(NSMutableURLRequest *)request
{    
    NSString* scheme = [[request URL] scheme];
    NSString* preparedHostName = [NSString stringWithFormat:@"%@://%@", scheme, [[request URL] host] ];
    
    if ([[request URL] port]) {
        preparedHostName = [preparedHostName stringByAppendingFormat:@":%@", [[request URL] port]];
    }
    
    // Construct the relative URL path, followed by the body if POST.
    NSMutableString *requestBodyRaw = [NSMutableString stringWithString:[[[request URL] absoluteString] substringFromIndex:[preparedHostName length]]];
    if([request HTTPBody]) {
        // Append "?" and the HTTP body.
        NSString* dataString = [[[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding] autorelease];
        [requestBodyRaw appendFormat:@"?%@", dataString];
    }
    
    NSString *requestBodyHash = [self SHA_Base64:requestBodyRaw];
    
    // Construct the nonce (salt). First part of the salt is the delta of the current time and the stored time the
    // version was issued at, then a colon, then a random string of a certain length.
    NSString* randomString = [self genRandStringLength:kNonceRandomStringLength];
    NSString* nonce = [NSString stringWithFormat:@"%@:%@", [self.delegate appBladeProjectIssuedTimestamp], randomString];
    
    // Set port number based on the scheme
    NSString* port = [scheme isEqualToString:@"https"] ? @"443" : @"80";
    
    NSString* ext = [self udid];

    // Compose the normalized request body.
    NSMutableString* request_body = [NSMutableString stringWithFormat:@"%@\n%@\n%@\n%@\n%@\n%@\n%@\n",
                                     nonce,
                                     [request HTTPMethod],
                                     requestBodyRaw,
                                     [[request URL] host],
                                     port,
                                     requestBodyHash,
                                     ext];
    
    // Digest the normalized request body.
    NSString* mac = [self HMAC_SHA256_Base64:request_body with_key:[_delegate appBladeProjectSecret]];
    
    NSMutableString *authHeader = [NSMutableString stringWithString:@"HMAC "];
    [authHeader appendFormat:@"id=\"%@\"", [_delegate appBladeProjectToken]];
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
    } else {
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
    [_delegate appBladeWebClientFailed:self];
    
    [_request release];
    _request = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if(_api == AppBladeWebClientAPI_Permissions) {
        NSError *error;
        NSPropertyListFormat format;
        
        NSString* string = [[[NSString alloc] initWithData:_receivedData encoding:NSUTF8StringEncoding] autorelease];
        NSLog(@"Received Response from AppBlade: %@", string);
                
        NSDictionary *plist = [NSPropertyListSerialization propertyListWithData:_receivedData options:NSPropertyListImmutable format:&format error:&error];
        
        [_receivedData release];
        _receivedData = nil;
        
        if (plist && error == NULL) {
            [_delegate appBladeWebClient:self receivedPermissions:plist];
        } else {
            NSLog(@"Error parsing permisions plist: %@", [error debugDescription]);
            [_delegate appBladeWebClientFailed:self];
        }
        
    } else if (_api == AppBladeWebClientAPI_ReportCrash) {
        [_delegate appBladeWebClientCrashReported:self];
    }
    else if (_api == AppBladeWebClientAPI_Feedback) {
        
        int status = [[self.responseHeaders valueForKey:@"statusCode"] intValue];
        BOOL success = (status == 201 || status == 200);
        
        [_delegate appBladeWebClientSentFeedback:self withSuccess:success];
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
		} else {
			*objPointer++ = _base64EncodingTable[(objRawData[0] & 0x03) << 4];
			*objPointer++ = '=';
			*objPointer++ = '=';
		}
	}
	// Terminate the string-based result
	*objPointer = '\0';
	// Return the results as an NSString object
	return [NSString stringWithCString:strResult encoding:NSASCIIStringEncoding];
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

@end
