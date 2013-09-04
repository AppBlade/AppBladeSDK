//
//  AppBladeTests.m
//  AppBladeTests
//
//  Created by AndrewTremblay on 7/30/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "AppBladeTests.h"
#import <UIKit/UIKit.h>
#import "AppBlade.h"
#import "AppBlade+PrivateMethods.h"

#define kAppBladeTestPlistName @"TestAppBladeKeys"
#define kAppBladeTestNonExistentPlistName @"TestAppBladeKeysDoesNotExist"


@implementation AppBladeTests

- (void)setUp
{
    [super setUp];

    [[AppBlade sharedManager] registerWithAppBladePlist];
}

- (void)tearDown
{
    // Tear-down code here.
    [super tearDown];
}

- (void)test01SdkVersionExists
{
    NSString* sdkVersion = [AppBlade sdkVersion];
    STAssertNotNil(sdkVersion, @"Could not find SDK version.");
}


- (void)test02CacheDirectoryCreates
{
    BOOL isDirectory = YES;
    STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[AppBlade cachesDirectoryPath] isDirectory:&isDirectory], @"Could not create cache directory.");
    STAssertTrue(isDirectory, @"Cache directory was created but is not a directory.");

    [[AppBlade sharedManager] checkAndCreateAppBladeCacheDirectory];
    isDirectory = YES;
    STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[AppBlade cachesDirectoryPath] isDirectory:&isDirectory], @"Could not keep cache directory.");
    STAssertTrue(isDirectory, @"Cache directory exists but is not a directory.");
}

#pragma mark Dev Tests (no codesign)

#pragma mark ENT Tests (codesign)

#pragma mark AppStore Tests (codesigned, fairplay encrypted)

- (void)test03NonExistentPlistDisablesSDK
{
    
}


@end
