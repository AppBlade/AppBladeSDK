//
//  AppBladeGenericFeatureManager.h
//  AppBlade
//
//  Created by AndrewTremblay on 7/17/13.
//  Copyright (c) 2013 AppBlade. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppBlade.h"
#import "APBWebOperation.h"
#import "APBDataManager.h"

#import "AppBladeLogging.h"

@protocol APBBasicFeatureManager

@required
//every manager delegate has to include the APBDataManagerDelegate regardless of database use
- (id)initWithDelegate:(id<APBWebOperationDelegate, APBDataManagerDelegate>)webOpAndDataManagerDelegate;

@optional

//Suggested pragma structure (after implementing the required methods, which should always be first)
#pragma mark - Web Request Generators
//wherein you generate the unique web request for the SDK, please use the Blocks whenever possible
#pragma mark Stored Web Request Handling
//wherein you implement any storage behavior for pending API calls.

-(void)createTablesWithDelegate:(id<APBDataManagerDelegate>)databaseDelegate;

-(NSString *)getDefaultForeignKeyDefinition:(NSString *)referencingColumn;

//then whatever else you feel like


@end
