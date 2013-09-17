//
//  AppBlade+PrivateMethods.h
//  AppBlade
//
//  Created by AndrewTremblay on 7/31/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//
#import "APBWebOperation.h"
/*!
 @header AppBlade+PrivateMethods
 @brief Header containing all the methods that we don't want to be publcaly used.
 Do not rely on any of these methods, as they may disappear or change at any time. 
 */

@interface AppBlade (PrivateMethods)

/*! 
 @methodgroup Appblade Private Methods
 
 @discussion  Methods that probably shouldn't be used by the average developer. These are documented here for the sake of completeness.
 */

/*!
 @brief Internal method to confirm proper SDK setup before continuing.
 @discussion Checks for keychain access and the appbladekeys.plist. If neither are found then the SDK is disabled with an error message of what was missing.
*/
- (void)validateProjectConfiguration;

/*!
 @brief Disables the SDK with a message.
 @discussion Used when setting up the SDK.
 */
- (void)raiseConfigurationExceptionWithMessage:(NSString *)name;

/*!
 @brief Halts the request queue, pausing all APBWebOperations
 
 @discussion This will not pause any operations currently running, their webcalls will still send and likely be caught by AppBlade. 

  */
- (void) pauseCurrentPendingRequests;

/*!
  @brief Cancels all APBWebOperations in the pendingRequests queue
 @discussion This will not cancel any operations currently running, so a slight race condition exists.
 See the isCancelled flag to ensure the cancellation behavior is handled properly for each feature's web request.
 
 */
- (void) cancelAllPendingRequests;


/*!
 @brief Selectively cancels all APBWebOperations in the pendingRequests queue that contain the sent token as the device-secret header

 @param token The token to try to cancel
 
 @discussion
 This check was added to help with the token authentication cycle, which can be better explained on the APBTokenManager page.
  
 This will not cancel any operations currently running, so a slight race condition exists.
 See the isCancelled flag to ensure the cancellation behavior is handled properly for each feature's web request.
 
 @seealso //apple_ref/doc/anysymbol/APBTokenManager APBTokenManager

 */
- (void) cancelPendingRequestsByToken:(NSString *)token;

-(NSMutableDictionary*) appBladeDeviceSecrets;
- (BOOL)hasDeviceSecret;
- (BOOL)isDeviceSecretBeingConfirmed;
- (BOOL)isCurrentToken:(NSString *)token;


- (NSObject*)readFile:(NSString *)filePath;
- (NSString*)hashFileOfPlist:(NSString *)filePath;
- (void)registerWithAppBladeDictionary:(NSDictionary*)appbladeVariables atPlistPath:(NSString*)plistPath;

/*!
 @brief Path to the AppBlade cache directory.
 @discussion Path to the AppBlade cache directory. Useful for direct modificaion of stored requests.
 @return Path to the AppBlade cache directory.
 */
+ (NSString*)cachesDirectoryPath;

/*!
 @brief Clears the contents of the AppBlade cache directory.
 @discussion Occurrs when the SDK is disabled. (see -(void)setDisabled:(BOOL)isDisabled;) 
*/
- (void)clearCacheDirectory;



/*!
 @brief Creates the AppBlade cache directory, if it does not exist.
 */
- (void)checkAndCreateAppBladeCacheDirectory;

- (void) resumeCurrentPendingRequests;


-(void)setDisabled:(BOOL)isDisabled;
-(BOOL)isAllDisabled;


/*!
 @methodgroup APBWebOperationDelegate Protocol Methods
 */

/*!
 @brief A simple method that constructs a web operation with the delegate preset.
 @discussion This is mostly included to save on space, but also to make sure the person implementing this protocol knows what a APBWebOperation is and does.
 @return an APBWebOperation with the delegate set to the APBWebOperationDelegate
 */
- (APBWebOperation *)generateWebOperation;

/*!
 @brief Adds an APBWebOperation to the pending request queue.
 @discussion Adds an APBWebOperation to the pending request queue, depending on the size of the queue and current queued objects.
 @param webOperation the APBWebOperation to add to the NSOpereationQueue that the APBWebOperationDelegate contains
 */
- (void)addPendingRequest:(APBWebOperation *)webOperation;

/*!
 @brief Returns the number of APBWebOperations with the specified AppBladeWebClientAPI value.
 @discussion Returns the number of APBWebOperations with the specified AppBladeWebClientAPI value.
 
 For example:
 <ul>
 <li>AppBladeWebClientAPI_Feedback returns current number of pending/sending Feedback Report web requests.</li>
 <li> AppBladeWebClientAPI_AllTypes returns current number of all pending/sending web requests. Essentially the size of the queue.</li>
 </ul>
 
 Note that in the AppBlade singleton this returns the calls in the queue regardless of state. APBWebOperations only leave the queue once they finish their webcall and execute any completion blocks they have. The number represented in this return value is therefore inclusive to both the running, yet-to-run, and finishing Web Operations. More logic would be required to distinguish calls with more granularity, though that is currently not necessarry anywhere.
 
 @param clientType : the API call to find.
 @return the number of current APBWebOperation of that type
 */
- (NSInteger)pendingRequestsOfType:(AppBladeWebClientAPI)clientType;

@end