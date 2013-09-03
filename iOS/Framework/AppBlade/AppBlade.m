//
//  AppBlade.m
//  AppBlade
//
//  Created by Craig Spitzkoff on 6/1/11.
//  Copyright 2011 AppBlade. All rights reserved.
//

#import "AppBlade.h"
#import "AppBlade+PrivateMethods.h"
#import "AppBladeLogging.h"
#import "AppBladeSimpleKeychain.h"

#import "AppBladeWebOperation.h"
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

#import "AppBladeBasicFeatureManager.h"

//Core Managers
#import "AppBladeDeviceSecretManager.h"
#import "AppBladeTokenRequestManager.h"

//Feature List (with exclusion conditionals)
#ifndef SKIP_AUTHENTICATION
    #import "AppBladeAuthenticationManager.h"
    #endif
#ifndef SKIP_AUTO_UPDATING
    #import "AppBladeUpdatesManager.h"
    #endif
#ifndef SKIP_FEEDBACK
    #import "AppBladeFeedbackReportingManager.h"
    #endif
#ifndef SKIP_CRASH_REPORTING
    #import "AppBladeCrashReportingManager.h"
    #endif
#ifndef SKIP_SESSIONS
    #import "AppBladeSessionTrackingManager.h"
    #endif
#ifndef SKIP_CUSTOM_PARAMS
    #import "AppBladeCustomParametersManager.h"
    #endif



@interface AppBlade ()<AppBladeWebOperationDelegate
    #ifndef SKIP_FEEDBACK
    , FeedbackDialogueDelegate
    #endif
    >

@property (nonatomic, assign, getter = isAllDisabled, setter = setDisabled:) BOOL allDisabled;
@property (nonatomic, retain) NSOperationQueue* pendingRequests;

@property (nonatomic, strong) AppBladeDeviceSecretManager* deviceSecretManager;
@property (nonatomic, strong) AppBladeTokenRequestManager* tokenRequestManager;


#ifndef SKIP_AUTHENTICATION
@property (nonatomic, strong) AppBladeAuthenticationManager* authenticationManager;
#endif
#ifndef SKIP_AUTO_UPDATING
@property (nonatomic, strong) AppBladeUpdatesManager* updatesManager;
#endif
#ifndef SKIP_CRASH_REPORTING
@property (nonatomic, strong) AppBladeCrashReportingManager* crashManager;
void post_crash_callback (siginfo_t *info, ucontext_t *uap, void *context);
#endif
#ifndef SKIP_FEEDBACK
@property (nonatomic, strong) AppBladeFeedbackReportingManager* feedbackManager;
#endif
#ifndef SKIP_SESSIONS
@property (nonatomic, strong) AppBladeSessionTrackingManager* AppBladeSessionTrackingManager;
#endif
#ifndef SKIP_CUSTOM_PARAMS
@property (nonatomic, strong) AppBladeCustomParametersManager* customParamsManager;
#endif

@end

@implementation AppBlade
@synthesize allDisabled = _allDisabled;

@synthesize deviceSecretManager;
@synthesize tokenRequestManager;

#ifndef SKIP_AUTHENTICATION
@synthesize authenticationManager;
#endif
#ifndef SKIP_AUTO_UPDATING
@synthesize updatesManager;
#endif
#ifndef SKIP_CRASH_REPORTING
@synthesize crashManager;
#endif
#ifndef SKIP_FEEDBACK
@synthesize feedbackManager;
#endif
#ifndef SKIP_SESSIONS
@synthesize AppBladeSessionTrackingManager;
#endif
#ifndef SKIP_CUSTOM_PARAMS
@synthesize customParamsManager;
#endif


#ifndef SKIP_CRASH_REPORTING
/* A custom post-crash callback */
void post_crash_callback (siginfo_t *info, ucontext_t *uap, void *context) {
#ifndef SKIP_SESSIONS
    [AppBlade endSession];
#endif
}
#endif


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
#if TARGET_IPHONE_SIMULATOR
    return NO;
