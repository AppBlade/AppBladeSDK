//
//  AppBlade.m
//  AppBlade
//
//  Created by Craig Spitzkoff on 6/1/11.
//  Copyright 2011 AppBlade. All rights reserved.
//

#import "AppBlade.h"
#import "AppBladeLogging.h"
#import "AppBladeSimpleKeychain.h"

#import "PLCrashReporter.h"
#import "PLCrashReport.h"
#import "AppBladeWebClient.h"
#import "PLCrashReportTextFormatter.h"
#import "FeedbackDialogue.h"
#import "asl.h"
#import <QuartzCore/QuartzCore.h>

#import <CommonCrypto/CommonHMAC.h>
#include "FileMD5Hash.h"
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <TargetConditionals.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#import <mach-o/ldsyms.h>

#include "FileMD5Hash.h"



static NSString* const s_sdkVersion                     = @"0.5.0";

NSString* const kAppBladeErrorDomain                    = @"com.appblade.sdk";
const int kAppBladeOfflineError                         = 1200;
const int kAppBladeParsingError                         = 1208;
const int kAppBladePermissionError                      = 1216;
NSString* const kAppBladeCacheDirectory                 = @"AppBladeCache";

const int kUpdateAlertTag                               = 316;

const int kTokenRefreshStatusCode                       = 401; //if this is ever returned, that means the token is expired and needs renewing before the api can be called
const int kTokenInvalidStatusCode                       = 403; //if this is ever returned, that means the app is being used illegally

static NSString *s_letters                              = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
static NSString* const kAppBladeBacklogFileName         = @"AppBladeBacklog.plist";
static NSString* const kAppBladeFeedbackKeyNotes        = @"notes";
static NSString* const kAppBladeFeedbackKeyScreenshot   = @"screenshot";
static NSString* const kAppBladeFeedbackKeyFeedback     = @"feedback";
static NSString* const kAppBladeFeedbackKeyBackup       = @"backupFileName";
static NSString* const kAppBladeCrashReportKeyFilePath  = @"queuedFilePath";
static NSString* const kAppBladeCustomFieldsFile        = @"AppBladeCustomFields.plist";

static NSString* const kAppBladeDefaultHost             = @"https://appblade.com";

static NSString* const kAppBladeSessionFile             = @"AppBladeSessions.txt";

//Keychain Values
static NSString* const kAppBladeKeychainTtlKey          = @"appBlade_ttl";
static NSString* const kAppBladeKeychainDeviceSecretKey = @"appBlade_device_secret";
    static NSString* const kAppBladeKeychainDeviceSecretKeyOld = @"old_secret";
    static NSString* const kAppBladeKeychainDeviceSecretKeyNew = @"new_secret";
    static NSString* const kAppBladeKeychainPlistHashKey = @"plist_hash";


static NSString* const kAppBladeKeychainDisabledKey        = @"appBlade_disabled";
static NSString* const kAppBladeKeychainDisabledKeyTrue    = @"riydwfudfhijkfsy7rew78toryiwehj";
static NSString* const kAppBladeKeychainDisabledKeyFalse   = @"riydwfudfhijkfsz7rew78toryiwehj";

//Plist Key Values
static NSString* const kAppBladePlistApiDictionaryKey     = @"api_keys";
    static NSString* const kAppBladePlistDeviceSecretKey     = @"device_secret";
    static NSString* const kAppBladePlistProjectSecretKey    = @"project_secret";
    static NSString* const kAppBladePlistEndpointKey         = @"host";
static NSString* const kAppBladePlistDefaultDeviceSecretValue    = @"DEFAULT";
static NSString* const kAppBladePlistDefaultProjectSecretValue   = @"DEFAULT";


//API Response Values
static NSString* const kAppBladeApiTokenResponseDeviceSecretKey     = @"device_secret";
static NSString* const kAppBladeApiTokenResponseTimeToLiveKey       = @"ttl";


@interface AppBlade () <AppBladeWebClientDelegate, FeedbackDialogueDelegate>

@property (nonatomic, retain) NSURL* upgradeLink;

// Feedback
@property (nonatomic, retain) NSMutableDictionary* feedbackDictionary;
@property (nonatomic, assign) BOOL showingFeedbackDialogue;
@property (nonatomic, retain) UITapGestureRecognizer* tapRecognizer;
@property (nonatomic, assign) UIWindow* window;

@property (nonatomic, retain) NSDate *sessionStartDate;

@property (nonatomic, retain) NSOperationQueue* pendingRequests;
@property (nonatomic, retain) NSOperationQueue* tokenRequests;


- (void)validateProjectConfiguration;
- (void)raiseConfigurationExceptionWithFieldName:(NSString *)name;
- (void)checkAndCreateAppBladeCacheDirectory;

- (void)handleCrashReport;
- (void)showFeedbackDialogue;

- (void)promptFeedbackDialogue;
- (void)reportFeedback:(NSString*)feedback;
- (NSString*)captureScreen;
- (UIImage*)getContentBelowView;
- (UIImage *) rotateImage:(UIImage *)img angle:(int)angle;

- (NSString*)randomString:(int)length;


- (BOOL)hasPendingSessions;
//hasPendingCrashReport in PLCrashReporter
- (BOOL)hasPendingFeedbackReports;
- (void)handleBackloggedFeedback;
- (void)removeIntermediateFeedbackFiles:(NSString *)feedbackPath;

-(NSMutableDictionary*) appBladeDeviceSecrets;
- (BOOL)hasDeviceSecret;
- (BOOL)isDeviceSecretBeingConfirmed;

- (NSInteger)pendingRequestsOfType:(AppBladeWebClientAPI)clientType;
- (BOOL)isCurrentToken:(NSString *)token;

- (void) cancelAllPendingRequests;
- (void) cancelPendingRequestsByToken:(NSString *)token;

- (NSString*)hashFileOfPlist:(NSString *)filePath;

void post_crash_callback (siginfo_t *info, ucontext_t *uap, void *context);
@end


@implementation AppBlade
@synthesize appBladeDeviceSecret = _appbladeDeviceSecret;


static AppBlade *s_sharedManager = nil;

/* A custom post-crash callback */
void post_crash_callback (siginfo_t *info, ucontext_t *uap, void *context) {
    [AppBlade endSession];
}


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
        ABErrorLog(@"Could not find main() symbol (very odd)");
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



#pragma mark - Lifecycle

+ (NSString*)sdkVersion
{
    return s_sdkVersion;
}

+ (void)logSDKVersion
{
    NSLog(@"AppBlade SDK v %@.", s_sdkVersion);
}

+ (AppBlade *)sharedManager
{
    if (s_sharedManager == nil) {
        s_sharedManager = [[super allocWithZone:NULL] init];
    }
    return s_sharedManager;
}


+ (NSString*)cachesDirectoryPath
{
    NSString* cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [cacheDirectory stringByAppendingPathComponent:kAppBladeCacheDirectory];
}

+ (void)clearCacheDirectory
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *directory = [AppBlade cachesDirectoryPath];
    NSError *error = nil;
    for (NSString *file in [fm contentsOfDirectoryAtPath:directory error:&error]) {
        BOOL success = [fm removeItemAtPath:[NSString stringWithFormat:@"%@%@", directory, file] error:&error];
        if (!success || error) {
            // it failed.
            ABErrorLog(@"AppBlade failed to remove the caches directory after receiving invalid credentials");
        }
    }
    [[AppBlade sharedManager] checkAndCreateAppBladeCacheDirectory]; //reinitialize the folder
}

