//
//  AppBladeDatabaseObject.m
//  AppBlade
//
//  Created by AndrewTremblay on 12/9/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//
#import "AppBladeDatabaseObject.h"
#import "AppBladeDatabaseColumn.h"

//For the snapshot
#import "AppBlade.h"
#import "APBApplicationInfoManager.h"
#import "APBDeviceInfoManager.h"


@interface AppBladeDatabaseObject()
@property (nonatomic, strong, readwrite, getter = getId) NSString *dbRowId; //we need to be able to set this

@end

@implementation AppBladeDatabaseObject

-(NSString *)sqlFormattedProperty:(id)propertyValue
{
    //case check for whatever is passed?
    if(propertyValue == nil){
        return @"NULL";
    }
    
    if([propertyValue isKindOfClass:[NSString class]])
    {
        return (NSString *)propertyValue;
    }else if([propertyValue isKindOfClass:[NSDate class]]){
        return [NSString stringWithFormat:@"%f", [(NSDate *)propertyValue timeIntervalSince1970] ];
    }
    else if([propertyValue isKindOfClass:[AppBladeDatabaseObject class]]){
        return [(AppBladeDatabaseObject *)propertyValue getId];
    }
    else{
        return @"NULL";
    }
}


-(NSString *)formattedSelectSqlStringForTable: (NSString *)tableName
{
    return [NSString stringWithFormat:@"SELECT * FROM %@ WHERE id='%@'",
            tableName,
            [self getId ] ];
}


-(NSString *)formattedInsertSqlStringForTable:(NSString *)tableName
{
    return [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)",
            tableName,
            [self removeIdColumn:[self columnNames]],
            [self removeIdColumn:[self columnValues]]];
}

-(NSString *)formattedReplaceSqlStringForTable:(NSString *)tableName
{
    return [NSString stringWithFormat:@"REPLACE INTO %@ (%@) VALUES (%@)",
            tableName,
            [self columnNames],
            [self columnValues]];
}

-(NSError *)readFromSQLiteStatement:(sqlite3_stmt *)statement
{
     NSString *dbRowIdCheck = [[NSString alloc]
                              initWithUTF8String:
                              (const char *) sqlite3_column_text(statement, 0)];
    if(dbRowIdCheck == nil){
        NSError *error = [[NSError alloc] initWithDomain:@"AppBladeDatabaseObject" code:0 userInfo:nil];
        return error;
    }
    
    NSString *dbExecIdCheck = [[NSString alloc]
                               initWithUTF8String:
                               (const char *) sqlite3_column_text(statement, 1)];
    if(dbExecIdCheck == nil){
        self.executableIdentifier = [[AppBlade sharedManager] executableUUID];
    }
  
    self.dbRowId = dbRowIdCheck;
    return nil;
}

-(NSString *)columnNames {
    NSMutableArray *toRet = [NSMutableArray arrayWithArray:[self baseColumnNames] ];
    [toRet addObjectsFromArray:[self additionalColumnNames]];
    return [toRet componentsJoinedByString:@", "];
}

-(NSString *)columnValues {
    NSMutableArray *toRet = [NSMutableArray arrayWithArray:[self baseColumnValues] ];
    [toRet addObjectsFromArray:[self additionalColumnValues]];
    return [toRet componentsJoinedByString:@", "];//default column increments silently
}

//usage [obj removeIdColumn:[obj columnValues]];
-(NSString *)removeIdColumn:(NSString *)commaSeparatedList
{
    NSRange indexOfFirstComma = [commaSeparatedList rangeOfString:@","];
    return [commaSeparatedList substringFromIndex:(indexOfFirstComma.location + indexOfFirstComma.length)];
}
//id column must always come first,
-(NSArray *)baseColumnNames {  return @[ @"id",         @"snapshot_exec_id" ]; }

-(NSArray *)baseColumnValues { return @[ self.dbRowId,  self.executableIdentifier ];  }

-(NSArray *)additionalColumnNames {  return @[ ]; }

-(NSArray *)additionalColumnValues { return @[ ];  }


//column reads
-(NSString *)readStringInAdditionalColumn:(int)indexOffset fromFromSQLiteStatement:(sqlite3_stmt *)statement
{
    return [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, indexOffset)];
}

-(NSDate *)readDateInAdditionalColumn:(int)indexOffset fromFromSQLiteStatement:(sqlite3_stmt *)statement
{
    return [NSDate dateWithTimeIntervalSince1970:[self readTimeIntervalInAdditionalColumn:index fromFromSQLiteStatement:statement]];
}

-(NSTimeInterval)readTimeIntervalInAdditionalColumn:(int)indexOffset fromFromSQLiteStatement:(sqlite3_stmt *)statement
{
    return sqlite3_column_double(statement, indexOffset);
}

-(NSData *)readDataInAdditionalColumn:(int)indexOffset fromFromSQLiteStatement:(sqlite3_stmt *)statement
{
    return [[NSData alloc] initWithBytes:(const char *) sqlite3_column_blob(statement, indexOffset) length:sqlite3_column_bytes(statement, indexOffset)];
}

@end