#else
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
#endif
}



#pragma mark - Lifecycle
static AppBlade *s_sharedManager = nil;
-(void)setDisabled:(BOOL)isDisabled
{
    _allDisabled = isDisabled;
    if(isDisabled){
        [self pauseCurrentPendingRequests];
    }
}


+ (AppBlade *)sharedManager
{
    if (s_sharedManager == nil) {
        s_sharedManager = [[super allocWithZone:NULL] init];
    }
    return s_sharedManager;
}

- (id)init {
    if ((self = [super init])) {
        // Delegate authentication outcomes and other messages are handled by self unless overridden.
        self.delegate = self;
        //init the core managers
        self.deviceSecretManager = [[AppBladeDeviceSecretManager alloc] init];
        self.tokenRequestManager = [[AppBladeTokenRequestManager alloc] init];
        //init the feature managers conditionally, all other feature-dependent initialization code goes in their respective initWithDelegate calls
#ifndef SKIP_AUTHENTICATION
        self.authenticationManager  = [[AppBladeAuthenticationManager alloc] initWithDelegate:self];
#endif
#ifndef SKIP_AUTO_UPDATING
        self.updatesManager         = [[AppBladeUpdatesManager alloc] initWithDelegate:self];
#endif
#ifndef SKIP_FEEDBACK
        self.feedbackManager        = [[AppBladeFeedbackReportingManager alloc] initWithDelegate:self];
#endif
#ifndef SKIP_CRASH_REPORTING
        self.crashManager           = [[AppBladeCrashReportingManager alloc] initWithDelegate:self];
#endif
#ifndef SKIP_SESSIONS
        self.AppBladeSessionTrackingManager = [[AppBladeSessionTrackingManager alloc] initWithDelegate:self];
#endif
#ifndef SKIP_CUSTOM_PARAMS
        self.customParamsManager    = [[AppBladeCustomParametersManager alloc] initWithDelegate:self];
#endif
    }
    return self;
}

- (void)validateProjectConfiguration
{
    NSString* const exceptionMissingMessageFormat = @"AppBlade is missing %@. The project is likely misconfigured. Make sure you declare the shared AppBlade manager from within your application delegate and you have your AppBladeKeys plist file in the right place.";

    NSString *missingElement = @"";
    BOOL projectInvalid = FALSE;
    //All the necessary plist vairables must be included
    if (self.appBladeProjectSecret == nil || self.appBladeProjectSecret.length == 0) {
         missingElement = @"Project Secret";
    }//project can be missing if we have a device secret
    if (([missingElement isEqualToString:@"Project Secret"]) && ([self appBladeDeviceSecret] == nil || [[self appBladeDeviceSecret] length] == 0)) {
        missingElement = @"both a Device Secret and Project secret. It needs one of them";
        projectInvalid = TRUE;
    }

    if (!projectInvalid && (!self.appBladeHost || self.appBladeHost.length == 0)) {
        missingElement =  @"the Project Host (endpoint)";
        projectInvalid = TRUE;
    }
    
    NSString *configurationExceptionMessage = [NSString stringWithFormat:exceptionMissingMessageFormat, missingElement];
    
    //we have the data, now check the keychain
    if(![AppBladeSimpleKeychain hasKeychainAccess]){
        configurationExceptionMessage = @"AppBlade cannot be enabled on this build because it cannot access the keychain. The build was likely signed improperly.";
    }
    
    if(projectInvalid){
        [self raiseConfigurationExceptionWithMessage:configurationExceptionMessage];
    }
}


- (void)raiseConfigurationExceptionWithMessage:(NSString *)message
{
    NSLog(@"%@", message);
    NSLog(@"AppBlade must now disable itself.");
    [[AppBlade sharedManager] setDisabled:YES];
}

#pragma mark SDK setup

- (void)registerWithAppBladePlist
{
    [self registerWithAppBladePlistNamed:@"AppBladeKeys"];
}

