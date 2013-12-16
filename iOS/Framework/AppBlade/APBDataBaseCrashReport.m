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


-(NSArray *)columnNamesList {
    return @[ kDbCrashReportColumnNameStackTrace, kDbCrashReportColumnNameReportedAt,
#ifndef SKIP_CUSTOM_PARAMS
              kDbCrashReportColumnNameCustomParamsRef
#endif
          ];
}


-(NSArray *)rowValuesList {
    return @[[self SqlFormattedProperty: self.stackTrace], [self SqlFormattedProperty: self.crashReportedAt],
#ifndef SKIP_CUSTOM_PARAMS
             [self SqlFormattedProperty:self.customParameterId]
#endif
          ];
}

-(NSString *)columnNames {
    return [[self columnNamesList] componentsJoinedByString:@", "];
}

-(NSString *)rowValues {
    return [[self rowValuesList] componentsJoinedByString:@", "];
}


-(NSString *)insertSqlIntoTable:(NSString *)tableName {
    return [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)", tableName, [self columnNames], [self rowValues]];
}

-(NSError *)readFromSQLiteStatement:(sqlite3_stmt *)statement {
    NSError *toRet = [super readFromSQLiteStatement:statement];
    if(toRet != nil)
        return toRet;

    self.stackTrace = [self readStringAtColumn:kDbCrashReportColumnIndexStackTrace fromFromSQLiteStatement:statement];
    self.crashReportedAt = [self readDateAtColumn:kDbCrashReportColumnIndexReportedAt fromFromSQLiteStatement:statement];
#ifndef SKIP_CUSTOM_PARAMS
    self.customParameterId = [self readStringAtColumn:kDbCrashReportColumnIndexCustomParamsRef fromFromSQLiteStatement:statement];
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
