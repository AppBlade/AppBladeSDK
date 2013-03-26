//
//  AppBlade.m
//  AppBlade
//
//  Created by Craig Spitzkoff on 6/1/11.
//  Copyright 2011 AppBlade. All rights reserved.
//

#import "AppBlade.h"
#import "AppBladeSimpleKeychain.h"
#import "AppBladeLocationSingleton.h"

#import "PLCrashReporter.h"
#import "PLCrashReport.h"
#import "AppBladeWebClient.h"
#import "PLCrashReportTextFormatter.h"
#import "FeedbackDialogue.h"
#import "asl.h"
#import <QuartzCore/QuartzCore.h>

static NSString* const s_sdkVersion                     = @"0.3.0";

NSString* const kAppBladeErrorDomain                    = @"com.appblade.sdk";
const int kAppBladeOfflineError                         = 1200;
const int kAppBladeParsingError                         = 1208;
const int kAppBladePermissionError                      = 1216;
NSString* const kAppBladeCacheDirectory                 = @"AppBladeCache";

const int kUpdateAlertTag                               = 316;

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


@interface AppBlade () <AppBladeWebClientDelegate, FeedbackDialogueDelegate>

@property (nonatomic, retain) NSURL* upgradeLink;


// Feedback
@property (nonatomic, retain) NSMutableDictionary* feedbackDictionary;
@property (nonatomic, assign) BOOL showingFeedbackDialogue;
@property (nonatomic, retain) UITapGestureRecognizer* tapRecognizer;
@property (nonatomic, assign) UIWindow* window;

@property (nonatomic, retain) NSDate *sessionStartDate;

@property (nonatomic, retain) NSMutableSet* activeClients;


- (void)raiseConfigurationExceptionWithFieldName:(NSString *)name;
- (void)handleCrashReport;
- (void)showFeedbackDialogue;

- (void)promptFeedbackDialogue;
- (void)reportFeedback:(NSString*)feedback;

- (void)checkAndCreateAppBladeCacheDirectory;
- (NSString*)captureScreen;
- (UIImage*)getContentBelowView;
- (NSString*)randomString:(int)length;

- (BOOL)hasPendingFeedbackReports;
- (void)handleBackloggedFeedback;

- (NSInteger)activeClientsOfType:(AppBladeWebClientAPI)clientType;
- (void)removeIntermediateFeedbackFiles:(NSString *)feedbackPath;

- (BOOL)hasPendingSessions;


- (UIImage *) rotateImage:(UIImage *)img angle:(int)angle;

@end


@implementation AppBlade

@synthesize appBladeHost = _appBladeHost;
@synthesize appBladeProjectID = _appBladeProjectID;
@synthesize appBladeProjectToken = _appBladeProjectToken;
@synthesize appBladeProjectSecret = _appBladeProjectSecret;
@synthesize appBladeProjectIssuedTimestamp = _appBladeProjectIssuedTimestamp;
@synthesize delegate = _delegate;
@synthesize upgradeLink = _upgradeLink;
@synthesize feedbackDictionary = _feedbackDictionary;
@synthesize showingFeedbackDialogue = _showingFeedbackDialogue;
@synthesize tapRecognizer = _tapRecognizer;

@synthesize sessionStartDate = _sessionStartDate;

@synthesize window = _window;

@synthesize activeClients = _activeClients;



static AppBlade *s_sharedManager = nil;