- (void)registerWithAppBladePlistNamed:(NSString*)plistName
{
    
    ABDebugLog_internal(@"Kicking off AppBlade Registration");
    [self pauseCurrentPendingRequests]; //while registering, pause all requests that might rely on the token.
    
    if (![AppBladeSimpleKeychain hasKeychainAccess]){
        [[AppBlade sharedManager] setDisabled:YES];
        ABDebugLog_internal(@"AppBlade must disable due to missing keychain permissions.");
    }
    
    NSString * plistPath = [[NSBundle mainBundle] pathForResource:plistName ofType:@"plist"];
    NSDictionary* appbladeVariables = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    if(appbladeVariables != nil)
    {
        [self registerWithAppBladeDictionary:appbladeVariables atPlistPath:plistPath];
    }
    else
    {
        [self raiseConfigurationExceptionWithMessage: [NSString stringWithFormat:@"Could not load %@.plist, make sure it exists and is connected to your project target.", plistName]];
    }
    
    if([kAppBladePlistDefaultProjectSecretValue isEqualToString:self.appBladeProjectSecret] || self.appBladeProjectSecret == nil || [self.appBladeProjectSecret  length] == 0)
    {
        ABDebugLog_internal(@"User did not provide proper API credentials for AppBlade to be used in development.");
    }
}

- (void)registerWithAppBladeDictionary:(NSDictionary*)appbladeVariables atPlistPath:(NSString*)plistPath
{
    
    NSDictionary* appBladePlistStoredKeys = (NSDictionary*)[appbladeVariables valueForKey:kAppBladePlistApiDictionaryKey];
    NSMutableDictionary* appBladeKeychainKeys = [self appBladeDeviceSecrets]; //keychain persists across updates, we need to be careful
    
    NSString * md5 = @"";
    if(plistPath != nil)
    {
        md5 = [self hashFileOfPlist:plistPath];
        NSString* appBlade_plist_hash = (NSString *)[appBladeKeychainKeys objectForKey:kAppBladeKeychainPlistHashKey];
        if(![appBlade_plist_hash isEqualToString:md5]){ //our hashes don't match!
            ABDebugLog_internal(@"Our hashes don't match! Clearing out current secrets!");
            [self clearStoredDeviceSecrets]; //we have to clear our device secrets, it's the only way
        }
    }
    self.appBladeHost =  [AppBladeWebOperation buildHostURL:[appBladePlistStoredKeys valueForKey:kAppBladePlistEndpointKey]];
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

-(BOOL)isAppStoreBuild
{
    return is_encrypted();
}

-(void)cleanOutKeychain {
    [AppBladeSimpleKeychain deleteLocalKeychain];
}

-(void)sanitizeKeychain {
    [AppBladeSimpleKeychain sanitizeKeychain];
}

#pragma mark Pending Requests Queue

-(NSOperationQueue *) tokenRequests {
    return [self.tokenRequestManager tokenRequests];
}

//token requests are never paused or cancelled

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
        AppBladeWebOperation *op = (AppBladeWebOperation *)[currentOperations objectAtIndex:i];
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
    if(self.isAllDisabled){
        ABDebugLog_internal(@"Can't refreshToken, SDK disabled");
        return;
    }
    
    [self.tokenRequestManager refreshToken:tokenToConfirm];
}

- (void)confirmToken:(NSString *)tokenToConfirm
{
    if(self.isAllDisabled){
        ABDebugLog_internal(@"Can't confirmToken, SDK disabled");
        return;
    }
    [self.tokenRequestManager confirmToken:tokenToConfirm];
}


- (BOOL)isCurrentToken:(NSString *)token {
    return [self.tokenRequestManager isCurrentToken:token];
}

- (BOOL)tokenConfirmRequestPending {
    return [self.tokenRequestManager tokenConfirmRequestPending];
}

- (BOOL)tokenRefreshRequestPending {
    return [self.tokenRequestManager tokenRefreshRequestPending];
}



