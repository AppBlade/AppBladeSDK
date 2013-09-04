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
#import "APBTokenManager.h" //need this for the tokens queue

#define kAppBladeTestPlistName @"TestAppBladeKeys"
#define kAppBladeTestNonExistentPlistName @"TestAppBladeKeysDoesNotExist"


@implementation AppBladeTests

- (void)setUp
{
    [super setUp];
    //we neeed to test registration, so nothing can really go here.
    [[AppBlade sharedManager] clearAppBladeKeychain];
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
    STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[AppBlade cachesDirectoryPath] isDirectory:&isDirectory], @"Could not keep cache directory.");
    STAssertTrue(isDirectory, @"Cache directory exists but is not a directory.");
}

- (void)test03CacheDirectoryClears
{
    [[AppBlade sharedManager] clearCacheDirectory];
    NSArray *listOfFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[AppBlade cachesDirectoryPath] error:nil];
    STAssertEquals([listOfFiles count], 0, @"Could not remove files in cache directory.");
}

-(void)test04AppBladePlistsExist
{

}

-(void)test05AppBladeRegistersDeviceSecret
{
    [[AppBlade sharedManager] registerWithAppBladePlistNamed:kAppBladeTestPlistName];
    NSLog(@"Waiting until we get a registration back from AppBlade.");
    [[[[AppBlade sharedManager] tokenManager] tokenRequests] waitUntilAllOperationsAreFinished];
    STAssertTrue([[AppBlade sharedManager] hasDeviceSecret], @"No Device Secret after registration.");
    STAssertEquals([[[AppBlade sharedManager] appBladeDeviceSecrets] count], 1, @"We expect only one device secret to be stored after project secret registration");
}

#pragma mark Dev Tests (no codesign)

#pragma mark ENT Tests (codesign)

#pragma mark AppStore Tests (codesigned, fairplay encrypted)

- (void)test03NonExistentPlistDisablesSDK
{
    
}


@end