/* A custom post-crash callback */
void post_crash_callback (siginfo_t *info, ucontext_t *uap, void *context) {
    [AppBlade endSession];
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

- (id)init {
    if ((self = [super init])) {
        // Delegate authentication outcomes and other messages are handled by self unless overridden.
        _delegate = self;
        _activeClients = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)validateProjectConfiguration
{
    // Validate AppBlade project settings. This should be executed by every public method before proceding.
    if(!self.appBladeHost || self.appBladeHost.length == 0) {
        //could be redundant now that we are handling host building from the webclient
        NSLog(@"Host not being ovewritten, falling back to default host (%@)", kAppBladeDefaultHost);
        self.appBladeHost = kAppBladeDefaultHost;
    }
    
    if (!self.appBladeProjectID || self.appBladeProjectID.length == 0) {
        [self raiseConfigurationExceptionWithFieldName:@"Project ID"];
    } else if (!self.appBladeProjectToken || self.appBladeProjectToken.length == 0) {
        [self raiseConfigurationExceptionWithFieldName:@"Project Token"];
    } else if (!self.appBladeProjectSecret || self.appBladeProjectSecret.length == 0) {
        [self raiseConfigurationExceptionWithFieldName:@"Project Secret"];
    } else if (!self.appBladeProjectIssuedTimestamp || self.appBladeProjectIssuedTimestamp.length == 0) {
        [self raiseConfigurationExceptionWithFieldName:@"Project Issued At Timestamp"];
    }
}

- (void)raiseConfigurationExceptionWithFieldName:(NSString *)name
{
    NSString *exceptionMessageFormat = [NSString stringWithFormat:@"AppBlade %@ not set. Configure the shared AppBlade manager from within your application delegate or AppBlade plist file.", name];
    NSLog(@"%@", exceptionMessageFormat);
    [NSException raise:@"AppBladeException" format:exceptionMessageFormat];
    abort();
}

- (void)dealloc
{   
    [_upgradeLink release];
    [_feedbackDictionary release];
    [_appBladeHost release];
    [_appBladeProjectID release];
    [_appBladeProjectToken release];
    [_appBladeProjectSecret release];
    [_appBladeProjectIssuedTimestamp release];
    [_delegate release];
    [_upgradeLink release];
    [_feedbackDictionary release];
    [_tapRecognizer release];
    [_window release];
    
    [_sessionStartDate release];

    [_activeClients release];
    [super dealloc];
}

#pragma mark

- (void)checkApproval
{
    [self validateProjectConfiguration];

    AppBladeWebClient * client = [[[AppBladeWebClient alloc] initWithDelegate:self] autorelease];
    [self.activeClients addObject:client];
    [client checkPermissions];    
}

- (void)catchAndReportCrashes
{
    NSLog(@"Catch and report crashes");
    [self validateProjectConfiguration];

    PLCrashReporter *crashReporter = [PLCrashReporter sharedReporter];
    NSError *error;
    
    [self checkForExistingCrashReports];
    
    // Enable the Crash Reporter
    if (![crashReporter enableCrashReporterAndReturnError: &error])
        NSLog(@"Warning: Could not enable crash reporter: %@", error);
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
        PLCrashReport *report = [[[PLCrashReport alloc] initWithData: crashData error: &error] autorelease];
        if (report != nil) {
            reportString = [PLCrashReportTextFormatter stringValueForCrashReport:report withTextFormat: PLCrashReportTextFormatiOS];
//            NSLog(@"Formatting crash report with PLCrashReportTextFormatter %@", reportString);
            //send pending crash report to a unique file name in the the queue
            queuedFilePath = [crashReporter saveCrashReportInQueue:reportString]; //file will stay in the queue until it's sent
            if(queuedFilePath == nil){
                NSLog(@"error saving crash report");
            }else{
                NSLog(@"moved crash report to %@", queuedFilePath);
            }
        }
        else
        {
            NSLog(@"Could not parse crash report");
        }
    }
    else
    {
        NSLog(@"Could not load a crash report from live file");
    }
    [crashReporter purgePendingCrashReport]; //remove crash report from immediate file, we have it in the queue now

    if(queuedFilePath == nil){
        //we had no immediate crash, or an invalid save, grab any stored crash report
        queuedFilePath = [crashReporter getNextCrashReportPath];
        reportString = [NSString stringWithContentsOfFile:queuedFilePath encoding:NSUTF8StringEncoding error:&error];
    }
    
    if(queuedFilePath != nil){
        AppBladeWebClient * client = [[[AppBladeWebClient alloc] initWithDelegate:self] autorelease];
        [self.activeClients addObject:client];
        client.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:queuedFilePath,  kAppBladeCrashReportKeyFilePath, nil];
        [client reportCrash:reportString withParams:[self getCustomParams]];
    }else{
        NSLog(@"No crashes to report");
    }
}

