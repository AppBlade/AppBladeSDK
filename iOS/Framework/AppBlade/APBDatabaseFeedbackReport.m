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
-(id)initFromSQLiteStatement:(sqlite3_stmt *)statement
{
    self = [super init];
    if (self) {
        NSError *errorCheck = [self readFromSQLiteStatement:statement];
        if(errorCheck){
            ABErrorLog(@"%@", [errorCheck debugDescription]);
            return nil;
        }
    }
    return self;
}

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
        [self setCustomParamSnapshot];
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


-(NSError *)cleanUpIntermediateData
{
    NSError *cleanupError = nil;
    if(self.screenshotURL){
        NSString *screenshotFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:self.screenshotURL];
        NSError *screenShotError = nil;
        [[NSFileManager defaultManager] removeItemAtPath:screenshotFilePath error:&screenShotError];
        if(screenShotError){
            ABErrorLog(@"error removing screenshot: %@", [screenShotError debugDescription]);
            if([[NSFileManager defaultManager] fileExistsAtPath:screenshotFilePath]){
               cleanupError = cleanupError ? cleanupError : [APBDataManager dataBaseErrorWithMessage:[NSString stringWithFormat:@"Screenshot file at %@ could not be removed!", screenshotFilePath]];
            }
        }
    }
    NSError *customError = [self removeCustomParamsSnapshot];
    if(customError) {
        ABErrorLog(@"error removing custom parameter in database: %@", [customError debugDescription]);
        //error removing custom params snapshot
        if(![[self getCustomParamSnapshot]  isEqual: @{ }]){
            cleanupError = cleanupError ? cleanupError : [APBDataManager dataBaseErrorWithMessage:[NSString stringWithFormat:@"custom parameter snapshot could not be removed!"]];
        }
    }
    return  cleanupError;
}

#pragma mark - Custom Parameter methods

-(NSDictionary *)getCustomParamSnapshot {
#ifndef SKIP_CUSTOM_PARAMS
   APBDatabaseCustomParameter *paramObj = [self customParameterObj];
    if (paramObj == nil) {  //custom param not found and could not be created
        return [paramObj asDictionary];
    }else{
        return @{ };
    }
#else
    return @{ };
#endif
}

-(void)setCustomParamSnapshot {
#ifndef SKIP_CUSTOM_PARAMS
    if(self.customParameterId == nil){
        NSError *error = nil;
        APBDatabaseCustomParameter *newCustomParamDataObj = [[[AppBlade sharedManager] customParamsManager]  generateCustomParameterFromCurrentParamsWithError:&error];
        self.customParameterId = [newCustomParamDataObj getId];
    }//currently we only cover setting the custom parameter once per object.
#endif
    //if we don't have custom parameters enabled, this call does nothing
}

-(NSError *)removeCustomParamsSnapshot
{
#ifndef SKIP_CUSTOM_PARAMS
    if(self.customParameterId == nil){
        NSError *errorCheck = nil;
        [[[AppBlade sharedManager] customParamsManager] removeCustomParamById:self.customParameterId error:&errorCheck];
        if(errorCheck != nil){
            return errorCheck;
        }
    }//currently we only cover setting the custom parameter once per object.
#endif
    //even if we don't have custom parameters enabled, still try to remove whatever data we are linked to
    return nil;
}

#ifndef SKIP_CUSTOM_PARAMS
-(APBDatabaseCustomParameter *)customParameterObj{
    //lookup custom parameter obj, this should occur rarely if ever.
    if(self.customParameterId){
        return [[[AppBlade sharedManager] customParamsManager] getCustomParamById:self.customParameterId];
    }else{
        NSError *errorCheck = nil;
       APBDatabaseCustomParameter* customParam =[[[AppBlade sharedManager] customParamsManager] generateCustomParameterFromCurrentParamsWithError:&errorCheck];
        if(customParam){
            self.customParameterId = [customParam getId];
        }else{
            ABErrorLog(@"Custom parameter snapshot could not be created.");
        }
        return customParam;
    }
}
#endif


@end