- (id)init {
    if ((self = [super init])) {
        // Delegate authentication outcomes and other messages are handled by self unless overridden.
        self.delegate = self;
    }
    return self;
}


- (void)validateProjectConfiguration
{
    //All the necessary plist vairables must be included
    if ([self appBladeDeviceSecret] == nil || [[self appBladeDeviceSecret] length] == 0) {
        if (self.appBladeProjectSecret == nil || self.appBladeProjectSecret.length == 0) {
            [self raiseConfigurationExceptionWithFieldName:@"Project Secret OR Device Secret"];
        }
    }
    else if (!self.appBladeHost || self.appBladeHost.length == 0) {
        [self raiseConfigurationExceptionWithFieldName:@"Project Host"];
    }
}

- (void)raiseConfigurationExceptionWithFieldName:(NSString *)name
{
    NSString* const exceptionMessageFormat = @"AppBlade %@ not set. Configure the shared AppBlade manager from within your application delegate or AppBlade plist file.";
    [NSException raise:@"AppBladeException" format:exceptionMessageFormat, name];
    abort();
}


#pragma mark SDK setup

- (void)registerWithAppBladePlist
{
    [self registerWithAppBladePlist:@"AppBladeKeys"];
}

- (void)registerWithAppBladePlist:(NSString*)plistName
{
    [self pauseCurrentPendingRequests]; //while registering, pause all requests that might rely on the token. 
    NSString * plistPath = [[NSBundle mainBundle] pathForResource:plistName ofType:@"plist"];
    NSDictionary* appbladeVariables = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    if(appbladeVariables != nil)
    {
        NSDictionary* appBladePlistStoredKeys = (NSDictionary*)[appbladeVariables valueForKey:kAppBladePlistApiDictionaryKey];
        NSMutableDictionary* appBladeKeychainKeys = [self appBladeDeviceSecrets]; //keychain persists across updates, we need to be careful
        
        NSString * md5 = [self hashFileOfPlist:plistPath];
        NSString* appBlade_plist_hash = (NSString *)[appBladeKeychainKeys objectForKey:kAppBladeKeychainPlistHashKey];
        if(![appBlade_plist_hash isEqualToString:md5]){ //our hashes don't match!
            ABDebugLog_internal(@"Our hashes don't match! Clearing out current secrets!");
            [self clearStoredDeviceSecrets]; //we have to clear our device secrets, it's the only way
        }        
        self.appBladeHost =  [AppBladeWebClient buildHostURL:[appBladePlistStoredKeys valueForKey:kAppBladePlistEndpointKey]];
        self.appBladeProjectSecret = [appBladePlistStoredKeys valueForKey:kAppBladePlistProjectSecretKey];
        if(self.appBladeProjectSecret == nil)
        {
            self.appBladeProjectSecret = @"";
        }
        
        NSString *storedDeviceSecret = [self appBladeDeviceSecret];
        if(storedDeviceSecret == nil || [storedDeviceSecret length] == 0){
            NSString * storedDeviceSecret = (NSString *)[appBladePlistStoredKeys objectForKey:kAppBladePlistDeviceSecretKey];
            ABDebugLog_internal(@"Our device secret being set from plist:%@.", storedDeviceSecret);
            [self setAppBladeDeviceSecret:storedDeviceSecret];
            appBladeKeychainKeys = [self appBladeDeviceSecrets];
            [appBladeKeychainKeys setValue:md5 forKey:kAppBladeKeychainPlistHashKey];
            [AppBladeSimpleKeychain save:kAppBladeKeychainDeviceSecretKey data:appBladeKeychainKeys]; //update our md5 as well. We JUST updated.
            ABDebugLog_internal(@"Our device secret is currently:%@.", [self appBladeDeviceSecret]);
        }
        [self validateProjectConfiguration];
        
        if(self.appBladeProjectSecret.length > 0) {
            [[AppBlade  sharedManager] refreshToken:[self appBladeDeviceSecret]];
        } else {
            [[AppBlade  sharedManager] confirmToken:[self appBladeDeviceSecret]]; //confirm our existing device_secret immediately
        }
    }
    else
    {
        [self raiseConfigurationExceptionWithFieldName:plistName];
    }
    
    if([kAppBladePlistDefaultProjectSecretValue isEqualToString:self.appBladeProjectSecret] || self.appBladeProjectSecret == nil || [self.appBladeProjectSecret  length] == 0)
    {
        ABDebugLog_internal(@"User did not provide proper API credentials for AppBlade to be used in development.");
    }
}

-(BOOL)isAppStoreBuild
{
    return is_encrypted();
}

#pragma mark Pending Requests Queue 

-(NSOperationQueue *) tokenRequests {
    if(!_tokenRequests){
        _tokenRequests = [[NSOperationQueue alloc] init];
        _tokenRequests.name = @"AppBlade Token Queue";
        _tokenRequests.maxConcurrentOperationCount = 1;
    }
    return _tokenRequests;
}

//token requests are never pause or cancelled

-(NSOperationQueue *) pendingRequests {
    if(!_pendingRequests){
        _pendingRequests = [[NSOperationQueue alloc] init];
        _pendingRequests.name = @"AppBlade API Queue";
        _pendingRequests.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    }
    return _pendingRequests;
}

-(void) pauseCurrentPendingRequests {
    [[self pendingRequests] setSuspended:YES];
}

-(void) resumeCurrentPendingRequests {
    [[self pendingRequests] setSuspended:NO];
}

-(void) cancelAllPendingRequests {
    [[self pendingRequests] cancelAllOperations];
    [[self pendingRequests] setSuspended:NO];
}

-(void) cancelPendingRequestsByToken:(NSString*) token {
    NSString *tokenToCheckAgainst = token;
    if(nil == tokenToCheckAgainst) {
        tokenToCheckAgainst = [self appBladeDeviceSecret];
    }
    
    NSArray *currentOperations = [[self pendingRequests] operations];
    for (int i = 0; i < [currentOperations count]; i++) {
        AppBladeWebClient *op = (AppBladeWebClient *)[currentOperations objectAtIndex:i];
        if(nil == op.sentDeviceSecret || ![tokenToCheckAgainst isEqualToString:op.sentDeviceSecret]) {
            [op cancel];
        }
    }
    [[self pendingRequests] setSuspended:NO];
}


#pragma mark API Token Calls


//Eventually these will help enable/disable our appBladeDisabled value. It gives us the ability to condemn/redeem the device.

- (void)refreshToken:(NSString *)tokenToConfirm
{
    //ensure no other requests or confirms are already running.
    if([self isDeviceSecretBeingConfirmed]) {
        ABDebugLog_internal(@"Refresh already in queue. Ignoring.");
        return;
    }else if (tokenToConfirm != nil && ![self isCurrentToken:tokenToConfirm]){
        ABDebugLog_internal(@"Token not current, refresh token request is out of sync. Ignoring.");
        return;
    }
    
    //HOLD EVERYTHING. bubble the request to the top.
    [self pauseCurrentPendingRequests];
    AppBladeWebClient * client = [[AppBladeWebClient alloc] initWithDelegate:self];
    [client refreshToken:[self appBladeDeviceSecret]];
    [self.tokenRequests addOperation:client];
}

