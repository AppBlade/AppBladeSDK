//
//  APBDataManager.h
//  AppBlade
//
//  Created by AndrewTremblay on 11/30/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

#import "AppBladeDatabaseColumn.h"
#import "AppBladeDatabaseConstants.h"

static NSString* const kAppBladeDatabaseName        = @"AppBlade.sqlite";
static NSString* const kAppBladeDatabaseTextEncoding= @"UTF-8"; //Cannot currently be changed. Still here for prescience.
static int const kAppBladeDatabaseVersion           = 0; //For internal use only. (should link to PRAGMA user_version;)

//major design structure
//every table has an index column for keyvalue and reference (preferably called id)
//all columns can be null, though a default value can be declared (via additional args)


@class APBDataManager;
@protocol APBDataManagerDelegate <NSObject>
-(APBDataManager *)getDataManager;
@end

@interface APBDataManager : NSObject
-(NSString *)getDatabaseFilePath;
-(NSString *)getDocumentsSubFolderPath; //the sql file is stored somewhere in documents

+(NSError *)dataBaseErrorWithMessage:(NSString *)msg; //useful internal for all the error messages

+(NSString *)defaultIdColumnDefinition; //the default id column definition dictionary, since it is used so widely elsewhere.

-(AppBladeDatabaseColumn *)generateReferenceColumn:(NSString *)columnName forTable:(NSString *)tableName;

//careful with this one
-(NSError *)executeArbitrarySqlQuery:(NSString *)query;

//table functions (table will always create at least one column named "id" for the primary key
-(BOOL)tableExistsWithName:(NSString *)tableName;
-(NSError *)createTable:(NSString *)tableName withColumns:(NSArray *)columnData;
-(NSError *)removeTable:(NSString *)tableName;

//row functions
-(NSError *)addRow:(NSDictionary *)newRow toTable:(NSString *)tableName;

-(NSError *)addOrUpdateRow:(NSDictionary *)row toTable:(NSString *)tableName;
-(NSError *)updateRow:(NSDictionary *)row toTable:(NSString *)tableName;

-(NSError *)removeRow:(NSDictionary *)row fromTable:(NSString *)tableName;

@end
