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
    }else if([[propertyValue type] isKindOfClass:[AppBladeDatabaseObject class]]){
        return [(AppBladeDatabaseObject *)propertyValue getId];
    }
    else{
        return @"NULL";
    }
}

-(NSString *)insertSqlIntoTable:(NSString *)tableName
{
    return [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)", tableName, [self columnNames], [self rowValues]];
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


//column read
-(NSString *)readStringAtColumn:(int)index fromFromSQLiteStatement:(sqlite3_stmt *)statement
{
    return [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, index)];
}

-(NSData *)readStringAtColumn:(int)index fromFromSQLiteStatement:(sqlite3_stmt *)statement
{
    return [[NSData alloc] initWithBytes:(const char *) sqlite3_column_blob(statement, index) length:sqlite3_column_bytes(satement, index)];
}

@end
