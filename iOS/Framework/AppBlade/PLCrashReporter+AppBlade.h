//
//  PLCrashReporter+AppBlade.h
//  AppBlade
//
//  Created by AndrewTremblay on 2/6/14.
//  Copyright (c) 2014 Raizlabs Corporation. All rights reserved.
//
#import "PLCrashReporter.h"

// these once-public, now-private methods are required by AppBlade for backwards compatibility
@interface PLCrashReporter ()
- (NSString *) queuedCrashReportDirectory;
-(NSString *)crashReportDirectory;
-(NSString *)crashReportPath;

@end
