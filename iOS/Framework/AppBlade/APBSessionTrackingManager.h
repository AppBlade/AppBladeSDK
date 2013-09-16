/*!
 @header  APBSessionTrackingManager.h
 @abstract  Holds all session-tracking functionality
 @framework AppBlade
 @author AndrewTremblay on 7/16/13.
 @copyright Raizlabs 2013. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "APBBasicFeatureManager.h"



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

- (void)logSessionEnd;
- (void)logSessionStart;
- (NSDictionary*)currentSession;

-(void)checkForAndPostSessions
;
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