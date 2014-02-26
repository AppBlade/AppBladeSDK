//
//  AppBladeDatabaseObject.m
//  AppBlade
//
//  Created by AndrewTremblay on 12/9/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//
#import "AppBladeDatabaseObject.h"
#import "AppBladeDatabaseColumn.h"

#import "APBDataManager.h"

//For the snapshot
#import "AppBladeLogging.h"
#import "AppBlade.h"
#import "APBApplicationInfoManager.h"
#import "APBDeviceInfoManager.h"


@interface AppBladeDatabaseObject()
//@property (nonatomic, strong, readwrite, getter = getId) NSString *dbRowId; //we need to be able to set this

@end

@implementation AppBladeDatabaseObject

#pragma mark - Base Snapshot Info

-(void)takeFreshSnapshot
{ //loads all snapshot data from their relevant locations
    self.createdAt = [NSDate new];
    self.executableIdentifier = [[AppBlade sharedManager] executableUUID];
    self.deviceVersionSanitized = [[AppBlade sharedManager] iosVersionSanitized];
    self.deviceName  = [[UIDevice currentDevice] name];                  //device name when this row was created
    self.activeToken = [[AppBlade sharedManager] appBladeDeviceSecret];  //the token when this row was created
}

//will always begin with @"id", followed by our snapshot columns
-(NSString *)columnNames {
    NSMutableArray *toRet = [NSMutableArray arrayWithArray:[self baseColumnNames] ];
    [toRet addObjectsFromArray:[self additionalColumnNames]];
    return [toRet componentsJoinedByString:@", "];
}

//will always begin with the id value, or null, followed by our snapshot values
-(NSString *)columnValues {
    NSMutableArray *toRet = [NSMutableArray arrayWithArray:[self baseColumnValues] ];
    [toRet addObjectsFromArray:[self additionalColumnValues]];
    return [toRet componentsJoinedByString:@", "];//default column increments silently
}

//usage [obj removeIdColumn:[obj columnValues]];
-(NSString *)removeIdColumn:(NSString *)commaSeparatedList //technically this function removes ANY column that begind the list, but we only use it for the case of id
{
    NSRange indexOfFirstComma = [commaSeparatedList rangeOfString:@","];
    return [commaSeparatedList substringFromIndex:(indexOfFirstComma.location + indexOfFirstComma.length)];
}

//id column must always come first, unless the data hasn't been written yet
-(NSArray *)baseColumnNames {  return @[ @"id",  @"snapshot_created_at",  @"snapshot_exec_id",  @"snapshot_device_version" ]; }

-(NSArray *)baseColumnValues {
        return @[ [self sqlFormattedProperty: self.dbRowId],
                  [self sqlFormattedProperty: self.createdAt],
                  [self sqlFormattedProperty: self.executableIdentifier],
                  [self sqlFormattedProperty: self.deviceVersionSanitized]];
}
#pragma mark - Additional columns

-(NSArray *)additionalColumnNames {  return @[ ]; }

-(NSArray *)additionalColumnValues { return @[ ];  }

#pragma mark - Write methods

-(NSString *)sqlFormattedProperty:(id)propertyValue
{
    //case check for whatever is passed?
    if(propertyValue == nil){
        return @"NULL";
    }
    
    if([propertyValue isKindOfClass:[NSString class]])
    {
        return [NSString stringWithFormat:@"\"%@\"", (NSString *)propertyValue];
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

-(NSError *)bindDataToPreparedStatement:(sqlite3_stmt *)statement { return nil;  } //default implementation does nothing


#pragma mark - Read methods

-(NSError *)readFromSQLiteStatement:(sqlite3_stmt *)statement
{
    ABDebugLog_internal(@"READING IN BASE DATABASE OBJECT VALUES");

    NSString *dbRowIdCheck = [[NSString alloc] initWithUTF8String:
                              (const char *) sqlite3_column_text(statement, 0)];
    if(dbRowIdCheck == nil){
        NSError *error = [[NSError alloc] initWithDomain:@"AppBladeDatabaseObject" code:0 userInfo:nil];
        return error;
    }
    self.dbRowId = dbRowIdCheck;
    //read in the core values (TODO: only read them in when we need them)
    self.createdAt = [NSDate dateWithTimeIntervalSince1970: sqlite3_column_double(statement, 1)];
    //    self.createdAt  = [NSDate date];
    self.executableIdentifier = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 2)];
    //    self.executableIdentifier = [[AppBlade sharedManager] executableUUID];
    self.deviceVersionSanitized = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 3)];
    //    self.deviceVersionSanitized = [[AppBlade sharedManager] iosVersionSanitized];
    return nil;
}

-(void)setIdFromDatabaseStatement:(NSInteger)rowId
{
    self.dbRowId = [NSString stringWithFormat:@"%ld", (long)rowId];
}

