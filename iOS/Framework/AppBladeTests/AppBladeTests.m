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
    STAssertTrue(([listOfFiles count] == 0), @"Could not remove files in cache directory.");
}

-(void)test04AppBladePlistsExist
{
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:kAppBladeTestPlistName ofType:@"plist"];
    STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:path], @"Could not find keys plist.");
}

-(void)test05AppBladeRegistersDeviceSecret
{
    NSString *plistPath = [[NSBundle bundleForClass:[self class]] pathForResource:kAppBladeTestPlistName ofType:@"plist"];
    NSDictionary* testDictionary = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    [[AppBlade sharedManager] registerWithAppBladeDictionary:testDictionary atPlistPath:plistPath];
    NSLog(@"Waiting until we get a registration back from AppBlade.");
    STAssertFalse([[AppBlade sharedManager] hasDeviceSecret], @"We shouldn't have a Device Secret yet.");
    APB_WAIT_WHILE([[[AppBlade  sharedManager] tokenManager] isDeviceSecretBeingConfirmed], kNetworkPatience);
    NSString *deviceString = [[AppBlade sharedManager] appBladeDeviceSecret];
    STAssertTrue(([deviceString length] > 0), @"We could not retrieve a device secret:\n %@", [[AppBlade sharedManager] appBladeDeviceSecrets]);
}

#pragma mark Dev Tests (no codesign)

#pragma mark ENT Tests (codesign)

#pragma mark AppStore Tests (codesigned, fairplay encrypted)



@end
