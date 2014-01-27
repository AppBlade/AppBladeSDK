//
//  APBCustomParametersAppTests.m
//  KitchenSink
//
//  Created by AndrewTremblay on 1/26/14.
//  Copyright (c) 2014 AppBlade Corporation. All rights reserved.
//

#import "APBCustomParametersAppTests.h"

@implementation APBCustomParametersAppTests
-(void)test01CustomParametersBehaviorInitialized
{
    STAssertTrue(([[AppBlade sharedManager] initializedFeatures] && AppBladeFeaturesCustomParametersEnabled), @"Custom parameters feature must be enabled in order for tests to run.");
}

-(void) test02CustomParametersCreate
{
    //     [[[AppBlade sharedManager] customParamsManager] getCustomParams];
}

-(void) test03CustomParametersAreSetAndUnset
{
#warning todo
}

-(void) test04CustomParametersAreStoredInSnapshots
{
#warning todo
}


@end
