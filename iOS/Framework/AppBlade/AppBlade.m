//
//  AppBlade.m
//  AppBlade
//
//  Created by Craig Spitzkoff on 6/1/11.
//  Copyright 2011 AppBlade. All rights reserved.
//

#import "AppBlade.h"
#import "AppBladeSimpleKeychain.h"
#import "PLCrashReporter.h"
#import "PLCrashReport.h"
#import "AppBladeWebClient.h"
#import "PLCrashReportTextFormatter.h"
#import "FeedbackDialogue.h"
#import "asl.h"
#import <QuartzCore/QuartzCore.h>

static NSString* const s_sdkVersion                     = @"0.2";

const int kUpdateAlertTag                               = 316;

static NSString* const kAppBladeErrorDomain             = @"com.appblade.sdk";
static const int kAppBladeOfflineError                  = 1200;
static NSString *s_letters                              = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
static NSString* const kAppBladeCacheDirectory          = @"AppBladeCache";
static NSString* const kAppBladeBacklogFileName         = @"AppBladeBacklog.plist";
static NSString* const kAppBladeFeedbackKeyConsole      = @"console";
static NSString* const kAppBladeFeedbackKeyNotes        = @"notes";
static NSString* const kAppBladeFeedbackKeyScreenshot   = @"screenshot";
static NSString* const kAppBladeFeedbackKeyFeedback     = @"feedback";
static NSString* const kAppBladeFeedbackKeyBackup       = @"backupFileName";

@interface AppBlade () <AppBladeWebClientDelegate, FeedbackDialogueDelegate>

@property (nonatomic, retain) NSURL* upgradeLink;

// Feedback
@property (nonatomic, retain) NSMutableDictionary* feedbackDictionary;
@property (nonatomic, assign) BOOL showingFeedbackDialogue;
@property (nonatomic, retain) UITapGestureRecognizer* tapRecognizer;
@property (nonatomic, retain) NSMutableSet* feedbackRequests;
@property (nonatomic, assign) UIView* feedbackView;
@property (nonatomic, retain, readwrite) NSDictionary* appBladeParams;

- (void)raiseConfigurationExceptionWithFieldName:(NSString *)name;
- (void)handleCrashReport;
- (void)handleFeedback;

- (void)showFeedbackDialogue;
- (void)reportFeedback:(NSString*)feedback;

- (void)checkAndCreateAppBladeCacheDirectory;
- (NSString*)captureScreen;
- (UIImage*)getContentBelowView:(UIView*)view;
- (NSString*)randomString:(int)length;

- (BOOL)hasPendingFeedbackReports;
- (void)handleBackloggedFeedback;

- (void)showFeedbackDialogue;
- (void)showFeedbackDialogueWithScreenshot:(BOOL)takeScreenshot;

//- (UIImage *) rotateImage:(UIImage *)img angle:(int)angle;

- (void)displayFeedbackDialogue;

@end


@implementation AppBlade

@synthesize appBladeProjectID = _appBladeProjectID;
@synthesize appBladeProjectToken = _appBladeProjectToken;
@synthesize appBladeProjectSecret = _appBladeProjectSecret;
@synthesize appBladeProjectIssuedTimestamp = _appBladeProjectIssuedTimestamp;
@synthesize delegate = _delegate;
@synthesize upgradeLink = _upgradeLink;
@synthesize feedbackDictionary = _feedbackDictionary;
@synthesize showingFeedbackDialogue = _showingFeedbackDialogue;
@synthesize tapRecognizer = _tapRecognizer;
@synthesize feedbackRequests = _feedbackRequests;
@synthesize appBladeParams = _appBladeParams;

@synthesize feedbackView = _feedbackView;

static AppBlade *s_sharedManager = nil;

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
    }
    return self;
}

