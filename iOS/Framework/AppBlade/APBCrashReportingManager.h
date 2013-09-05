//
//  CrashReporting.h
//  AppBlade
//
//  Created by AndrewTremblay on 7/16/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "APBBasicFeatureManager.h"

@interface APBCrashReportingManager : NSObject<APBBasicFeatureManager>
@property (nonatomic, strong) id<APBWebOperationDelegate> delegate;

#pragma mark - Web Request Generators
- (APBWebOperation*) generateCrashReportFromDictionary:(NSDictionary *)crashDictionary withParams:(NSDictionary *)paramsDict;

- (void)handleWebClientCrashReported:(APBWebOperation *)client;
- (void)crashReportCallbackFailed:(APBWebOperation *)client withErrorString:(NSString*)errorString;

#pragma mark Stored Web Request Handling

#pragma mark Stored Crash Handling
- (void) catchAndReportCrashes;
- (void) checkForExistingCrashReports;
- (NSMutableDictionary *) handleCrashReportAsDictionary;

@end


//Our additional requirements
@interface AppBlade (CrashReporting)

@property (nonatomic, strong) APBCrashReportingManager*         crashManager;
//hasPendingCrashReport in PLCrashReporter
- (void)appBladeWebClientCrashReported:(APBWebOperation *)client;


@end