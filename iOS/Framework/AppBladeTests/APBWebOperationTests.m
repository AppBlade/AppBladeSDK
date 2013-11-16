//
//  APBWebOperationTests.m
//  AppBlade
//
//  Created by AndrewTremblay on 7/30/13.
//  Copyright (c) 2013 AppBlade. All rights reserved.
//

#import "APBWebOperationTests.h"
#import "APBWebOperation.h"
#import "APBWebOperation+PrivateMethods.h"
#import "AppBlade.h"
#import "AppBlade+PrivateMethods.h"


#define kAppBladeTestHostURL @"https://appblade.com/"
#define kAppBladeTestPlistName @"TestAppBladeKeys"


@implementation APBWebOperationTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

-(void) test01ConnectToAppBlade
{
    NSURL *url = [NSURL URLWithString:kAppBladeTestHostURL];
    NSData *data = [NSData dataWithContentsOfURL:url];
    STAssertNotNil(data, @"Connection to %@ could not be made", kAppBladeTestHostURL);
}

-(void) test02CanLoadPlist
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString * plistPath = [bundle pathForResource:kAppBladeTestPlistName ofType:@"plist"];
    NSDictionary* appbladeVariables = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    STAssertNotNil(appbladeVariables, @"Could not load dictionary from %@", plistPath);
}

-(void) test03ConnectWithProjectSecret
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString * plistPath = [bundle pathForResource:kAppBladeTestPlistName ofType:@"plist"];
    NSDictionary* appbladeVariables = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    [[AppBlade sharedManager] registerWithAppBladeDictionary:appbladeVariables atPlistPath:nil];
}

// What happens when we make many calls at once? They should queue up, one at a time. This will
// test this feature, and override the callbacks specified in the plist so we can count the callbacks.
-(void) test04MultipleRequests
{

}

#pragma mark - Verification Methods

#pragma mark - Validation Callbacks


@end
