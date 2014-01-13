//
//  APBDatabaseFeedbackReport.h
//  AppBlade
//
//  Created by AndrewTremblay on 12/9/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//

#import "AppBladeDatabaseObject.h"
#import "APBDatabaseCustomParameter.h"

#import "AppBladeDatabaseObject+CustomParametersCompatibility.h"



static NSString* const kDbFeedbackReportColumnNameScreenshotURL = @"screenshotURL";
static NSInteger const kDbFeedbackReportColumnIndexOffsetScreenshotURL = 1;
static NSString* const kDbFeedbackReportColumnNameText       = @"text";
static NSInteger const kDbFeedbackReportColumnIndexOffsetText = 2;
static NSString* const kDbFeedbackReportColumnNameReportedAt = @"reportedAt";
static NSInteger const kDbFeedbackReportColumnIndexOffsetReportedAt = 3;
#ifndef SKIP_CUSTOM_PARAMS
static NSString* const kDbFeedbackReportColumnNameCustomParamsRef = @"customParamsId";
static NSInteger const kDbFeedbackReportColumnIndexOffsetCustomParamsRef = 4;
#endif

@interface APBDatabaseFeedbackReport : AppBladeDatabaseObject
    -(id)initWithFeedbackDictionary:(NSDictionary *)feedbackDictionary;
    -(id)initWithText:(NSString *)feedbackText screenshotURL:(NSString *)feedbackScreenshotURL reportedAt:(NSDate *)feedbackReportedAt;

    +(NSArray *)columnDeclarations;

    @property (nonatomic, strong) NSString *text;           // the entire stack trace file
    @property (nonatomic, strong) NSString *screenshotURL;  // screenshot location (no way are we storing images in a database)
    @property (nonatomic, strong) NSDate   *reportedAt;     // time of report
    -(UIImage *)screenshot;     //helper method for loading the screenshot

#ifndef SKIP_CUSTOM_PARAMS
    @property (nonatomic, strong) NSString *customParameterId;
#endif

@end
