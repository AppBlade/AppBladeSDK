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

#define kAppBladeTestPlistName @"TestAppBladeKeys"
#define kAppBladeTestNonExistentPlistName @"TestAppBladeKeysDoesNotExist"


@implementation AppBladeTests

- (void)setUp
{
    [super setUp];
    // Set-up code here.
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
    [[AppBlade sharedManager] checkAndCreateAppBladeCacheDirectory];
    BOOL isDirectory = YES;
    STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[AppBlade cachesDirectoryPath] isDirectory:&isDirectory], @"Could not create cache directory.");
    STAssertTrue(isDirectory, @"Cache directory exists but is not a directory.");
}

- (void)test03NonExistentPlistDisablesSDK
{
    
}


@end
