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
#ifdef APPBLADE_TEST_JAILBROKEN
    STAssertTrue(jailbreak, @"Could not detect proper jailbreak value.");
#else
    STAssertFalse(jailbreak, @"Could not detect proper jailbreak value.");
#endif
}

@end