- (void)loadSDKKeysFromPlist:(NSString *)plist
{
    NSDictionary* keys = [NSDictionary dictionaryWithContentsOfFile:plist];
    self.appBladeHost =  [AppBladeWebClient buildHostURL:[keys objectForKey:@"host"]];
    self.appBladeProjectID = [keys objectForKey:@"projectID"];
    self.appBladeProjectToken = [keys objectForKey:@"token"];
    self.appBladeProjectSecret = [keys objectForKey:@"secret"];
    self.appBladeProjectIssuedTimestamp = [keys objectForKey:@"timestamp"];
}



#pragma mark - AppBladeWebClient
-(void) appBladeWebClientFailed:(AppBladeWebClient *)client
{
    [self appBladeWebClientFailed:client withErrorString:NULL];
}

- (void)appBladeWebClientFailed:(AppBladeWebClient *)client withErrorString:(NSString*)errorString
{
    if (client.api == AppBladeWebClientAPI_Permissions)  {
        
        // check only once if the delegate responds to this selector
        BOOL signalDelegate = [self.delegate respondsToSelector:@selector(appBlade:applicationApproved:error:)];
        
        // if the connection failed, see if the application is still within the previous TTL window.
        // If it is, then let the application run. Otherwise, ensure that the TTL window is closed and
        // prevent the app from running until the request completes successfully. This will prevent
        // users from unlocking an app by simply changing their clock.
        if ([self withinStoredTTL]) {
            if(signalDelegate) {
                [self.delegate appBlade:self applicationApproved:YES error:nil];
            }
            
        }
        else {
            [self closeTTLWindow];
            if(signalDelegate) {
                NSDictionary* errorDictionary = nil;
                NSError* error = nil;
                if(errorString){
                    errorDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                       NSLocalizedString(errorString, nil), NSLocalizedDescriptionKey,
                                       NSLocalizedString(errorString, nil),  NSLocalizedFailureReasonErrorKey, nil];
                    error = [NSError errorWithDomain:kAppBladeErrorDomain code:kAppBladeParsingError userInfo:errorDictionary];

                }else{
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
            NSLog(@"ERROR sending feedback");
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
                    NSLog(@"Error writing backup file to %@", backupFilePath);
                }
                self.feedbackDictionary = nil;
            }
            else {
                [self.activeClients removeObject:client];
            }
        }
    }
    else if(client.api == AppBladeWebClientAPI_Sessions){
        NSLog(@"ERROR sending sessions");
    }
    else if(client.api == AppBladeWebClientAPI_ReportCrash)
    {
        NSLog(@"ERROR sending crash %@, keeping crashes until they are sent", client.userInfo);
    }
    else
    {
        NSLog(@"Nonspecific AppBladeWebClient error: %i", client.api);
    }
    
    [self.activeClients removeObject:client];
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
        
        if (signalApproval)
            [self.delegate appBlade:self applicationApproved:NO error:error];
        
        
    }
    else {
        
        NSNumber *ttl = [permissions objectForKey:@"ttl"];
        if (ttl) {
            [self updateTTL:ttl];
        }
        
        // tell the client the application was approved.
        if (signalApproval) {
            [self.delegate appBlade:self applicationApproved:YES error:nil];
        }
        
        
        // determine if there is an update available
        NSDictionary* update = [permissions objectForKey:@"update"];
        if(update)
        {
            NSString* updateMessage = [update objectForKey:@"message"];
            NSString* updateURL = [update objectForKey:@"url"];
            
            if ([self.delegate respondsToSelector:@selector(appBlade:updateAvailable:updateMessage:updateURL:)]) {
                [self.delegate appBlade:self updateAvailable:YES updateMessage:updateMessage updateURL:updateURL];
            }
        }
    }
    
    [self.activeClients removeObject:client];
    
    
}