#pragma mark API Blockable Calls

#pragma mark  Authentication

- (void)checkApprovalWithUpdatePrompt:(BOOL)shouldPrompt  //deprecated, do not use
{
#ifndef SKIP_AUTHENTICATION
    [self checkApproval];
#else
    NSLog(@"%s has been disabled in this build of AppBlade.", __PRETTY_FUNCTION__);
#endif
}

- (void)checkApproval
{
#ifndef SKIP_AUTHENTICATION
    if(self.isAllDisabled){
        ABDebugLog_internal(@"Can't checkApproval, SDK disabled");
        return;
    }
    [self validateProjectConfiguration];    
    [self.authenticationManager checkApproval];
#else
    NSLog(@"%s has been disabled in this build of AppBlade.", __PRETTY_FUNCTION__);
#endif
}

#pragma mark Auto Updating

- (void)checkForUpdates
{
#ifndef SKIP_AUTO_UPDATING
    [self validateProjectConfiguration];
    if(self.isAllDisabled){
        ABDebugLog_internal(@"Can't checkForUpdates, SDK disabled");
        return;
    }
    [self.updatesManager checkForUpdates];
#else
    NSLog(@"%s has been disabled in this build of AppBlade.", __PRETTY_FUNCTION__);
#endif
}

#pragma mark Crash Reporting

- (void)catchAndReportCrashes
{
#ifndef SKIP_CRASH_REPORTING
    [self validateProjectConfiguration];
    if(self.isAllDisabled){
        ABDebugLog_internal(@"Can't catch and report crashes, SDK disabled");
        return;
    }
    ABDebugLog_internal(@"Catch and report crashes");
    [self.crashManager catchAndReportCrashes];
#else
    NSLog(@"%s has been disabled in this build of AppBlade.", __PRETTY_FUNCTION__);
#endif
}

- (void)checkForExistingCrashReports
{
#ifndef SKIP_CRASH_REPORTING
    if(self.isAllDisabled){
        ABDebugLog_internal(@"Can't catch and report crashes, SDK disabled");
        return;
    }

    [self.crashManager checkForExistingCrashReports];
#else
    NSLog(@"%s has been disabled in this build of AppBlade.", __PRETTY_FUNCTION__);
#endif
}

- (void)handleCrashReport
{
#ifndef SKIP_CRASH_REPORTING    
    if(self.isAllDisabled){
        ABDebugLog_internal(@"Can't catch and report crashes, SDK disabled");
        return;
    }

    NSDictionary *crashDict = [self.crashManager handleCrashReportAsDictionary];
    if(crashDict != nil){
        AppBladeWebOperation * client = [self.crashManager generateCrashReportFromDictionary:crashDict withParams:[self getCustomParams]];
        [self.pendingRequests addOperation:client];
    }
#else
    NSLog(@"%s has been disabled in this build of AppBlade.", __PRETTY_FUNCTION__);
#endif
}




#pragma mark - Feedback

- (void)allowFeedbackReporting
{
#ifndef SKIP_FEEDBACK
    if(self.isAllDisabled){
        ABDebugLog_internal(@"Can't check HasPendingFeedbackReports, SDK disabled");
        return;
    }
    UIWindow* feedbackWindow = [[UIApplication sharedApplication] keyWindow];
    if (feedbackWindow) {
        [self allowFeedbackReportingForWindow:feedbackWindow withOptions:AppBladeFeedbackSetupDefault];
        ABDebugLog_internal(@"Allowing feedback.");
    }
    else {
        ABErrorLog(@"Cannot setup for feedback. No keyWindow.");
    }
#else
    NSLog(@"%s has been disabled in this build of AppBlade.", __PRETTY_FUNCTION__)
#endif
}

- (BOOL)hasPendingFeedbackReports
{
    if(self.isAllDisabled){
        ABDebugLog_internal(@"Can't check hasPendingFeedbackReports, SDK disabled");
        return NO;
    }
    #ifndef SKIP_FEEDBACK
        return [self.feedbackManager hasPendingFeedbackReports];
    #else
        NSLog(@"%s has been disabled in this build of AppBlade.", __PRETTY_FUNCTION__)
    #endif
}


