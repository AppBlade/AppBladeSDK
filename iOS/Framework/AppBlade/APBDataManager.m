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

#import "AppBlade.h"

#import "APBDatabaseCustomParameter.h" //for debugging only  

#import "AppBlade.h"

@interface APBDataManager()
//@property (nonatomic) sqlite3 *db;
@end

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
            NSURL *pathURL = [NSURL URLWithString:dataFolder];
            [pathURL setResourceValue:[NSNumber numberWithBool:YES]
                               forKey:NSURLIsExcludedFromBackupKey
                                error:nil]; //keep the database around, but exclude the AppBlade folder from iCloud backup
        }
        if(error != nil){
            ABErrorLog(@"Critical error! Could not create directory %@. Reason: %@", dataFolder, error.description);
        }
        
        //create or migrate the database
        NSString *dataBasePath = [self getDatabaseFilePath];

        if (![[NSFileManager defaultManager] fileExistsAtPath:dataBasePath]){
            ABDebugLog_internal(@"Creating the database");
            if ([self prepareTransaction] == SQLITE_OK)
            {
                //set our user version
                const char *sqlStatement = [[NSString stringWithFormat:@"PRAGMA user_version = %d;", kAppBladeDatabaseVersion] UTF8String];
                char *error;
                sqlite3_exec(_db, sqlStatement, NULL, NULL, &error);
                [self finishTransaction];
            }
            if(error != nil){
                ABErrorLog(@"Critical error! Could not create database %@. Reason: %@", dataFolder, error.description);
            }
        }else {
            if ([self shouldMigrateDatabase]){
                ABDebugLog_internal(@"Database exists but must be updated.");
                //do any migration logic here
            }else{
                ABDebugLog_internal(@"Database exists and does not require updating.");
                //confirm the database version is up to date.
            }
        }

        //debug, see what options were created in our database
        ABDebugLog_internal(@"Reading options in the database.");
        NSArray *options = [self compiledDatabaseOptions];
        for (NSString *s in options) {
            ABDebugLog_internal(@"%@", s);
        }
    }
    return self;
}

-(NSString *)getDocumentsSubFolderPath
{
    return [NSHomeDirectory() stringByAppendingPathComponent:@"tmp/AppBlade"];
}

-(NSString *)getDatabaseFilePath
{
    
    return [[self getDocumentsSubFolderPath] stringByAppendingPathComponent:kAppBladeDatabaseName];
}

+(NSError *)dataBaseErrorWithMessage:(NSString *)msg
{
    return [NSError errorWithDomain:@"AppBlade Database"
                               code:200
                           userInfo:[NSDictionary dictionaryWithObjectsAndKeys:msg, NSLocalizedDescriptionKey, nil]];
}

+(NSString *)defaultIdColumnDefinition
{
    return @"id INTEGER PRIMARY KEY AUTOINCREMENT";
}

+(NSString *)snapshotColumnsDefinitions
{
    return @"snapshot_created_at TEXT, snapshot_exec_id TEXT, snapshot_device_version TEXT";
}



+(NSString *)sqlQueryToTrimTable:(NSString *) origTable toColumns:(NSArray *)columns
{
    NSString *colNamesCommaSeparated = [columns componentsJoinedByString:@", "];
    return [NSString stringWithFormat:
             @"CREATE TEMPORARY TABLE %@_backup(%@);"
               "INSERT INTO %@_backup SELECT %@ FROM %@;"
               "DROP TABLE %@;"
               "CREATE TABLE %@(%@);"
               "INSERT INTO %@ SELECT %@ FROM %@_backup;"
               "DROP TABLE %@_backup;"
               "COMMIT;",
               origTable, colNamesCommaSeparated,
               origTable, colNamesCommaSeparated, origTable,
               origTable,
               origTable, colNamesCommaSeparated,
               origTable, colNamesCommaSeparated, origTable,
               origTable
               ];
}

-(AppBladeDatabaseColumn *)generateReferenceColumn:(NSString *)columnName forTable:(NSString *)tableName{
    return [AppBladeDatabaseColumn initColumnNamed:columnName
                                    withContraints:AppBladeColumnConstraintAffinityInteger 
                                    additionalArgs:[NSString stringWithFormat:kAppBladeDatabaseForeignKeyFormat, columnName, @"id", tableName]];
}