- (void)confirmToken:(NSString *)tokenToConfirm
{
    //ensure no other requests or confirms are already running.
    if([self isDeviceSecretBeingConfirmed]) {
        ABDebugLog_internal(@"Confirm (or refresh) already in queue. Ignoring.");
        return;
    }else if (tokenToConfirm != nil && ![self isCurrentToken:tokenToConfirm]){
        ABDebugLog_internal(@"Token not current, confirm token request is out of sync. Ignoring.");
        return;
    }
    
    //HOLD EVERYTHING. bubble the request to the top.
    [self pauseCurrentPendingRequests];
    
    AppBladeWebClient * client = [[AppBladeWebClient alloc] initWithDelegate:self];
    [client confirmToken:[self appBladeDeviceSecret]];
    [self.tokenRequests addOperation:client];
}

#pragma mark API Blockable Calls

- (void)checkApprovalWithUpdatePrompt:(BOOL)shouldPrompt  //deprecated, do not use
{
    [self checkApproval];
}

- (void)checkApproval
{
    [self validateProjectConfiguration];
    AppBladeWebClient * client = [[AppBladeWebClient alloc] initWithDelegate:self] ;
    [client checkPermissions];
    [self.pendingRequests addOperation:client];
}

- (void)checkForUpdates
{
    [self validateProjectConfiguration];
    ABDebugLog_internal(@"Checking for updates");
    AppBladeWebClient * client = [[AppBladeWebClient alloc] initWithDelegate:self] ;
    [client checkForUpdates];
    [self.pendingRequests addOperation:client];
}


- (void)catchAndReportCrashes
{
    ABDebugLog_internal(@"Catch and report crashes");
    [self validateProjectConfiguration];

    PLCrashReporter *crashReporter = [PLCrashReporter sharedReporter];
    NSError *error;
    
    [self checkForExistingCrashReports];
    
    // Enable the Crash Reporter
    if (![crashReporter enableCrashReporterAndReturnError: &error])
        ABErrorLog(@"Warning: Could not enable crash reporter: %@", error);
}

- (void)checkForExistingCrashReports
{
    PLCrashReporter *crashReporter = [PLCrashReporter sharedReporter];
    // Check if we previously crashed
    if ([crashReporter hasPendingCrashReport]){
        [self handleCrashReport];
    }
}

- (void)handleCrashReport
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
        AppBladeWebClient * client = [[AppBladeWebClient alloc] initWithDelegate:self];
        client.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:queuedFilePath,  kAppBladeCrashReportKeyFilePath, nil];
        [client reportCrash:reportString withParams:[self getCustomParams]];
        [self.pendingRequests addOperation:client];
    }
    else
    {
        ABDebugLog_internal(@"No crashes to report");
    }
}

- (NSString*)hashFileOfPlist:(NSString *)filePath
{
    NSString* returnString = nil;
    CFStringRef executableFileMD5Hash =
    FileMD5HashCreateWithPath((CFStringRef)CFBridgingRetain(filePath), FileHashDefaultChunkSizeForReadingData);
    if (executableFileMD5Hash) {
        returnString = (NSString *)CFBridgingRelease(executableFileMD5Hash);
        CFRelease(executableFileMD5Hash);
    }
    
    return returnString;
}


#pragma mark - AppBladeWebClient
-(void) appBladeWebClientFailed:(AppBladeWebClient *)client
{
    [self appBladeWebClientFailed:client withErrorString:NULL];
}

- (void)appBladeWebClientFailed:(AppBladeWebClient *)client withErrorString:(NSString*)errorString
{
    if (nil == client) {
        return;
    }
    int status = [[client.responseHeaders valueForKey:@"statusCode"] intValue];  
    // check only once if the delegate responds to this selector
    BOOL canSignalDelegate = [self.delegate respondsToSelector:@selector(appBlade:applicationApproved:error:)];

    if (client.api == AppBladeWebClientAPI_GenerateToken)  {
        ABErrorLog(@"ERROR generating token");
        //wait for a retry or deactivate the SDK for the duration of the current install
        if(status == kTokenInvalidStatusCode)
        {  //the token we used to generate a new token is no longer valid
            ABErrorLog(@"Token refresh failed because current token had its access revoked.");
            [AppBlade clearCacheDirectory];//all of the pending data is to be considered invlid, don't let it clutter the app.
        }
        else
        {  //likely a 500 or some other timeout
            ABErrorLog(@"Token refresh failed due to an error from the server.");
            //try to confirm the token that we have. If it works, we can go with that.
        }
    }
    else if (client.api == AppBladeWebClientAPI_ConfirmToken)  {
        ABErrorLog(@"ERROR confirming token");
        //schedule a token refresh or deactivate based on status
        if(status == kTokenRefreshStatusCode)
        {
            [[AppBlade  sharedManager] refreshToken:[client sentDeviceSecret]];
        }
        else if(status == kTokenInvalidStatusCode)
        {
            NSDictionary*errorDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                               NSLocalizedString(errorString, nil), NSLocalizedDescriptionKey,
                               NSLocalizedString(errorString, nil),  NSLocalizedFailureReasonErrorKey, nil];
            NSError* error = [NSError errorWithDomain:kAppBladeErrorDomain code:kAppBladeParsingError userInfo:errorDictionary];
            if(canSignalDelegate) {
                [self.delegate appBlade:self applicationApproved:NO error:error];
            }
        }
        else
        {  //likely a 500 or some other timeout from the server
            //if we can't confirm the token then we can't use it.
            [self cancelPendingRequestsByToken:[client sentDeviceSecret]];
            //Try again later.
            double delayInSeconds = 30.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [[AppBlade  sharedManager] confirmToken:[client sentDeviceSecret]];
            });
        }
    }
    else {
        //non-token related api failures all attempt a token refresh when given a refresh status code,
        if([self isCurrentToken:[client sentDeviceSecret]]){
            if(status == kTokenRefreshStatusCode)
            {
                [[AppBlade  sharedManager] refreshToken:[client sentDeviceSecret]]; //refresh the token
            }else if(status == kTokenInvalidStatusCode) { //we think the response was invlaid?
                [[AppBlade  sharedManager] confirmToken:[client sentDeviceSecret]]; //one more confirm, just to be safe.
            }
        }
        
        if (client.api == AppBladeWebClientAPI_Permissions)  {
            // if the connection failed, see if the application is still within the previous TTL window.
            // If it is, then let the application run. Otherwise, ensure that the TTL window is closed and
            // prevent the app from running until the request completes successfully. This will prevent
            // users from unlocking an app by simply changing their clock.
            if ([self withinStoredTTL]) {
                if(canSignalDelegate) {
                    [self.delegate appBlade:self applicationApproved:YES error:nil];
                }
            }
            else {
                [self closeTTLWindow];
                if(canSignalDelegate) {
                    NSDictionary* errorDictionary = nil;
                    NSError* error = nil;
                    if(errorString){
                        errorDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                           NSLocalizedString(errorString, nil), NSLocalizedDescriptionKey,
                                           NSLocalizedString(errorString, nil),  NSLocalizedFailureReasonErrorKey, nil];
                        error = [NSError errorWithDomain:kAppBladeErrorDomain code:kAppBladeParsingError userInfo:errorDictionary];

                    }
                    else
                    {
                        errorDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                           NSLocalizedString(@"Please check your internet connection to gain access to this application", nil), NSLocalizedDescriptionKey,
                                           NSLocalizedString(@"Please check your internet connection to gain access to this application", nil),  NSLocalizedFailureReasonErrorKey, nil];
                        error = [NSError errorWithDomain:kAppBladeErrorDomain code:kAppBladeOfflineError userInfo:errorDictionary];
                    }
                    [self.delegate appBlade:self applicationApproved:NO error:error];
                }
                
            }
        }
        else if (client.api == AppBladeWebClientAPI_Feedback) {
            @synchronized (self){
                ABErrorLog(@"ERROR sending feedback");
                NSString* backupFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeBacklogFileName];
                NSMutableArray* backupFiles = [NSMutableArray arrayWithContentsOfFile:backupFilePath];
                NSString *fileName = [client.userInfo objectForKey:kAppBladeFeedbackKeyBackup];
                BOOL isBacklog = ([[backupFiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF == %@",fileName]] count] > 0);
                if (!isBacklog) {
                    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
                    NSString* newFeedbackName = [[NSString stringWithFormat:@"%0.0f", now] stringByAppendingPathExtension:@"plist"];
                    NSString* feedbackPath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:newFeedbackName];
                    [self.feedbackDictionary writeToFile:feedbackPath atomically:YES];
                    
                    if (!backupFiles) {
                        backupFiles = [NSMutableArray array];
                    }
                    
                    [backupFiles addObject:newFeedbackName];
                    
                    BOOL success = [backupFiles writeToFile:backupFilePath atomically:YES];
                    if(!success){
                        ABErrorLog(@"Error writing backup file to %@", backupFilePath);
                    }
                    self.feedbackDictionary = nil;
                }
                else {

                }
            }
        }
        else if(client.api == AppBladeWebClientAPI_Sessions){
            ABErrorLog(@"ERROR sending sessions");
        }
        else if(client.api == AppBladeWebClientAPI_ReportCrash)
        {
            ABErrorLog(@"ERROR sending crash %@, keeping crashes until they are sent", client.userInfo);
        }
        else if(client.api == AppBladeWebClientAPI_UpdateCheck)
        {
            ABErrorLog(@"ERROR getting updates from AppBlade %@", client.userInfo);
        }
        else
        {
            ABErrorLog(@"Nonspecific AppBladeWebClient error: %i", client.api);
        }
    }
}

