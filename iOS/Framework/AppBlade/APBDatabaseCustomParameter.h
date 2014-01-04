//
//  APBDatabaseCustomParameter.h
//  AppBlade
//
//  Created by AndrewTremblay on 12/9/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//

#import "AppBladeDatabaseObject.h"

@interface APBDatabaseCustomParameter : AppBladeDatabaseObject
+(NSArray *)columnDeclarations;
-(NSDictionary *)asDictionary;
@end
