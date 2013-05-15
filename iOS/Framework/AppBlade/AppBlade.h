//
//  AppBlade.h
//  AppBlade
//
//  Created by Craig Spitzkoff on 6/1/11.
//  Copyright 2011 AppBlade. All rights reserved.
//
//  For instructions on how to use this library, please look at the README.
//
//  Support and FAQ can be found at http://support.appblade.com
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


UIKIT_EXTERN NSString* const kAppBladeErrorDomain;
UIKIT_EXTERN int const kAppBladeOfflineError;
UIKIT_EXTERN int const kAppBladeParsingError;
UIKIT_EXTERN int const kAppBladePermissionError;
UIKIT_EXTERN NSString* const kAppBladeCacheDirectory;


@class AppBlade;

@protocol AppBladeDelegate <NSObject>

// Was the application approved to run?
-(void) appBlade:(AppBlade *)appBlade applicationApproved:(BOOL)approved error:(NSError*)error;

// Is there an update of this application available?
-(void) appBlade:(AppBlade *)appBlade updateAvailable:(BOOL)update updateMessage:(NSString*)message updateURL:(NSString*)url;

@end

@interface AppBlade : NSObject <AppBladeDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate> 

// AppBlade host name //Include neither http:// nor https://, we'll handle that.
@property (nonatomic, retain) NSString* appBladeHost;

// AppBlade API project issued secret.
@property (nonatomic, retain) NSString* appBladeProjectSecret;

// AppBlade API project issued device secret. 
@property (nonatomic, retain) NSString* appBladeDeviceSecret;


// The AppBlade delegate receives messages regarding device authentication and other events.
// See protocol declaration, above.
@property (nonatomic, assign) id<AppBladeDelegate> delegate;

// Returns SDK Version
+ (NSString*)sdkVersion;

// Log SDK Version
+ (void)logSDKVersion;


// AppBlade manager singleton.
+ (AppBlade *)sharedManager;

// Use the plist that AppBlade embeds for the iOS settings
- (void)registerWithAppBladePlist;
- (void)registerWithAppBladePlist:(NSString*)plistName;

//Device secret calls
-(NSMutableDictionary*) appBladeDeviceSecrets;
-(void)clearAppBladeKeychain;

- (NSString *) appBladeDeviceSecret;
- (void) setAppBladeDeviceSecret:(NSString *)appBladeDeviceSecret;


// Sets up variables & Checks if any crashes have ocurred, sends logs to AppBlade.
- (void)catchAndReportCrashes;

//method to call if you want to attempt to send crash reports more often than ususal 
- (void)checkForExistingCrashReports;



//Define special custom fields to be sent back to Appblade in your Feedback reports or Crash reports
-(NSDictionary *)getCustomParams;
-(void)setCustomParams:(NSDictionary *)newFieldValues;
-(void)setCustomParam:(id)newObject withValue:(NSString*)key __attribute__((deprecated("use method -(void)setCustomParam:(id)object forKey:(NSString*)keyme")));
-(void)setCustomParam:(id)object forKey:(NSString*)key;
-(void)clearAllCustomParams;


/*
 *    WARNING: The following features below are only for ad hoc and enterprise applications. Shipping an app to the iTunes App
 *    store with a call to |-checkApproval|, for example, could result in app termination or rejection.
 */

// Checks with AppBlade to see if the app is allowed to run on this device. Will also notify of updates.
- (void)checkApproval;

// Approval check with ability to disable the check/notification for updates. DEPRECATED
- (void)checkApprovalWithUpdatePrompt:(BOOL)shouldPrompt __attribute__((deprecated("use method - (void)checkForUpdates for update checks from now on")));

// Checks with AppBlade anonymously to see if the app can be updated with a new build.
- (void)checkForUpdates;


//Path to the AppBlade cache directory. Useful for direct modificaion of stored requests.
+ (NSString*)cachesDirectoryPath;
+ (void)clearCacheDirectory;

// Sets up a 3-finger double tap for reporting feedback
- (void)allowFeedbackReporting;

// In case you only want 3-finger double tap feedback in a specific window.
- (void)allowFeedbackReportingForWindow:(UIWindow*)window;

// In case you want feedback but want to handle prompting it yourself (no 3-finger double tap).
- (void)setupCustomFeedbackReporting;

- (void)setupCustomFeedbackReportingForWindow:(UIWindow*)window;

// Shows a feedback dialogue and handles screenshot
- (void)showFeedbackDialogue;
- (void)showFeedbackDialogue:(BOOL)withScreenshot;


+ (void)startSession;
+ (void)endSession;


- (void)refreshToken:(NSString *)tokenToConfirm;
- (void)confirmToken:(NSString *)tokenToConfirm;

-(BOOL)isAppStoreBuild;

@end
