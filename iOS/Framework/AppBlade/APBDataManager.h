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

@interface APBDataManager : NSObject

-(NSString *)getDatabaseFilePath;

@end
