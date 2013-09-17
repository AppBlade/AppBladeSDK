/*!
 @framework AppBlade
 @header  APBTokenManager.h
 @abstract  Holds all Token management functionality for APBTokenManager
 @author AndrewTremblay on 7/16/13.
 @copyright Raizlabs 2013. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "AppBlade.h"
#import "APBWebOperation.h"
#import "AppBladeLogging.h"

/*!
 @class APBTokenManager
 @brief Core Manager for all Token-related requests and behavior.
 
 Tokens are our basis for all authentication and identification for the SDK, and their use is slightly complicated to explain.

 Tokens are generated at registration call, and all current feature web calls require it as a header. Because of this, no other web requests can occur before a valid token is stored and confirmed.
 
 Token generation is a multi-step process:
 1. A token must be generated from AppBlade.
 2. The received token must be stored locally.
 3. The stored token must be sent back to AppBlade to be confirmed and activated.
 
 To generate a token in step one, AppBlade requires initial credentials. These credentials are either the API "Project Secret" — which exists in your AppBlade.plist file – or the value of an embedded token that is injected into the AppBlade.plist on ipa download.  This latter token, or "Device Secret", is a pre-approved token which ties identification to the registered AppBlade device, logged in AppBlade user, and uploaded AppBlade version.

 Project Secrets are used for Development and App Store releases, and Device Secrets are used for AppBlade-downloaded builds. 
 
 Whenever Device Secret is mentioned in function calls, it should be considered equivalent to the current stored and usable token.
 
 Due to their complexity, Token requests are stored and managed through their own NSOperation Queue, called tokenRequest. Whenever there is a token request pending, the main request queue (called pendingRequests in AppBlade) is considered paused. Once the token refresh process completes (i.e. a token is refreshed and confrmed) The tokenRequests queue will empty and the Featire requests will resume. 
 
 If a new token cannot be generated, the AppBlade SDK searches for a reason why in the status code. 
 If the status code is 401, the token expired, and a token refresh process is begun (equivalent to the process described above).
 If the status code is ever 403, the token is considered forbidden and depnding on the origin of the app (AppBlade or App Store) the app is either closed or the SDK inside it is disabled.
 If the status code is 500, there was an undetermined web error and the SDK retries at a later time (All pending requests remain pending).

 */
@interface APBTokenManager : NSObject
-(NSOperationQueue *) tokenRequests;
-(NSOperationQueue *) addTokenRequest:(NSOperation *)request;

/*!
 @brief Begins a refresh token call, passing the current token if possible.
 */
- (void)refreshToken:(NSString *)tokenToConfirm;

/*!
 @brief Begins a token confirmation call, passing the freshly retrieved token.
 */
- (void)confirmToken:(NSString *)tokenToConfirm;

/*!
 @brief Checks to see ith eth passed token matches the current assumed token.
 A retroactive callback to detect if an authentication failure should be respected.
 */
- (BOOL)isCurrentToken:(NSString *)token;

- (BOOL)tokenConfirmRequestPending;
- (BOOL)tokenRefreshRequestPending;

/*!
 @brief Helper method for retrieving all device secret data in the app keychain
 */
- (NSMutableDictionary*) appBladeDeviceSecrets;


/*!
 @brief Getter method for for the current device secret, or active SDK token.
 */
- (NSString *)appBladeDeviceSecret;

/*!
 @brief Setter method for for the current device secret, or active SDK token.
 */
- (void) setAppBladeDeviceSecret:(NSString *)appBladeDeviceSecret;

- (void)clearAppBladeKeychain;
- (void)clearStoredDeviceSecrets;

- (BOOL)hasDeviceSecret;

/*!
 
 */
- (BOOL)isDeviceSecretBeingConfirmed;

@property (nonatomic, retain) NSString* appBladeDeviceSecret;


@end

/*!
 @category APBWebOperation(TokenManager)
 Our Token related generatiors for APBWebOperation 
 */
@interface APBWebOperation (TokenManager)

/*!
 Prepares the APBWebOperation to become a refresh Token call
 */
- (void)refreshToken:(NSString *)tokenToConfirm;

/*!
 Prepares the APBWebOperation to become a confirm Token call
 */
- (void)confirmToken:(NSString *)tokenToConfirm;

@end


/*!
 @category AppBlade(TokenManager)
 Our TokenManager-related web callbacks for the main AppBlade class.
 We also want the tokenManager to be visible to these functions, so we create a dynamic link to the internal APBTokenManager property.
 */
@interface AppBlade (TokenManager)
@property (nonatomic, strong) APBTokenManager* tokenManager;

/*!
 Callback for a generate token call
 */
- (void)appBladeWebClient:(APBWebOperation *)client receivedGenerateTokenResponse:(NSDictionary *)response;


/*!
 Callback for a confirm token call
 */
- (void)appBladeWebClient:(APBWebOperation *)client receivedConfirmTokenResponse:(NSDictionary *)response;

@end