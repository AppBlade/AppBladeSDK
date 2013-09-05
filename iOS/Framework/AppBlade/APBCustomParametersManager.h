//
//  AppBladeCustomParameters.h
//  AppBlade
//
//  Created by AndrewTremblay on 7/16/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "APBBasicFeatureManager.h"
#import "AppBlade+PrivateMethods.h"

@interface APBCustomParametersManager : NSObject<APBBasicFeatureManager>
@property (nonatomic, strong) id<APBWebOperationDelegate> delegate;

-(NSDictionary *)getCustomParams;
-(void)setCustomParams:(NSDictionary *)newFieldValues;
-(void)setCustomParam:(id)newObject withValue:(NSString*)key;
-(void)setCustomParam:(id)object forKey:(NSString*)key;
-(void)clearAllCustomParams;

@end


//Our additional requirements
@interface AppBlade (CustomParameters)

@property (nonatomic, strong) APBCustomParametersManager* customParamsManager;

@end