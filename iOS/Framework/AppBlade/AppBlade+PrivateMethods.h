//
//  AppBlade+PrivateMethods.h
//  AppBlade
//
//  Created by AndrewTremblay on 7/31/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//
#import "AppBladeWebOperation.h"

@interface AppBlade (PrivateMethods)

- (void)validateProjectConfiguration;
- (void)raiseConfigurationExceptionWithMessage:(NSString *)name;

-(NSMutableDictionary*) appBladeDeviceSecrets;
- (BOOL)hasDeviceSecret;
- (BOOL)isDeviceSecretBeingConfirmed;


- (AppBladeWebOperation *)generateWebOperation;
- (void)addPendingRequest:(AppBladeWebOperation *)webOperation;
- (NSInteger)pendingRequestsOfType:(AppBladeWebClientAPI)clientType;
- (BOOL)isCurrentToken:(NSString *)token;

- (void) pauseCurrentPendingRequests;
- (void) cancelAllPendingRequests;
- (void) cancelPendingRequestsByToken:(NSString *)token;

- (NSObject*)readFile:(NSString *)filePath;
- (NSString*)hashFileOfPlist:(NSString *)filePath;
- (void)registerWithAppBladeDictionary:(NSDictionary*)appbladeVariables atPlistPath:(NSString*)plistPath;
- (void)checkAndCreateAppBladeCacheDirectory;




@end