//column reads (writes have the values embedded into the sql statement, so we shouldn't need to bind them.)
-(NSData *)readDataInAdditionalColumn:(NSNumber *)indexOffset fromSQLiteStatement:(sqlite3_stmt *)statement
{
    NSNumber *actualIndex = [NSNumber numberWithUnsignedLong:([[self baseColumnNames] count] - (NSUInteger)1 + [indexOffset integerValue])];
    return [[NSData alloc] initWithBytes:(const char *) sqlite3_column_blob(statement, [actualIndex intValue]) length:sqlite3_column_bytes(statement, indexOffset)];
}

-(NSString *)readStringInAdditionalColumn:(NSNumber *)indexOffset fromSQLiteStatement:(sqlite3_stmt *)statement
{
    NSNumber *actualIndex = [NSNumber numberWithUnsignedLong:(([[self baseColumnNames] count] - 1) + [indexOffset integerValue])];
    //confirm we have a column at that index
    ABDebugLog_internal(@"DB READ ADDIT'L STRING AT INDEX OFFSET: %ld ( Actual: %ld )", (long)[indexOffset integerValue], (long)[actualIndex integerValue]);
    
    int totalColumns = sqlite3_column_count(statement);
    if(totalColumns > [actualIndex intValue]){
        NSString *retrievedString = nil;
        if([self columnTypeAtIndex:actualIndex fromSQLiteStatement:statement] == SQLITE_TEXT){
            char *sqlite_text = (char *)sqlite3_column_text(statement, actualIndex);
            NSString *retrievedString = (sqlite_text) ? [NSString stringWithUTF8String:sqlite_text] : nil; //"safe"
            if(!retrievedString) {
                ABErrorLog(@"DB ERROR: String should never be nil");
            }else{
                ABDebugLog_internal(@"DB READ STRING %@", retrievedString);
            }
        }else{
            ABErrorLog(@"DB ERROR: column is not text");
        }
        return retrievedString;
    }else
    {
        ABDebugLog_internal(@"Index out of bounds: %d", [actualIndex intValue]);
        return nil;
    }
}

-(NSDate *)readDateInAdditionalColumn:(NSNumber *)indexOffset fromSQLiteStatement:(sqlite3_stmt *)statement
{
    return [NSDate dateWithTimeIntervalSince1970:[self readTimeIntervalInAdditionalColumn:indexOffset fromSQLiteStatement:statement]];
}

-(NSTimeInterval)readTimeIntervalInAdditionalColumn:(NSNumber *)indexOffset fromSQLiteStatement:(sqlite3_stmt *)statement
{
    NSNumber *actualIndex = [NSNumber numberWithUnsignedLong:([[self baseColumnNames] count] - 1 + [indexOffset integerValue])];
    //adding NSUinteger to an NSInteger and then blindly assuming it's an int
    return sqlite3_column_double(statement, [actualIndex intValue]);
}


-(int)columnTypeAtIndex:(NSNumber *)columnIndex fromSQLiteStatement:(sqlite3_stmt *)statement
{
    return sqlite3_column_type(statement, columnIndex);
}

#pragma mark - Delete methods
/*! Helper method to remove any external files (or other dependencies) right before the row is stricken from the database.  */
-(NSError *)cleanUpIntermediateData {    return nil; }


#pragma mark - Formatted sql statements
// we can't select a data object that hasn't yet been written to a table
-(NSString *)formattedSelectSqlStringForTable: (NSString *)tableName
{
    if([self getId] == nil){
        return nil;
    }
    
    return [NSString stringWithFormat:@"SELECT * FROM %@ WHERE id='%@'",
            tableName,
            [self getId ] ];
}


-(NSString *)formattedCreateSqlStringForTable:(NSString *)tableName
{
    NSString *adjustedColumnNames = [self removeIdColumn:[self columnNames]];
    NSString *adjustedColumnValues = [self removeIdColumn:[self columnValues]];
    
    return [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)",
            tableName, adjustedColumnNames, adjustedColumnValues];
}

-(NSString *)formattedUpsertSqlStringForTable:(NSString *)tableName
{
    if([self getId] == nil){ //no id means the object isn't in a table yet
        return [self formattedCreateSqlStringForTable:tableName];
    }else{
        return [NSString stringWithFormat:@"INSERT OR REPLACE INTO %@ (%@) VALUES (%@)",
                tableName,
                [self columnNames],
                [self columnValues]];
    }
}

//will return nil if the getId is nil
-(NSString *)formattedDeleteSqlStringForTable:(NSString *)tableName
{
    if([self getId] == nil){
        return nil;
    }
    
    return [NSString stringWithFormat:@"DELETE FROM %@ WHERE id='%@'",
            tableName,
            [self getId ] ];
}


@end