-(BOOL)shouldMigrateDatabase
{
    return ([self storedDatabaseVersion] < kAppBladeDatabaseVersion); //This is an internal check reserved for point releases to the SDK, not to be confused with App-level updates (handled within the keychain).
}

//preparation methods
-(int)prepareTransaction
{
     sqlite3_open([[self getDatabaseFilePath] UTF8String], &_db);
    //enable foreign keys on every open, just to be thorough
    sqlite3_stmt *enableForeignKey;
    NSString *strsql = [NSString stringWithFormat:@"PRAGMA foreign_keys = ON"];
    const char *sql=(char *)[strsql UTF8String];
    return (sqlite3_prepare_v2(_db, sql,-1, &enableForeignKey, NULL) != SQLITE_OK);
}
-(int)finishTransaction
{
   return sqlite3_close(_db);
}


-(int)storedDatabaseVersion
{
    int databaseVersion = -1;

    static sqlite3_stmt *stmt_version;
    if ([self prepareTransaction] == SQLITE_OK)
    {
        if(sqlite3_prepare_v2(_db, "PRAGMA user_version;", -1, &stmt_version, NULL) == SQLITE_OK) {
            while(sqlite3_step(stmt_version) == SQLITE_ROW) {
                databaseVersion = sqlite3_column_int(stmt_version, 0);
            }
        } else {
            NSLog(@"%s: ERROR Preparing: , %s", __FUNCTION__, sqlite3_errmsg(_db));
        }
        sqlite3_finalize(stmt_version);
    }
    [self finishTransaction];
    
    return databaseVersion;
}


/*
 As of this writing, the options in the compiled sqlite build contain:
 CURDIR,
 ENABLE_FTS3,
 ENABLE_FTS3_PARENTHESIS,
 ENABLE_LOCKING_STYLE=1,
 ENABLE_RTREE,
 OMIT_AUTORESET,
 OMIT_BUILTIN_TEST,
 OMIT_LOAD_EXTENSION,
 TEMP_STORE=1,
 THREADSAFE=2
*/
-(NSArray *)compiledDatabaseOptions
{
    static sqlite3_stmt *stmt_compile_options;
    NSMutableArray* options = [NSMutableArray array];
    NSString* optionString;
    sqlite3 *myDB;
    if (sqlite3_open([[self getDatabaseFilePath] UTF8String], &myDB) == SQLITE_OK) {

    if(sqlite3_prepare_v2(myDB, "PRAGMA compile_options;", -1, &stmt_compile_options, NULL) == SQLITE_OK) {
        while(sqlite3_step(stmt_compile_options) == SQLITE_ROW) {
            optionString = [NSString stringWithUTF8String:((char *)sqlite3_column_text(stmt_compile_options, 0))];
            [options addObject:optionString];
        }
    } else {
        NSLog(@"%s: ERROR Preparing: , %s", __PRETTY_FUNCTION__, sqlite3_errmsg(myDB));
    }
    sqlite3_finalize(stmt_compile_options);
    }
    sqlite3_close(myDB);

    return options;
}



/*!
 INSERT INTO table-name DEFAULT VALUES
 
 INSERT INTO table-name ( column-name1, column-name2) VALUES (aValue1, aValue2), (bValue1, bValue2)
 
 DELETE FROM table-name WHERE expression
 
 UPDATE table-name SET column-name=expresssion WHERE expressions
 */
-(NSError *)executeArbitrarySqlQuery:(NSString *)query
{
    if ([self prepareTransaction] == SQLITE_OK) {
        int results = 0;
        const char *querySQL = [query UTF8String];
        sqlite3_stmt * queryStatement = nil;
        results = sqlite3_exec(_db, querySQL, NULL, NULL, NULL);
        if (results != SQLITE_DONE) {
            const char *err = sqlite3_errmsg(_db);
            NSString *errMsg = [NSString stringWithFormat:@"%s",err];
            if (![errMsg isEqualToString:@"not an error"]) {
                return [APBDataManager dataBaseErrorWithMessage:errMsg];
            }
        }
        sqlite3_finalize(queryStatement);
        [self finishTransaction];
        return nil;
    } else {
        return [APBDataManager dataBaseErrorWithMessage:@"Could not open database."];
    }
    return nil;

}




