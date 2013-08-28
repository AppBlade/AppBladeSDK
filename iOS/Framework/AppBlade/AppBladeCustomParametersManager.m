//
//  AppBladeCustomParameters.m
//  AppBlade
//
//  Created by AndrewTremblay on 7/16/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "AppBladeCustomParametersManager.h"

@implementation AppBladeCustomParametersManager
@synthesize delegate;

- (id)initWithDelegate:(id<AppBladeWebOperationDelegate>)webOpDelegate
{
    if((self = [super init])) {
        self.delegate = webOpDelegate;
    }
    
    return self;
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


@end
