/*
 *  AppBlade.h
 *  AppBlade iOS SDK v0.5.0
 *
 *  Created by Craig Spitzkoff on 6/1/11.
 *  Documented by Andrew Tremblay
 *  Copyright 2011 AppBlade. All rights reserved.
 *
 *  For instructions on how to use this library, please look at the README.
 *
 *  Support and FAQ can be found at http://support.appblade.com
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "AppBladeSharedConstants.h"

@class AppBlade;

 #pragma mark - APPBLADE DELEGATE PROTOCOL
/** Protocol to receive messages regarding device authentication and other events. */
@protocol AppBladeDelegate <NSObject>

/**
 This method is called when the delegate is notified of whether the Application was approved to run.
 @param    appBlade    The specific appblade reference the delegate is observing.
 @param    approved    The boolean of whether the application is approved or not.
 @param    error       An optional error parameter.

 @result This method returns nothing. If \c false is passed to the approved parameter, A \c kill() will be sent to the main thread and the app will terminate.
 */
-(void) appBlade:(AppBlade *)appBlade applicationApproved:(BOOL)approved error:(NSError*)error;

@end

#pragma mark - APPBLADE
/** Our main class. It contains our singleton and all public methods, which are used as entrypoints for the lower level managers. */
@interface AppBlade : NSObject <AppBladeDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate>

#pragma mark  API KEYS

@property (nonatomic, retain) NSString* appBladeHost; /*!< Our endpoint. Usually the AppBlade host name, but it can be custom */
@property (nonatomic, retain) NSString* appBladeProjectSecret;/*!< AppBlade API project-issued secret. */

// Device Secret
-(NSString*) appBladeDeviceSecret; /*!<  Our AppBlade-issued device secret. Used in API calls. */
-(void) setAppBladeDeviceSecret:(NSString *)appBladeDeviceSecret; /*!< Setter method for the device secret. Used in API calls */

/** Delegate to receive messages regarding device authentication and other events */
@property (nonatomic, assign) id<AppBladeDelegate> delegate;

#pragma mark SINGLETON
/** Our singleton reference, and the only way that AppBlade shoud be referenced. */
+ (AppBlade *)sharedManager;


#pragma mark INITIAL REGISTRATION
/**
 Initial registration method that uses the AppBlade.plist that you embedded on setup
 required before anything else in AppBlade can be used.
 */
- (void)registerWithAppBladePlist;

/**
 Initial registration method that takes a custom parameter for the plist name that you embedded on setup
 This special plist must exist in your main bundle.
 */
- (void)registerWithAppBladePlistNamed:(NSString*)plistName;

/** @defgroup Features */
#pragma mark APPBLADE AUTHENTICATION / KILLSWITCH
/** @defgroup authentication Authentication & Killswitch
    @ingroup Features
    @{
 */
/** Checks with AppBlade to see if the app is allowed to run on this device. */
- (void)checkApproval;
/** @} */


#pragma mark AUTO UPDATING
/** @defgroup autoupdating Auto Updating
 @ingroup Features
 @{
 */
/** Checks with AppBlade anonymously to see if the app can be updated with a new build. */
- (void)checkForUpdates;
/** @} */


#pragma mark CRASH REPORTING
/** @defgroup crash Crash Reporting
 @ingroup Features
 @{
 */
/** Sets up variables & Checks if any crashes have ocurred, sends logs to AppBlade. */
- (void)catchAndReportCrashes;

/** Method to call if you want to attempt to send crash reports more often than ususal */
- (void)checkForExistingCrashReports;

- (void)handleCrashReport;
/** @} */


#pragma mark FEEDBACK REPORTING
/** @defgroup feedback Feedback Reporting
 @ingroup Features
 @{
 */
- (void)allowFeedbackReporting;
- (void)allowFeedbackReportingForWindow:(UIWindow*)window withOptions:(AppBladeFeedbackSetupOptions)options;

/** Shows a feedback dialogue and handles screenshot */
- (void)showFeedbackDialogue;
- (void)showFeedbackDialogueWithOptions:(AppBladeFeedbackDisplayOptions)options;

/** Helper function to manually trigger a feedback check. */
- (void)handleBackloggedFeedback;
/** @} */



#pragma mark SESSION TRACKING
/** @defgroup sessionTracking Session Tracking
 @ingroup Features
 @{
 */
- (void)logSessionStart;
- (void)logSessionEnd;
- (NSDictionary*)currentSession;
/** @} */



#pragma mark CUSTOM PARAMETERS
/** @defgroup customparams Custom Parameters
 @ingroup Features
 @{
 */
/** Define special custom fields to be sent back to Appblade in your Feedback reports or Crash reports */
-(void)setCustomParam:(id)object forKey:(NSString*)key;

/** Getter function for all current stored params */
-(NSDictionary *)getCustomParams;
-(void)setCustomParams:(NSDictionary *)newCustomParams;
-(void)clearAllCustomParams;
/** @} */


#pragma mark OTHER SDK METHODS
/** @defgroup mainhelpers Helper Methods
 @ingroup Features
 @{
 */
//Creates a random string of a specified length
- (NSString*)randomString:(int)length;

//Keychain methods
- (void)clearAppBladeKeychain;
- (void)sanitizeKeychain;
- (void)cleanOutKeychain;

/**  Returns SDK Version */
+ (NSString*)sdkVersion;
/**  Log SDK Version to NSLog */
+ (void)logSDKVersion;

/** @} */
@end