- (void)allowFeedbackReportingForWindow:(UIWindow *)window
{
#ifndef SKIP_FEEDBACK
    if(self.isAllDisabled){
        ABDebugLog_internal(@"Can't setup for custom feedback, SDK disabled");
        return;
    }
    [self validateProjectConfiguration];
    [self.feedbackManager allowFeedbackReportingForWindow:window withOptions:AppBladeFeedbackSetupDefault];
#else
    NSLog(@"%s has been disabled in this build of AppBlade.", __PRETTY_FUNCTION__)
#endif
}


- (void)allowFeedbackReportingForWindow:(UIWindow *)feedbackWindow withOptions:(AppBladeFeedbackSetupOptions)options
{
#ifndef SKIP_FEEDBACK
    if(self.isAllDisabled){
        ABDebugLog_internal(@"Can't setup for custom feedback, SDK disabled");
        return;
    }
    [self validateProjectConfiguration];
    [self.feedbackManager allowFeedbackReportingForWindow:feedbackWindow withOptions:options];
#else
    NSLog(@"%s has been disabled in this build of AppBlade.", __PRETTY_FUNCTION__)
#endif
}


//feedback UI must still be handled in the AppBlade class
- (void)showFeedbackDialogue
{
#ifndef SKIP_FEEDBACK
    [self showFeedbackDialogueWithOptions:AppBladeFeedbackDisplayDefault];
#else
    NSLog(@"%s has been disabled in this build of AppBlade.", __PRETTY_FUNCTION__)
#endif

}

- (void)showFeedbackDialogueWithOptions:(AppBladeFeedbackDisplayOptions)options
{
#ifndef SKIP_FEEDBACK
    [self validateProjectConfiguration];
    if(self.isAllDisabled){
        ABDebugLog_internal(@"Can't show feedback dialog, SDK disabled");
        return;
    }

    [self.feedbackManager showFeedbackDialogueWithOptions:options];
#else
    NSLog(@"%s has been disabled in this build of AppBlade.", __PRETTY_FUNCTION__)
#endif
}


-(void)feedbackDidSubmitText:(NSString*)feedbackText{
#ifndef SKIP_FEEDBACK
    ABDebugLog_internal(@"reporting text %@", feedbackText);
    [self reportFeedback:feedbackText];
    self.feedbackManager.showingFeedbackDialogue = NO;
#else
    NSLog(@"%s has been disabled in this build of AppBlade.", __PRETTY_FUNCTION__)
#endif
}

- (void)feedbackDidCancel
{
#ifndef SKIP_FEEDBACK
    NSString* screenshotPath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:[self.feedbackManager.feedbackDictionary objectForKey:kAppBladeFeedbackKeyScreenshot]];
    [[NSFileManager defaultManager] removeItemAtPath:screenshotPath error:nil];
    self.feedbackManager.feedbackDictionary = nil;
    self.feedbackManager.showingFeedbackDialogue = NO;
#else
    NSLog(@"%s has been disabled in this build of AppBlade.", __PRETTY_FUNCTION__)
#endif
}


- (void)handleBackloggedFeedback
{
#ifndef SKIP_FEEDBACK
    if(self.isAllDisabled){
        ABDebugLog_internal(@"Can't handleBackloggedFeedback, SDK disabled");
        return;
    }
    @synchronized (self){
        [self.feedbackManager handleBackloggedFeedback];
    }
#else
        NSLog(@"%s has been disabled in this build of AppBlade.", __PRETTY_FUNCTION__)
#endif
}

#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}


#pragma mark - Session Reporting

