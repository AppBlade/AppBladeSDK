//
//  AppBladeDatabaseColumn.h
//  AppBlade

//  Created by AndrewTremblay on 12/5/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "APBDataManager.h"
static NSString* const kAppBladeColumnDictName  = @"columnName";
static NSString* const kAppBladeColumnDictType  = @"columnType";
static NSString* const kAppBladeColumnDictContraints     = @"columnConstraints";
static NSString* const kAppBladeColumnDictAdditionalArgs = @"columnAdditionalArgs";

/*!
  A dictionary category for making the database column generation a little bit easier to do. 
 */
@interface AppBladeDatabaseColumn : NSObject
@property (nonatomic, strong) NSString *columnName;
@property (nonatomic, strong) NSString *columnType;
@property (nonatomic, assign) AppBladeColumnConstraint constraints;
@property (nonatomic, strong) NSString *additionalArgs;

+(id)initColumnNamed:(NSString*)name ofType:(NSString *)columnType withContraints:(AppBladeColumnConstraint)constraints additionalArgs:(NSString *)args;
-(id)initWithDict:(NSDictionary *)dictionary;
-(NSDictionary *)toDictionary;

-(NSString *)toSQLiteColumnDefinition;

@end
