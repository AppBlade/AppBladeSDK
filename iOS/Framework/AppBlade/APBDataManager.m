//
//  APBDataManager.m
//  AppBlade
//
//  Created by AndrewTremblay on 11/30/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//

#import "APBDataManager.h"
#import "AppBladeLogging.h"

#import "AppBladeDatabaseColumn.h"

/*!
 The datamanager is feature agnostic. It should only concern itself with evaluating SQL queries, whatever they may be.
*/
@implementation APBDataManager

#pragma mark - Initializers & Global functions

-(id)init{
    if((self = [super init])) {
        NSError *error = nil;
        //check existence of the AppBlade subfolder
        NSString *dataFolder = [self getDocumentsSubFolderPath];
        if (![[NSFileManager defaultManager] fileExistsAtPath:dataFolder]){
            ABDebugLog_internal(@"Creating %@", dataFolder);
            [[NSFileManager defaultManager] createDirectoryAtPath:dataFolder withIntermediateDirectories:YES attributes:nil error:&error]; //Create folder
        }
        if(error != nil){
            ABErrorLog(@"Critical error! Could not create directory %@. Reason: %@", dataFolder, error.description);
        }
        
        //create or migrate the database
        NSString *dataBase = [self getDatabaseFilePath];
        if (![[NSFileManager defaultManager] fileExistsAtPath:dataBase]){
            ABDebugLog_internal(@"Creating the database %@", dataBase);
        }else {
            if ([self shouldMigrateDatabase]){
                ABDebugLog_internal(@"Database exists but must be updated.");
                //do any migration logic here
            }else{
                ABDebugLog_internal(@"Database exists and does not require updating.");
                //confirm the database version is up to date.
            }
        }
        

    }
    return self;
}

-(BOOL)shouldMigrateDatabase
{
    return FALSE; //This is reserved for point releases to the SDK, not to be confused with App-level updates.
}

