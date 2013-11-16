/*!
 @header  APBWebOperation.h
 @abstract  Core header class containing the APBWebOperation interface, APBWebOperationDelegate protocol.
 @discussion See @link APBWebOperationDelegate @/link and @link APBWebOperation @/link for more information.
 @framework AppBlade
 @author Created by Craig Spitzkoff on 6/18/11. Maintained AndrewTremblay on 7/16/13.
 @copyright AppBlade 2013. All rights reserved.
 
 @seealso //apple_ref/occ/cl/APBWebOperation(PrivateMethods) APBWebOperation (PrivateMethods)
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@class APBWebOperation;

/*!
 @methodgroup Web Methods
 */

/*!
 AppBladeRequestPrepareBlock is our setup block, and is called immediately before web request is sent. This is usually where you want the most up to date data to be added to the request, like security credentials.
 */
typedef void (^AppBladeRequestPrepareBlock)(id preparationData);

/*!
 AppBladeRequestCompletionBlock is our main workhorse, though sometimes most of the logic is actually in manager handle* calls.
*/
typedef void (^AppBladeRequestCompletionBlock)(NSMutableURLRequest *request, id rawSentData, NSDictionary* responseHeaders, NSMutableData* receivedData, NSError *webError);

/*!
 AppBladeRequestSuccessBlock is our block for when the webcall was succesful. It usually involves cleaning up data that was just sent.
 */
typedef void (^AppBladeRequestSuccessBlock)(id data, NSError* error); //we can return an error and still be successful

/*!
 AppBladeRequestFailureBlock is our block for when the webcall failed. It usually involves storing our data that failed to send.
 */
typedef void (^AppBladeRequestFailureBlock)(id data, NSError* error);


/*!
 AppBladeWebClientAPI is our enumerator for quickly identifying what requests are pending. Every webcall that our features use should have a value in this enum. 
 */
typedef enum {
    AppBladeWebClientAPI_GenerateToken,
    AppBladeWebClientAPI_ConfirmToken,
	AppBladeWebClientAPI_Permissions,
    AppBladeWebClientAPI_ReportCrash,
    AppBladeWebClientAPI_Feedback,
    AppBladeWebClientAPI_Sessions,
    AppBladeWebClientAPI_UpdateCheck,
    AppBladeWebClientAPI_AllTypes
} AppBladeWebClientAPI;


/*!
 defaultURLScheme default web scheme. (https)
 */
extern NSString *defaultURLScheme;

/*!
 defaultAppBladeHostURL default endpoint url. (appblade.com)
 */
extern NSString *defaultAppBladeHostURL;

/*!
 The headerfield name for the header that contains our devices secret, which is our primary authentication method. ("X-device-secret")
 */
extern NSString *deviceSecretHeaderField;

/*!
 @methodgroup Web Delegate Methods
 */


/*!
 @protocol APBWebOperationDelegate
 The protocol that either the singleton or a feature manager could use to handle webcallbacks.  
*/
@protocol APBWebOperationDelegate <NSObject>

@required
- (NSString *)appBladeHost;
- (NSString *)appBladeProjectSecret;
- (NSString *)appBladeDeviceSecret;

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

/*!
 @brief Iterates through the pendingrequests to find the webOperation.
 @discussion Iterates through the pendingrequests to find the webOperation.
 (Though really it's just a wrapper for an NSOperationQueue containsObject call)
 @param webOperation : the APBWebOperation to find
 @return TRUE if the webOperation existed in the queue at the time of calling, false otherwise
 */
- (BOOL)containsOperationInPendingRequests:(APBWebOperation *)webOperation;



/*!
 Essentially - (void)appBladeWebClientFailed:(APBWebOperation *)client withErrorString:nil;
 */
- (void)appBladeWebClientFailed:(APBWebOperation *)client;

/*!
 Internal function call that allows us to centralize failure behavior outside of the failure blocks.
 */
- (void)appBladeWebClientFailed:(APBWebOperation *)client withErrorString:(NSString*)errorString;


@end


