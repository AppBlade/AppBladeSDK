//
//  APBDatabaseCrashReport.m
//  AppBlade
//
//  Created by AndrewTremblay on 12/5/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//

#import "APBDatabaseCrashReport.h"


static NSString* const kDbCrashReportColumnNameStackTrace = @"stackTrace";
static NSString* const kDbCrashReportColumnNameReportedAt = @"reportedAt";
static NSString* const kDbCrashReportColumnNameCustomParamsRef = @"customParamsId";

@interface APBDatabaseCrashReport()
@property (nonatomic, readwrite) NSString* dbRowId;

@end


@implementation APBDatabaseCrashReport
    //will handle storing and retrieving the data format of the crash reports table
+(NSArray *)columnDeclarations {
        return @[[AppBladeDatabaseColumn initColumnNamed:kDbCrashReportColumnNameStackTrace withContraints: (AppBladeColumnConstraintAffinityNone | AppBladeColumnConstraintNotNull) additionalArgs:nil],
                 [AppBladeDatabaseColumn initColumnNamed:kDbCrashReportColumnNameReportedAt withContraints:(AppBladeColumnConstraintAffinityReal | AppBladeColumnConstraintNotNull) additionalArgs:nil]
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


#ifndef SKIP_CUSTOM_PARAMS
-(APBDatabaseCustomParameter *)customParameterObj{
    //lookup custom parameter obj
    return nil;
}
#endif

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
    //self.dbRowId = dbRowIdCheck;
    
    NSArray *cols = [self columnNamesList];
    
    
    if(dbRowIdCheck == nil){
        NSError *error = [[NSError alloc] initWithDomain:@"AppBladeDatabaseObject" code:0 userInfo:nil];
        return error;
    }
    

    
#ifndef SKIP_CUSTOM_PARAMS
    self.customParameterId = [[NSString alloc] initWithUTF8String:
                            (const char *) sqlite3_column_text(statement, kDbCrashReportColumnIndexCustomParamsRef)];
#endif

    return nil;
}

#ifndef SKIP_CUSTOM_PARAMS
-(APBDatabaseCustomParameter *)customParameterObj{
    //lookup custom parameter obj
    APBDatabaseCustomParameter *toRet = [[[AppBlade sharedManager] customParamsManager] getCustomParamById:self.customParameterId];
    
    return nil;
}
#endif

@end
