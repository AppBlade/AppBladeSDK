//
//  AppBladeAuthentication.h
//  AppBlade
//
//  Created by AndrewTremblay on 7/16/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AppBladeBasicFeatureManager.h"

@interface AppBladeAuthenticationManager : NSObject<AppBladeBasicFeatureManager>
@property (nonatomic, strong) id<AppBladeWebOperationDelegate> delegate;

- (void)checkApproval;
- (void)handleWebClient:(AppBladeWebOperation *)client receivedPermissions:(NSDictionary *)permissions;
- (void)permissionCallbackFailed:(AppBladeWebOperation *)client withErrorString:(NSString*)errorString;

#pragma mark TTL (Time To Live) Methods
- (void)closeTTLWindow;
- (void)updateTTL:(NSNumber*)ttl;
- (BOOL)withinStoredTTL;


@end


//Our additional requirements
@interface AppBlade (Authorization)
- (void)appBladeWebClient:(AppBladeWebOperation *)client receivedPermissions:(NSDictionary *)permissions;

@end


@interface AppBladeWebOperation (Authorization)
- (void)checkPermissions;

@end