- (void)validateProjectConfiguration
{
    // Validate AppBlade project settings. This should be executed by every public method before proceding.
    if(!self.appBladeProjectID) {
        [self raiseConfigurationExceptionWithFieldName:@"Project ID"];
    } else if (!self.appBladeProjectToken) {
        [self raiseConfigurationExceptionWithFieldName:@"Project Token"];
    } else if (!self.appBladeProjectSecret) {
        [self raiseConfigurationExceptionWithFieldName:@"Project Secret"];
    } else if (!self.appBladeProjectIssuedTimestamp) {
        [self raiseConfigurationExceptionWithFieldName:@"Project Issued At Timestamp"];
    }
}

- (void)raiseConfigurationExceptionWithFieldName:(NSString *)name
{
    NSString *exceptionMessageFormat = @"App Blade %@ not set. Configure the shared AppBlade manager from within your "
                                        "application delegate.";
    [NSException raise:@"AppBladeException" format:exceptionMessageFormat, name];
    abort();
}

- (void)dealloc
{   
    [_upgradeLink release];
    [_feedbackDictionary release];
    [_feedbackRequests release];
    [super dealloc];
}

#pragma mark

- (void)checkApproval
{
    [self validateProjectConfiguration];

    AppBladeWebClient* client = [[[AppBladeWebClient alloc] initWithDelegate:self] autorelease];
    [client checkPermissions];    
}

- (void)catchAndReportCrashes
{
    NSLog(@"Catch and report crashes");
    [self validateProjectConfiguration];

    PLCrashReporter *crashReporter = [PLCrashReporter sharedReporter];
    NSError *error;
    
    // Check if we previously crashed
    if ([crashReporter hasPendingCrashReport])
        [self handleCrashReport];
    
    // Enable the Crash Reporter
    if (![crashReporter enableCrashReporterAndReturnError: &error])
        NSLog(@"Warning: Could not enable crash reporter: %@", error);
 
}

- (void)handleCrashReport
{
    PLCrashReporter *crashReporter = [PLCrashReporter sharedReporter];
    NSData *crashData;
    NSError *error;
    
    // Try loading the crash report
    crashData = [crashReporter loadPendingCrashReportDataAndReturnError: &error];
    if (crashData == nil) {
        [crashReporter purgePendingCrashReport];
        NSLog(@"Purged pending crash report");
        return;
    }
    
    // try to parse the crash data into a PLCrashReport. 
    PLCrashReport *report = [[[PLCrashReport alloc] initWithData: crashData error: &error] autorelease];
    if (report == nil) {
        NSLog(@"Could not parse crash report");
        [crashReporter purgePendingCrashReport];
        return;
    }
    
    NSString* reportString = [PLCrashReportTextFormatter stringValueForCrashReport: report withTextFormat: PLCrashReportTextFormatiOS];
    AppBladeWebClient* client = [[[AppBladeWebClient alloc] initWithDelegate:self] autorelease];
    [client reportCrash:reportString withParams:self.appBladeParams];

}

- (void)loadSDKKeysFromPlist:(NSString *)plist
{
    NSDictionary* keys = [NSDictionary dictionaryWithContentsOfFile:plist];
    self.appBladeProjectID = [keys objectForKey:@"projectID"];
    self.appBladeProjectToken = [keys objectForKey:@"token"];
    self.appBladeProjectSecret = [keys objectForKey:@"secret"];
    self.appBladeProjectIssuedTimestamp = [keys objectForKey:@"timestamp"];
}

#pragma mark - Feedback

- (BOOL)hasPendingFeedbackReports
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeBacklogFileName]];
}

- (void)displayFeedbackDialogue
{
    
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGRect screenFrame = self.feedbackView.frame;
    
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
        // We need to react properly to interface orientations
        CGSize size = screenFrame.size;
        screenFrame.size.width = size.height;
        screenFrame.size.height = size.width;
    }
    
    FeedbackDialogue *feedback = [[FeedbackDialogue alloc] initWithFrame:CGRectMake(0, 0, screenFrame.size.width, screenFrame.size.height)];
    feedback.delegate = self;
    
    [self.feedbackView addSubview:feedback];   
    [feedback.textView becomeFirstResponder];
    
}

- (void)showFeedbackDialogue
{
    [self showFeedbackDialogueWithScreenshot:YES inView:nil];
}

