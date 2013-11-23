#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AppBladeSharedConstants.h"

/*!
 @header AppBlade
 @brief Class containing the AppBlade sharedManager singleton and entrypoint methods to AppBlade functions
 @discussion Support and FAQ can be found at http://support.appblade.com
 @unsorted
 */

@class AppBlade;

 #pragma mark - APPBLADE DELEGATE PROTOCOL
/*! 
 @protocol
 @brief Protocol to receive messages regarding device authentication and other events. */
@protocol AppBladeDelegate <NSObject>

/*!
 @method
 @brief This method is called when the delegate is notified of whether the Application was approved to run.
 @param    appBlade    The specific appblade reference the delegate is observing.
 @param    approved    The boolean of whether the application is approved or not.
 @param    error       An optional error parameter.

 @result This method returns nothing. If \c false is passed to the approved parameter, A \c kill() will be sent to the main thread and the app will terminate.
 */
-(void) appBlade:(AppBlade *)appBlade applicationApproved:(BOOL)approved error:(NSError*)error;

@end

#pragma mark - APPBLADE
/*! 
 @class
 @brief Our main class. AppBlade contains our singleton and all public methods, which are used as entrypoints for the lower level managers. */
@interface AppBlade : NSObject <AppBladeDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate>

#pragma mark  API KEYS

/*! 
 @brief Our endpoint. Usually the AppBlade host name, but it can be customized from the plist */
@property (nonatomic, retain) NSString* appBladeHost;
/*! 
 @brief AppBlade API project-issued secret. */
@property (nonatomic, retain) NSString* appBladeProjectSecret;

// Device Secret
/*!
 Our AppBlade-issued device secret. Used in API calls. */
-(NSString*) appBladeDeviceSecret;
/*!
 @property Setter method for the device secret. Used in API calls */
-(void) setAppBladeDeviceSecret:(NSString *)appBladeDeviceSecret;

/*! @brief Option value that determines when web requests occur.
 For example, if your app should run in a kiosk, have it respect a timeout.
 */
@property (nonatomic, assign) NSInteger webReportingGlobalOptions;
@property (nonatomic, assign) NSInteger webReportingTimeout;


/*! 
 @property
 Delegate to receive messages regarding device authentication and other events */
@property (nonatomic, assign) id<AppBladeDelegate> delegate;

#pragma mark SINGLETON
/*!  
 @property
 Our singleton reference, and the only way that AppBlade shoud be referenced. */
+ (AppBlade *)sharedManager;


#pragma mark INITIAL REGISTRATION
/*!
 @functiongroup Initial Registration
 */
/*!
 @method
 @abstract Initial registration method, use before enything else.
 @discussion AppBlade registration that uses the AppBlade.plist that you embedded on setup.
 It's required that you register before anything else in AppBlade can be used.
 */
- (void)registerWithAppBladePlist;

/*!
 @method
 
 @abstract Initial registration method, use before enything else.
 @discussion AppBlade registration that takes a custom parameter for the plist name that you embedded on setup.
 This special plist must exist in your main bundle. Note that AppBlade will not find the plist and inject it with tokens if you do this, so this call is not advised.
 */
- (void)registerWithAppBladePlistNamed:(NSString*)plistName;

#pragma mark APPBLADE AUTHENTICATION / KILLSWITCH
/*!
 @functiongroup Authentication & Killswitch
 */
/*!
 @method
 @abstract Checks with AppBlade to see if the app is allowed to run on this device. */
- (void)checkApproval;


#pragma mark AUTO UPDATING
/*!
 @functiongroup Auto Updating
 */


/*!
 @method
 @abstract Checks with AppBlade anonymously to see if the app can be updated with a new build. */
- (void)checkForUpdates;


#pragma mark CRASH REPORTING
/*!
 @functiongroup Crash Reporting
 */

/*!
 @method
 @abstract Sets up variables & Checks if any crashes have ocurred, sends logs to AppBlade. */
- (void)catchAndReportCrashes;

/*!
 @method
 @abstract Method to call if you want to attempt to send crash reports more often than ususal */
- (void)checkForExistingCrashReports;

/*!
 @method
 @abstract Function called when app resumes from crash. */
- (void)handleCrashReport;

#pragma mark FEEDBACK REPORTING
/*! 
 @functiongroup Feedback Reporting
 */

/*!
 @method
 @abstract Initializes the Feedback Reporting Feature
 */
- (void)allowFeedbackReporting;
/*!
 @method
 @abstract Initializes the Feedback Reporting Feature with additional options
 */
- (void)allowFeedbackReportingForWindow:(UIWindow*)window withOptions:(AppBladeFeedbackSetupOptions)options;

/*!
 @method
 @abstract Shows a feedback dialogue and handles screenshot */
- (void)showFeedbackDialogue;
/*!
 @method
 @abstract Shows a feedback dialogue and handles screenshot with additional options */
- (void)showFeedbackDialogueWithOptions:(AppBladeFeedbackDisplayOptions)options;

/*!
 @method
 @abstract Helper function to manually trigger a feedback check. */
- (void)handleBackloggedFeedback;

#pragma mark SESSION TRACKING
/*!
 @functiongroup Session Tracking
 */

/*!  
 @method
 @abstract Starts a new Session Tracking session. */
- (void)logSessionStart;
/*!  
 @method
 @abstract Ends a the current Session Tracking session, if one exists. Does nothing otherwise. */
- (void)logSessionEnd;

/*!  
 @method
 @abstract Retrieves a copy of the current session data if one exists. The object returned does nothing to affect the actual session. */
- (NSDictionary*)currentSession;


#pragma mark CUSTOM PARAMETERS
/*!
 @functiongroup Custom Parameters
 */

/*! 
 @method
 @abstract Define special custom fields to be sent back to Appblade in your Feedback reports or Crash reports */
-(void)setCustomParam:(id)object forKey:(NSString*)key;

/*!  
 @method
 @abstract Getter function for all current stored params */
-(NSDictionary *)getCustomParams;

/*! 
 @method
 @abstract Setter function for current stored params */
-(void)setCustomParams:(NSDictionary *)newCustomParams;

/*!  
 @method
 @abstract Destructive function that clears all current stored params. */
-(void)clearAllCustomParams;

#pragma mark OTHER SDK METHODS
/*!
 @functiongroup Keychain Methods
 */
/*!  
 @method
 @abstract Clears AppBlade Related keychains */
- (void)clearAppBladeKeychain;
/*!   
 @method
 @abstract  Tries to intelligently clear keychains if we need it */
- (void)sanitizeKeychain;

/*!
 @method
 @abstract  Clears ALL reachable items in the keychain. Very dangerous. */
- (void)cleanOutKeychain;

/*!
 @functiongroup Other SDK Methods
 */

/*! 
 Creates a random string of a specified length
 */
- (NSString*)randomString:(int)length;

/*! 
 @property
 @abstract   Returns SDK Version */
+ (NSString*)sdkVersion;
/*!  
 @method
 @abstract Log SDK Version to NSLog */
+ (void)logSDKVersion;
@end
