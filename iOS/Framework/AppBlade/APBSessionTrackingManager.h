/*!
 @header  APBSessionTrackingManager.h
 @abstract  Holds all session-tracking functionality
 @framework AppBlade
 @author AndrewTremblay on 7/16/13.
 @copyright AppBlade 2013. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "APBBasicFeatureManager.h"

#define APPBLADE_SESSION_TRACKING_INTERVAL 30.0 //seconds

extern NSString *sessionURLFormat;
extern NSString *kSessionStartDate;
extern NSString *kSessionEndDate;
extern NSString *kSessionTimeElapsed;


/*!
 @class APBSessionTrackingManager
 @abstract The AppBlade Update Availablilty feature
 @discussion This manager contains the checkForUpdates call and callbacks. When AppBlade determines that a new build is available for the app, this update manager will handle the installation of said new build.
 */
@interface APBSessionTrackingManager : NSObject<APBBasicFeatureManager>
@property (nonatomic, strong) id<APBWebOperationDelegate> delegate;
@property (nonatomic, retain) NSDate *sessionStartDate;
@property (nonatomic, retain) NSDate *sessionEndDate;

/*!
 @brief the AppBladeSessionTrackingBlock for tracking appblade sessions automatically
 @discussion sessionTrackingBlock is our primary tracking block and is meant for cases where the state of the app must be perpetually tracked, such as when the app enters Guided Access or Kiosk mode.
 */
@property (nonatomic, retain) NSTimer *sessionTrackingTimer;

@property (nonatomic, assign) AppBladeSessionTrackingSetupOptions trackingOptions;
#warning trackingOptions are unimplemented

/*!
 session tracking methods
 */
- (void)trackSessions;
- (void)trackSessionsWithOptions:(AppBladeSessionTrackingSetupOptions)options;
- (void)checkSessions:(NSTimer *)timer;
- (void)stopTrackingSessions;

/*!
 Starts a session.
 */
- (void)logSessionStart;

/*! 
 Stops a session.
 */
- (void)logSessionEnd;

/*!
 A dictionary containing data bout the current session.
 */
- (NSDictionary*)currentSession;

/*!
 Send the next finished session.
 */
-(void)checkForAndPostSessions;

/*!
 A useful function for checking if there is session data available to be sent
 */
- (BOOL)hasPendingSessions;
- (void)handleWebClientSentSessions:(APBWebOperation *)client withSuccess:(BOOL)success;
- (void)sessionTrackingCallbackFailed:(APBWebOperation *)client withErrorString:(NSString*)errorString;

@end


@interface APBWebOperation (SessionTracking)

-(void)postSessions:(NSArray *)sessions;

@end

//Our additional requirements
@interface AppBlade (SessionTracking)
    @property (nonatomic, strong) APBSessionTrackingManager* sessionTrackingManager;
    - (void)appBladeWebClientSentSessions:(APBWebOperation *)client withSuccess:(BOOL)success;
@end