+ (void)startSession
{
#ifndef SKIP_SESSIONS
    if([[AppBlade sharedManager] isAllDisabled]){
        ABDebugLog_internal(@"Can't show feedback dialog, SDK disabled");
        return;
    }
    ABDebugLog_internal(@"Starting Session Logging");
    [[AppBlade sharedManager] logSessionStart];
#else
    NSLog(@"%s has been disabled in this build of AppBlade.", __PRETTY_FUNCTION__)
#endif
}


+ (void)endSession
{
#ifndef SKIP_SESSIONS
    ABDebugLog_internal(@"Ended Session Logging");
    if([[AppBlade sharedManager] isAllDisabled]){
        ABDebugLog_internal(@"Can't show feedback dialog, SDK disabled");
        return;
    }

    [[AppBlade sharedManager] logSessionEnd];
#else
    NSLog(@"%s has been disabled in this build of AppBlade.", __PRETTY_FUNCTION__)
#endif
}

- (void)logSessionStart
{
#ifndef SKIP_SESSIONS
    if(self.isAllDisabled){
        ABDebugLog_internal(@"Can't startSession, SDK disabled");
        return;
    }
    [[self AppBladeSessionTrackingManager] logSessionStart];
#else
    NSLog(@"%s has been disabled in this build of AppBlade.", __PRETTY_FUNCTION__)
#endif

}

- (void)logSessionEnd
{
#ifndef SKIP_SESSIONS
    if(self.isAllDisabled){
        ABDebugLog_internal(@"Can't endSession, SDK disabled");
        return;
    }
    [[self AppBladeSessionTrackingManager] logSessionEnd];
#else
    NSLog(@"%s has been disabled in this build of AppBlade.", __PRETTY_FUNCTION__)
#endif

}

#pragma mark - AppBlade Custom Params
-(NSDictionary *)getCustomParams
{
    NSDictionary *toRet = [NSDictionary dictionary];
#ifndef SKIP_CUSTOM_PARAMS
    if([[AppBlade sharedManager] isAllDisabled]){
        ABDebugLog_internal(@"Can't getCustomParams, SDK disabled");
        return toRet;
    }
    [[self customParamsManager] getCustomParams];
    ABDebugLog_internal(@"getting %@", toRet);
#else
    NSLog(@"%s has been disabled in this build of AppBlade.", __PRETTY_FUNCTION__)
#endif
    ABDebugLog_internal(@"getting Custom Params %@", toRet);
    return toRet;
}

-(void)setCustomParams:(NSDictionary *)newFieldValues
{
#ifndef SKIP_CUSTOM_PARAMS
    if([[AppBlade sharedManager] isAllDisabled]){
        ABDebugLog_internal(@"Can't %s, SDK disabled", __PRETTY_FUNCTION__);
        return;
    }
    [[self customParamsManager] setCustomParams:newFieldValues];
#else
    NSLog(@"%s has been disabled in this build of AppBlade.", __PRETTY_FUNCTION__)
#endif
    
}

-(void)setCustomParam:(id)newObject withValue:(NSString*)key
{
#ifndef SKIP_CUSTOM_PARAMS
    if([[AppBlade sharedManager] isAllDisabled]){
        ABDebugLog_internal(@"Can't %s, SDK disabled", __PRETTY_FUNCTION__);
        return;
    }
    [[self customParamsManager] setCustomParam:newObject withValue:key];
#else
    NSLog(@"%s has been disabled in this build of AppBlade.", __PRETTY_FUNCTION__)
#endif
    

}


-(void)setCustomParam:(id)object forKey:(NSString*)key
{
#ifndef SKIP_CUSTOM_PARAMS
    if([[AppBlade sharedManager] isAllDisabled]){
        ABDebugLog_internal(@"Can't %s, SDK disabled", __PRETTY_FUNCTION__);
        return;
    }
    [[self customParamsManager] setCustomParam:object forKey:key];
#else
    NSLog(@"%s has been disabled in this build of AppBlade.", __PRETTY_FUNCTION__)
#endif
}