- (void)appBladeWebClient:(AppBladeWebClient *)client receivedGenerateTokenResponse:(NSDictionary *)response
{    
    NSString *deviceSecretString = [response objectForKey:kAppBladeApiTokenResponseDeviceSecretKey];
    if(deviceSecretString != nil) {
        ABDebugLog_internal(@"Updating token ");
        [self setAppBladeDeviceSecret:deviceSecretString]; //updating new device secret
        //immediately confirm we have a new token stored
        ABDebugLog_internal(@"token from request %@", [client sentDeviceSecret]);
        ABDebugLog_internal(@"confirming new token %@", [self appBladeDeviceSecret]);
        [self confirmToken:[self appBladeDeviceSecret]];
    }
    else {
        ABDebugLog_internal(@"ERROR parsing token refresh response, keeping last valid token %@", self.appBladeDeviceSecret);
        int statusCode = [[client.responseHeaders valueForKey:@"statusCode"] intValue];
        ABDebugLog_internal(@"token refresh response status code %d", statusCode);
        if(statusCode == kTokenInvalidStatusCode){
            [self.delegate appBlade:self applicationApproved:NO error:nil];
        }else if (statusCode == kTokenRefreshStatusCode){
            [self refreshToken:[self appBladeDeviceSecret]];
        }else{
            [self resumeCurrentPendingRequests]; //resume requests (in case it went through.)
        }
    }
}

- (void)appBladeWebClient:(AppBladeWebClient *)client receivedConfirmTokenResponse:(NSDictionary *)response
{
    NSString *deviceSecretTimeout = [response objectForKey:kAppBladeApiTokenResponseTimeToLiveKey];
    if(deviceSecretTimeout != nil) {
        ABDebugLog_internal(@"Token confirmed. Business as usual.");
        [self resumeCurrentPendingRequests]; //continue requests that we could have had pending. they will be ignored if they fail with the old token.
    }
    else {
        ABDebugLog_internal(@"ERROR parsing token confirm response, keeping last valid token %@", self.appBladeDeviceSecret);
        int statusCode = [[client.responseHeaders valueForKey:@"statusCode"] intValue];
        ABDebugLog_internal(@"token confirm response status code %d", statusCode);
        if(statusCode == kTokenInvalidStatusCode){
            [self.delegate appBlade:self applicationApproved:NO error:nil];
        }else if (statusCode == kTokenRefreshStatusCode){
            [self refreshToken:[self appBladeDeviceSecret]];
        }else{
            [self resumeCurrentPendingRequests]; //resume requests (in case it went through.)
        }
    }
}


- (void)appBladeWebClient:(AppBladeWebClient *)client receivedPermissions:(NSDictionary *)permissions
{
    NSString *errorString = [permissions objectForKey:@"error"];
    BOOL signalApproval = [self.delegate respondsToSelector:@selector(appBlade:applicationApproved:error:)];
    
    if ((errorString && ![self withinStoredTTL]) || [[client.responseHeaders valueForKey:@"statusCode"] intValue] == 403) {
        [self closeTTLWindow];
        NSDictionary* errorDictionary = [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(errorString, nil), NSLocalizedDescriptionKey,
                                         NSLocalizedString(errorString, nil),  NSLocalizedFailureReasonErrorKey, nil];
        NSError* error = [NSError errorWithDomain:kAppBladeErrorDomain code:kAppBladePermissionError userInfo:errorDictionary];
        
        if (signalApproval) {
            [self.delegate appBlade:self applicationApproved:NO error:error];
        }
    }
    else {
        NSNumber *ttl = [permissions objectForKey:kAppBladeApiTokenResponseTimeToLiveKey];
        if (ttl) {
            [self updateTTL:ttl];
        }
        
        // tell the client the application was approved.
        if (signalApproval) {
            [self.delegate appBlade:self applicationApproved:YES error:nil];
        }
    }
    
}

- (void)appBladeWebClient:(AppBladeWebClient *)client receivedUpdate:(NSDictionary*)updateData
{
    // determine if there is an update available
    NSDictionary* update = [updateData objectForKey:@"update"];
    if(update)
    {
        NSString* updateMessage = [update objectForKey:@"message"];
        NSString* updateURL = [update objectForKey:@"url"];
        
        if ([self.delegate respondsToSelector:@selector(appBlade:updateAvailable:updateMessage:updateURL:)]) {
            [self.delegate appBlade:self updateAvailable:YES updateMessage:updateMessage updateURL:updateURL];
        }
    }
    
}

- (void)appBladeWebClientCrashReported:(AppBladeWebClient *)client
{
    // purge the crash report that was just reported.
    int status = [[client.responseHeaders valueForKey:@"statusCode"] intValue];
    BOOL success = (status == 201 || status == 200);
    if(success){ //we don't need to hold onto this crash.
        ABDebugLog_internal(@"Appblade: success sending crash report, response status code: %d", status);
        [[PLCrashReporter sharedReporter] purgePendingCrashReport];
        NSString *pathOfCrashReport = [client.userInfo valueForKey:kAppBladeCrashReportKeyFilePath];
        [[NSFileManager defaultManager] removeItemAtPath:pathOfCrashReport error:nil];
        ABDebugLog_internal(@"Appblade: removed crash report, %@", pathOfCrashReport);

        if ([[PLCrashReporter sharedReporter] hasPendingCrashReport]){
            ABDebugLog_internal(@"Appblade: PLCrashReporter has more crash reports");
            [self handleCrashReport];
        }
        else
        {
            ABDebugLog_internal(@"Appblade: PLCrashReporter has no more crash reports");
        }
    }
    else
    {
        ABErrorLog(@"Appblade: error sending crash report, response status code: %d", status);
        //No more crash reports for now. We might have bad internet access.
    }
}

