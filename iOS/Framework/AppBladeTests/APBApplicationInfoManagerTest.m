//
//  APBApplicationInfoManagerTest.m
//  AppBlade
//
//  Created by AndrewTremblay on 9/10/13.
//  Copyright (c) 2013 AppBlade. All rights reserved.
//

#import "APBApplicationInfoManagerTest.h"

#import "AppBlade.h"
#import "APBApplicationInfoManager.h"

@implementation APBApplicationInfoManagerTest


- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    // Tear-down code here.
    [super tearDown];
}

- (void)test01executableUUIDExists
{
    NSString* executableUUID = [[AppBlade sharedManager] executableUUID];
    STAssertNotNil(executableUUID, @"Could not retrieve an executableUUID.");
}

- (void)test02hashExecutableExists
{
    NSString* hashExecutable = [[AppBlade sharedManager] hashExecutable];
    STAssertNotNil(hashExecutable, @"Could not retrieve an executable hash.");
}


- (void)test03isAppStoreBuildReturns
{
    BOOL executableUUID = [[AppBlade sharedManager] isAppStoreBuild];
#ifdef APPBLADE_TEST_FAIRPLAY_ENCRYPTED
    STAssertTrue(executableUUID, @"Could not assert appstore build was true.");
#else
    STAssertFalse(executableUUID, @"Could not invalid appstore build detected.");
#endif
}




@end
