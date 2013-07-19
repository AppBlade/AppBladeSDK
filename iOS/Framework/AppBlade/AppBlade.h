//
//  AppBlade.h
//  AppBlade iOS SDK v0.5.0
//
//  Created by Craig Spitzkoff on 6/1/11.
//  Copyright 2011 AppBlade. All rights reserved.
//
//  For instructions on how to use this library, please look at the README.
//
//  Support and FAQ can be found at http://support.appblade.com

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "AppBladeSharedConstants.h"
//Features
#import "AppBladeAuthenticationManager.h"
#import "AppBladeUpdatesManager.h"
#import "SessionTrackingManager.h"
#import "CrashReportingManager.h"
#import "FeedbackReportingManager.h"
#import "AppBladeLogging.h"

@class AppBlade;

/******************************
 APPBLADE DELEGATE PROTOCOL
 ******************************/
@protocol AppBladeDelegate <NSObject>

// Was the application approved to run?
-(void) appBlade:(AppBlade *)appBlade applicationApproved:(BOOL)approved error:(NSError*)error;

// Is there an update of this application available?
-(void) appBlade:(AppBlade *)appBlade updateAvailable:(BOOL)update updateMessage:(NSString*)message updateURL:(NSString*)url;

@end

@interface AppBlade : NSObject <AppBladeDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate> 
/******************************
 API KEYS
 ******************************/
// AppBlade host name, or custom endpoint.
@property (nonatomic, retain) NSString* appBladeHost;
// AppBlade API project-issued secret.
@property (nonatomic, retain) NSString* appBladeProjectSecret;
// AppBlade API project-issued device secret.
@property (nonatomic, retain) NSString* appBladeDeviceSecret;
-(void)setAppBladeDeviceSecret:(NSString *)appBladeDeviceSecret;

// The AppBlade delegate receives messages regarding device authentication and other events.
// See protocol declaration, above.
@property (nonatomic, assign) id<AppBladeDelegate> delegate;
/******************************
 SINGLETON
 ******************************/
+ (AppBlade *)sharedManager;

/******************************
 INITIAL API REGISTRATION CALLS
 ******************************/
// Uses the AppBlade plist that you embedded
- (void)registerWithAppBladePlist;
- (void)registerWithAppBladePlistNamed:(NSString*)plistName;

- (void)refreshToken:(NSString *)tokenToConfirm;
- (void)confirmToken:(NSString *)tokenToConfirm;

/******************************
 APPBLADE AUTHENTICATION / KILLSWITCH
 ******************************/
// Checks with AppBlade to see if the app is allowed to run on this device.
- (void)checkApproval;

/******************************
 AUTO UPDATING
 ******************************/
// Checks with AppBlade anonymously to see if the app can be updated with a new build.
- (void)checkForUpdates;

/******************************
 CRASH REPORTING
 ******************************/
// Sets up variables & Checks if any crashes have ocurred, sends logs to AppBlade.
- (void)catchAndReportCrashes;

//method to call if you want to attempt to send crash reports more often than ususal
- (void)checkForExistingCrashReports;

- (void)handleCrashReport;


/******************************
 FEEDBACK REPORTING
 ******************************/
- (void)allowFeedbackReporting;
- (void)allowFeedbackReportingForWindow:(UIWindow*)window withOptions:(AppBladeFeedbackSetupOptions)options;

// Shows a feedback dialogue and handles screenshot
- (void)showFeedbackDialogue;
- (void)showFeedbackDialogueWithOptions:(AppBladeFeedbackDisplayOptions)options;

//other feedback methods and functions
- (void)handleBackloggedFeedback;



/******************************
 SESSION TRACKING
 ******************************/
+ (void)startSession;
+ (void)endSession;


/******************************
 CUSTOM PARAMETERS
 ******************************/
//Define special custom fields to be sent back to Appblade in your Feedback reports or Crash reports
-(void)setCustomParam:(id)object forKey:(NSString*)key;

//Other params
-(NSDictionary *)getCustomParams;
-(void)setCustomParams:(NSDictionary *)newCustomParams;
-(void)clearAllCustomParams;


/******************************
 OTHER SDK METHODS
 ******************************/

//Checks the app binary for Apple's Signature, if true, then this build was signed by apple.
-(BOOL)isAppStoreBuild;

// Returns SDK Version
+ (NSString*)sdkVersion;
// Log SDK Version
+ (void)logSDKVersion;

//Path to the AppBlade cache directory. Useful for direct modificaion of stored requests.
+ (NSString*)cachesDirectoryPath;
+ (void)clearCacheDirectory;

//Keychain 
-(void)clearAppBladeKeychain;


@end