- (void)appBladeWebClientSentFeedback:(AppBladeWebClient *)client withSuccess:(BOOL)success
{
    @synchronized (self){
        BOOL isBacklog = [[self.pendingRequests operations] containsObject:client];
        if (success) {
            ABDebugLog_internal(@"feedback Successful");
            
            NSDictionary* feedback = [client.userInfo objectForKey:kAppBladeFeedbackKeyFeedback];
            // Clean up
            NSString* screenshotPath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:[feedback objectForKey:kAppBladeFeedbackKeyScreenshot]];
            [[NSFileManager defaultManager] removeItemAtPath:screenshotPath error:nil];

            NSString* backupFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeBacklogFileName];
            NSMutableArray* backups = [NSMutableArray arrayWithContentsOfFile:backupFilePath];
           
            NSString* fileName = [client.userInfo objectForKey:kAppBladeFeedbackKeyBackup];

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
                [self handleBackloggedFeedback];
            }
            else
            {
                ABDebugLog_internal(@"no more pending feedback");
            }
        }
        else if (!isBacklog) {
            ABDebugLog_internal(@"Unsuccesful feedback not found in backLog");
            
            // If we fail sending, add to backlog
            // We do not remove backlogged files unless the request is sucessful
            
            NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
            NSString* newFeedbackName = [[NSString stringWithFormat:@"%0.0f", now] stringByAppendingPathExtension:@"plist"];
            NSString* feedbackPath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:newFeedbackName];
            
            [self.feedbackDictionary writeToFile:feedbackPath atomically:YES];
            
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
        } //It's failed and already in the backlog. Keep it there.
        
        if (!isBacklog) {
            self.feedbackDictionary = nil;
        }
    }
}

- (void)appBladeWebClientSentSessions:(AppBladeWebClient *)client withSuccess:(BOOL)success
{
    if(success){
        //delete existing sessions, as we have reported them
        NSString* sessionFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeSessionFile];
        if ([[NSFileManager defaultManager] fileExistsAtPath:sessionFilePath]) {
            NSError *deleteError = nil;
            [[NSFileManager defaultManager] removeItemAtPath:sessionFilePath error:&deleteError];
            
            if(deleteError){
                ABErrorLog(@"Error deleting Session log: %@", deleteError.debugDescription);
            }
        }
    }
    else
    {
        ABErrorLog(@"Error sending Session log");
    }
}


#pragma mark - AppBladeDelegate
- (void)appBlade:(AppBlade *)appBlade applicationApproved:(BOOL)approved error:(NSError *)error
{
    if(!approved) {
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Permission Denied"
                                                         message:[error localizedDescription]
                                                        delegate:self
                                               cancelButtonTitle:@"Exit"
                                               otherButtonTitles: nil] ;
        [alert show];
    }
    
}


-(void) appBlade:(AppBlade *)appBlade updateAvailable:(BOOL)update updateMessage:(NSString*)message updateURL:(NSString*)url
{
    if (update) {
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Update Available"
                                                         message:message
                                                        delegate:self
                                               cancelButtonTitle:@"Cancel"
                                               otherButtonTitles: @"Upgrade", nil] ;
        alert.tag = kUpdateAlertTag;
        self.upgradeLink = [NSURL URLWithString:url];
        
        [alert show];
        
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == kUpdateAlertTag) {
        if (buttonIndex == 1) {
            [[UIApplication sharedApplication] openURL:self.upgradeLink];
            self.upgradeLink = nil;   
            exit(0);
        }
    }
    else
    {
        exit(0);
    }
}


#pragma mark - Feedback

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


- (void)allowFeedbackReporting
{
    ABDebugLog_internal(@"allowFeedbackReporting");

    UIWindow* window = [[UIApplication sharedApplication] keyWindow];
    if (window) {
        [self allowFeedbackReportingForWindow:window];
        ABDebugLog_internal(@"Allowing feedback.");
    }
    else {
        ABErrorLog(@"Cannot setup for feedback. No keyWindow.");
    }
}

- (void)allowFeedbackReportingForWindow:(UIWindow *)window
{
    self.window = window;
    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showFeedbackDialogue)] ;
    self.tapRecognizer.numberOfTapsRequired = 2;
    self.tapRecognizer.numberOfTouchesRequired = 3;
    self.tapRecognizer.delegate = self;
    [window addGestureRecognizer:self.tapRecognizer];
    
    [self checkAndCreateAppBladeCacheDirectory];
    
    if ([self hasPendingFeedbackReports]) {
        [self handleBackloggedFeedback];
    }
}

- (void)setupCustomFeedbackReporting
{
    UIWindow* window = [[UIApplication sharedApplication] keyWindow];
    if (window) {
        [self setupCustomFeedbackReportingForWindow:window];
        ABDebugLog_internal(@"Allowing custom feedback.");
        
    }
    else {
        ABErrorLog(@"Cannot setup for custom feedback. No keyWindow.");
    }

}

- (void)setupCustomFeedbackReportingForWindow:(UIWindow*)window
{
    if (window) {
        ABDebugLog_internal(@"Allowing custom feedback for window %@", window);
        self.window = window;
    }
    else
    {
        ABErrorLog(@"Cannot setup for custom feedback. Not a valid window.");
        return;
    }
    [self checkAndCreateAppBladeCacheDirectory];
    if ([self hasPendingFeedbackReports]) {
        [self handleBackloggedFeedback];
    }
}

- (void)showFeedbackDialogue
{
    [self showFeedbackDialogue:YES];
}

- (void)showFeedbackDialogue:(BOOL)withScreenshot
{
    if(!self.showingFeedbackDialogue){
        self.showingFeedbackDialogue = YES;
        if(self.feedbackDictionary == nil){
            self.feedbackDictionary = [NSMutableDictionary  dictionary];
        }

        //More like SETUP feedback dialogue, am I right? I'm hilarious. Anyway, this gets all our ducks in a row before showing the feedback dialogue
        if(withScreenshot){
            NSString* screenshotPath = [self captureScreen];
            [self.feedbackDictionary setObject:[screenshotPath lastPathComponent] forKey:kAppBladeFeedbackKeyScreenshot];
        }
        else
        {
        
        }
        //other setup methods (like the reintroduction of the console log) will go here
        [self promptFeedbackDialogue];
    }
    else
    {
        ABDebugLog_internal(@"Feedback window already presenting, or a screenshot is trying to be captured");
        return;
    }
}