-(void)clearAllCustomParams
{
#ifndef SKIP_CUSTOM_PARAMS
    if([[AppBlade sharedManager] isAllDisabled]){
        ABDebugLog_internal(@"Can't %s, SDK disabled", __PRETTY_FUNCTION__);
        return;
    }
    [[self customParamsManager] clearAllCustomParams];
#else
    NSLog(@"%s has been disabled in this build of AppBlade.", __PRETTY_FUNCTION__)
#endif
    
}


#pragma mark - AppBladeDelegate
- (void)appBlade:(AppBlade *)appBlade applicationApproved:(BOOL)approved error:(NSError *)error
{
    if(!approved && ![self isAppStoreBuild]) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Permission Denied"
                                                        message:[error localizedDescription]
                                                       delegate:self
                                              cancelButtonTitle:@"Exit"
                                              otherButtonTitles: nil] ;
        alert.tag = kPermissionDeniedAlertTag;
        [alert show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == kPermissionDeniedAlertTag) {
        exit(0);
    }
}


- (BOOL)containsOperationInPendingRequests:(AppBladeWebOperation *)webOperation
{
    return [[self.pendingRequests operations] containsObject:webOperation];
}


#pragma mark - AppBladeWebOperation
-(void) appBladeWebClientFailed:(AppBladeWebOperation *)client
{
    [self appBladeWebClientFailed:client withErrorString:NULL];
}

- (void)appBladeWebClientFailed:(AppBladeWebOperation *)client withErrorString:(NSString*)errorString
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
            NSDictionary*errorDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                            NSLocalizedString(errorString, nil), NSLocalizedDescriptionKey,
                                            NSLocalizedString(errorString, nil),  NSLocalizedFailureReasonErrorKey, nil];
            NSError* error = [NSError errorWithDomain:kAppBladeErrorDomain code:kAppBladeParsingError userInfo:errorDictionary];
            if(canSignalDelegate) {
                [self.delegate appBlade:self applicationApproved:NO error:error];
            }
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
            ABErrorLog(@"ERROR receiving permissions %s", errorString);
            #ifndef SKIP_AUTHENTICATION
                [self.authenticationManager permissionCallbackFailed:client withErrorString:errorString];
            #endif
        }
        else if (client.api == AppBladeWebClientAPI_Feedback) {
            ABErrorLog(@"ERROR sending feedback %s", errorString);
        }
        else if(client.api == AppBladeWebClientAPI_Sessions){
            ABErrorLog(@"ERROR sending sessions %s", errorString);
            #ifndef SKIP_SESSIONS
                [self.AppBladeSessionTrackingManager sessionTrackingCallbackFailed:client withErrorString:errorString];
            #endif
        }
        else if(client.api == AppBladeWebClientAPI_ReportCrash)
        {
            ABErrorLog(@"ERROR sending crash %@, keeping crashes until they are sent", client.userInfo);
            #ifndef SKIP_CRASH_REPORTING
                [self.crashManager crashReportCallbackFailed:client withErrorString:errorString];
            #endif
        }
        else if(client.api == AppBladeWebClientAPI_UpdateCheck)
        {
            ABErrorLog(@"ERROR getting updates from AppBlade %@", client.userInfo);
            #ifndef SKIP_AUTO_UPDATING
                [self.updatesManager updateCallbackFailed:client withErrorString:errorString];
            #endif
        }
        else
        {
            ABErrorLog(@"Nonspecific AppBladeWebClient error: %i", client.api);
        }
    }
}

- (void)appBladeWebClient:(AppBladeWebOperation *)client receivedGenerateTokenResponse:(NSDictionary *)response
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

- (void)appBladeWebClient:(AppBladeWebOperation *)client receivedConfirmTokenResponse:(NSDictionary *)response
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



- (void)appBladeWebClientCrashReported:(AppBladeWebOperation *)client
{
#ifndef SKIP_CRASH_REPORTING
    [self.crashManager handleWebClientCrashReported:client];
#endif
}