#pragma mark -
#pragma mark Table functions
-(BOOL)tableExistsWithName:(NSString *)tableName
{
    NSError *errorCheck = nil;  //the table exists if we can open and find the table with no errors
    if ([self prepareTransaction] == SQLITE_OK) {
        NSMutableString *checkTableQuery = [NSMutableString stringWithFormat:@"SELECT * FROM sqlite_master WHERE tbl_name = \"%@\" AND type = \"table\"", tableName];
        
        //create all chars tables
        const char *checkTableQuerySQL = [checkTableQuery UTF8String];
        sqlite3_stmt * checkTableQueryStatement = nil;
        int result = sqlite3_prepare_v2(_db, checkTableQuerySQL,1,  &checkTableQueryStatement, NULL);
        if (result == SQLITE_OK)
        {
            if (sqlite3_step(checkTableQueryStatement) == SQLITE_ROW)
            {
                errorCheck = nil; //found!
            }else{
                errorCheck = [APBDataManager dataBaseErrorWithMessage:@"Not found"];
            }

        }else{
            errorCheck = [APBDataManager dataBaseErrorWithMessage:@"Could not prepare SQL Query"];
        }
        
        sqlite3_finalize(checkTableQueryStatement);
        [self finishTransaction];
    }else{
        errorCheck = [APBDataManager dataBaseErrorWithMessage:@"database not opened"];
    }
    
    return (errorCheck == nil);
}

-(NSMutableDictionary*)tableInfo:(NSString *)table
{
    [self prepareTransaction];
    sqlite3_stmt *sqlStatement;
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    const char *sqlTableInfoQuery = [[NSString stringWithFormat:@"pragma table_info('%s')",[table UTF8String]] UTF8String];
    if(sqlite3_prepare_v2(_db, sqlTableInfoQuery, -1, &sqlStatement, NULL) != SQLITE_OK)
    {
        NSLog(@"Problem with prepare statement tableInfo %@",[NSString stringWithUTF8String:(const char *)sqlite3_errmsg(_db)]);
        
    }
    while (sqlite3_step(sqlStatement)==SQLITE_ROW)
    {
        [result setObject:@"" forKey:[NSString stringWithUTF8String:(char*)sqlite3_column_text(sqlStatement, 1)]];
        
    }
    [self finishTransaction];

    return result;
}


-(BOOL)table:(NSString *)table containsColumn:(NSString *)columnName
{
    NSDictionary *tableDict = [self tableInfo:table];
    return ([tableDict objectForKey:columnName] != nil);
}