- (void)promptFeedbackDialogue
{
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGRect screenFrame = self.window.frame;
    
    CGRect vFrame = CGRectZero;
    if([[self.window subviews] count] > 0){
        UIView *v = [[self.window subviews] objectAtIndex:0];
        vFrame = v.frame; //adjust for any possible offset in the subview we'll add our feedback to.
    }
    
    CGRect statusBarFrame = [UIApplication sharedApplication].statusBarFrame;
    
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
        //make an adjustment for the case where the view we're adding to is stretched beyond the window.
        screenFrame.origin.x = screenFrame.origin.x -vFrame.origin.x + statusBarFrame.size.width;
        
        // We need to react properly to interface orientations
        CGSize size = screenFrame.size;
        screenFrame.size.width = size.height;
        screenFrame.size.height = size.width;
        CGPoint origin = screenFrame.origin;
        screenFrame.origin.x = origin.y;
        screenFrame.origin.y = origin.x;
    }
    else
    {
        //make an adjustment for the case where the view we're adding to is stretched beyond the window.
        screenFrame.origin.y = screenFrame.origin.y -vFrame.origin.y + statusBarFrame.size.height;
    }
    
    ABDebugLog_internal(@"Displaying feedback dialog in frame X:%.f Y:%.f W:%.f H:%.f",
          screenFrame.origin.x, screenFrame.origin.y,
          screenFrame.size.width, screenFrame.size.height);
    
    
    FeedbackDialogue *feedback = [[FeedbackDialogue alloc] initWithFrame:CGRectMake(screenFrame.origin.x, screenFrame.origin.y, screenFrame.size.width, screenFrame.size.height)];
    feedback.delegate = self;
    
    // get the first window in the application if one was not supplied.
    if (!self.window){
        self.window = [[UIApplication sharedApplication] keyWindow];
        self.showingFeedbackDialogue = YES;
        ABDebugLog_internal(@"Feedback window not defined, using default (Images might not come through.)");
    }
    if([[self.window subviews] count] > 0){
        [[[self.window subviews] objectAtIndex:0] addSubview:feedback];
        self.showingFeedbackDialogue = YES;
        [feedback.textView becomeFirstResponder];
    }
    else
    {
        ABErrorLog(@"No subviews in feedback window, cannot prompt feedback dialog at this time.");
        feedback.delegate = nil;
        self.showingFeedbackDialogue = NO;
    }
    
}

-(void)feedbackDidSubmitText:(NSString*)feedbackText{
    
    ABDebugLog_internal(@"reporting text %@", feedbackText);
    [self reportFeedback:feedbackText];
    self.showingFeedbackDialogue = NO;

}

- (void)feedbackDidCancel
{
    NSString* screenshotPath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:[self.feedbackDictionary objectForKey:kAppBladeFeedbackKeyScreenshot]];
    [[NSFileManager defaultManager] removeItemAtPath:screenshotPath error:nil];
    self.feedbackDictionary = nil;
    self.showingFeedbackDialogue = NO;
    
}


- (void)reportFeedback:(NSString *)feedback
{
    
    [self.feedbackDictionary setObject:feedback forKey:kAppBladeFeedbackKeyNotes];
    
    ABDebugLog_internal(@"caching and attempting send of feedback %@", self.feedbackDictionary);
    
    //store the feedback in the cache director in the event of a termination
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSString* newFeedbackName = [[NSString stringWithFormat:@"%0.0f", now] stringByAppendingPathExtension:@"plist"];
    NSString* feedbackPath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:newFeedbackName];
    
    [self.feedbackDictionary writeToFile:feedbackPath atomically:YES];
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
    
    AppBladeWebClient * client = [[AppBladeWebClient alloc] initWithDelegate:self];
    ABDebugLog_internal(@"Sending screenshot");
    [client sendFeedbackWithScreenshot:[self.feedbackDictionary objectForKey:kAppBladeFeedbackKeyScreenshot] note:feedback console:nil params:[self getCustomParams]];
    [self.pendingRequests addOperation:client];
}


- (void)handleBackloggedFeedback
{
    @synchronized (self){
        ABDebugLog_internal(@"handleBackloggedFeedback");
        NSString* backupFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeBacklogFileName];
        NSMutableArray* backupFiles = [NSMutableArray arrayWithContentsOfFile:backupFilePath];
        if (backupFiles.count > 0) {
            NSString* fileName = [backupFiles objectAtIndex:0]; //get earliest unsent feedback
            NSString* feedbackPath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:fileName];
            
            NSDictionary* feedback = [NSDictionary dictionaryWithContentsOfFile:feedbackPath];
            if (feedback) {
                ABDebugLog_internal(@"Feedback found at %@", feedbackPath);
                ABDebugLog_internal(@"backlog Feedback dictionary %@", feedback);
                NSString *screenshotFileName = [feedback objectForKey:kAppBladeFeedbackKeyScreenshot];
                //validate that additional files exist
                NSString *screenshotFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:screenshotFileName];
                bool screenShotFileExists = [[NSFileManager defaultManager] fileExistsAtPath:screenshotFilePath];
                if(screenShotFileExists){
                    AppBladeWebClient * client = [[AppBladeWebClient alloc] initWithDelegate:self];
                    client.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:feedback, kAppBladeFeedbackKeyFeedback, fileName, kAppBladeFeedbackKeyBackup, nil];
                    [client sendFeedbackWithScreenshot:screenshotFileName note:[feedback objectForKey:kAppBladeFeedbackKeyNotes] console:nil params:[self getCustomParams]];
                    [self.pendingRequests addOperation:client];
                }
                else
                {
                    //clean up files if one doesn't exist
                    [self removeIntermediateFeedbackFiles:feedbackPath];
                    ABDebugLog_internal(@"invalid feedback at %@, removing File and intermediate files", feedbackPath);
                    [backupFiles removeObject:fileName];
                    ABDebugLog_internal(@"writing valid pending feedback objects back to file");
                    [backupFiles writeToFile:backupFilePath atomically:YES];

                }
            }
            else
            {
                ABDebugLog_internal(@"No Feedback found at %@, invalid feedback, removing File", feedbackPath);
                [backupFiles removeObject:fileName];
                ABDebugLog_internal(@"writing valid pending feedback objects back to file");
                [backupFiles writeToFile:backupFilePath atomically:YES];
            }
        }
    }
}

-(NSString *)captureScreen
{
    [self checkAndCreateAppBladeCacheDirectory];
    UIImage *currentImage = [self getContentBelowView];
    if(currentImage == nil){
        ABErrorLog(@"ERROR, could not capture screenshot, possible invalid keywindow");
    }
    NSString* fileName = [[self randomString:36] stringByAppendingPathExtension:@"png"];
	NSString *pngFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:fileName] ;
	NSData *data1 = [NSData dataWithData:UIImagePNGRepresentation(currentImage)];
	[data1 writeToFile:pngFilePath atomically:YES];
    ABDebugLog_internal(@"Screen captured in fileName %@", fileName);
    return pngFilePath ;
    
}

- (UIImage*)getContentBelowView
{
    UIWindow* keyWindow = [[UIApplication sharedApplication] keyWindow];
    UIGraphicsBeginImageContext(keyWindow.bounds.size);
    [keyWindow.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImage* returnImage = nil;
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
        if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
            returnImage = [self rotateImage:image angle:270];
        }
        else {
            returnImage = [self rotateImage:image angle:90];
        }
    }
    else {
        returnImage = image;
    }
    
    return returnImage;
    
}

// From: http://megasnippets.com/source-codes/objective_c/rotate_image
- (UIImage *) rotateImage:(UIImage *)img angle:(int)angle
{
    CGImageRef imgRef = [img CGImage];
    CGContextRef context;
    
    switch (angle) {
        case 90:
            UIGraphicsBeginImageContext(CGSizeMake(img.size.height, img.size.width));
            context = UIGraphicsGetCurrentContext();
            CGContextTranslateCTM(context, img.size.height, img.size.width);
            CGContextScaleCTM(context, 1.0, -1.0);
            CGContextRotateCTM(context, M_PI/2.0);
            break;
        case 180:
            UIGraphicsBeginImageContext(CGSizeMake(img.size.width, img.size.height));
            context = UIGraphicsGetCurrentContext();
            CGContextTranslateCTM(context, img.size.width, 0);
            CGContextScaleCTM(context, 1.0, -1.0);
            CGContextRotateCTM(context, -M_PI);
            break;
        case 270:
            UIGraphicsBeginImageContext(CGSizeMake(img.size.height, img.size.width));
            context = UIGraphicsGetCurrentContext();
            CGContextScaleCTM(context, 1.0, -1.0);
            CGContextRotateCTM(context, -M_PI/2.0);
            break;
        default:
            return nil;
    }  
    
    CGContextDrawImage(context, CGRectMake(0, 0, img.size.width, img.size.height), imgRef);
    UIImage *ret = UIGraphicsGetImageFromCurrentImageContext();  
    
    UIGraphicsEndImageContext();
    return ret;
}

