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
-(id)initWithFeedbackDictionary:(NSDictionary *)feedbackDictionary
{
    self = [super init];
    if (self) {
        [self takeFreshSnapshot];
        [self setScreenshotURL:[feedbackDictionary valueForKey:kAppBladeFeedbackKeyScreenshot]];
        [self setText:[feedbackDictionary valueForKey:kAppBladeFeedbackKeyNotes]];
        [self setReportedAt:[NSDate new]];
        
        
        [[AppBlade sharedManager] getCustomParams];
    }
    return self;
}


//will handle storing and retrieving the data format of the crash reports table
+(NSArray *)columnDeclarations
{
    return @[[AppBladeDatabaseColumn initColumnNamed:@"feedbackText" withContraints: (AppBladeColumnConstraintAffinityText) additionalArgs:nil],
             [AppBladeDatabaseColumn initColumnNamed:@"reportedAt"   withContraints:(AppBladeColumnConstraintAffinityText | AppBladeColumnConstraintNotNull) additionalArgs:nil]
#ifndef SKIP_CUSTOM_PARAMS
             , [AppBladeDatabaseColumn initColumnNamed:@"customParamId" withContraints:(AppBladeColumnConstraintAffinityText | AppBladeColumnConstraintNotNull) additionalArgs:[APBCustomParametersManager getDefaultForeignKeyDefinition:@"customParamId"]]
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


-(NSArray *)rowValuesList {
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

-(NSDictionary *)getCustomParams {
#ifndef SKIP_CUSTOM_PARAMS
    [self.customParameterObj asDictionary];
#else
    return @{};
#endif
}

#ifndef SKIP_CUSTOM_PARAMS
-(APBDatabaseCustomParameter *)customParameterObj{
    //lookup custom parameter obj, cache the resul in a property object if we use it too much. (we won't use it too much)
    return [[[AppBlade sharedManager] customParamsManager] getCustomParamById:self.customParameterId];
}
#endif



@end
