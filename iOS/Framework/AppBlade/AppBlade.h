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
/*! Our AppBlade-issued device secret. Used in API calls. */
-(NSString*) appBladeDeviceSecret;
/*! Setter method for the device secret. Used in API calls */
-(void) setAppBladeDeviceSecret:(NSString *)appBladeDeviceSecret;

/*! Delegate to receive messages regarding device authentication and other events */
@property (nonatomic, assign) id<AppBladeDelegate> delegate;

#pragma mark SINGLETON
/*!  Our singleton reference, and the only way that AppBlade shoud be referenced. */
+ (AppBlade *)sharedManager;


#pragma mark INITIAL REGISTRATION
/*!
 @functiongroup INITIAL REGISTRATION
 */
/*!
 @abstract Initial registration method, use before enything else. 
 @discussion AppBlade registration that uses the AppBlade.plist that you embedded on setup.
 It's required that you register before anything else in AppBlade can be used.
 */
- (void)registerWithAppBladePlist;

/*!
 @abstract Initial registration method, use before enything else.
 @discussion AppBlade registration that takes a custom parameter for the plist name that you embedded on setup.
 This special plist must exist in your main bundle. Note that AppBlade will not find the plist and inject it with tokens if you do this, so this call is not advised.
 */
- (void)registerWithAppBladePlistNamed:(NSString*)plistName;

#pragma mark APPBLADE AUTHENTICATION / KILLSWITCH
/*!
 @functiongroup Authentication & Killswitch
 */
/*! @function checkApproval 
 Checks with AppBlade to see if the app is allowed to run on this device. */
- (void)checkApproval;


#pragma mark AUTO UPDATING
/*!
 @functiongroup AUTO UPDATING
 */


/*! @function checkForUpdates
 Checks with AppBlade anonymously to see if the app can be updated with a new build. */
- (void)checkForUpdates;


#pragma mark CRASH REPORTING
/*!
 @functiongroup CRASH REPORTING
 */

/*! @function catchAndReportCrashes
 Sets up variables & Checks if any crashes have ocurred, sends logs to AppBlade. */
- (void)catchAndReportCrashes;

/*!  @function checkForExistingCrashReports 
 Method to call if you want to attempt to send crash reports more often than ususal */
- (void)checkForExistingCrashReports;

/*!  @function handleCrashReport
 Function called when app resumes from crash. */
- (void)handleCrashReport;

#pragma mark FEEDBACK REPORTING
/*! 
 @functiongroup FEEDBACK REPORTING
 */

/*!  @function allowFeedbackReporting
 Initializes the Feedback Reporting Feature
 */
- (void)allowFeedbackReporting;
/*!  @function allowFeedbackReportingForWindow:(UIWindow*)window withOptions:(AppBladeFeedbackSetupOptions)options
 Initializes the Feedback Reporting Feature with additional options
 */
- (void)allowFeedbackReportingForWindow:(UIWindow*)window withOptions:(AppBladeFeedbackSetupOptions)options;

/*! @function showFeedbackDialogue
 Shows a feedback dialogue and handles screenshot */
- (void)showFeedbackDialogue;
/*! @function showFeedbackDialogueWithOptions:(AppBladeFeedbackDisplayOptions)options
 Shows a feedback dialogue and handles screenshot with additional options */
- (void)showFeedbackDialogueWithOptions:(AppBladeFeedbackDisplayOptions)options;

/*! @function handleBackloggedFeedback
 Helper function to manually trigger a feedback check. */
- (void)handleBackloggedFeedback;

#pragma mark SESSION TRACKING
/*!
 @functiongroup SESSION TRACKING
 */

/*! @function logSessionStart
 Starts a new Session Tracking session. */
- (void)logSessionStart;
/*! @function logSessionEnd
 Ends a the current Session Tracking session, if one exists. Does nothing otherwise. */
- (void)logSessionEnd;

/*! @function currentSession
 Retrieves a copy of the current session data if one exists. The object returned does nothing to affect the actual session. */
- (NSDictionary*)currentSession;


#pragma mark CUSTOM PARAMETERS
/*!
 @functiongroup CUSTOM PARAMETERS
 */

/*! @function setCustomParam:(id)object forKey:(NSString*)key
 Define special custom fields to be sent back to Appblade in your Feedback reports or Crash reports */
-(void)setCustomParam:(id)object forKey:(NSString*)key;

/*! @function getCustomParams
 Getter function for all current stored params */
-(NSDictionary *)getCustomParams;

/*! @function setCustomParams:(NSDictionary *)newCustomParams
 Setter function for current stored params */
-(void)setCustomParams:(NSDictionary *)newCustomParams;

/*! @function clearAllCustomParams
 Destructive function that clears all current stored params. */
-(void)clearAllCustomParams;

#pragma mark OTHER SDK METHODS
/*!
 @functiongroup OTHER SDK METHODS
 */

/*! @function randomString:(int)length
 Creates a random string of a specified length
 */
- (NSString*)randomString:(int)length;

//Keychain methods
/*!  @function clearAppBladeKeychain
 Clears AppBlade Related keychains */
- (void)clearAppBladeKeychain;
/*!  @function sanitizeKeychain
 Trie to intelligently clear keychains if we need it */
- (void)sanitizeKeychain;

/*!  @function cleanOutKeychain
 Clears ALL reachable items in the keychain. Very dangerous. */
- (void)cleanOutKeychain;

/*! @function sdkVersion
 Returns SDK Version */
+ (NSString*)sdkVersion;
/*! @function logSDKVersion
 Log SDK Version to NSLog */
+ (void)logSDKVersion;
@end
