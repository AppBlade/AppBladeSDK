//
//  AppBladeTokenRequestManager.h
//  AppBlade
//
//  Created by AndrewTremblay on 8/29/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppBlade.h"
#import "APBWebOperation.h"
#import "AppBladeLogging.h"

@interface APBTokenManager : NSObject
-(NSOperationQueue *) tokenRequests;
-(NSOperationQueue *) addTokenRequest:(NSOperation *)request;

- (void)refreshToken:(NSString *)tokenToConfirm;
- (void)confirmToken:(NSString *)tokenToConfirm;
- (BOOL)isCurrentToken:(NSString *)token;
- (BOOL)tokenConfirmRequestPending;
- (BOOL)tokenRefreshRequestPending;

//"Device Secret" = Stored and Usable Token
- (NSMutableDictionary*) appBladeDeviceSecrets;
- (NSString *)appBladeDeviceSecret;
- (void) setAppBladeDeviceSecret:(NSString *)appBladeDeviceSecret;

- (void)clearAppBladeKeychain;
- (void)clearStoredDeviceSecrets;

- (BOOL)hasDeviceSecret;
- (BOOL)isDeviceSecretBeingConfirmed;

@property (nonatomic, retain) NSString* appBladeDeviceSecret;


@end

@interface APBWebOperation (TokenManager)
- (void)refreshToken:(NSString *)tokenToConfirm;
- (void)confirmToken:(NSString *)tokenToConfirm;

@end

@interface AppBlade (TokenManager)
@property (nonatomic, strong) APBTokenManager* tokenManager;

- (void)refreshToken:(NSString *)tokenToConfirm;
- (void)confirmToken:(NSString *)tokenToConfirm;

- (void)appBladeWebClient:(APBWebOperation *)client receivedGenerateTokenResponse:(NSDictionary *)response;
- (void)appBladeWebClient:(APBWebOperation *)client receivedConfirmTokenResponse:(NSDictionary *)response;

@end