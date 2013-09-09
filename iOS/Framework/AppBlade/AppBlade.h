/*!
  @header AppBlade
  @brief Class containing the AppBlade sharedManager singleton and entrypoint methods to AppBlade functions
  @discussion Support and FAQ can be found at http://support.appblade.com
  @namespace AppBlade
 */
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AppBladeSharedConstants.h"

@class AppBlade;

 #pragma mark - APPBLADE DELEGATE PROTOCOL
/*! @brief Protocol to receive messages regarding device authentication and other events. */
@protocol AppBladeDelegate <NSObject>

/*!
 @brief This method is called when the delegate is notified of whether the Application was approved to run.
 @param    appBlade    The specific appblade reference the delegate is observing.
 @param    approved    The boolean of whether the application is approved or not.
 @param    error       An optional error parameter.

 @result This method returns nothing. If \c false is passed to the approved parameter, A \c kill() will be sent to the main thread and the app will terminate.
 */
-(void) appBlade:(AppBlade *)appBlade applicationApproved:(BOOL)approved error:(NSError*)error;

@end

#pragma mark - APPBLADE
/*! @brief Our main class. AppBlade contains our singleton and all public methods, which are used as entrypoints for the lower level managers. */
@interface AppBlade : NSObject <AppBladeDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate>

#pragma mark  API KEYS

/*! @brief Our endpoint. Usually the AppBlade host name, but it can be custom */
@property (nonatomic, retain) NSString* appBladeHost;
/*! @brief AppBlade API project-issued secret. */
@property (nonatomic, retain) NSString* appBladeProjectSecret;

// Device Secret
/*! @brief Our AppBlade-issued device secret. Used in API calls. */
-(NSString*) appBladeDeviceSecret;
/*! @brief Setter method for the device secret. Used in API calls */
-(void) setAppBladeDeviceSecret:(NSString *)appBladeDeviceSecret;

/*! @brief Delegate to receive messages regarding device authentication and other events */
@property (nonatomic, assign) id<AppBladeDelegate> delegate;

#pragma mark SINGLETON
/*! @brief Our singleton reference, and the only way that AppBlade shoud be referenced. */
+ (AppBlade *)sharedManager;


#pragma mark INITIAL REGISTRATION
/*!
 @brief Initial registration method, use before enything else. 
 @discussion AppBlade registration that uses the AppBlade.plist that you embedded on setup.
 It's required that you register before anything else in AppBlade can be used.
 */
- (void)registerWithAppBladePlist;

/*!
 @brief Initial registration method, use before enything else.
 @discussion AppBlade registration that takes a custom parameter for the plist name that you embedded on setup.
 This special plist must exist in your main bundle. Note that AppBlade will not find the plist and inject it with tokens if you do this, so this call is not advised.
 */
- (void)registerWithAppBladePlistNamed:(NSString*)plistName;

#pragma mark APPBLADE AUTHENTICATION / KILLSWITCH
// Authentication & Killswitch
/*! @brief Checks with AppBlade to see if the app is allowed to run on this device. */
- (void)checkApproval;


#pragma mark AUTO UPDATING
/*! Checks with AppBlade anonymously to see if the app can be updated with a new build. */
- (void)checkForUpdates;


#pragma mark CRASH REPORTING
/*! Sets up variables & Checks if any crashes have ocurred, sends logs to AppBlade. */
- (void)catchAndReportCrashes;

/*! Method to call if you want to attempt to send crash reports more often than ususal */
- (void)checkForExistingCrashReports;

- (void)handleCrashReport;

#pragma mark FEEDBACK REPORTING
/*! Initializes the Feedback Reporting Feature */
- (void)allowFeedbackReporting;
- (void)allowFeedbackReportingForWindow:(UIWindow*)window withOptions:(AppBladeFeedbackSetupOptions)options;

/*! Shows a feedback dialogue and handles screenshot */
- (void)showFeedbackDialogue;
- (void)showFeedbackDialogueWithOptions:(AppBladeFeedbackDisplayOptions)options;

/*! Helper function to manually trigger a feedback check. */
- (void)handleBackloggedFeedback;

#pragma mark SESSION TRACKING
/*! Starts a new Session Tracking session. */
- (void)logSessionStart;
- (void)logSessionEnd;
- (NSDictionary*)currentSession;



#pragma mark CUSTOM PARAMETERS
/*! Define special custom fields to be sent back to Appblade in your Feedback reports or Crash reports */
-(void)setCustomParam:(id)object forKey:(NSString*)key;

/*! Getter function for all current stored params */
-(NSDictionary *)getCustomParams;
-(void)setCustomParams:(NSDictionary *)newCustomParams;
-(void)clearAllCustomParams;

#pragma mark OTHER SDK METHODS
// Creates a random string of a specified length
- (NSString*)randomString:(int)length;

//Keychain methods
/*! Clears ALL keychains */
- (void)clearAppBladeKeychain;
- (void)sanitizeKeychain;
- (void)cleanOutKeychain;

/*!  Returns SDK Version */
+ (NSString*)sdkVersion;
/*!  Log SDK Version to NSLog */
+ (void)logSDKVersion;
@end
