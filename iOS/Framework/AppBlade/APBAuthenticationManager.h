/*!
  @header  AppBladeAuthentication.h
  @abstract  Holds all authentication-checking and killswitch-related functionality
  @framework AppBlade
  @author AndrewTremblay on 7/16/13.
  @copyright AppBlade 2013. All rights reserved.
*/

#import <Foundation/Foundation.h>

#import "APBBasicFeatureManager.h"

extern NSString *kTtlDictTimeoutKey;
extern NSString *kTtlDictDateSetKey;

/*!
 @class APBAuthenticationManager
 @abstract The AppBlade Authentication & Killswitch feature
 @discussion This manager contains the checkApproval call and time to live window functionality (ttl, for short).
 */
@interface APBAuthenticationManager : NSObject<APBBasicFeatureManager>
@property (nonatomic, strong) id<APBWebOperationDelegate> delegate;

- (void)checkApproval;
- (void)handleWebClient:(APBWebOperation *)client receivedPermissions:(NSDictionary *)permissions;
- (void)permissionCallbackFailed:(APBWebOperation *)client withErrorString:(NSString*)errorString;

#pragma mark TTL (Time To Live) Methods
- (void)closeTTLWindow;



/*!
 @abstract Updates our "time-to-live" for authentication
 @param ttl number of seconds you'd like the app to wai before checking for a refresh again
 */
- (void)updateTTL:(NSNumber*)ttl;
- (NSDictionary *)currentTTL;
- (BOOL)withinStoredTTL;


@end



/*! 
  @abstract Our additional properties and methods for Authentication
 */
@interface AppBlade (Authorization)
@property (nonatomic, strong) APBAuthenticationManager* authenticationManager; //declared here too so the compiler doesn't cry

- (void)appBladeWebClient:(APBWebOperation *)client receivedPermissions:(NSDictionary *)permissions;
- (void)appBladeWebClient:(APBWebOperation *)client failedPermissions:(NSString *)errorString;
@end


@interface APBWebOperation (Authorization)
- (void)checkPermissions;

@end
