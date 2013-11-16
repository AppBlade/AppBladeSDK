/*!
 @header  APBWebOperation+PrivateMethods.h
 @abstract  Private methods for our APBWebOperation interface.
 @discussion See @link APBWebOperationDelegate @/link and @link APBWebOperation @/link for more information.
 @framework AppBlade
 @author Created by AndrewTremblay on 7/31/13.
 @copyright AppBlade 2013. All rights reserved.

 
 */

#import "APBWebOperation.h"

/*!
 @category APBWebOperation(PrivateMethods)
 @discussion contains private methods for the APBWebOperation class. 

*/
@interface APBWebOperation(PrivateMethods)

/*!
  @discussion This method is where the parrallelized NSURLConnection is initialized and sent.
 If the request was already released or the isCancelled flag was set to true 
 */
-(void)issueRequest;
-(void)scheduleTimeout;
-(void)cancelTimeout;

// Crypto methods.
- (NSString *)HMAC_SHA256_Base64:(NSString *)data with_key:(NSString *)key;
- (NSString *)SHA_Base64:(NSString *)raw;
- (NSString *)genRandStringLength:(int)len;
- (NSString *)urlEncodeValue:(NSString*)string; //no longer being used
- (NSString *)hashFile:(NSString*)filePath;
- (NSString *)hashExecutable;
- (NSString *)hashInfoPlist;

@end
