//
//  APBDatabaseFeedbackReport.h
//  AppBlade
//
//  Created by AndrewTremblay on 12/9/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//

#import "AppBladeDatabaseObject.h"
#import "APBDatabaseCustomParameter.h"

static NSString* const kDbFeedbackReportColumnNameScreenshot = @"screenshotURL";
static NSString* const kDbFeedbackReportColumnNameText       = @"text";
static NSString* const kDbFeedbackReportColumnNameReportedAt = @"reportedAt";
#ifndef SKIP_CUSTOM_PARAMS
static NSString* const kDbFeedbackReportColumnNameCustomParamsRef = @"customParamsId";
#endif

@interface APBDatabaseFeedbackReport : AppBladeDatabaseObject
@property (nonatomic, strong) NSString *text;           // the entire stack trace file
@property (nonatomic, strong) NSString *screenshotURL;  // screenshot location (no way are we storing images in a database)
-(UIImage *)screenshot;     //helper method for loading the screenshot
@property (nonatomic, strong) NSDate   *reportedAt;     // time of report

#ifndef SKIP_CUSTOM_PARAMS
    @property (nonatomic, strong) NSString *customParameterId;
    -(APBDatabaseCustomParameter *)customParameterObj;
#endif

    +(NSArray *)columnDeclarations;

    -(NSArray *)columnNamesList;

    -(NSArray *)rowValuesList;

@end
