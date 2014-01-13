//
//  APBDatabaseCustomParameter.h
//  AppBlade
//
//  Created by AndrewTremblay on 12/9/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//

#import "AppBladeDatabaseObject.h"

static NSString* const kDbCustomParamColumnNameDictBlob = @"currentParams";
static NSInteger const kDbCustomParamColumnIndexOffsetDictBlob = 1;
static NSString* const kDbCustomParamColumnNameSnapshotDate = @"createdAt";
static NSInteger const kDbCustomParamColumnIndexOffsetSnapshotDate = 2;


@interface APBDatabaseCustomParameter : AppBladeDatabaseObject
-(id)initWithDictionary:(NSDictionary *)dictionary;
@property (nonatomic, strong) NSDictionary *storedParams;
@property (nonatomic, strong) NSDate *snapshotDate;

-(NSString *)paramsAsString;
-(void)parseStringFromStorage:(NSString *)stringifiedParams;

+(NSArray *)columnDeclarations;

-(NSArray *)additionalColumnNames; //default implementation is an empty array
-(NSArray *)additionalColumnValues; //default implementation is an empty array

-(NSDictionary *)asDictionary;

@end