- (void)appBladeWebClientCrashReported:(AppBladeWebClient *)client
{
    // purge the crash report that was just reported.
    int status = [[client.responseHeaders valueForKey:@"statusCode"] intValue];
    BOOL success = (status == 201 || status == 200);
    if(success){ //we don't need to hold onto this crash.
        NSLog(@"Appblade: success sending crash report, response status code: %d", status);
        [[PLCrashReporter sharedReporter] purgePendingCrashReport];
        NSString *pathOfCrashReport = [client.userInfo valueForKey:kAppBladeCrashReportKeyFilePath];
        [[NSFileManager defaultManager] removeItemAtPath:pathOfCrashReport error:nil];
        NSLog(@"Appblade: removed crash report, %@", pathOfCrashReport);

        if ([[PLCrashReporter sharedReporter] hasPendingCrashReport]){
            NSLog(@"Appblade: PLCrashReporter has more crash reports");
            [self handleCrashReport];
        }else{
            NSLog(@"Appblade: PLCrashReporter has no more crash reports");
        }
    }
    else
    {
        NSLog(@"Appblade: error sending crash report, response status code: %d", status);
        //No more crash reports for now. We might have bad internet access.
    }
    [self.activeClients removeObject:client];
}

- (void)appBladeWebClientSentFeedback:(AppBladeWebClient *)client withSuccess:(BOOL)success
{
    @synchronized (self){
        BOOL isBacklog = [self.activeClients containsObject:client];
        if (success) {
            NSLog(@"feedback Successful");
            
            NSDictionary* feedback = [client.userInfo objectForKey:kAppBladeFeedbackKeyFeedback];
            // Clean up
            NSString* screenshotPath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:[feedback objectForKey:kAppBladeFeedbackKeyScreenshot]];
            [[NSFileManager defaultManager] removeItemAtPath:screenshotPath error:nil];

            NSString* backupFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeBacklogFileName];
            NSMutableArray* backups = [NSMutableArray arrayWithContentsOfFile:backupFilePath];
           
            NSString* fileName = [client.userInfo objectForKey:kAppBladeFeedbackKeyBackup];

            NSString* filePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:fileName];
            NSLog(@"Removing supporting feedback files and the feedback file herself");
            [self removeIntermediateFeedbackFiles:filePath];
           
            NSLog(@"Removing Successful feedback object from main feedback list");
            [backups removeObject:fileName];
            if (backups.count > 0) {
                NSLog(@"writing pending feedback objects back to file");
                [backups writeToFile:backupFilePath atomically:YES];
            }
            
            NSLog(@"checking for more pending feedback");
            if ([self hasPendingFeedbackReports]) {
                NSLog(@"more pending feedback");
                [self handleBackloggedFeedback];
            }else{
                NSLog(@"no more pending feedback");
            }
        }
        else if (!isBacklog) {
            NSLog(@"Unsuccesful feedback not found in backLog");
            
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
                NSLog(@"Error writing backup file to %@", backupFilePath);
            }
        } //It's failed and already in the backlog. Keep it there.
        
        if (!isBacklog) {
            self.feedbackDictionary = nil;
        }
        
        [self.activeClients removeObject:client];
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
                NSLog(@"Error deleting Session log: %@", deleteError.debugDescription);
            }
        }
    }
    else
    {
        NSLog(@"Error sending Session log");
    }
    [self.activeClients removeObject:client];
}


#pragma mark - AppBladeDelegate
- (void)appBlade:(AppBlade *)appBlade applicationApproved:(BOOL)approved error:(NSError *)error
{
    if(!approved) {
        
        UIAlertView* alert = [[[UIAlertView alloc] initWithTitle:@"Permission Denied"
                                                         message:[error localizedDescription]
                                                        delegate:self
                                               cancelButtonTitle:@"Exit"
                                               otherButtonTitles: nil] autorelease];
        [alert show];
    }
    
}


