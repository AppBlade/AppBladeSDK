//
//  AppBladeCustomParameters.m
//  AppBlade
//
//  Created by AndrewTremblay on 7/16/13.
//  Copyright (c) 2013 AppBlade. All rights reserved.
//

#import "APBCustomParametersManager.h"
#import "APBDatabaseCustomParameter.h"

@implementation APBCustomParametersManager
@synthesize delegate;

- (id)initWithDelegate:(id<APBWebOperationDelegate, APBDataManagerDelegate>)webOpAndDataManagerDelegate
{
    if((self = [super init])) {
        self.delegate = webOpAndDataManagerDelegate;
        self.dbMainTableName = kDbCustomParametersMainTableName;
        self.dbMainTableAdditionalColumns = [APBDatabaseCustomParameter columnDeclarations];
        
        [self createTablesWithDelegate:webOpAndDataManagerDelegate];
    }
    
    return self;
}


-(void)createTablesWithDelegate:(id<APBDataManagerDelegate>)databaseDelegate
{
    if([[databaseDelegate getDataManager] tableExistsWithName:self.dbMainTableName]){
        //table exists, see if we need to update it (we don't in this case, customparameter either exists or doesn't
    }else{
        //table doesn't exist! we need to create it.
        [[databaseDelegate getDataManager] createTable:self.dbMainTableName withColumns:self.dbMainTableAdditionalColumns];
    }
}

+(NSString *)getDefaultForeignKeyDefinition:(NSString *)referencingColumn
{
    return [NSString stringWithFormat:@"FOREIGN KEY(%@) REFERENCES %@(id) ON DELETE CASCADE", referencingColumn, kDbCustomParametersMainTableName];
}


-(NSDictionary *)getCustomParams
{
    NSDictionary *toRet = [NSDictionary dictionary];
    NSString* customFieldsPath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeCustomFieldsFile];
    if ([[NSFileManager defaultManager] fileExistsAtPath:customFieldsPath]) {
        NSDictionary* currentFields = [NSDictionary dictionaryWithContentsOfFile:customFieldsPath];
        toRet = currentFields;
    }
    else
    {
        ABDebugLog_internal(@"no file found, reinitializing");
        [self setCustomParams:toRet];
    }
    ABDebugLog_internal(@"getting Custom Params %@", toRet);
    return toRet;
}

-(void)setCustomParams:(NSDictionary *)newFieldValues
{
    [[AppBlade sharedManager] checkAndCreateAppBladeCacheDirectory];
    NSString* customFieldsPath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeCustomFieldsFile];
    if ([[NSFileManager defaultManager] fileExistsAtPath:customFieldsPath]) {
        ABDebugLog_internal(@"WARNING: Overwriting all existing user params");
    }
    if(newFieldValues){
        NSError *error = nil;
        NSData *paramsData = [NSPropertyListSerialization dataWithPropertyList:newFieldValues format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
        if(!error){
            [paramsData writeToFile:customFieldsPath atomically:YES];
        }
        else
        {
            ABErrorLog(@"Error parsing custom params %@", newFieldValues);
        }
    }
    else
    {
        ABDebugLog_internal(@"clearing custom params, removing file");
        [[NSFileManager defaultManager] removeItemAtPath:customFieldsPath error:nil];
    }    
}

-(void)setCustomParam:(id)newObject withValue:(NSString*)key
{
    NSDictionary* currentFields = [self getCustomParams];
    if (currentFields == nil) {
        currentFields = [NSDictionary dictionary];
    }
    NSMutableDictionary* mutableFields = [currentFields  mutableCopy];
    if(key && newObject){
        [mutableFields setObject:newObject forKey:key];
    }
    else if(key && !newObject){
        [mutableFields removeObjectForKey:key];
    }
    else
    {
        ABErrorLog(@"AppBlade: invalid nil key when setting custom parameters");
    }
    ABDebugLog_internal(@"setting to %@", mutableFields);
    currentFields = (NSDictionary *)mutableFields;
    [self setCustomParams:currentFields];
}



-(void)setCustomParam:(id)object forKey:(NSString*)key
{
    NSDictionary* currentFields = [self getCustomParams];
    if (currentFields == nil) {
        currentFields = [NSDictionary dictionary];
    }
    NSMutableDictionary* mutableFields = [currentFields  mutableCopy] ;
    if(key && object){
        [mutableFields setObject:object forKey:key];
    }
    else if(key && !object){
        [mutableFields removeObjectForKey:key];
    }
    else
    {
        ABErrorLog(@"invalid nil key");
    }
    ABDebugLog_internal(@"setting to %@", mutableFields);
    currentFields = (NSDictionary *)mutableFields;
    [self setCustomParams:currentFields];
}

-(void)clearAllCustomParams
{
    [self setCustomParams:nil];
}



/*
 When do we need a custom parameter snapshot stored?
 When the custom parameter has changed between feature calls.
 When a feature is stored, make sure an up-to-date snapshot is stored as well.
 For the sake of simplicity, keep 1 snapshot per stored data that would use it until we have time to get clever about it.
 */
-(APBDatabaseCustomParameter *)generateCustomParameterFromCurrentParamsWithError:(NSError * __autoreleasing *) error
{
    NSError *errorCheck = nil;
    NSDictionary *paramsSnapshot = [self getCustomParams];
    APBDatabaseCustomParameter* newCustomParamObj = [[self.delegate getDataManager] insertNewCustomParams:paramsSnapshot error:&errorCheck];
    if(errorCheck)
        * error = errorCheck;
    return newCustomParamObj;
}

-(void)removeCustomParamById:(NSString *)paramId error:(NSError * __autoreleasing *) error
{
    * error = [APBDataManager dataBaseErrorWithMessage:@"incomplete implementation"];
}

-(APBDatabaseCustomParameter *)getCustomParamById:(NSString *)paramId
{
    return [[self.delegate getDataManager] getCustomParameterWithID:paramId ];
}

@end


@implementation APBDataManager(CustomParameters)
@dynamic db;

-(APBDatabaseCustomParameter *)insertNewCustomParams:(NSDictionary *)paramsToStore error:(NSError * __autoreleasing *) error
{
    NSError *errorCheck = nil;
    APBDatabaseCustomParameter *newData = [[APBDatabaseCustomParameter alloc] initWithDictionary:paramsToStore];
    APBDatabaseCustomParameter *generatedData = (APBDatabaseCustomParameter *)[self upsertData:newData
                                                                                       toTable:kDbCustomParametersMainTableName
                                                                                         error:&errorCheck];
    if(errorCheck) {
        ABErrorLog(@"error inserting custom params %@", [errorCheck description]);
        return nil;
    }
    return generatedData;
}

-(APBDatabaseCustomParameter *)getCustomParameterWithID:(NSString *)customParamId
{
    NSString *paramQuery = [NSString stringWithFormat:@"id = %@", customParamId];
    return (APBDatabaseCustomParameter *)[self findDataWithClass:[APBDatabaseCustomParameter class] inTable:kDbCustomParametersMainTableName withParams:paramQuery];
}

-(NSError *)removeCustomParameterWithID:(NSString *)customParamId
{
#warning incomplete
    return nil;
}

@end
