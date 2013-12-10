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


//an APBDatabaseCrashReport object will represent a single row in the CrashReports database
@interface APBDatabaseCrashReport : AppBladeDatabaseObject
+(NSArray *)columnDeclarations;

@property (nonatomic, strong) NSData *crashBlob; // the entire feedback blob
@property (nonatomic, strong) NSDate *crashReportedAt;
@property (nonatomic, strong) NSData *crashDeliveredAt;

@end