-(void) appBlade:(AppBlade *)appBlade updateAvailable:(BOOL)update updateMessage:(NSString*)message updateURL:(NSString*)url
{
    if (update) {
        
        UIAlertView* alert = [[[UIAlertView alloc] initWithTitle:@"Update Available"
                                                         message:message
                                                        delegate:self
                                               cancelButtonTitle:@"Cancel"
                                               otherButtonTitles: @"Upgrade", nil] autorelease];
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
            NSLog(@"found file at %@", feedbackBacklogFilePath);
            NSMutableArray* backupFiles = [NSMutableArray arrayWithContentsOfFile:feedbackBacklogFilePath];
            if (backupFiles.count > 0) {
                NSLog(@"found %d files at feedbackBacklogFilePath", backupFiles.count);
                toRet = YES;
            }else {
                NSLog(@"found NO files at feedbackBacklogFilePath");
                toRet = NO;
            }
        }else{
            NSLog(@"found nothing at %@", feedbackBacklogFilePath);
            toRet = NO;
        }
    }
    return toRet;
}


- (void)allowFeedbackReporting
{
    NSLog(@"allowFeedbackReporting");

    UIWindow* window = [[UIApplication sharedApplication] keyWindow];
    if (window) {
        [self allowFeedbackReportingForWindow:window];
        NSLog(@"Allowing feedback.");
    }
    else {
        NSLog(@"Cannot setup for feedback. No keyWindow.");
    }
}

- (void)allowFeedbackReportingForWindow:(UIWindow *)window
{
    self.window = window;
    self.tapRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showFeedbackDialogue)] autorelease];
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
        NSLog(@"Allowing custom feedback.");
        
    }
    else {
        NSLog(@"Cannot setup for custom feedback. No keyWindow.");
    }

}

- (void)setupCustomFeedbackReportingForWindow:(UIWindow*)window
{
    if (window) {
        NSLog(@"Allowing custom feedback for window %@", window);
        self.window = window;
    }
    else
    {
        NSLog(@"Cannot setup for custom feedback. Not a valid window.");
        return;
    }
    [self checkAndCreateAppBladeCacheDirectory];
    if ([self hasPendingFeedbackReports]) {
        [self handleBackloggedFeedback];
    }
}


- (void)showFeedbackDialogue
{
    if(!self.showingFeedbackDialogue){
        self.showingFeedbackDialogue = YES;
        if(self.feedbackDictionary == nil){
            self.feedbackDictionary = [NSMutableDictionary  dictionary];
        }

        //More like SETUP feedback dialogue, am I right? I'm hilarious. Anyway, this gets all our ducks in a row before showing the feedback dialogue
        NSString* screenshotPath = [self captureScreen];
        [self.feedbackDictionary setObject:[screenshotPath lastPathComponent] forKey:kAppBladeFeedbackKeyScreenshot];
        //other setup methods (like the reintroduction of the console log) will go here
        [self promptFeedbackDialogue];
    }
    else
    {
        NSLog(@"Feedback window already presenting, or a screenshot is trying to be captured");
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
    
    NSLog(@"Displaying feedback dialog in frame X:%.f Y:%.f W:%.f H:%.f",
          screenFrame.origin.x, screenFrame.origin.y,
          screenFrame.size.width, screenFrame.size.height);
    
    
    FeedbackDialogue *feedback = [[FeedbackDialogue alloc] initWithFrame:CGRectMake(screenFrame.origin.x, screenFrame.origin.y, screenFrame.size.width, screenFrame.size.height)];
    feedback.delegate = self;
    
    // get the first window in the application if one was not supplied.
    if (!self.window){
        self.window = [[UIApplication sharedApplication] keyWindow];
        self.showingFeedbackDialogue = YES;
        NSLog(@"Feedback window not defined, using default (Images might not come through.)");
    }
    if([[self.window subviews] count] > 0){
        [[[self.window subviews] objectAtIndex:0] addSubview:feedback];
        self.showingFeedbackDialogue = YES;
        [feedback.textView becomeFirstResponder];
    }
    else
    {
        NSLog(@"No subviews in feedback window, cannot prompt feedback dialog at this time.");
        feedback.delegate = nil;
        self.showingFeedbackDialogue = NO;
    }
    
}

-(void)feedbackDidSubmitText:(NSString*)feedbackText{
    
    NSLog(@"reporting text %@", feedbackText);
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
    
    NSLog(@"caching and attempting send of feedback %@", self.feedbackDictionary);
    
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
        NSLog(@"Error writing backup file to %@", backupFilePath);
    }
    
    AppBladeWebClient * client = [[[AppBladeWebClient alloc] initWithDelegate:self] autorelease];
    [self.activeClients addObject:client];
    NSLog(@"Sending screenshot");
    [client sendFeedbackWithScreenshot:[self.feedbackDictionary objectForKey:kAppBladeFeedbackKeyScreenshot] note:feedback console:nil params:[self getCustomParams]];
}