-(NSString *)getDocumentsSubFolderPath
{
    return [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/AppBlade"];
}

-(NSString *)getDatabaseFilePath
{
    
    return [[self getDocumentsSubFolderPath] stringByAppendingPathComponent:kAppBladeDataBaseName];
}

+(NSError *)dataBaseErrorWithMessage:(NSString *)msg
{
    return [NSError errorWithDomain:@"AppBlade Database"
                               code:200
                           userInfo:[NSDictionary dictionaryWithObjectsAndKeys:msg, NSLocalizedDescriptionKey, nil]];
}
/*!
 INSERT INTO table-name DEFAULT VALUES
 
 INSERT INTO table-name ( column-name1, column-name2) VALUES (aValue1, aValue2), (bValue1, bValue2)
 
 DELETE FROM table-name WHERE expression
 
 UPDATE table-name SET column-name=expresssion WHERE expressions
 */
-(NSError *)executeArbitrarySqlQuery:(NSString *)query
{
    const char *dbpath = [self.getDatabaseFilePath UTF8String];
    sqlite3 *myDB;
    if (sqlite3_open(dbpath, &myDB) == SQLITE_OK) {
        int results = 0;
        const char *querySQL = [query UTF8String];
        sqlite3_stmt * queryStatement = nil;
        results = sqlite3_exec(myDB, querySQL, NULL, NULL, NULL);
        if (results != SQLITE_DONE) {
            const char *err = sqlite3_errmsg(myDB);
            NSString *errMsg = [NSString stringWithFormat:@"%s",err];
            if (![errMsg isEqualToString:@"not an error"]) {
                return [APBDataManager dataBaseErrorWithMessage:errMsg];
            }
        }
        sqlite3_finalize(queryStatement);
        sqlite3_close(myDB);
        return nil;
    } else {
        return [APBDataManager dataBaseErrorWithMessage:@"Could not open database."];
    }
    return nil;

}




#pragma mark -
#pragma mark Table functions
-(NSError *)createTable:(NSString *)tableName
{
    const char *dbpath = [self.getDatabaseFilePath UTF8String];
    sqlite3 *myDB;
    if (sqlite3_open(dbpath, &myDB) == SQLITE_OK) {
        
        NSString *createTableQuery = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(id INTEGER PRIMARY KEY)", tableName];
        
        int results = 0;
        //create all chars tables
        const char *createTableQuerySQL = [createTableQuery UTF8String];
        sqlite3_stmt * createTableQueryStatement = nil;
        results = sqlite3_exec(myDB, createTableQuerySQL, NULL, NULL, NULL);
        if (results != SQLITE_DONE) {
            const char *err = sqlite3_errmsg(myDB);
            NSString *errMsg = [NSString stringWithFormat:@"%s",err];
            if (![errMsg isEqualToString:@"not an error"]) {
                return [APBDataManager dataBaseErrorWithMessage:errMsg];
            }
        }
        
        sqlite3_finalize(createTableQueryStatement);
        sqlite3_close(myDB);
        
        return nil;
    }else{
        return [APBDataManager dataBaseErrorWithMessage:@"database not opened"];
    }
}

/*
 columnDict format :
 @[  @{@"columnName":@"id", @"columnType":@"NUMBER", @"columnConstraints":costraintEnum, @"columnAdditionalArgs":@""},
     @{@"columnName":@"createdAt", @"columnType":@"TEXT", @"additionalArgs":@""},  
     @{@"columnName":@"updatedAt", @"columnType":@"TEXT"}
 ]
*/

-(NSError *)createTable:(NSString *)tableName withColumns:(NSArray *)columnData
{
    const char *dbpath = [self.getDatabaseFilePath UTF8String];
    sqlite3 *myDB;
    if (sqlite3_open(dbpath, &myDB) == SQLITE_OK) {
        
        NSString *createTableQuery = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(id INTEGER PRIMARY KEY", tableName];

        for(NSMutableDictionary* col in columnData){
            createTableQuery = [NSString stringWithFormat:@"%@, %@", createTableQuery, [col toSQLiteColumnDefinition]];
        }
        createTableQuery = [NSString stringWithFormat:@"%@)", createTableQuery];
        
        int results = 0;
        //create all chars tables
        const char *createTableQuerySQL = [createTableQuery UTF8String];
        sqlite3_stmt * createTableQueryStatement = nil;
        results = sqlite3_exec(myDB, createTableQuerySQL, NULL, NULL, NULL);
        if (results != SQLITE_DONE) {
            const char *err = sqlite3_errmsg(myDB);
            NSString *errMsg = [NSString stringWithFormat:@"%s",err];
            if (![errMsg isEqualToString:@"not an error"]) {
                return [APBDataManager dataBaseErrorWithMessage:errMsg];
            }
        }
        
        sqlite3_finalize(createTableQueryStatement);
        sqlite3_close(myDB);
        
        return nil;
    }else{
        return [APBDataManager dataBaseErrorWithMessage:@"database not opened"];
    }
}

-(NSError *)removeTable:(NSString *)tableName
{
    const char *dbpath = [self.getDatabaseFilePath UTF8String];
    sqlite3 *myDB;
    if (sqlite3_open(dbpath, &myDB) == SQLITE_OK) {
        
        NSString *deleteTableQuery = [NSString stringWithFormat:@"DROP TABLE IF EXISTS %@", tableName];
        
        int results = 0;
        //create all chars tables
        const char *deleteTableQuerySQL = [deleteTableQuery UTF8String];
        sqlite3_stmt * deleteTableQueryStatement = nil;
        results = sqlite3_exec(myDB, deleteTableQuerySQL, NULL, NULL, NULL);
        if (results != SQLITE_DONE) {
            const char *err = sqlite3_errmsg(myDB);
            NSString *errMsg = [NSString stringWithFormat:@"%s",err];
            if (![errMsg isEqualToString:@"not an error"]) {
                return [APBDataManager dataBaseErrorWithMessage:errMsg];
            }
        }
        
        sqlite3_finalize(deleteTableQueryStatement);
        sqlite3_close(myDB);
        
        return nil;
    }else{
        return [APBDataManager dataBaseErrorWithMessage:@"database not opened"];
    }
}
#pragma mark Column functions
-(NSError *)addColumns:(NSArray *)columns toTable:(NSString *)tableName {
#warning Dangerous. Messy. We have no way of knowing which columns were added. Wrap this in a better SQL query
    for (NSDictionary *column in columns) {
        NSError *e = [self addColumn:column toTable:tableName];
        if(e != nil)
            return e;
    }
    return nil;
}
//column functions (these are kinda dumb right now, we aren't expecting the tables to change after they're created. 
-(NSError *)addColumn:(NSDictionary *)column toTable:(NSString *)tableName
{
#warning incomplete
    return nil;
}

-(NSError *)addColumn:(NSString *)columnName withConstraints:(AppBladeColumnConstraint)constraints toTable:(NSString *)tableName
{
    return [self addColumn:columnName withConstraints:constraints withAdditionalArgs:nil toTable:tableName];
}

-(NSError *)addColumn:(NSString *)columnName withConstraints:(AppBladeColumnConstraint)constraints withAdditionalArgs:(NSString *)args toTable:(NSString *)tableName{
#warning incomplete
    return nil;
}

-(NSError *)removeColumn:(NSString *)columnName fromTable:(NSString *)tableName{
#warning incomplete
    return nil;
}


#pragma mark Row functions
-(NSError *)addRow:(NSDictionary *)newRow toTable:(NSString *)tableName {
#warning incomplete
    return nil;
}

-(NSError *)removeRow:(NSDictionary *)row fromTable:(NSString *)tableName {
#warning incomplete
    return nil;
}


-(NSError *)addRows:(NSArray *)newRows toTable:(NSString *)tableName {
#warning incomplete
    return nil;
}

-(NSError *)removeRows:(NSArray *)rows fromTable:(NSString *)tableName {
#warning incomplete
    return nil;
}


-(NSDictionary *)getFirstRowFromCriteria:(NSDictionary *)rowCriteria fromTable:(NSString *)tableName error:(NSError *)error {
#warning incomplete
    return nil;
}

-(NSArray *)getAllRowsFromCriteria:(NSDictionary *)rowCriteria fromTable:(NSString *)tableName error:(NSError *)error
{
#warning incomplete
    return nil;
}

-(NSError *)updateRow:(NSDictionary *)row toTable:(NSString *)tableName {
#warning incomplete
    return nil;
}

-(NSError *)addOrUpdateRow:(NSDictionary *)row toTable:(NSString *)tableName
{
#warning incomplete
    return nil;
}




@end
