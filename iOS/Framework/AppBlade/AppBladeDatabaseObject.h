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
    @property (nonatomic, strong) NSString *tableName; //the table this object was read from
    @property (nonatomic, strong, readonly, getter = getId) NSString *dbRowId; //the id this row has in the table
                                                                               //dbRowId is linked to column "id"
    //snapshot datetime
    @property (nonatomic, strong) NSDate *createdAt;
    //snapshot data:
    //when a new row is created, all the necessary data about the app and device should be stored, as it is subject to change
    //e.g. An app update, or an OS update.
    @property (nonatomic, strong) NSString *executableIdentifier;    //build identifier when this row was created
    @property (nonatomic, strong) NSString *deviceName;              //device name when this row was created

    //the database object subclasses are expected to override these methods
    -(NSArray *)additionalColumnNames; //default implementation is an empty array
    -(NSArray *)additionalColumnValues; //default implementation is an empty array

    //reads in and populates properties from the appropriate values in the sqlite statement
    -(NSError *)readFromSQLiteStatement:(sqlite3_stmt *)statement; //this method should 
    //helper methods for additional columns (subclasses shouldn't need to keep track of the offset)
    -(NSString *)readStringInAdditionalColumn:(int)index fromFromSQLiteStatement:(sqlite3_stmt *)statement;
    -(NSDate *)  readDateInAdditionalColumn:(int)index fromFromSQLiteStatement:(sqlite3_stmt *)statement;
    -(NSData *)  readDataInAdditionalColumn:(int)index fromFromSQLiteStatement:(sqlite3_stmt *)statement;
    -(NSTimeInterval)readTimeIntervalInAdditionalColumn:(int)index fromFromSQLiteStatement:(sqlite3_stmt *)statement;

    -(NSString *)sqlFormattedProperty:(id)propertyValue;

    -(NSString *)formattedSelectSqlStringForTable: (NSString *)tableName;
    -(NSString *)formattedInsertSqlStringForTable: (NSString *)tableName;
    -(NSString *)formattedReplaceSqlStringForTable:(NSString *)tableName;

    -(void) writeString:(NSString *)stringVal  toAdditionalColumn:(int)index fromFromSQLiteStatement:(sqlite3_stmt *)statement;
    -(void) writeDate:(NSDate *)dateVal        toAdditionalColumn:(int)index fromFromSQLiteStatement:(sqlite3_stmt *)statement;
    -(void) writeData:(NSData *)dataVal        toAdditionalColumn:(int)index fromFromSQLiteStatement:(sqlite3_stmt *)statement;
    -(void) writeTimeInterval:(NSTimeInterval)intervalVal toAdditionalColumn:(int)index fromFromSQLiteStatement:(sqlite3_stmt *)statement;


@end