-(NSError *)createTable:(NSString *)tableName withColumns:(NSArray *)columnData
{
    ABDebugLog_internal(@"attempting to create %@ : %@", tableName, columnData);

    if ([self prepareTransaction] == SQLITE_OK) {
        //prepare the query given the params
        NSMutableString *createTableQuery = [NSMutableString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(", tableName];
        [createTableQuery appendString:[APBDataManager defaultIdColumnDefinition]];
        [createTableQuery appendFormat:@", %@", [APBDataManager snapshotColumnsDefinitions]];
        ABDebugLog_internal(@"added internal id, exec, and snapshot columns");
        for(AppBladeDatabaseColumn* col in columnData){
            ABDebugLog_internal(@"adding column %@", [col toDictionary]);
            
            [createTableQuery appendFormat:@", %@", [col toSQLiteColumnDefinition]];
        }
        [createTableQuery appendString:@")"];  //close paren
        
        int results = 0;
        //create all chars tables
        const char *createTableQuerySQL = [createTableQuery UTF8String];
        sqlite3_stmt * createTableQueryStatement = nil;
        results = sqlite3_exec(_db, createTableQuerySQL, NULL, NULL, NULL);
        if (results != SQLITE_DONE) {
            const char *err = sqlite3_errmsg(_db);
            NSString *errMsg = [NSString stringWithFormat:@"%s",err];
            if (![errMsg isEqualToString:@"not an error"]) {
                return [APBDataManager dataBaseErrorWithMessage:errMsg];
            }
        }
        
        sqlite3_finalize(createTableQueryStatement);
        [self finishTransaction];
        
        return nil;
    }else{
        return [APBDataManager dataBaseErrorWithMessage:@"database not opened"];
    }
}


-(NSError *)removeTable:(NSString *)tableName
{
    if ([self prepareTransaction] == SQLITE_OK) {
        NSString *deleteTableQuery = [NSString stringWithFormat:@"DROP TABLE IF EXISTS %@", tableName];
        int results = 0;
        //create all chars tables
        const char *deleteTableQuerySQL = [deleteTableQuery UTF8String];
        sqlite3_stmt * deleteTableQueryStatement = nil;
        results = sqlite3_exec(_db, deleteTableQuerySQL, NULL, NULL, NULL);
        if (results != SQLITE_DONE) {
            const char *err = sqlite3_errmsg(_db);
            NSString *errMsg = [NSString stringWithFormat:@"%s",err];
            if (![errMsg isEqualToString:@"not an error"]) {
                return [APBDataManager dataBaseErrorWithMessage:errMsg];
            }
        }
        
        sqlite3_finalize(deleteTableQueryStatement);
        [self finishTransaction];
        return nil;
    }else{
        return [APBDataManager dataBaseErrorWithMessage:@"database not opened"];
    }
}



-(NSError *)alterTable:(NSString *)tableName withTransaction:(APBDataTransaction) transactionBlock
{
    if ([self prepareTransaction] == SQLITE_OK) {
        transactionBlock(_db);
    }else{
        return [APBDataManager dataBaseErrorWithMessage:@"database not opened"];
    }
    return nil;
}


-(NSString *)currentDbErrorMsg
{
    const char *err = sqlite3_errmsg(_db);
    NSString *errMsg = [NSString stringWithFormat:@"%s",err];
    ABErrorLog(@"%@", errMsg);
    return errMsg;
}


#pragma mark Data functions
-(BOOL)data:(AppBladeDatabaseObject*)dataObject existsInTable: (NSString *)tableName
{ //there'a a more efficient way of checking to see the data exists other than loading the entire object from the database
   AppBladeDatabaseObject *dataToFind = [self findDataWithClass:[dataObject class] inTable:tableName withParams:[NSString stringWithFormat:@"id = '%@'", dataObject.getId]];
    return (dataToFind != nil);
}
-(BOOL)dataExistsInTable: (NSString *)tableName withId:(NSString *)rowId {
    //there'a a more efficient way of checking to see the data exists other than loading the entire object from the database
    AppBladeDatabaseObject *dataToFind = [self findDataWithClass:[AppBladeDatabaseObject class] inTable:tableName withParams:[NSString stringWithFormat:@"id = '%@'", rowId]];
    return (dataToFind != nil);
}



//upsert: We either update data if it exists, or insert new data
-(AppBladeDatabaseObject *)upsertData:(AppBladeDatabaseObject *)dataObject toTable:(NSString *)tableName error:(NSError * __autoreleasing *)error
{
    if(dataObject == nil){
        * error = [APBDataManager dataBaseErrorWithMessage:@"no data object passed"];
    }
    sqlite3_stmt    *statement;
    if ([self prepareTransaction] == SQLITE_OK)
    {
        //create the actual sqlite command
        NSString *insertSQL = [dataObject formattedUpsertSqlStringForTable:tableName];
        
        ABDebugLog_internal(@"AB DB : %@", insertSQL);
        const char *insert_stmt = [insertSQL UTF8String];
        if(sqlite3_prepare_v2(_db, insert_stmt, -1, &statement, NULL) == SQLITE_OK){
            //bind any additional data to the upsert statement (like blobs)
            NSError* errorCheck = [dataObject bindDataToPreparedStatement:statement]; // might not do anything, given the specific data object.
            NSString* databaseErrorMessage = [NSString stringWithFormat:@"%s", sqlite3_errmsg(_db)];
            if (errorCheck == nil && [databaseErrorMessage isEqualToString:@"not an error"] && sqlite3_step(statement) == SQLITE_DONE){
                if([dataObject getId] == nil){
                    //then we have to update the data with the id
                    NSInteger lastRow = sqlite3_last_insert_rowid(_db);
                    [dataObject setIdFromDatabaseStatement:lastRow];
                }
                * error = nil;
            } else {
                * error = [APBDataManager dataBaseErrorWithMessage:[NSString stringWithFormat:@"Error during writeData: step %s", sqlite3_errmsg(_db)]];
            }
            sqlite3_finalize(statement);
        }else {
            * error = [APBDataManager dataBaseErrorWithMessage:[NSString stringWithFormat:@"Error during writeData: prepare %s", sqlite3_errmsg(_db)]];
        }
        [self finishTransaction];
    }
    return dataObject;
}

-(void)deleteData:(AppBladeDatabaseObject*)dataObject fromTable:(NSString *)tableName error:(NSError *__autoreleasing *)error
{
    NSError *intermediateDataErrorCheck = [dataObject cleanUpIntermediateData];
    if (intermediateDataErrorCheck) {
        ABErrorLog(@"Error removing intermediate data : %@", [intermediateDataErrorCheck description]);
        *error = intermediateDataErrorCheck;
    }
    sqlite3_stmt    *statement;
    if ([self prepareTransaction] == SQLITE_OK)
    {
        NSString *insertSQL = [dataObject formattedDeleteSqlStringForTable:tableName];
        if(insertSQL == nil){
            * error = [APBDataManager dataBaseErrorWithMessage:[NSString stringWithFormat:@"SQL query string could not be formatted"]];
        }else{
        const char *insert_stmt = [insertSQL UTF8String];
        if(sqlite3_prepare_v2(_db, insert_stmt, -1, &statement, NULL) == SQLITE_OK){
            if ([dataObject bindDataToPreparedStatement:statement] == nil && sqlite3_step(statement) == SQLITE_DONE){
                * error = nil;
            } else {
                * error = [APBDataManager dataBaseErrorWithMessage:[NSString stringWithFormat:@"Error during deleteData: step %s", sqlite3_errmsg(_db)]];
            }
            sqlite3_finalize(statement);
        }else {
            * error = [APBDataManager dataBaseErrorWithMessage:[NSString stringWithFormat:@"Error during deleteData: prepare %s", sqlite3_errmsg(_db)]];
        }
        }
        [self finishTransaction];
    }
}



-(AppBladeDatabaseObject *)findDataWithClass:(Class)classToFind inTable:(NSString *)tableName withParams:(NSString *)params
{
    if (classToFind == nil || ![classToFind isSubclassOfClass:[AppBladeDatabaseObject class]]) { //confirm we passed the right class
        ABErrorLog(@"Class \"%@\" needs to exist and be a subclass of AppBladeDatabaseObject", NSStringFromClass(classToFind));
        return nil;
    }
    AppBladeDatabaseObject *dataToFind = [[classToFind alloc] init]; //initialize the class

    NSError *errorCheck = nil;
    sqlite3_stmt    *statement;
    if ([self prepareTransaction]  == SQLITE_OK)
    {
        NSString *querySQL = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@", tableName, params];
        ABDebugLog_internal(@"AB DB query: %@", querySQL); //build the statement that we need to find the data to read
        const char *query_stmt = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(_db, query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            if (sqlite3_step(statement) == SQLITE_ROW)
            {
                //Match found (posssibly)
                errorCheck = [dataToFind readFromSQLiteStatement:statement]; //read in the data (using the class we overrode)
                if(errorCheck == nil && dataToFind && [dataToFind getId]){
                    ABDebugLog_internal(@"Match found with no errors");
                }else{
                    if (![dataToFind getId]) {
                        //if an id was not set, we did not actually find a match (or complete a read) and no error was thrown (!)
                        errorCheck = [APBDataManager dataBaseErrorWithMessage:@"row id not set"]; //id errors take precedence
                    }else {
                        ABDebugLog_internal(@"DB Error: %s",sqlite3_errmsg(_db));
                        NSString *errMsgFromSql = [NSString stringWithFormat:@"%s", sqlite3_errmsg(_db)];
                        if(errMsgFromSql){
                            errorCheck = [APBDataManager dataBaseErrorWithMessage:errMsgFromSql];
                        }
                    }//otherwise use what's in the errorCheck value
                    ABDebugLog_internal(@"DB ERROR finding match! %@", [errorCheck debugDescription]);
                }
            } else {
                //Match not found
                errorCheck = [APBDataManager dataBaseErrorWithMessage:@"Match not found"];
            }
            sqlite3_finalize(statement);
        }else{
            errorCheck = [APBDataManager dataBaseErrorWithMessage: [NSString stringWithFormat:@"error preparing statement %@ : %s", querySQL, sqlite3_errmsg(_db)]];
        }
        if(errorCheck)
            ABErrorLog(@"DB error finding data %@", [errorCheck debugDescription]);
        
        [self finishTransaction];
    }
    if(errorCheck != nil){
        ABErrorLog(@"%@", errorCheck);
        return nil;
    }
    return  dataToFind;
}



@end
