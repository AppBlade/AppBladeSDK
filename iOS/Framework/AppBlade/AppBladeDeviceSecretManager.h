//
//  AppBladeDeviceSecretManager.h
//  AppBlade
//
//  Created by AndrewTremblay on 8/29/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppBlade.h"

@interface AppBladeDeviceSecretManager : NSObject
- (NSMutableDictionary*) appBladeDeviceSecrets;
- (NSString *)appBladeDeviceSecret;
- (void) setAppBladeDeviceSecret:(NSString *)appBladeDeviceSecret;

- (void)clearAppBladeKeychain;
- (void)clearStoredDeviceSecrets;

- (BOOL)hasDeviceSecret;
- (BOOL)isDeviceSecretBeingConfirmed;

@property (nonatomic, retain) NSString* appBladeDeviceSecret;


@end


@interface AppBlade (AppBladeDeviceSecretManager)

- (NSOperationQueue*)tokenRequests;

@end