#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}


#pragma mark - Analytics
- (BOOL)hasPendingSessions
{   //check active clients for API_Sessions
    NSInteger sessionClients = [self pendingRequestsOfType:AppBladeWebClientAPI_Sessions];
    return sessionClients > 0;
}


+ (void)startSession
{
    ABDebugLog_internal(@"Starting Session Logging");
    [[AppBlade sharedManager] logSessionStart];
}


+ (void)endSession
{
    ABDebugLog_internal(@"Ended Session Logging");
    [[AppBlade sharedManager] logSessionEnd];
}

- (void)logSessionStart
{
    NSString* sessionFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeSessionFile];
    ABDebugLog_internal(@"Checking Session Path: %@", sessionFilePath);

    if ([[NSFileManager defaultManager] fileExistsAtPath:sessionFilePath]) {
        NSArray* sessions = (NSArray*)[self readFile:sessionFilePath];
        ABDebugLog_internal(@"%d Sessions Exist, posting them", [sessions count]);
        
        if(![self hasPendingSessions]){
            AppBladeWebClient * client = [[AppBladeWebClient alloc] initWithDelegate:self];
            [client postSessions:sessions];
            [self.pendingRequests addOperation:client];
        }
    }
    
    self.sessionStartDate = [NSDate date];
}

- (void)logSessionEnd
{
    NSDictionary* sessionDict = [NSDictionary dictionaryWithObjectsAndKeys:self.sessionStartDate, @"started_at", [NSDate date], @"ended_at", [self getCustomParams], @"custom_params", nil];
    
    NSMutableArray* pastSessions = nil;
    NSString* sessionFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeSessionFile];
    if ([[NSFileManager defaultManager] fileExistsAtPath:sessionFilePath]) {
        NSArray* sessions = (NSArray*)[self readFile:sessionFilePath];
        pastSessions = [sessions mutableCopy] ;
    }
    else {
        pastSessions = [NSMutableArray arrayWithCapacity:1];
    }
    
    [pastSessions addObject:sessionDict];
    
    NSData* sessionData = [NSKeyedArchiver archivedDataWithRootObject:pastSessions];
    [sessionData writeToFile:sessionFilePath atomically:YES];
}

#pragma mark - AppBlade Custom Params
-(NSDictionary *)getCustomParams
{
    NSDictionary *toRet = nil;
    NSString* customFieldsPath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeCustomFieldsFile];
    if ([[NSFileManager defaultManager] fileExistsAtPath:customFieldsPath]) {
        NSDictionary* currentFields = [NSDictionary dictionaryWithContentsOfFile:customFieldsPath];
        toRet = currentFields;
    }
    else
    {
        ABDebugLog_internal(@"no file found, reinitializing");
        toRet = [NSDictionary dictionary];
        [self setCustomParams:toRet];
    }
    ABDebugLog_internal(@"getting %@", toRet);

    return toRet;
}

-(void)setCustomParams:(NSDictionary *)newFieldValues
{
    [self checkAndCreateAppBladeCacheDirectory];
    NSString* customFieldsPath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeCustomFieldsFile];
    if ([[NSFileManager defaultManager] fileExistsAtPath:customFieldsPath]) {
        ABDebugLog_internal(@"WARNING: Overwriting all existing user params");
    }
    if(newFieldValues){
        NSError *error = nil;
        NSData *paramsData = [NSPropertyListSerialization dataWithPropertyList:newFieldValues format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
        if(!error){
            [paramsData writeToFile:customFieldsPath atomically:YES];
        }
        else
        {
            ABErrorLog(@"Error parsing custom params %@", newFieldValues);
        }
    }
    else
    {
        ABDebugLog_internal(@"clearing custom params, removing file");
        [[NSFileManager defaultManager] removeItemAtPath:customFieldsPath error:nil];
    }
}

-(void)setCustomParam:(id)newObject withValue:(NSString*)key{
    NSDictionary* currentFields = [self getCustomParams];
    if (currentFields == nil) {
        currentFields = [NSDictionary dictionary];
    }
    NSMutableDictionary* mutableFields = [currentFields  mutableCopy];
    if(key && newObject){
        [mutableFields setObject:newObject forKey:key];
    }
    else if(key && !newObject){
        [mutableFields removeObjectForKey:key];
    }
    else
    {
        ABErrorLog(@"AppBlade: invalid nil key when setting custom parameters");
    }
    ABDebugLog_internal(@"setting to %@", mutableFields);
    currentFields = (NSDictionary *)mutableFields;
    [self setCustomParams:currentFields];
}


-(void)setCustomParam:(id)object forKey:(NSString*)key;
{
    NSDictionary* currentFields = [self getCustomParams];
    if (currentFields == nil) {
        currentFields = [NSDictionary dictionary];
    }
    NSMutableDictionary* mutableFields = [currentFields  mutableCopy] ;
    if(key && object){
        [mutableFields setObject:object forKey:key];
    }
    else if(key && !object){
        [mutableFields removeObjectForKey:key];
    }
    else
    {
        ABErrorLog(@"invalid nil key");
    }
    ABDebugLog_internal(@"setting to %@", mutableFields);
    currentFields = (NSDictionary *)mutableFields;
    [self setCustomParams:currentFields];
}

-(void)clearAllCustomParams
{
    [self setCustomParams:nil];
}


#pragma mark - TTL (Time To Live) Methods

- (void)closeTTLWindow
{
    [AppBladeSimpleKeychain delete:kAppBladeKeychainTtlKey];
}

- (void)updateTTL:(NSNumber*)ttl
{
    NSDate* ttlDate = [NSDate date];
    NSDictionary* appBlade = [NSDictionary dictionaryWithObjectsAndKeys:ttlDate, @"ttlDate",ttl, @"ttlInterval", nil];
    [AppBladeSimpleKeychain save:kAppBladeKeychainTtlKey data:appBlade];
}

// determine if we are within the range of the stored TTL for this application
- (BOOL)withinStoredTTL
{
    NSDictionary* appBlade_ttl = [AppBladeSimpleKeychain load:kAppBladeKeychainTtlKey];
    NSDate* ttlDate = [appBlade_ttl objectForKey:@"ttlDate"];
    NSNumber* ttlInterval = [appBlade_ttl objectForKey:@"ttlInterval"];
    
    // if we don't have either value, we're definitely not within a stored TTL
    if(nil == ttlInterval || nil == ttlDate)
        return NO;
    
    // if the current date is earlier than our last ttl date, the user has turned their clock back. Invalidate.
    NSDate* currentDate = [NSDate date];
    if ([currentDate compare:ttlDate] == NSOrderedAscending) {
        return NO;
    }
    
    // if the current date is later than the ttl date adjusted with the TTL, the window has expired
    NSDate* adjustedTTLDate = [ttlDate dateByAddingTimeInterval:[ttlInterval integerValue]];
    if ([currentDate compare:adjustedTTLDate] == NSOrderedDescending) {
        return NO;
    }
    
    return YES;
}

