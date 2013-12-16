//
//  APBDatabaseCrashReport.h
//  AppBlade
//
//  Created by AndrewTremblay on 12/5/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppBladeDatabaseColumn.h"
#import "AppBladeDatabaseObject.h"

#ifndef SKIP_CUSTOM_PARAMS
#import "APBCustomParametersManager.h"
#endif


static NSString* const kDbCrashReportColumnNameStackTrace = @"stackTrace";
static int const kDbCrashReportColumnIndexStackTrace = 1;
static NSString* const kDbCrashReportColumnNameReportedAt = @"crashedAt";
static int const kDbCrashReportColumnIndexReportedAt = 2;
static NSString* const kDbCrashReportColumnNameCustomParamsRef = @"customParamsId";
static int const kDbCrashReportColumnIndexCustomParamsRef = 3;

//an APBDatabaseCrashReport object will represent a single row in the CrashReports database
@interface APBDatabaseCrashReport : AppBladeDatabaseObject
+(NSArray *)columnDeclarations;

@property (nonatomic, strong) NSString *stackTrace; // the entire stack trace file
@property (nonatomic, strong) NSDate *crashReportedAt; // time of crash
#ifndef SKIP_CUSTOM_PARAMS
@property (nonatomic, strong) NSString *customParameterId;
-(APBDatabaseCustomParameter *)customParameterObj;
#endif

@end
