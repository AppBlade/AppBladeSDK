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
//every table has an index column for keyvalue and reference (called id)
//all columns can be null, though a default value can be declared (via additional args)

//sqlite does not enforce types, they instead use affinities
typedef NS_OPTIONS(NSUInteger, AppBladeColumnConstraint) {
    AppBladeColumnConstraintNone                    = 0,
    AppBladeColumnConstraintNotNull                 = 1 <<  1,
    AppBladeColumnConstraintAffinityText             = 1 <<  2,
    AppBladeColumnConstraintAffinityNumeric          = 1 <<  3,
    AppBladeColumnConstraintAffinityInteger          = 1 <<  4,
    AppBladeColumnConstraintAffinityReal             = 1 <<  5,
    AppBladeColumnConstraintAffinityNone             = 1 <<  6, //no multiple affinities, please
    AppBladeColumnConstraintPrimaryKey              = 1 <<  7, //can cause memory issues
    AppBladeColumnConstraintUnique                  = 1 <<  8,
    AppBladeColumnConstraintAutoincrement           = 1 <<  9
};  //todo1: more sql-related datatypes.
    //todo2: increment, sorting, maybe link foreign keys into this enum somehow

static NSString* const kAppBladeColumnAffinityText      = @"TEXT";
static NSString* const kAppBladeColumnAffinityNumeric   = @"NUMERIC";
static NSString* const kAppBladeColumnAffinityInteger   = @"INTEGER";
static NSString* const kAppBladeColumnAffinityReal      = @"REAL";
static NSString* const kAppBladeColumnAffinityNone      = @"NONE";

static NSString* const kAppBladeColumnStorageTypeNull    = @"NULL";
static NSString* const kAppBladeColumnStorageTypeInteger = @"INTEGER";
static NSString* const kAppBladeColumnStorageTypeReal  = @"REAL";
static NSString* const kAppBladeColumnStorageTypeText  = @"TEXT";
static NSString* const kAppBladeColumnStorageTypeBlob  = @"BLOB";

//Foreign Key
static NSString* const kAppBladeDatabaseForeignKeyFormat  = @"FOREIGN KEY(%@) REFERENCES %@(%@)"; //existing_column_name, secondary_table_name, secondary_existing_column (likely id)

//default values must be handled separately, same with other CHECK functions, those can go in AdditionalArgs for now

//in the case of AppBladeDataBaseColumnTypeReference, pass a dictionary with {reftype, reference-table-name, index-value(s)},
typedef NS_OPTIONS(NSUInteger, AppBladeDataBaseRefType) {
    AppBladeDataBaseRefTypeInvalid                      = 0,
    AppBladeDataBaseRefTypeOneToOne                     = 1 << 1,
    AppBladeDataBaseRefTypeManyToOne                    = 1 << 2,
    AppBladeDataBaseRefTypeOneToMany                    = 1 << 3
};


@class APBDataManager;
@protocol APBDataManagerDelegate <NSObject>

-(BOOL)dataBaseExists;
-(APBDataManager *)getDataManager;

@end

@interface APBDataManager : NSObject
-(NSString *)getDatabaseFilePath;
-(NSString *)getDocumentsSubFolderPath; //the sql file is stored somewhere in documents

+(NSError *)dataBaseErrorWithMessage:(NSString *)msg; //useful internal for all the error messages

//careful with this one
-(NSError *)executeArbitrarySqlQuery:(NSString *)query;

//table functions (table will always create at least one column named "id" for the primary key
-(NSError *)createTable:(NSString *)tableName withColumns:(NSArray *)columnData;
-(NSError *)removeTable:(NSString *)tableName;

//column functions (probably not going to be used all that much, since the tables probably aren't going to be changed after initilization)
-(NSError *)addColumns:(NSArray *)columns toTable:(NSString *)tableName;
-(NSError *)addColumn:(NSDictionary *)column toTable:(NSString *)tableName;
-(NSError *)removeColumn:(NSString *)columnName fromTable:(NSString *)tableName;

//row functions
-(NSError *)addRow:(NSDictionary *)newRow toTable:(NSString *)tableName;
-(NSError *)addRows:(NSArray *)newRows toTable:(NSString *)tableName;

-(NSError *)addOrUpdateRow:(NSDictionary *)row toTable:(NSString *)tableName;
-(NSError *)updateRow:(NSDictionary *)row toTable:(NSString *)tableName;

//Will return the data in the row as a dictionary, or nil with an NSError
-(NSDictionary *)getFirstRowFromCriteria:(NSDictionary *)rowCriteria fromTable:(NSString *)tableName error:(NSError *)error;
-(NSArray *)getAllRowsFromCriteria:(NSDictionary *)rowCriteria fromTable:(NSString *)tableName error:(NSError *)error;

-(NSError *)removeRows:(NSArray *)rows fromTable:(NSString *)tableName;
-(NSError *)removeRow:(NSDictionary *)row fromTable:(NSString *)tableName;

@end
