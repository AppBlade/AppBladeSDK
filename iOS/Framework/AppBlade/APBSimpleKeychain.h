/*!
@header  APBSimpleKeychain.h
  AppBlade

  Created by jkaufman on 3/23/11.
  Copyright 2011 AppBlade. All rights reserved.

  Simple wrapper for saving NSCoding-compliant objects to Keychain.

  Original solution by StackOverflow user Anomie: http://stackoverflow.com/q/5251820
*/
#import <Foundation/Foundation.h>



/*!
 @class APBSimpleKeychain
 @abstract Our keychain manipulation class.
 @discussion Simple wrapper for saving NSCoding-compliant objects to Keychain.
 Original solution by StackOverflow user Anomie: http://stackoverflow.com/q/5251820

 */
@interface APBSimpleKeychain : NSObject
/*!
 @abstract Returns true when the app has acceptable keychain access.
 @discussion Checks basic keychain permissions of reading and writing and deleting. Our internal requirements may change accross devices,  processors, app signage, and function inclusion.
 @return true If accessible keychain access was met.
 */
+ (BOOL)hasKeychainAccess;

/*!
 @abstract Removes the entry for the given service from keychain.
 @discussion Accepts service name and NSCoding-complaint data object. Automatically overwrites if something exists.
 @return Returns true if no errors occcurred on deletion
 */
+ (BOOL)delete:(NSString *)service;

/*!
 @abstract Accepts service name and NSCoding-complaint data object and storeds it to the local keychain.
 @discussion Accepts service name and NSCoding-complaint data object. Automatically overwrites if something exists.
 @return Returns true if no errors occcurred on save
 */
+ (BOOL)save:(NSString *)service data:(id)data;

/*!
 @abstract Loads the stored keychain data from the entered service
 @discussion Casting the object is left to the developer, only NSCoding-complaint data objects are accepted to be stored, so a simple cast to <pre>NSString</pre> or <pre>NSDictionary</pre> should be all that's required.
 @return An object inflated from the data stored in the keychain entry for the given service.
 */
+ (id)load:(NSString *)service;

/*!
 @abstract Provides a human-readable error message from the OSErrorCode
 @discussion This error message is provided in the MAC SDK, but not iOS. The reason for that is unknown.
 @param errorCode The error code you wish to translate into english. 
 @return A human readable error string
 */
+(NSString*) errorMessageFromCode:(OSStatus)errorCode;

/*!
 @abstract Deletes every deletable thing we have in the app via a clever for loop.
 @discussion This is obviously a very dangerous function which should never be used in production. It's useful for development and testing devices that retrieve differently signed builds. Use it as you would a stick of dynamite; clear out a construction site with it, don't use it to tidy up the living room. 
 @return Ω
*/
+ (void)deleteLocalKeychain;


/*!
 @abstract Checks for any obvious inconsitencies in the keychain
 @discussion This function checks basic functions of the keychain, e.g. whether a written value can be immediately retrieved, if it can be deleted, etcetera. It does not detect keychin permissions directly. That is for +(BOOL)hasKeychainAccess to do.
 This by no means is guaranteed to catch all keychain problems, but it's our function and it seems to catch the ones we need to catch.
 
 @return true if our internal checks detect something terribly wrong with the keychain
 */
+ (BOOL)keychainInconsistencyExists;

/*!
 @abstract Attempts to conditionally wipe the entire keychain. 
 @discussion It's essentially deleteLocalKeychain if keychainInconsistencyExists. Even with the catch in place, this function is also not reccommended for production.
 */
+ (void)sanitizeKeychain; 

@end