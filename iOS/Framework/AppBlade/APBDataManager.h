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

static NSString* const kAppBladeColumnStorageTypeNull  = @"NULL";
static NSString* const kAppBladeColumnStorageTypeInteger = @"INTEGER";
static NSString* const kAppBladeColumnStorageTypeReal  = @"REAL";
static NSString* const kAppBladeColumnStorageTypeText  = @"TEXT";
static NSString* const kAppBladeColumnStorageTypeBlob  = @"BLOB";

//Foreign Key
static NSString* const kAppBladeDatabaseForeignKeyFormat  = @"FOREIGN KEY(%@) REFERENCES %@(%@)";


//default values must be handled separately, same with other CHECK functions


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

-(NSError *)executeSqlQuery:(NSString *)query;

//table functions (table will always create at least one column named "id" for the primary key
-(NSError *)createTable:(NSString *)tableName withColumns:(NSArray *)columnData;
-(NSError *)removeTable:(NSString *)tableName;

//column functions
-(NSError *)addColumns:(NSArray *)columns toTable:(NSString *)tableName;
//column functions
-(NSError *)addColumn:(NSString *)columnName withConstraints:(AppBladeColumnConstraint)constraints toTable:(NSString *)tableName;
-(NSError *)addColumn:(NSString *)columnName withConstraints:(AppBladeColumnConstraint)constraints withDefaultValue:(id)defaultValue toTable:(NSString *)tableName;
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
