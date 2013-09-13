//
//  AppBladeAuthentication.h
//  AppBlade
//
//  Created by AndrewTremblay on 7/16/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "APBBasicFeatureManager.h"

extern NSString *kTtlDictTimeoutKey;
extern NSString *kTtlDictDateSetKey;

@interface APBAuthenticationManager : NSObject<APBBasicFeatureManager>
@property (nonatomic, strong) id<APBWebOperationDelegate> delegate;

- (void)checkApproval;
- (void)handleWebClient:(APBWebOperation *)client receivedPermissions:(NSDictionary *)permissions;
- (void)permissionCallbackFailed:(APBWebOperation *)client withErrorString:(NSString*)errorString;

#pragma mark TTL (Time To Live) Methods
- (void)closeTTLWindow;
- (void)updateTTL:(NSNumber*)ttl;
- (NSDictionary *)currentTTL;
- (BOOL)withinStoredTTL;


@end



//Our additional requirements
@interface AppBlade (Authorization)
@property (nonatomic, strong) APBAuthenticationManager* authenticationManager; //declared here too so the compiler doesn't cry

- (void)appBladeWebClient:(APBWebOperation *)client receivedPermissions:(NSDictionary *)permissions;
- (void)appBladeWebClient:(APBWebOperation *)client failedPermissions:(NSString *)errorString;
@end


@interface APBWebOperation (Authorization)
- (void)checkPermissions;

@end
