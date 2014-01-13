//
//  APBDatabaseFeedbackReport.m
//  AppBlade
//
//  Created by AndrewTremblay on 12/9/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//
#import "AppBlade.h"

#import "APBDatabaseFeedbackReport.h"
#import "AppBladeDatabaseColumn.h"

#ifndef SKIP_CUSTOM_PARAMS
#import "APBCustomParametersManager.h"
#endif


@implementation APBDatabaseFeedbackReport
-(id)initWithText:(NSString *)feedbackText screenshotURL:(NSString *)feedbackScreenshotURL reportedAt:(NSDate *)feedbackReportedAt
{
    self = [super init];
    if (self) {
        [self takeFreshSnapshot];
        [self setScreenshotURL: feedbackScreenshotURL];
        [self setText:          feedbackText];
        [self setReportedAt:    feedbackReportedAt];
#ifndef SKIP_CUSTOM_PARAMS
        [self setCustomParamSnapshot]; //current custom params are stored as a semi-readable string
#endif
    }
    return self;
}


-(id)initWithFeedbackDictionary:(NSDictionary *)feedbackDictionary
{
    self = [super init];
    if (self) {
        [self takeFreshSnapshot];
        [self setScreenshotURL:[feedbackDictionary valueForKey:kAppBladeFeedbackKeyScreenshot]];
        [self setText:[feedbackDictionary valueForKey:kAppBladeFeedbackKeyNotes]];
        [self setReportedAt:[NSDate new]];
#ifndef SKIP_CUSTOM_PARAMS
        [self setCustomParamSnapshot];
#endif
    }
    return self;
}


//will handle storing and retrieving the data format of the crash reports table
+(NSArray *)columnDeclarations
{
    return @[[AppBladeDatabaseColumn initColumnNamed:kDbFeedbackReportColumnNameScreenshotURL withContraints: (AppBladeColumnConstraintAffinityText) additionalArgs:nil],
             [AppBladeDatabaseColumn initColumnNamed:kDbFeedbackReportColumnNameText withContraints: (AppBladeColumnConstraintAffinityText) additionalArgs:nil],
             [AppBladeDatabaseColumn initColumnNamed:kDbFeedbackReportColumnNameReportedAt  withContraints:(AppBladeColumnConstraintAffinityText | AppBladeColumnConstraintNotNull) additionalArgs:nil]
#ifndef SKIP_CUSTOM_PARAMS
             , [AppBladeDatabaseColumn initColumnNamed:kDbFeedbackReportColumnNameCustomParamsRef withContraints:(AppBladeColumnConstraintAffinityText | AppBladeColumnConstraintNotNull) additionalArgs:[APBCustomParametersManager getDefaultForeignKeyDefinition:kDbFeedbackReportColumnNameCustomParamsRef]]
#endif
             ];
}

-(NSArray *)additionalColumnNames {
    return @[ kDbFeedbackReportColumnNameScreenshotURL, kDbFeedbackReportColumnNameText, kDbFeedbackReportColumnNameReportedAt
#ifndef SKIP_CUSTOM_PARAMS
              , kDbFeedbackReportColumnNameCustomParamsRef
#endif
              ];
}

-(NSArray *)additionalColumnValues {
    return @[[self sqlFormattedProperty: self.screenshotURL], [self sqlFormattedProperty: self.text], [self sqlFormattedProperty: self.reportedAt]
#ifndef SKIP_CUSTOM_PARAMS
         , [self sqlFormattedProperty:self.customParameterId]
#endif
        ];
}


-(UIImage *)screenshot
{
    return [UIImage imageWithContentsOfFile:self.screenshotURL];
}

-(NSError *)readFromSQLiteStatement:(sqlite3_stmt *)statement {
    NSError *toRet = [super readFromSQLiteStatement:statement];
    if(toRet != nil)
        return toRet;
    
    self.text = [self readStringInAdditionalColumn:[NSNumber numberWithInt:kDbFeedbackReportColumnIndexOffsetText] fromFromSQLiteStatement:statement];
    self.screenshotURL = [self readStringInAdditionalColumn:[NSNumber numberWithInt:kDbFeedbackReportColumnIndexOffsetScreenshotURL] fromFromSQLiteStatement:statement];
#ifndef SKIP_CUSTOM_PARAMS
    self.customParameterId = [self readStringInAdditionalColumn:[NSNumber numberWithInt:kDbFeedbackReportColumnIndexOffsetCustomParamsRef] fromFromSQLiteStatement:statement];
#endif
    
    return nil;
}

@end