- (void)showFeedbackDialogueInView:(UIView *)view
{
    [self showFeedbackDialogueWithScreenshot:YES inView:view];
}

- (void)showFeedbackDialogueWithScreenshot:(BOOL)takeScreenshot
{
    [self showFeedbackDialogueWithScreenshot:takeScreenshot inView:nil];
}

- (void)showFeedbackDialogueWithScreenshot:(BOOL)takeScreenshot inView:(UIView *)view
{
    // Any time the feedback dialogue is shown, this method gets called.
    if (self.showingFeedbackDialogue) {
        return;
    }
    
    if (!view && !self.feedbackView) {
        self.feedbackView = [[[[UIApplication sharedApplication] keyWindow] subviews] lastObject];
    }
    else if (view) {
        self.feedbackView = view;
    }
    
    if (takeScreenshot) {
        [self handleFeedback];
    }
    else {
        [self displayFeedbackDialogue];
    }
    
}

#pragma mark -

-(void)feedbackDidSubmitText:(NSString*)feedbackText{
    
//    NSLog(@"AppBlade received %@", feedbackText);
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

- (void)allowFeedbackReporting
{
    UIWindow* window = [[UIApplication sharedApplication] keyWindow];
    if (window) {
        [self allowFeedbackReportingForWindow:window];
    }
    else {
        NSLog(@"Cannot setup for feeback. No keyWindow.");
    }
}

- (void)allowFeedbackReportingForWindow:(UIWindow *)window
{
    self.feedbackView = [[window subviews] lastObject];
    self.tapRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleFeedback)] autorelease];
    self.tapRecognizer.numberOfTapsRequired = 2;
    self.tapRecognizer.numberOfTouchesRequired = 3;
    self.tapRecognizer.delegate = self;
    [window addGestureRecognizer:self.tapRecognizer];
    
    [self checkAndCreateAppBladeCacheDirectory];
    
    if ([self hasPendingFeedbackReports]) {
        [self handleBackloggedFeedback];
    }
}

- (void)handleFeedback
{
    self.showingFeedbackDialogue = YES;
#if !TARGET_IPHONE_SIMULATOR
    aslmsg q, m;
    int i;
    const char *key, *val;
    
    q = asl_new(ASL_TYPE_QUERY);
    
    aslresponse r = asl_search(NULL, q);
    NSMutableArray* logs = [NSMutableArray arrayWithCapacity:15];
    while (NULL != (m = aslresponse_next(r)))
    {
        
        NSMutableDictionary* logDict = [NSMutableDictionary dictionaryWithCapacity:10];
        for (i = 0; (NULL != (key = asl_key(m, i))); i++)
        {
            NSString *keyString = [NSString stringWithUTF8String:(char *)key];
            
            val = asl_get(m, key);
            
            NSString *string = [NSString stringWithUTF8String:val];
            
            [logDict setObject:string forKey:keyString];
        }
        
        [logs addObject:logDict];
    }
    aslresponse_free(r);
    NSString* fileName = [[self randomString:36] stringByAppendingPathExtension:@"plist"];
	NSString *plistFilePath = [[[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:fileName] retain];
    [logs writeToFile:plistFilePath atomically:YES];
    [plistFilePath release];
    
    self.feedbackDictionary = [NSMutableDictionary dictionaryWithObject:fileName forKey:kAppBladeFeedbackKeyConsole];
#else
    self.feedbackDictionary = [NSMutableDictionary dictionary];
#endif
    NSString* screenshotPath = [self captureScreen];
    
    [self.feedbackDictionary setObject:[screenshotPath lastPathComponent] forKey:kAppBladeFeedbackKeyScreenshot];
    
    [self displayFeedbackDialogue];
}

- (void)handleBackloggedFeedback
{
    NSString* backupFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeBacklogFileName];
    NSMutableArray* backupFiles = [[[NSArray arrayWithContentsOfFile:backupFilePath] mutableCopy] autorelease];
    if (backupFiles.count > 0) {
        NSString* fileName = [backupFiles objectAtIndex:0];
        NSString* feedbackPath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:fileName];
        
        NSDictionary* feedback = [NSDictionary dictionaryWithContentsOfFile:feedbackPath];
        if (feedback) {
            AppBladeWebClient* client = [[[AppBladeWebClient alloc] initWithDelegate:self] autorelease];
            client.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:feedback, kAppBladeFeedbackKeyFeedback, fileName, kAppBladeFeedbackKeyBackup, nil];
            [client sendFeedbackWithScreenshot:[feedback objectForKey:kAppBladeFeedbackKeyScreenshot] note:[feedback objectForKey:kAppBladeFeedbackKeyNotes] console:[feedback objectForKey:kAppBladeFeedbackKeyConsole] params:self.appBladeParams];
            
            if (!self.feedbackRequests) {
                self.feedbackRequests = [NSMutableSet set];
            }
            
            [self.feedbackRequests addObject:client];
        }
    }
}

