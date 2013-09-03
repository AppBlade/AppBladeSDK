//
//  AppBladeDeviceSecretManager.m
//  AppBlade
//
//  Created by AndrewTremblay on 8/29/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "APBDeviceSecretManager.h"
#import "APBSimpleKeychain.h"
#import "AppBlade+PrivateMethods.h"
#import "AppBladeLogging.h"

@implementation APBDeviceSecretManager
@synthesize appBladeDeviceSecret = _appbladeDeviceSecret;

-(NSMutableDictionary*) appBladeDeviceSecrets
{
    NSMutableDictionary* appBlade_deviceSecret_dict = (NSMutableDictionary* )[APBSimpleKeychain load:kAppBladeKeychainDeviceSecretKey];
    if(nil == appBlade_deviceSecret_dict)
    {
        appBlade_deviceSecret_dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"", kAppBladeKeychainDeviceSecretKeyNew, @"", kAppBladeKeychainDeviceSecretKeyOld, @"", kAppBladeKeychainPlistHashKey, nil];
        [APBSimpleKeychain save:kAppBladeKeychainDeviceSecretKey data:appBlade_deviceSecret_dict];
        ABDebugLog_internal(@"Device Secrets were nil. Reinitialized.");
    }
    return appBlade_deviceSecret_dict;
}


- (NSString *)appBladeDeviceSecret
{
    //get the last available device secret
    NSMutableDictionary* appBlade_keychain_dict = [self appBladeDeviceSecrets];
    NSString* device_secret_stored = (NSString*)[appBlade_keychain_dict valueForKey:kAppBladeKeychainDeviceSecretKeyNew]; //assume we have the newest in new_secret key
    NSString* device_secret_stored_old = (NSString*)[appBlade_keychain_dict valueForKey:kAppBladeKeychainDeviceSecretKeyOld];
    if(nil == device_secret_stored || [device_secret_stored isEqualToString:@""])
    {
        ABDebugLog_internal(@"Device Secret from storage:%@, falling back to old value:(%@).", (device_secret_stored == nil  ? @"null" : ( [device_secret_stored isEqualToString:@""] ? @"empty" : device_secret_stored) ), (device_secret_stored_old == nil  ? @"null" : ( [device_secret_stored_old isEqualToString:@""] ? @"empty" : device_secret_stored_old) ));
        _appbladeDeviceSecret = (NSString*)[device_secret_stored_old copy];     //if we have no stored keys, returns default empty string
    }else
    {
        _appbladeDeviceSecret = (NSString*)[device_secret_stored copy];
    }
    
    return _appbladeDeviceSecret;
}

- (void) setAppBladeDeviceSecret:(NSString *)appBladeDeviceSecret
{
    //always store the last two device secrets
    NSMutableDictionary* appBlade_keychain_dict = [self appBladeDeviceSecrets];
    NSString* device_secret_latest_stored = [appBlade_keychain_dict objectForKey:kAppBladeKeychainDeviceSecretKeyNew]; //get the newest key (to our knowledge)
    if((nil != appBladeDeviceSecret) && ![device_secret_latest_stored isEqualToString:appBladeDeviceSecret]) //if we don't already have the "new" token as the newest token
    {
        [appBlade_keychain_dict setObject:[device_secret_latest_stored copy] forKey:kAppBladeKeychainDeviceSecretKeyOld]; //we don't care where the old key goes
        [appBlade_keychain_dict setObject:[appBladeDeviceSecret copy] forKey:kAppBladeKeychainDeviceSecretKeyNew];
        //update the newest key
    }
    //save the stored keychain
    [APBSimpleKeychain save:kAppBladeKeychainDeviceSecretKey data:appBlade_keychain_dict];
}


- (void)clearAppBladeKeychain
{
    NSMutableDictionary* appBlade_keychain_dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"", kAppBladeKeychainDeviceSecretKeyNew, @"", kAppBladeKeychainDeviceSecretKeyOld, @"", kAppBladeKeychainPlistHashKey, nil];
    [APBSimpleKeychain save:kAppBladeKeychainDeviceSecretKey data:appBlade_keychain_dict];
}

- (void)clearStoredDeviceSecrets
{
    NSMutableDictionary* appBlade_keychain_dict = [self appBladeDeviceSecrets];
    if(nil != appBlade_keychain_dict)
    {
        [appBlade_keychain_dict setValue:@"" forKey:kAppBladeKeychainDeviceSecretKeyNew];
        [appBlade_keychain_dict setValue:@"" forKey:kAppBladeKeychainDeviceSecretKeyOld];
        [APBSimpleKeychain save:kAppBladeKeychainDeviceSecretKey data:appBlade_keychain_dict];
        ABDebugLog_internal(@"Cleared device secrets.");
    }
}


-(BOOL)hasDeviceSecret
{
    return [[self appBladeDeviceSecret] length] == 0;
}

- (BOOL)isDeviceSecretBeingConfirmed
{
    BOOL tokenRequestInProgress = ([[[AppBlade sharedManager] tokenRequests] operationCount]) != 0;
    BOOL processIsNotFinished = tokenRequestInProgress; //if we have a process, assume it's not finished, if we have one then of course it's finished
    if(tokenRequestInProgress) { //the queue has a maximum concurrent process size of one, that's why we can do what comes next
        APBWebOperation *process = (APBWebOperation *)[[[[AppBlade sharedManager] tokenRequests] operations] objectAtIndex:0];
        processIsNotFinished = ![process isFinished];
    }
    return tokenRequestInProgress && processIsNotFinished;
}


@end
