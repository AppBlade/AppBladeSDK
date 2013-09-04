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

@end

@interface APBWebOperation (AppBladeTokenRequestManager)
- (void)refreshToken:(NSString *)tokenToConfirm;
- (void)confirmToken:(NSString *)tokenToConfirm;

@end

@interface AppBlade (AppBladeTokenRequestManager)

- (void)appBladeWebClient:(APBWebOperation *)client receivedGenerateTokenResponse:(NSDictionary *)response;
- (void)appBladeWebClient:(APBWebOperation *)client receivedConfirmTokenResponse:(NSDictionary *)response;

@end