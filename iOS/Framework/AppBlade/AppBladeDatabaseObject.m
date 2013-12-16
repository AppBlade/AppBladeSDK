//
//  AppBladeDatabaseObject.m
//  AppBlade
//
//  Created by AndrewTremblay on 12/9/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//
#import "AppBladeDatabaseObject.h"
#import "AppBladeDatabaseColumn.h"

@interface AppBladeDatabaseObject()
@property (nonatomic, strong, readwrite, getter = getId) NSString *dbRowId; //we need to be able to set this

@end

@implementation AppBladeDatabaseObject

-(NSString *)SqlFormattedProperty:(id)propertyValue {
    //case check for whatever is passed?
    if(propertyValue == nil){
        return @"NULL";
    }
    
    if([[propertyValue type] isKindOfClass:[NSString class]])
    {
        return (NSString *)propertyValue;
    }else if([[propertyValue type] isKindOfClass:[NSDate class]]){
        return [NSString stringWithFormat:@"%f", [(NSDate *)propertyValue timeIntervalSince1970] ];
    }
    else if([[propertyValue type] isKindOfClass:[AppBladeDatabaseObject class]]){
        return [(AppBladeDatabaseObject *)propertyValue getId];
    }
    else{
        return @"NULL";
    }
}

-(NSString *)sqlToInsertDataIntoTable:(NSString *)tableName
{
    return [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)", tableName, [self columnNames], [self rowValues]];
}

-(NSString *)sqlToUpdateDataInTable:(NSString *)tableName
{
    return [NSString stringWithFormat:@"REPLACE INTO %@ (%@) VALUES (%@)", tableName, [self columnNamesAndId], [self rowValuesAndId]];
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
  
    self.dbRowId = dbRowIdCheck;
    return nil;
}

-(NSString *)columnNames {
    return @"";//default column increments silently
}

-(NSString *)rowValues {
    return @"";
}

-(NSString *)columnNamesAndId {
    NSMutableArray *toRet = [NSMutableArray arrayWithObject:@"id"];
    [toRet addObjectsFromArray:[self columnNamesList]];
    return [toRet componentsJoinedByString:@", "];//default column increments silently
}

-(NSString *)rowValuesAndId {
    NSMutableArray *toRet = [NSMutableArray arrayWithObject:self.dbRowId];
    [toRet addObjectsFromArray:[self rowValuesList]];
    return [toRet componentsJoinedByString:@", "];//default column increments silently
}

-(NSArray *)columnNamesList {
    return @[];
}

-(NSArray *)rowValuesList {
    return @[];
}


//column reads
-(NSString *)readStringAtColumn:(int)index fromFromSQLiteStatement:(sqlite3_stmt *)statement
{
    return [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, index)];
}

-(NSDate *)readDateAtColumn:(int)index fromFromSQLiteStatement:(sqlite3_stmt *)statement
{
    return [NSDate dateWithTimeIntervalSince1970:[self readTimeIntervalAtColumn:index fromFromSQLiteStatement:statement]];
}

-(NSTimeInterval)readTimeIntervalAtColumn:(int)index fromFromSQLiteStatement:(sqlite3_stmt *)statement
{
    return sqlite3_column_double(statement, index);
}

-(NSData *)readDataAtColumn:(int)index fromFromSQLiteStatement:(sqlite3_stmt *)statement
{
    return [[NSData alloc] initWithBytes:(const char *) sqlite3_column_blob(statement, index) length:sqlite3_column_bytes(statement, index)];
}

@end
