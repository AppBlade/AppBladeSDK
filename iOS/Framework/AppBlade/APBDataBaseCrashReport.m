//
//  APBDatabaseCrashReport.m
//  AppBlade
//
//  Created by AndrewTremblay on 12/5/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//

#import "APBDatabaseCrashReport.h"



@interface APBDatabaseCrashReport()

@property (nonatomic, readwrite) NSString* dbRowId;

@end


@implementation APBDatabaseCrashReport
    //will handle storing and retrieving the data format of the crash reports table
+(NSArray *)columnDeclarations {
        return @[[AppBladeDatabaseColumn initColumnNamed:kDbCrashReportColumnNameStackTrace
                                          withContraints: (AppBladeColumnConstraintAffinityNone | AppBladeColumnConstraintNotNull)
                                          additionalArgs:nil],
                 [AppBladeDatabaseColumn initColumnNamed:kDbCrashReportColumnNameReportedAt
                                          withContraints:(AppBladeColumnConstraintAffinityReal | AppBladeColumnConstraintNotNull)
                                          additionalArgs:nil]
#ifndef SKIP_CUSTOM_PARAMS
                 ,[AppBladeDatabaseColumn initColumnNamed:kDbCrashReportColumnNameCustomParamsRef
                                           withContraints:(AppBladeColumnConstraintAffinityInteger)
                                           additionalArgs:[APBCustomParametersManager getDefaultForeignKeyDefinition:kDbCrashReportColumnNameCustomParamsRef]]
#endif
             ];
}


-(NSArray *)additionalColumnNames {
//overrides [super additionalColumnNames];

    return @[ kDbCrashReportColumnNameStackTrace, kDbCrashReportColumnNameReportedAt,
#ifndef SKIP_CUSTOM_PARAMS
              kDbCrashReportColumnNameCustomParamsRef
#endif
          ];
}


-(NSArray *)additionalColumnValues {
//overrides [super additionalColumnValues];

    return @[[self sqlFormattedProperty: self.stackTrace], [self sqlFormattedProperty: self.crashReportedAt],
#ifndef SKIP_CUSTOM_PARAMS
             [self sqlFormattedProperty:self.customParameterId]
#endif
          ];
}


-(NSError *)readFromSQLiteStatement:(sqlite3_stmt *)statement {
    NSError *toRet = [super readFromSQLiteStatement:statement];
    if(toRet != nil)
        return toRet;

    self.stackTrace = [self readStringInAdditionalColumn:[NSNumber numberWithInt:kDbCrashReportColumnIndexOffsetStackTrace] fromSQLiteStatement:statement];
    self.crashReportedAt = [self readDateInAdditionalColumn:[NSNumber numberWithInt:kDbCrashReportColumnIndexOffsetReportedAt] fromSQLiteStatement:statement];
#ifndef SKIP_CUSTOM_PARAMS
    self.customParameterId = [self readStringInAdditionalColumn:[NSNumber numberWithInt:kDbCrashReportColumnIndexOffsetCustomParamsRef] fromSQLiteStatement:statement];
#endif

    return nil;
}

#ifndef SKIP_CUSTOM_PARAMS
-(APBDatabaseCustomParameter *)customParameterObj{
    //lookup custom parameter obj, cache the resul in a property object if we use it too much. (we won't use it too much)
    return [[[AppBlade sharedManager] customParamsManager] getCustomParamById:self.customParameterId];
}
#endif

@end
