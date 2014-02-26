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
    @property (nonatomic, strong, getter = getId) NSString *dbRowId; //the id this row has in the table
                                                                               //rowid is linked to column "id"
#pragma mark - Base Snapshot Info
    //snapshot datetime
    @property (nonatomic, strong) NSDate *createdAt;
    //snapshot data:
    //when a new row is created, all the necessary data about the app and device should be stored, as it is subject to change
    //e.g. An app update, or an OS update.
    @property (nonatomic, strong) NSString *executableIdentifier;    //build identifier when this row was created
    @property (nonatomic, strong) NSString *deviceVersionSanitized;  //the OS Version when this row was created
    @property (nonatomic, strong) NSString *deviceName;              //device name when this row was created
    @property (nonatomic, strong) NSString *activeToken;             //the token when this row was created
    -(void)takeFreshSnapshot; //loads all snapshot data from their relevant locations

#pragma mark - Additional columns
    //the database object subclasses are expected to override these methods
    -(NSArray *)additionalColumnNames; //default implementation is an empty array
    -(NSArray *)additionalColumnValues; //default implementation is an empty array

#pragma mark - Write methods
-(NSString *)sqlFormattedProperty:(id)propertyValue; // this now depends on whether we read. write, or bind later.
-(NSError *)bindDataToPreparedStatement:(sqlite3_stmt *)statement; //default implementation returns nil

#pragma mark - Read methods
    -(void)setIdFromDatabaseStatement:(NSInteger)rowId;
    //reads in and populates properties from the appropriate values in the sqlite statement
    -(NSError *)readFromSQLiteStatement:(sqlite3_stmt *)statement; //this method should 
    //helper methods for additional columns (subclasses shouldn't need to keep track of the offset)
    -(NSData *)  readDataInAdditionalColumn:(NSNumber *)index   fromSQLiteStatement:(sqlite3_stmt *)statement;
    -(NSString *)readStringInAdditionalColumn:(NSNumber *)index fromSQLiteStatement:(sqlite3_stmt *)statement;
    -(NSDate *)  readDateInAdditionalColumn:(NSNumber *)index   fromSQLiteStatement:(sqlite3_stmt *)statement;
    -(NSTimeInterval)readTimeIntervalInAdditionalColumn:(NSNumber *)index fromSQLiteStatement:(sqlite3_stmt *)statement;

#pragma mark - Delete methods
    -(NSError *)cleanUpIntermediateData;

#pragma mark - Formatted sql statements
    -(NSString *)formattedCreateSqlStringForTable:(NSString *)tableName;
    -(NSString *)formattedSelectSqlStringForTable:(NSString *)tableName;
    -(NSString *)formattedUpsertSqlStringForTable:(NSString *)tableName;
    -(NSString *)formattedDeleteSqlStringForTable:(NSString *)tableName;

@end