- (void)handleBackloggedFeedback
{
    @synchronized (self){
        NSLog(@"handleBackloggedFeedback");
        NSString* backupFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeBacklogFileName];
        NSMutableArray* backupFiles = [NSMutableArray arrayWithContentsOfFile:backupFilePath];
        if (backupFiles.count > 0) {
            NSString* fileName = [backupFiles objectAtIndex:0]; //get earliest unsent feedback
            NSString* feedbackPath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:fileName];
            
            NSDictionary* feedback = [NSDictionary dictionaryWithContentsOfFile:feedbackPath];
            if (feedback) {
                NSLog(@"Feedback found at %@", feedbackPath);
                NSLog(@"backlog Feedback dictionary %@", feedback);
                NSString *screenshotFileName = [feedback objectForKey:kAppBladeFeedbackKeyScreenshot];
                //validate that additional files exist
                NSString *screenshotFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:screenshotFileName];
                bool screenShotFileExists = [[NSFileManager defaultManager] fileExistsAtPath:screenshotFilePath];
                if(screenShotFileExists){
                    AppBladeWebClient * client = [[[AppBladeWebClient alloc] initWithDelegate:self] autorelease];
                    client.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:feedback, kAppBladeFeedbackKeyFeedback, fileName, kAppBladeFeedbackKeyBackup, nil];
                    [self.activeClients addObject:client];
                    [client sendFeedbackWithScreenshot:screenshotFileName note:[feedback objectForKey:kAppBladeFeedbackKeyNotes] console:nil params:[self getCustomParams]];
                    
                    if (!self.activeClients) {
                        self.activeClients = [NSMutableSet set];
                    }
                    
                    [self.activeClients addObject:client];
                }else{
                    //clean up files if one doesn't exist
                    [self removeIntermediateFeedbackFiles:feedbackPath];
                    NSLog(@"invalid feedback at %@, removing File and intermediate files", feedbackPath);
                    [backupFiles removeObject:fileName];
                    NSLog(@"writing valid pending feedback objects back to file");
                    [backupFiles writeToFile:backupFilePath atomically:YES];

                }
            }else{
                NSLog(@"No Feedback found at %@, invalid feedback, removing File", feedbackPath);
                [backupFiles removeObject:fileName];
                NSLog(@"writing valid pending feedback objects back to file");
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
        NSLog(@"ERROR, could not capture screenshot, possible invalid keywindow");
    }
    NSString* fileName = [[self randomString:36] stringByAppendingPathExtension:@"png"];
	NSString *pngFilePath = [[[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:fileName] retain];
	NSData *data1 = [NSData dataWithData:UIImagePNGRepresentation(currentImage)];
	[data1 writeToFile:pngFilePath atomically:YES];
    NSLog(@"Screen captured in fileName %@", fileName);
    return [pngFilePath autorelease];
    
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
    NSInteger sessionClients = [self activeClientsOfType:AppBladeWebClientAPI_Sessions];
    return sessionClients > 0;
}

