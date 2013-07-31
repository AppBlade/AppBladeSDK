//
//  AppBladeWebOperationTests.m
//  AppBlade
//
//  Created by AndrewTremblay on 7/30/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "AppBladeWebOperationTests.h"
#import "AppBladeWebOperation.h"
#import "AppBladeWebOperation+PrivateMethods.h"
#import "AppBlade.h"


#define kAppBladeTestHostURL @"https://appblade.com/"
#define kAppBladeTestPlistName @"TestAppBladeKeys"


@implementation AppBladeWebOperationTests

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

-(void) test02ConnectWithProjectSecret
{
    [[AppBlade sharedManager] registerWithAppBladePlistNamed:kAppBladeTestPlistName];
}

-(void) test03
{
    
}

// What happens when we make many calls at once? They should queue up, one at a time. This will
// test this feature, and override the callbacks specified in the plist so we can count the callbacks.
-(void) test04MultipleRequests
{

}

#pragma mark - Verification Methods

#pragma mark - Validation Callbacks


@end
