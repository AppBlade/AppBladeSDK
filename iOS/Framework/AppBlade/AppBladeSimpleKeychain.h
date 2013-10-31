//
//  SimpleKeychain.h
//  AppBlade
//
//  Created by jkaufman on 3/23/11.
//  Copyright 2011 Raizlabs. All rights reserved.
//
//  Simple wrapper for saving NSCoding-compliant objects to Keychain.
//
//  Original solution by StackOverflow user Anomie: http://stackoverflow.com/q/5251820

#import <Foundation/Foundation.h>

@class SimpleKeychainUserPass;

@interface AppBladeSimpleKeychain : NSObject
+ (BOOL)hasKeychainAccess;

+ (BOOL)delete:(NSString *)service;
+ (BOOL)save:(NSString *)service data:(id)data;
+ (id)load:(NSString *)service;

+(NSString*) errorMessageFromCode:(OSStatus)errorCode;

+ (void)deleteLocalKeychain; //Deletes every deletable thing we have in the app.
+ (BOOL)keychainInconsistencyExists; //our current check for keychain inconsistency

+ (void)sanitizeKeychain; //a helper function for that's essentially deleteLocalKeychain if keychainInconsistencyExists

@end