- (void)appBladeWebClientSentFeedback:(AppBladeWebOperation *)client withSuccess:(BOOL)success
{
#ifndef SKIP_FEEDBACK
    [self.feedbackManager handleWebClientSentFeedback:client withSuccess:success];
#endif
}

- (void)appBladeWebClientSentSessions:(AppBladeWebOperation *)client withSuccess:(BOOL)success
{
#ifndef SKIP_SESSIONS
    [self.AppBladeSessionTrackingManager handleWebClientSentSessions:client withSuccess:success];
#else
    NSLog(@"%s has been disabled in this build of AppBlade.", __PRETTY_FUNCTION__)
#endif
}


#pragma mark - Helper Methods
#pragma mark Device Secret Methods

-(NSMutableDictionary*) appBladeDeviceSecrets
{
    if(self.isAllDisabled){
        ABDebugLog_internal(@"Can't get appBladeDeviceSecrets, SDK disabled");
        return [NSMutableDictionary dictionaryWithObjectsAndKeys:@"", kAppBladeKeychainDeviceSecretKeyNew, @"", kAppBladeKeychainDeviceSecretKeyOld, @"", kAppBladeKeychainPlistHashKey, nil];;
    }
    return [self.deviceSecretManager appBladeDeviceSecrets];
}


- (NSString *)appBladeDeviceSecret
{
    if(self.isAllDisabled){
        ABDebugLog_internal(@"Can't get appBladeDeviceSecret, SDK disabled");
        return @"";
    }

    return [self.deviceSecretManager appBladeDeviceSecret];
}

- (void) setAppBladeDeviceSecret:(NSString *)appBladeDeviceSecret
{
    if(self.isAllDisabled){
        ABDebugLog_internal(@"Can't get setAppBladeDeviceSecret, SDK disabled");
        return;
    }
    [self.deviceSecretManager setAppBladeDeviceSecret:appBladeDeviceSecret];
}


- (void)clearAppBladeKeychain
{
    if(self.isAllDisabled){
        ABDebugLog_internal(@"Can't clearAppBladeKeychain, SDK disabled");
        return;
    }
    [self.deviceSecretManager clearAppBladeKeychain];
}

- (void)clearStoredDeviceSecrets
{
    if(self.isAllDisabled){
        ABDebugLog_internal(@"Can't clearStoredDeviceSecrets, SDK disabled");
        return;
    }
    [self.deviceSecretManager clearStoredDeviceSecrets];
}


-(BOOL)hasDeviceSecret
{
    return [self.deviceSecretManager hasDeviceSecret];
}

- (BOOL)isDeviceSecretBeingConfirmed
{
    return [self.deviceSecretManager isDeviceSecretBeingConfirmed];
}



#pragma mark AppBlade cache methods
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

#pragma mark File I/O

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

- (NSString*)hashFileOfPlist:(NSString *)filePath
{
    NSString* returnString = nil;
    CFStringRef executableFileMD5Hash =
    FileMD5HashCreateWithPath((__bridge CFStringRef)(filePath), FileHashDefaultChunkSizeForReadingData);
    if (executableFileMD5Hash) {
        returnString = (__bridge NSString *)(executableFileMD5Hash);
        // CFRelease(executableFileMD5Hash);
    }
    return returnString;
}


#pragma mark AppBladeWebOperation 

- (AppBladeWebOperation *)generateWebOperation
{
    AppBladeWebOperation * webOperation = [[AppBladeWebOperation alloc] initWithDelegate:self];
    return webOperation;
}


- (void)addPendingRequest:(AppBladeWebOperation *)webOperation
{
    [[self pendingRequests] addOperation:webOperation];
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

#pragma mark Assorted Other

-(NSString *) randomString: (int) len {
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [s_letters characterAtIndex: arc4random()%[s_letters length]]];
    }
    return randomString;
}



+ (NSString*)sdkVersion
{
    return s_sdkVersion;
}

+ (void)logSDKVersion
{
    NSLog(@"AppBlade SDK v %@.", s_sdkVersion);
}

@end
