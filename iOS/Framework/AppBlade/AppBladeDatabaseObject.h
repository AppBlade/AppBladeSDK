//
//  AppBladeDatabaseObject.h
//  AppBlade
//
//  Created by AndrewTremblay on 12/9/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

//represents a single row in a table
@interface AppBladeDatabaseObject : NSObject
//
//    @property (nonatomic, strong) NSString *tableName; //the table this object currently resides
    @property (nonatomic, strong, readonly, getter = getId) NSString *dbRowId; //the id this row has in the table

-(NSString *)SqlFormattedProperty:(id)propertyValue;

-(NSString *)insertSqlIntoTable:(NSString *)tableName;
-(NSError *)readFromSQLiteStatement:(sqlite3_stmt *)statement;

-(NSString *)readStringAtColumn:(int)index fromFromSQLiteStatement:(sqlite3_stmt *)statement;
-(NSDate *)readDateAtColumn:(int)index fromFromSQLiteStatement:(sqlite3_stmt *)statement;
-(NSTimeInterval)readTimeIntervalAtColumn:(int)index fromFromSQLiteStatement:(sqlite3_stmt *)statement;
-(NSData *)readDataAtColumn:(int)index fromFromSQLiteStatement:(sqlite3_stmt *)statement;


@end
