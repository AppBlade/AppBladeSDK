//
//  SessionTracking.h
//  AppBlade
//
//  Created by AndrewTremblay on 7/16/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "APBBasicFeatureManager.h"

@interface APBSessionTrackingManager : NSObject<APBBasicFeatureManager>
@property (nonatomic, strong) id<APBWebOperationDelegate> delegate;
@property (nonatomic, retain) NSDate *sessionStartDate;

- (void)logSessionEnd;
- (void)logSessionStart;

- (void)handleWebClientSentSessions:(APBWebOperation *)client withSuccess:(BOOL)success;
- (void)sessionTrackingCallbackFailed:(APBWebOperation *)client withErrorString:(NSString*)errorString;

- (BOOL)hasPendingSessions;
@end


@interface APBWebOperation (SessionTracking)
-(void)postSessions:(NSArray *)sessions;
@end

//Our additional requirements
@interface AppBlade (SessionTracking)
    @property (nonatomic, strong) APBSessionTrackingManager* sessionTrackingManager;
    - (void)appBladeWebClientSentSessions:(APBWebOperation *)client withSuccess:(BOOL)success;

@end