#pragma mark - Device Secret Methods
-(NSMutableDictionary*) appBladeDeviceSecrets
{
    NSMutableDictionary* appBlade_deviceSecret_dict = (NSMutableDictionary* )[AppBladeSimpleKeychain load:kAppBladeKeychainDeviceSecretKey];
    if(nil == appBlade_deviceSecret_dict)
    {
        appBlade_deviceSecret_dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"", kAppBladeKeychainDeviceSecretKeyNew, @"", kAppBladeKeychainDeviceSecretKeyOld, @"", kAppBladeKeychainPlistHashKey, nil];
        [AppBladeSimpleKeychain save:kAppBladeKeychainDeviceSecretKey data:appBlade_deviceSecret_dict];
        ABDebugLog_internal(@"Device Secrets were nil. Reinitialized.");
    }
    return appBlade_deviceSecret_dict;
}


- (NSString *)appBladeDeviceSecret
{
    //get the last available device secret
    NSMutableDictionary* appBlade_keychain_dict = [self appBladeDeviceSecrets];
    NSString* device_secret_stored = (NSString*)[appBlade_keychain_dict valueForKey:kAppBladeKeychainDeviceSecretKeyNew]; //assume we have the newest in new_secret key
    NSString* device_secret_stored_old = (NSString*)[appBlade_keychain_dict valueForKey:kAppBladeKeychainDeviceSecretKeyOld];
    if(nil == device_secret_stored || [device_secret_stored isEqualToString:@""])
    {
        ABDebugLog_internal(@"Device Secret from storage:%@, falling back to old value:(%@).", (device_secret_stored == nil  ? @"null" : ( [device_secret_stored isEqualToString:@""] ? @"empty" : device_secret_stored) ), (device_secret_stored_old == nil  ? @"null" : ( [device_secret_stored_old isEqualToString:@""] ? @"empty" : device_secret_stored_old) ));
        _appbladeDeviceSecret = (NSString*)[device_secret_stored_old copy];     //if we have no stored keys, returns default empty string
    }else
    {
        _appbladeDeviceSecret = (NSString*)[device_secret_stored copy];
    }
    
    return _appbladeDeviceSecret;
}

- (void) setAppBladeDeviceSecret:(NSString *)appBladeDeviceSecret
{
        //always store the last two device secrets
        NSMutableDictionary* appBlade_keychain_dict = [self appBladeDeviceSecrets];
        NSString* device_secret_latest_stored = [appBlade_keychain_dict objectForKey:kAppBladeKeychainDeviceSecretKeyNew]; //get the newest key (to our knowledge)
        if((nil != appBladeDeviceSecret) && ![device_secret_latest_stored isEqualToString:appBladeDeviceSecret]) //if we don't already have the "new" token as the newest token
        {
            [appBlade_keychain_dict setObject:[device_secret_latest_stored copy] forKey:kAppBladeKeychainDeviceSecretKeyOld]; //we don't care where the old key goes
            [appBlade_keychain_dict setObject:[appBladeDeviceSecret copy] forKey:kAppBladeKeychainDeviceSecretKeyNew];
                //update the newest key
        }
        //save the stored keychain
        [AppBladeSimpleKeychain save:kAppBladeKeychainDeviceSecretKey data:appBlade_keychain_dict];
}



- (void)clearAppBladeKeychain
{
    NSMutableDictionary* appBlade_keychain_dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"", kAppBladeKeychainDeviceSecretKeyNew, @"", kAppBladeKeychainDeviceSecretKeyOld, @"", kAppBladeKeychainPlistHashKey, nil];
    [AppBladeSimpleKeychain save:kAppBladeKeychainDeviceSecretKey data:appBlade_keychain_dict];
}

- (void)clearStoredDeviceSecrets
{
    NSMutableDictionary* appBlade_keychain_dict = [self appBladeDeviceSecrets];
    if(nil != appBlade_keychain_dict)
    {
        [appBlade_keychain_dict setValue:@"" forKey:kAppBladeKeychainDeviceSecretKeyNew];
        [appBlade_keychain_dict setValue:@"" forKey:kAppBladeKeychainDeviceSecretKeyOld];
        [AppBladeSimpleKeychain save:kAppBladeKeychainDeviceSecretKey data:appBlade_keychain_dict];
        ABDebugLog_internal(@"Cleared device secrets.");
    }
}


#pragma mark - Helper Methods

- (void)checkAndCreateAppBladeCacheDirectory
{
    NSString* directory = [AppBlade cachesDirectoryPath];
    NSFileManager* manager = [NSFileManager defaultManager];
    BOOL isDirectory = YES;
    if (![manager fileExistsAtPath:directory isDirectory:&isDirectory]) {
        ABDebugLog_internal(@"Appblade creating %@", directory);
        NSError* error = nil;
        BOOL success = [manager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error];
        if (!success) {
            ABErrorLog(@"Error creating directory %@", error);
        }
    }
}

- (NSObject*)readFile:(NSString *)filePath
{
    NSData* fileData = [NSData dataWithContentsOfFile:filePath];
    NSObject* returnObject = nil;
    if (fileData) {
        returnObject = [NSKeyedUnarchiver unarchiveObjectWithData:fileData];
    }
    else {
        NSError* error = nil;
        if (![[NSFileManager defaultManager] removeItemAtPath:filePath error:&error]) {
            ABErrorLog(@"AppBlade cannot remove file %@", [filePath lastPathComponent]);
        }
    }
    return returnObject;
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

- (NSInteger)pendingRequestsOfType:(AppBladeWebClientAPI)clientType {
    NSInteger amtToReturn = 0;
    
    if(clientType == AppBladeWebClientAPI_AllTypes){
        amtToReturn = [self.pendingRequests operationCount];
    }
    else
    {
        NSArray* clientsOfType = [[self.pendingRequests operations] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"api == %d", clientType ]];
        amtToReturn = clientsOfType.count;
    }
    return amtToReturn;
}


- (BOOL)tokenConfirmRequestPending {
    NSInteger confirmTokenRequests = [[self.tokenRequests operations] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"api == %d", AppBladeWebClientAPI_ConfirmToken]];
    return confirmTokenRequests > 0;
}

- (BOOL)tokenRefreshRequestPending {
    NSInteger confirmTokenRequests = [[self.tokenRequests operations] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"api == %d", AppBladeWebClientAPI_GenerateToken]];
    return confirmTokenRequests > 0;
}

- (BOOL)isDeviceSecretBeingConfirmed {
    BOOL tokenRequestInProgress = ([[self tokenRequests] operationCount]) != 0;
    BOOL processIsNotFinished = tokenRequestInProgress; //if we have a process, assume it's not finished, if we have one then of course it's finished
    if(tokenRequestInProgress) { //the queue has a maximum concurrent process size of one, that's why we can do what comes next
        AppBladeWebClient *process = (AppBladeWebClient *)[[[self tokenRequests] operations] objectAtIndex:0];
        processIsNotFinished = ![process isFinished];
    }
    return tokenRequestInProgress && processIsNotFinished;
}

- (BOOL)isCurrentToken:(NSString *)token {
    return (nil != token) && [[self appBladeDeviceSecret] isEqualToString:token];
}

-(BOOL)hasDeviceSecret
{
    return [[self appBladeDeviceSecret] length] == 0;
}

-(NSString *) randomString: (int) len {
    
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [s_letters characterAtIndex: arc4random()%[s_letters length]]];
    }
    
    return randomString;
}


@end
