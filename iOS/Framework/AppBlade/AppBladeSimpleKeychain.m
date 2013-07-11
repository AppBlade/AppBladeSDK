//
//  SimpleKeychain.m
//  AppBlade
//
//  Created by jkaufman on 3/23/11.
//  Copyright 2011 Raizlabs. All rights reserved.
//
#import "AppBladeSimpleKeychain.h"

@implementation AppBladeSimpleKeychain

+(BOOL)hasKeychainAccess
{
    //test with some dummy data, we need to be able to write, read, and remove.
    OSStatus keychainErrorCode = noErr; //
    NSString *keychainInterimCodeLabel = @"";

    OSStatus keychainInterimCode = noErr;
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:@"AppBladeKeychainTest"];

    CFDataRef keyData = NULL;
    
    //I only care about the first error code we hit
    //test writing
    SecItemDelete((__bridge CFDictionaryRef)keychainQuery);
    [keychainQuery setObject:[NSKeyedArchiver archivedDataWithRootObject:@"Delete This Thing"] forKey:(__bridge id)kSecValueData];
    keychainInterimCode = SecItemAdd((__bridge CFDictionaryRef)keychainQuery, NULL);
    keychainErrorCode = keychainInterimCode;
    keychainInterimCodeLabel = (keychainErrorCode != noErr) ? keychainInterimCodeLabel : @"writing";
    
    //test reading
    keychainInterimCode = SecItemCopyMatching((__bridge CFDictionaryRef)keychainQuery, (CFTypeRef *)&keyData);
    keychainErrorCode = (keychainErrorCode != noErr) ? keychainErrorCode : keychainInterimCode;
    keychainInterimCodeLabel = (keychainErrorCode != noErr) ? keychainInterimCodeLabel : @"reading";
    if (keyData) CFRelease(keyData);

    //test deleting
    keychainQuery = [self getKeychainQuery:@"AppBladeKeychainTest"];
    keychainInterimCode = SecItemDelete((__bridge CFDictionaryRef)keychainQuery);
    keychainErrorCode = (keychainErrorCode != noErr) ? keychainErrorCode : keychainInterimCode;
    keychainInterimCodeLabel = (keychainErrorCode != noErr) ? keychainInterimCodeLabel : @"deleting";
    
    
    // If the keychain item already exists, modify it:
    if (keychainErrorCode == noErr)
    {
        //TODO: more tests for all the writing, reading,
        return TRUE;
    }else{
        NSString *errorMessage = @"";
        //SecCopyErrorMessageString doesn't work in iOS! Consternation!
        switch (keychainErrorCode) {
            case errSecSuccess:
                errorMessage = @"\"No error.\" Wait. What? ";
                break;
            case errSecUnimplemented:
                errorMessage = @"Function or operation not implemented.";
                break;
            case errSecParam:
                errorMessage = @"One or more parameters passed to a function where not valid.";
                break;
            case errSecAllocate:
                errorMessage = @"Failed to allocate memory.";
                break;
            case errSecNotAvailable:
                errorMessage = @"No keychain is available. You may need to restart your device.";
                break;
            case errSecDuplicateItem:
                errorMessage = @"The specified item already exists in the keychain.";
                break;
            case errSecItemNotFound:
                errorMessage = @"The specified item could not be found in the keychain.";
                break;
            case errSecInteractionNotAllowed:
                errorMessage = @"User interaction is not allowed.";
                break;
            case errSecDecode:
                errorMessage = @"Unable to decode the provided data.";
                break;
            default:
                errorMessage = @"(unknown error)";
                break;
        } //Not using the AppBlade Logs here because this is a CRITICAL error that should not be kept quiet.
        NSLog(@"Keychain error occured during keychain %@ test: %ld : %@", keychainInterimCodeLabel, keychainErrorCode, errorMessage);
        NSLog(@"The AppBlade SDK needs keychain access to store credentials.");
        return FALSE;
    }
}


// Returns the keychain request dictionary for a SimpleKeychain entry.
+ (NSMutableDictionary *)getKeychainQuery:(NSString *)service
{
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:
            (__bridge id)kSecClassGenericPassword, (__bridge id)kSecClass,
            service, (__bridge id)kSecAttrService,
            service, (__bridge id)kSecAttrAccount,
            (__bridge id)kSecAttrAccessibleAfterFirstUnlock, (__bridge id)kSecAttrAccessible, // Keychain must be unlocked to access this value.
            nil];

}

// Accepts service name and NSCoding-complaint data object.
+ (void)save:(NSString *)service data:(id)data
{
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:service];
    SecItemDelete((__bridge CFDictionaryRef)keychainQuery);
    [keychainQuery setObject:[NSKeyedArchiver archivedDataWithRootObject:data] forKey:(__bridge id)kSecValueData];
    SecItemAdd((__bridge CFDictionaryRef)keychainQuery, NULL);
}

// Returns an object inflated from the data stored in the keychain entry for the given service.
+ (id)load:(NSString *)service
{
    id ret = nil;
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:service];
    [keychainQuery setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [keychainQuery setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    CFDataRef keyData = NULL;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)keychainQuery, (CFTypeRef *)&keyData) == noErr) {
        @try {
            ret = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData *)keyData];
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
    SecItemDelete((__bridge CFDictionaryRef)keychainQuery);
}

@end