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

//an APBDatabaseCrashReport object will represent a single row in the CrashReports database
@interface APBDatabaseCrashReport : AppBladeDatabaseObject
+(NSArray *)columnDeclarations;

@property (nonatomic, strong) NSData *stackTrace; // the entire stack trace (as a blob)
@property (nonatomic, strong) NSDate *crashReportedAt; // time of crash
#ifndef SKIP_CUSTOM_PARAMS
@property (nonatomic, strong) NSString *customParameterId;
-(APBDatabaseCustomParameter *)customParameterObj;
#endif

@end
