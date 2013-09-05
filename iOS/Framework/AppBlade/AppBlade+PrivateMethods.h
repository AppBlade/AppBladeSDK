//
//  AppBlade+PrivateMethods.h
//  AppBlade
//
//  Created by AndrewTremblay on 7/31/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//
#import "APBWebOperation.h"
/**
 @defgroup appbladeprivatemethods AppBlade Private Methods
 */
@interface AppBlade (PrivateMethods)

/** @ingroup appbladeprivatemethods
  @{
 */
- (void)validateProjectConfiguration;
- (void)raiseConfigurationExceptionWithMessage:(NSString *)name;

-(NSMutableDictionary*) appBladeDeviceSecrets;
- (BOOL)hasDeviceSecret;
- (BOOL)isDeviceSecretBeingConfirmed;


- (APBWebOperation *)generateWebOperation;
- (void)addPendingRequest:(APBWebOperation *)webOperation;
- (NSInteger)pendingRequestsOfType:(AppBladeWebClientAPI)clientType;
- (BOOL)isCurrentToken:(NSString *)token;

- (void) pauseCurrentPendingRequests;
- (void) cancelAllPendingRequests;
- (void) cancelPendingRequestsByToken:(NSString *)token;

- (NSObject*)readFile:(NSString *)filePath;
- (NSString*)hashFileOfPlist:(NSString *)filePath;
- (void)registerWithAppBladeDictionary:(NSDictionary*)appbladeVariables atPlistPath:(NSString*)plistPath;

//Path to the AppBlade cache directory. Useful for direct modificaion of stored requests.
+ (NSString*)cachesDirectoryPath;
- (void)clearCacheDirectory;
- (void)checkAndCreateAppBladeCacheDirectory;

- (void) resumeCurrentPendingRequests;
/**
 @} 
 */
@end