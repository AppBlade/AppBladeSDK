//
//  SimpleKeychain.m
//  AppBlade
//
//  Created by jkaufman on 3/23/11.
//  Copyright 2011 Raizlabs. All rights reserved.
//
#import "AppBladeSimpleKeychain.h"

@implementation AppBladeSimpleKeychain

// Returns the keychain request dictionary for a SimpleKeychain entry.
+ (NSMutableDictionary *)getKeychainQuery:(NSString *)service
{
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:
            (id)CFBridgingRelease(kSecClassGenericPassword), (id)CFBridgingRelease(kSecClass),
            service, (id)CFBridgingRelease(kSecAttrService),
            service, (id)CFBridgingRelease(kSecAttrAccount),
//          (id)kSecAttrAccessibleAfterFirstUnlock, (id)kSecAttrAccessible, // Keychain must be unlocked to access this value. // This is only available on iOS 4 and above.
            nil];
}

// Accepts service name and NSCoding-complaint data object.
+ (void)save:(NSString *)service data:(id)data
{
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:service];
    SecItemDelete((CFDictionaryRef)CFBridgingRetain(keychainQuery));
    [keychainQuery setObject:[NSKeyedArchiver archivedDataWithRootObject:data] forKey:(__bridge id)kSecValueData];
    SecItemAdd((CFDictionaryRef)CFBridgingRetain(keychainQuery), NULL);
}

// Returns an object inflated from the data stored in the keychain entry for the given service.
+ (id)load:(NSString *)service
{
    id ret = nil;
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:service];
    [keychainQuery setObject:(id)kCFBooleanTrue forKey:(id)CFBridgingRelease(kSecReturnData)];
    [keychainQuery setObject:(id)CFBridgingRelease(kSecMatchLimitOne) forKey:(id)CFBridgingRelease(kSecMatchLimit)];
    CFDataRef keyData = NULL;
    if (SecItemCopyMatching((CFDictionaryRef)CFBridgingRetain(keychainQuery), (CFTypeRef *)&keyData) == noErr) {
        @try {
            ret = [NSKeyedUnarchiver unarchiveObjectWithData:(NSData *)CFBridgingRelease(keyData)];
        }
        @catch (NSException *e) {
            NSLog(@"Unarchive of %@ failed: %@", service, e);
        }
        @finally {}
    }
    if (keyData) CFRelease(keyData);
    return ret;
}

// Removes the entry for the given service from keychain.
+ (void)delete:(NSString *)service
{
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:service];
    SecItemDelete((CFDictionaryRef)CFBridgingRetain(keychainQuery));
}

@end