/*!
 @class APBWebOperation
 @discussion The main class for all web operations. Each APBWebOperation object is to be considered a single webrequest (single GET/POST/PUT) that pends in a queue if too many requests were called in front of it.
 For more complicated web activities (like a conditional second web request on a failure), web operations can be queued or called from inside feature manager web-handling methods.
 Completion, success, and failure blocks should be used whenever possible.
 */
@interface APBWebOperation : NSOperation 



/*!
 @discussion all APBWebOperation should have a delegate for ownership and authority behavior. The delegate will be weakly referenced so that the
 */
- (id)initWithDelegate:(id<APBWebOperationDelegate>)delegate;
@property (nonatomic, weak) id<APBWebOperationDelegate> delegate;



/*!
 @methodgroup Web Request Info Methods
 */


/*!
 The api identifier for the webcall. Used in - (NSInteger)pendingRequestsOfType:(AppBladeWebClientAPI)clientType;
 */
@property (nonatomic, readwrite) AppBladeWebClientAPI api;

@property (nonatomic, strong) NSDictionary* userInfo;
@property (nonatomic, strong) NSMutableURLRequest* request;
@property (nonatomic, strong) NSDictionary* responseHeaders;
@property (nonatomic, strong) NSMutableData* receivedData;
@property (nonatomic, strong) NSString* sentDeviceSecret;

/*!
 @brief the AppBladeRequestPrepareBlock for this specific web operation
 @discussion AppBladeRequestPrepareBlock is our setup block, and is called immediately before web request is sent. This is usually where you want the most up to date data to be added to the request, like security credentials.
 */
@property (nonatomic, copy) AppBladeRequestPrepareBlock prepareBlock;

/*!
 @brief the AppBladeRequestCompletionBlock for this specific web operation
 @discussion AppBladeRequestCompletionBlock is our main workhorse, though sometimes most of the logic is actually in manager handle* calls.
 */
@property (nonatomic, copy) AppBladeRequestCompletionBlock requestCompletionBlock;

/*!
 @brief the AppBladeRequestSuccessBlock for this specific web operation
 @discussion AppBladeRequestSuccessBlock is our block for when the webcall was succesful. It usually involves cleaning up data that was just sent.
 This is an optional block, but helpful for keeping logic and behavior all in one place (you can declare what the operation does on success when you create the Web Operation).
 */
@property (nonatomic, copy) AppBladeRequestSuccessBlock successBlock;

/*!
 @brief the AppBladeRequestFailureBlock for this specific web operation
 @discussion AppBladeRequestFailureBlock is our block for when the webcall failed. It usually involves storing our data that failed to send.
 This is an optional block, but helpful for keeping logic and behavior all in one place (you can declare what the operation does on failure when you create the Web Operation).
 */
@property (nonatomic, copy) AppBladeRequestFailureBlock failBlock;

/*!
 @return The status code of the web operation, if the statusCode header exists. 500 if the statusCode header cannot be found.  
 @discussion If this method is called before the header completes, a 500 will be returned. This method should only be relied upon after the web operation finishes.
 */
-(int)getReceivedStatusCode;

/*!
 @methodgroup Web Request Builder Methods
 */

/*!
 @brief Standard generator for appending the host to the api endpoint.
 Every web operation will have some endpoint that they will need to GET/POST/PUT/DELETE to. This method generatess the full path to that endpoint. 
 */
+ (NSString *)buildHostURL:(NSString *)customURLString;
- (NSMutableURLRequest *)requestForURL:(NSURL *)url;

/*!
 Helper method to generate a string has of given data.
 Used for checksums to ensure files were completely transferred
 @param objData object to encode.
 @return NSString encoded string of the object
 */
- (NSString *)encodeBase64WithData:(NSData *)objData;

/*!
 Helper method to generate a numeric string (numbers 1-9, no zeros) of a certain length.
 @param len Length of string.
 @return NSString object of "random" "numbers" 
 */
- (NSString *)genRandNumberLength:(int)len;

/*!
 Adds Appblade authorization headers to a request. Should be used in the prepare block for the most immediate credentials.
 */
- (void)addSecurityToRequest:(NSMutableURLRequest *)request;

@end



