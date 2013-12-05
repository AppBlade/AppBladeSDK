//
//  NSDictionary+AppBladeDataBaseColumn.h
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
@interface NSMutableDictionary (AppBladeDataBaseColumn)
-(id)initColumnDictionaryNamed:(NSString*)name ofType:(NSString *)columnType withContraints:(AppBladeColumnConstraint)constraints additionalArgs:(NSString *)args;
-(NSString *)toSQLiteColumnDefinition;

-(NSString *)columnName;
-(void)setColumnName:(NSString *)name;

-(NSString *)columnType;
-(void)setColumnType:(NSString *)type;

-(AppBladeColumnConstraint)columnConstraints;
-(void)setColumnConstraints:(AppBladeColumnConstraint)constraints;

-(NSString *)columnAdditionalArgs;
-(void)setColumnAdditionalArgs:(NSString *)args;

@end
