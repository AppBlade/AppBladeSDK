//
//  APBDataManager.h
//  AppBlade
//
//  Created by AndrewTremblay on 11/30/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

static NSString* const kAppBladeDataBaseName        = @"AppBlade.sqlite";
static float const kAppBladeDataBaseVersion         = 0.0;

//major design structure
//every table has an index column for keyvalue and reference
//all columns can be null, though a default value can be declared

typedef NS_OPTIONS(NSUInteger, AppBladeDataBaseColumnType) {
    AppBladeDataBaseColumnTypeNone                         = 0,
    AppBladeDataBaseColumnTypeString                       = 1 <<  1,
    AppBladeDataBaseColumnTypeInteger                      = 1 <<  2,
    AppBladeDataBaseColumnTypeFloat                        = 1 <<  3,
    AppBladeDataBaseColumnTypeDouble                       = 1 <<  4,
    AppBladeDataBaseColumnTypeDateTime                     = 1 <<  5,
    AppBladeDataBaseColumnTypeBlob                         = 1 <<  6,
    AppBladeDataBaseColumnTypeReference                    = 1 <<  7
};


//in the case of AppBladeDataBaseColumnTypeReference, pass a dictionary with {reftype, reference-table-name, index-value(s)},
typedef NS_OPTIONS(NSUInteger, AppBladeDataBaseRefType) {
    AppBladeDataBaseRefTypeInvalid                      = 0,
    AppBladeDataBaseRefTypeOneToOne                     = 1 << 1,
    AppBladeDataBaseRefTypeManyToOne                    = 1 << 2,
    AppBladeDataBaseRefTypeOneToMany                    = 1 << 3
};

@interface APBDataManager : NSObject
-(NSString *)getDatabaseFilePath;
-(NSString *)getDocumentsSubFolderPath;

+(NSError *)dataBaseErrorWithMessage:(NSString *)msg;

//table functions
-(NSError *)createTable:(NSString *)tableName;
-(NSError *)removeTable:(NSString *)tableName;

//column functions
-(NSError *)addColumns:(NSArray *)columns toTable:(NSString *)tableName;
//column functions
-(NSError *)addColumn:(NSString *)columnName ofType:(AppBladeDataBaseColumnType)type toTable:(NSString *)tableName;
-(NSError *)addColumn:(NSString *)columnName ofType:(AppBladeDataBaseColumnType)type withDefaultValue:(id)defaultValue toTable:(NSString *)tableName;
-(NSError *)removeColumn:(NSString *)columnName fromTable:(NSString *)tableName;

//row functions
-(NSError *)addRow:(NSDictionary *)newRow toTable:(NSString *)tableName;
-(NSError *)removeRow:(NSDictionary *)row fromTable:(NSString *)tableName;

-(NSError *)addRows:(NSArray *)newRows toTable:(NSString *)tableName;
-(NSError *)removeRows:(NSArray *)rows toTable:(NSString *)tableName;

//Will return the data in the row as a dictionary, or nil with an NSError
-(NSDictionary *)getFirstRowFromCriteria:(NSDictionary *)rowCriteria fromTable:(NSString *)tableName error:(NSError *)error;
-(NSArray *)getAllRowsFromCriteria:(NSDictionary *)rowCriteria fromTable:(NSString *)tableName error:(NSError *)error;

-(NSError *)updateRow:(NSDictionary *)row toTable:(NSString *)tableName;
-(NSError *)createOrUpdateRow:(NSDictionary *)row toTable:(NSString *)tableName;



@end
