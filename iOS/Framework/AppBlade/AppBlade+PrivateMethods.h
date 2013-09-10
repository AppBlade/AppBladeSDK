//
//  AppBlade+PrivateMethods.h
//  AppBlade
//
//  Created by AndrewTremblay on 7/31/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//
#import "APBWebOperation.h"
/*!
 @header AppBlade+PrivateMethods
 @brief Header containing all the methods that we don't want to be publcaly used.
 Do not rely on any of these methods, as they may disappear or change at any time. 
 */

@interface AppBlade (PrivateMethods)

/*! 
 @methodgroup Appblade Private Methods
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
@end