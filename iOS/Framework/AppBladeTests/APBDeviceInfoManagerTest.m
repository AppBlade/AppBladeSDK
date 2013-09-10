//
//  APBDeviceInfoManagerTest.m
//  AppBlade
//
//  Created by AndrewTremblay on 9/10/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "APBDeviceInfoManagerTest.h"

#import "AppBlade.h"
#import "APBDeviceInfoManager.h"

@implementation APBDeviceInfoManagerTest

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    // Tear-down code here.
    [super tearDown];
}

- (void)test01osVersionBuildExists
{
    NSString* osVersion = [[AppBlade sharedManager] osVersionBuild];
    STAssertNotNil(osVersion, @"Could not retrieve an OS version.");
}


- (void)test02iosVersionSanitizedExists
{
    NSString* osVersionSanitized = [[AppBlade sharedManager] iosVersionSanitized];
    STAssertNotNil(osVersionSanitized, @"Could not retrieve an OS version.");
}

- (void)test03platformReadable
{
    NSString* platform = [[AppBlade sharedManager] platform];
    STAssertNotNil(platform, @"Could not retrieve an OS version.");
}

- (void)test03simpleJailBreakCheck
{
    BOOL jailbreak = [[AppBlade sharedManager] simpleJailBreakCheck];
    STAssertFalse(jailbreak, @"Could not retrieve an OS version.");
    //none of our test devices will ever be jailbroken, since we don't support jailbroken devices (we only detect them)
}

@end