- (void)reportFeedback:(NSString *)feedback
{
    [self.feedbackDictionary setObject:feedback forKey:kAppBladeFeedbackKeyNotes];
    AppBladeWebClient* client = [[[AppBladeWebClient alloc] initWithDelegate:self] autorelease];
    [client sendFeedbackWithScreenshot:[self.feedbackDictionary objectForKey:kAppBladeFeedbackKeyScreenshot] note:feedback console:[self.feedbackDictionary objectForKey:kAppBladeFeedbackKeyConsole] params:self.appBladeParams];
}

- (void)checkAndCreateAppBladeCacheDirectory
{
    NSString* directory = [AppBlade cachesDirectoryPath];
    NSFileManager* manager = [NSFileManager defaultManager];
    BOOL isDirectory = YES;
    if (![manager fileExistsAtPath:directory isDirectory:&isDirectory]) {
        NSError* error = nil;
        BOOL success = [manager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error];
        if (!success) {
            NSLog(@"Error creating directory %@", error);
        }
    }
}

-(NSString *)captureScreen
{
    [self checkAndCreateAppBladeCacheDirectory];
    UIImage *currentImage = [self getContentBelowView:self.feedbackView];
    NSString* fileName = [[self randomString:36] stringByAppendingPathExtension:@"png"];
	NSString *pngFilePath = [[[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:fileName] retain];
	NSData *data1 = [NSData dataWithData:UIImagePNGRepresentation(currentImage)];
	[data1 writeToFile:pngFilePath atomically:YES];
    return [pngFilePath autorelease];
    
}

- (UIImage*)getContentBelowView:(UIView*)view
{
    UIGraphicsBeginImageContext(view.bounds.size);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
    
}

-(NSString *) randomString: (int) len {
    
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [s_letters characterAtIndex: arc4random()%[s_letters length]]];
    }
    
    return randomString;
}

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

#pragma mark - Custom Params

- (void)setCustomParams:(NSDictionary *)params
{
    self.appBladeParams = params;
}

- (void)updateCustomParam:(id)key withValue:(id)value
{
    NSMutableDictionary* mutableParams = [[self.appBladeParams mutableCopy] autorelease];
    
    if (!mutableParams) {
        mutableParams = [NSMutableDictionary dictionary];
    }
    
    if (key && value) {
         [mutableParams setObject:value forKey:key];
    }
    else if (key && !value) {
        [mutableParams removeObjectForKey:key];
    }
    else {
        NSLog(@"AppBlade - Attempted to update params with nil key and nil value");
    }
}

- (void)clearAllCustomParams
{
    self.appBladeParams = nil;
}

