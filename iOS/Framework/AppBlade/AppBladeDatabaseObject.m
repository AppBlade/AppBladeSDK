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
    return [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)",
            tableName,
            [self removeIdColumn:[self columnNames]],
            [self removeIdColumn:[self columnValues]]];
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

//will not return valid string if the ID is not defined
-(NSString *)formattedDeleteSqlStringForTable:(NSString *)tableName
{
    if([self getId] == nil){
        return nil;
    }
    
    return [NSString stringWithFormat:@"DELETE * FROM %@ WHERE id='%@'",
            tableName,
            [self getId ] ];
}

-(NSError *)readFromSQLiteStatement:(sqlite3_stmt *)statement
{
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

-(NSArray *)baseColumnValues { return @[ self.dbRowId, self.createdAt, self.executableIdentifier,  self.deviceVersionSanitized ];  }

-(NSArray *)additionalColumnNames {  return @[ ]; }

-(NSArray *)additionalColumnValues { return @[ ];  }

-(NSError *)bindDataToPreparedStatement:(sqlite3_stmt *)statement { return nil;  }


-(void)setIdFromDatabaseStatement:(sqlite3_stmt *)statement
{
    NSString *idCheck = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
    
    NSLog(@"%@", idCheck);
}

//column reads (writes have the values embedded into the sql statement, so we shouldn't need to bind them.)
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
