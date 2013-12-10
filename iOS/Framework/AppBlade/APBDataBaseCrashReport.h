//
//  APBDatabaseCrashReport.h
//  AppBlade
//
//  Created by AndrewTremblay on 12/5/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppBladeDatabaseColumn.h"

//an APBDatabaseCrashReport object will represent a single row in the CrashReports database
@interface APBDatabaseCrashReport : NSObject
@property (nonatomic, strong) NSData *crashBlob;
@property (nonatomic, strong) NSDate *crashReportedAt;
@property (nonatomic, strong) NSData *crashDeliveredAt;

@end