- (void)allowLocationLogging
{
    [self allowLocationLoggingForDistance:DEFAULT_APPBLADE_LOCATION_LOGGING_DISTANCE andOrTime:DEFAULT_APPBLADE_LOCATION_LOGGING_TIME];
}

- (void)allowLocationLoggingForDistance:(int)meters andOrTime:(int)seconds
{
    [[AppBladeLocationSingleton sharedInstance] enableLocationTracking];
    [[AppBladeLocationSingleton sharedInstance] setLocationUpdateDistance:meters andTimeOut:seconds];
}

+ (void)startSession
{
    NSLog(@"Starting Session Logging");
    [[AppBlade sharedManager] logSessionStart];
}


-(void)updateSessionLocations
{
    [[AppBladeLocationSingleton sharedInstance] enableLocationTracking];
    [[AppBladeLocationSingleton sharedInstance] updateStoredLocations];
}

+ (void)endSession
{
    NSLog(@"Ended Session Logging");
    [[AppBlade sharedManager] logSessionEnd];
}

- (void)logSessionStart
{
    if(self.activeClients == nil){
        self.activeClients = [NSMutableSet set];
    }
    
    NSString* sessionFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeSessionFile];
    NSLog(@"Checking Session Path: %@", sessionFilePath);

    if ([[NSFileManager defaultManager] fileExistsAtPath:sessionFilePath]) {
        NSArray* sessions = (NSArray*)[self readFile:sessionFilePath];
        NSLog(@"%d Sessions Exist, posting them", [sessions count]);
        
        AppBladeWebClient * client = [[[AppBladeWebClient alloc] initWithDelegate:self] autorelease];
        [self.activeClients addObject:client];
        if(![self hasPendingSessions]){
            [client postSessions:sessions];
        }
    }
    
    self.sessionStartDate = [NSDate date];
}

- (void)logSessionEnd
{
    NSDictionary* sessionDict = [NSDictionary dictionaryWithObjectsAndKeys:self.sessionStartDate, @"started_at", [NSDate date], @"ended_at", [self getCustomParams], @"custom_params", [[AppBladeLocationSingleton sharedInstance] currentStoredLocations], @"locations", nil];
    
    NSMutableArray* pastSessions = nil;
    NSString* sessionFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeSessionFile];
    if ([[NSFileManager defaultManager] fileExistsAtPath:sessionFilePath]) {
        NSArray* sessions = (NSArray*)[self readFile:sessionFilePath];
        pastSessions = [[sessions mutableCopy] autorelease];
    }
    else {
        pastSessions = [NSMutableArray arrayWithCapacity:1];
    }
    
    [pastSessions addObject:sessionDict];
    
    NSData* sessionData = [NSKeyedArchiver archivedDataWithRootObject:pastSessions];
    [sessionData writeToFile:sessionFilePath atomically:YES];
    [[AppBladeLocationSingleton sharedInstance] clearStoredLocations];
}

#pragma mark - AppBlade Custom Params
-(NSDictionary *)getCustomParams
{
    NSDictionary *toRet = nil;
    NSString* customFieldsPath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeCustomFieldsFile];
    if ([[NSFileManager defaultManager] fileExistsAtPath:customFieldsPath]) {
        NSDictionary* currentFields = [NSDictionary dictionaryWithContentsOfFile:customFieldsPath];
        toRet = currentFields;
    }else {
        NSLog(@"no file found, reinitializing");
        toRet = [NSDictionary dictionary];
        [self setCustomParams:toRet];
    }
    NSLog(@"getting %@", toRet);

    return toRet;
}

