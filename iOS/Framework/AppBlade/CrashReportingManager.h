//
//  CrashReporting.h
//  AppBlade
//
//  Created by AndrewTremblay on 7/16/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AppBladeBasicFeatureManager.h"

@interface CrashReportingManager : NSObject<AppBladeBasicFeatureManager>
@property (nonatomic, strong) id<AppBladeWebOperationDelegate> delegate;

#pragma mark - Web Request Generators
- (AppBladeWebOperation*) generateCrashReportFromDictionary:(NSDictionary *)crashDictionary withParams:(NSDictionary *)paramsDict;

- (void) handleWebClientCrashReported:(AppBladeWebOperation *)client;

#pragma mark Stored Web Request Handling

#pragma mark Stored Crash Handling
- (void) catchAndReportCrashes;
- (void) checkForExistingCrashReports;
- (NSMutableDictionary *) handleCrashReportAsDictionary;

@end


//Our additional requirements
@interface AppBlade (CrashReporting)

@property (nonatomic, strong) CrashReportingManager*         crashManager;
//hasPendingCrashReport in PLCrashReporter


@end