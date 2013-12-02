//
//  APBDataManager.m
//  AppBlade
//
//  Created by AndrewTremblay on 11/30/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//

#import "APBDataManager.h"
#import "AppBladeLogging.h"

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


#pragma mark -
#pragma mark Table functions
-(NSError *)createTable:(NSString *)tableName
{
#warning incomplete
    return nil;
}
-(NSError *)removeTable:(NSString *)tableName
{
#warning incomplete
    return nil;
}
#pragma mark Column functions
-(NSError *)addColumns:(NSArray *)columns toTable:(NSString *)tableName {
#warning incomplete
    return nil;
}
//column functions
-(NSError *)addColumn:(NSString *)columnName ofType:(AppBladeDataBaseColumnType)type toTable:(NSString *)tableName
{
#warning incomplete
    return nil;
}

-(NSError *)addColumn:(NSString *)columnName ofType:(AppBladeDataBaseColumnType)type withDefaultValue:(id)defaultValue toTable:(NSString *)tableName{
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

-(NSError *)removeRows:(NSArray *)rows toTable:(NSString *)tableName {
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

-(NSError *)createOrUpdateRow:(NSDictionary *)row toTable:(NSString *)tableName
{
#warning incomplete
    return nil;
}




@end
