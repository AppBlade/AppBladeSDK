//
//  APBDataManager.m
//  AppBlade
//
//  Created by AndrewTremblay on 11/30/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//

#import "APBDataManager.h"
#import "AppBladeLogging.h"

@implementation APBDataManager

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
        if (![[NSFileManager defaultManager] fileExistsAtPath:dataFolder]){
            ABDebugLog_internal(@"Creating the database %@", dataFolder);
            
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
    return FALSE;
}

-(NSString *)getDocumentsSubFolderPath
{
    return [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/AppBlade"];
}

-(NSString *)getDatabaseFilePath
{
    
    return [[self getDocumentsSubFolderPath] stringByAppendingPathComponent:kAppBladeDataBaseName];
}

@end