-(void)setCustomParams:(NSDictionary *)newFieldValues
{
    [self checkAndCreateAppBladeCacheDirectory];
    NSString* customFieldsPath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeCustomFieldsFile];
    if ([[NSFileManager defaultManager] fileExistsAtPath:customFieldsPath]) {
        NSLog(@"WARNING: Overwriting all existing user params");
    }
    if(newFieldValues){
        NSError *error = nil;
        NSData *paramsData = [NSPropertyListSerialization dataWithPropertyList:newFieldValues format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
        if(!error){
            [paramsData writeToFile:customFieldsPath atomically:YES];
        }else{
            NSLog(@"Error parsing custom params %@", newFieldValues);
        }
    }else{
        NSLog(@"clearing custom params, removing file");
        [[NSFileManager defaultManager] removeItemAtPath:customFieldsPath error:nil];
    }
}

-(void)setCustomParam:(id)key withValue:(id)value
{
    NSDictionary* currentFields = [self getCustomParams];
    if (currentFields == nil) {
        currentFields = [NSDictionary dictionary];
    }
    NSMutableDictionary* mutableFields = [[currentFields  mutableCopy] autorelease];
    if(key && value){
        [mutableFields setObject:value forKey:key];
    }else if(key && !value){
        [mutableFields removeObjectForKey:key];
    }
    else
    {
        NSLog(@"invalid nil key");
    }
    NSLog(@"setting to %@", mutableFields);
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
    [AppBladeSimpleKeychain delete:@"appBlade"];
}

- (void)updateTTL:(NSNumber*)ttl
{
    NSDate* ttlDate = [NSDate date];
    NSDictionary* appBlade = [NSDictionary dictionaryWithObjectsAndKeys:ttlDate, @"ttlDate",ttl, @"ttlInterval", nil];
    [AppBladeSimpleKeychain save:@"appBlade" data:appBlade];
}

// determine if we are within the range of the stored TTL for this application
- (BOOL)withinStoredTTL
{
    NSDictionary* appBlade = [AppBladeSimpleKeychain load:@"appBlade"];
    NSDate* ttlDate = [appBlade objectForKey:@"ttlDate"];
    NSNumber* ttlInterval = [appBlade objectForKey:@"ttlInterval"];
    
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



#pragma mark - Helper Methods

- (void)checkAndCreateAppBladeCacheDirectory
{
    NSString* directory = [AppBlade cachesDirectoryPath];
    NSFileManager* manager = [NSFileManager defaultManager];
    BOOL isDirectory = YES;
    if (![manager fileExistsAtPath:directory isDirectory:&isDirectory]) {
        NSLog(@"Appblade creating %@", directory);
        NSError* error = nil;
        BOOL success = [manager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error];
        if (!success) {
            NSLog(@"Error creating directory %@", error);
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
            NSLog(@"AppBlade cannot remove file %@", [filePath lastPathComponent]);
        }
    }
    return returnObject;
}


- (void)removeIntermediateFeedbackFiles:(NSString *)feedbackPath
{
    NSDictionary* feedback = [NSDictionary dictionaryWithContentsOfFile:feedbackPath];
    if (feedback) {
        NSLog(@"Cleaning Feedback %@", feedback);
        NSString *screenshotFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:[feedback objectForKey:kAppBladeFeedbackKeyScreenshot]];
        
        NSError *screenShotError = nil;
        [[NSFileManager defaultManager] removeItemAtPath:screenshotFilePath error:&screenShotError];
    }
    NSError *feedbackPathError = nil;
    [[NSFileManager defaultManager] removeItemAtPath:feedbackPath error:&feedbackPathError];

}

- (NSInteger)activeClientsOfType:(AppBladeWebClientAPI)clientType {
    NSInteger amtToReturn = 0;
    
    if(clientType == AppBladeWebClientAPI_AllTypes){
        amtToReturn = [self.activeClients count];
    }
    else
    {
        NSSet* clientsOfType = [self.activeClients filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"api == %d", clientType ]];
        amtToReturn = clientsOfType.count;
    }
    return amtToReturn;
}


-(NSString *) randomString: (int) len {
    
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [s_letters characterAtIndex: arc4random()%[s_letters length]]];
    }
    
    return randomString;
}



@end
