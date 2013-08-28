//
//  SessionTracking.h
//  AppBlade
//
//  Created by AndrewTremblay on 7/16/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AppBladeBasicFeatureManager.h"

@interface SessionTrackingManager : NSObject<AppBladeBasicFeatureManager>
@property (nonatomic, strong) id<AppBladeWebOperationDelegate> delegate;
@property (nonatomic, retain) NSDate *sessionStartDate;

- (void)logSessionEnd;
- (void)logSessionStart;


@end

//Our additional requirements
@interface AppBlade (SessionTracking)

@property (nonatomic, strong) SessionTrackingManager*        sessionTrackingManager;



- (BOOL)hasPendingSessions;


@end