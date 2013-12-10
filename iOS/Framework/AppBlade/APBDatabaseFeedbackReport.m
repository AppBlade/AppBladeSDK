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

//will handle storing and retrieving the data format of the crash reports table
+(NSArray *)columnDeclarations
{
    return @[[AppBladeDatabaseColumn initColumnNamed:@"feedbackText" withContraints: (AppBladeColumnConstraintAffinityText) additionalArgs:nil],
             [AppBladeDatabaseColumn initColumnNamed:@"reportedAt" withContraints:(AppBladeColumnConstraintAffinityText | AppBladeColumnConstraintNotNull) additionalArgs:nil]
#ifndef SKIP_CUSTOM_PARAMS
             , [AppBladeDatabaseColumn initColumnNamed:@"customParamId" withContraints:(AppBladeColumnConstraintAffinityText | AppBladeColumnConstraintNotNull) additionalArgs:[APBCustomParametersManager getDefaultForeignKeyDefinition:@"customParamId"]]
#endif
             ];
}

@end