#pragma mark - AppBladeWebClient
-(void) appBladeWebClientFailed:(AppBladeWebClient *)client
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
                
                NSDictionary* errorDictionary = [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Please check your internet connection to gain access to this application", nil), NSLocalizedDescriptionKey, 
                                                 NSLocalizedString(@"Please check your internet connection to gain access to this application", nil),  NSLocalizedFailureReasonErrorKey, nil];
                
                NSError* error = [NSError errorWithDomain:kAppBladeErrorDomain code:kAppBladeOfflineError userInfo:errorDictionary];
                [self.delegate appBlade:self applicationApproved:NO error:error];                
            }

        }
    }
    else if (client.api == AppBladeWebClientAPI_Feedback) {
        NSLog(@"ERROR sending feedback");
        
        BOOL isBacklog = [self.feedbackRequests containsObject:client];
        if (!isBacklog) {
            NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
            NSString* newFeedbackName = [[NSString stringWithFormat:@"%0.0f", now] stringByAppendingPathExtension:@"plist"];
            NSString* feedbackPath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:newFeedbackName];
            
            [self.feedbackDictionary writeToFile:feedbackPath atomically:YES];
            
            NSString* backupFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeBacklogFileName];
            NSMutableArray* backupFiles = [[[NSArray arrayWithContentsOfFile:backupFilePath] mutableCopy] autorelease];
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
            [self.feedbackRequests removeObject:client];
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
        
        NSError* error = [NSError errorWithDomain:kAppBladeErrorDomain code:kAppBladeOfflineError userInfo:errorDictionary];

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

    
    
}

- (void)appBladeWebClientCrashReported:(AppBladeWebClient *)client
{
    // purge the crash report that was just reported. 
    PLCrashReporter *crashReporter = [PLCrashReporter sharedReporter];
    [crashReporter purgePendingCrashReport];
}

- (void)appBladeWebClientSentFeedback:(AppBladeWebClient *)client withSuccess:(BOOL)success
{
    BOOL isBacklog = [self.feedbackRequests containsObject:client];
    if (success) {
        NSDictionary* feedback = isBacklog ? [client.userInfo objectForKey:kAppBladeFeedbackKeyFeedback] : self.feedbackDictionary;
        // Clean up
        NSString* screenshotPath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:[feedback objectForKey:kAppBladeFeedbackKeyScreenshot]];
        [[NSFileManager defaultManager] removeItemAtPath:screenshotPath error:nil];
        
        NSString* consolePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:[feedback objectForKey:kAppBladeFeedbackKeyConsole]];
        [[NSFileManager defaultManager] removeItemAtPath:consolePath error:nil];
        
        if (isBacklog) {
            NSString* backupFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeBacklogFileName];
            NSMutableArray* backups = [NSMutableArray arrayWithContentsOfFile:backupFilePath];
            NSString* fileName = [client.userInfo objectForKey:kAppBladeFeedbackKeyBackup];
            NSString* filePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:fileName];
            
            NSError* error = nil;
            BOOL success = [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
            if (!success) {
                NSLog(@"Error removing AppBlade Feedback file. %@", error);
            }
            
            [backups removeObject:fileName];
            
            if (backups.count > 0) {
                [backups writeToFile:backupFilePath atomically:YES];
            }
            else {
                error = nil;
                [[NSFileManager defaultManager] removeItemAtPath:fileName error:&error];
            }
        }
        
        
        // Only continue to save feedback if we succeed
        if ([self hasPendingFeedbackReports]) {
            [self handleBackloggedFeedback];
        }
            
    }
    else if (!isBacklog) {
        
        // If we fail sending, add to backlog
        // We do not remove backlogged files unless the request is sucessful
        
        NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
        NSString* newFeedbackName = [[NSString stringWithFormat:@"%0.0f", now] stringByAppendingPathExtension:@"plist"];
        NSString* feedbackPath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:newFeedbackName];
        
        [self.feedbackDictionary writeToFile:feedbackPath atomically:YES];
        
        NSString* backupFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeBacklogFileName];
        NSMutableArray* backupFiles = [[[NSArray arrayWithContentsOfFile:backupFilePath] mutableCopy] autorelease];
        if (!backupFiles) {
            backupFiles = [NSMutableArray array];
        }
        
        [backupFiles addObject:newFeedbackName];
        
        BOOL success = [backupFiles writeToFile:backupFilePath atomically:YES];
        if(!success){
            NSLog(@"Error writing backup file to %@", backupFilePath);
        }
    }
    if (isBacklog) {
        [self.feedbackRequests removeObject:client];
    }
    else {
        self.feedbackDictionary = nil;
    }

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
    } else {
        exit(0);
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

@end
