//
//  APBDatabaseCrashReport.m
//  AppBlade
//
//  Created by AndrewTremblay on 12/5/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//

#import "APBDatabaseCrashReport.h"

#ifndef SKIP_CUSTOM_PARAMS
#import "APBCustomParametersManager.h"
#endif


@implementation APBDatabaseCrashReport
    //will handle storing and retrieving the data format of the crash reports table
+(NSArray *)columnDeclarations
    {
        return @[[AppBladeDatabaseColumn initColumnNamed:@"stackTrace" withContraints: (AppBladeColumnConstraintAffinityNone | AppBladeColumnConstraintNotNull) additionalArgs:nil],
                 [AppBladeDatabaseColumn initColumnNamed:@"reportedAt" withContraints:(AppBladeColumnConstraintAffinityText | AppBladeColumnConstraintNotNull) additionalArgs:nil]
    #ifndef SKIP_CUSTOM_PARAMS
                 ,[AppBladeDatabaseColumn initColumnNamed:@"customParamsId" withContraints:(AppBladeColumnConstraintAffinityInteger) additionalArgs:[APBCustomParametersManager getDefaultForeignKeyDefinition:@"customParamsId"]]
    #endif
                 ];
    }
@end
