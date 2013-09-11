//
//  KitchenSinkTests.m
//  KitchenSinkTests
//
//  Created by AndrewTremblay on 7/15/13.
//  Copyright (c) 2013 Raizlabs Corporation. All rights reserved.
//

#import "KitchenSinkTests.h"
#import "KitchenSinkTestConstants.h"
#import "KitchenSinkTestMacros.h"

#import "AppDelegate.h"

#import "AppBlade.h"
#import "AppBlade+PrivateMethods.h"
#import "APBTokenManager.h" //need this for the tokens queue

@implementation KitchenSinkTests

- (void)setUp
{
    [super setUp];
    [[AppBlade sharedManager] clearAppBladeKeychain]; //start with nothing every time
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)test01AppDelegateExists
{
    id appDelegate = [[UIApplication sharedApplication] delegate];
    STAssertNotNil(appDelegate, @"UIApplication failed to find the AppDelegate");
}

- (void)test01InAppRegister
{
    [[AppBlade sharedManager] registerWithAppBladePlist];
    NSLog(@"Waiting until we get a registration back from AppBlade.");
    STAssertFalse([[AppBlade sharedManager] hasDeviceSecret], @"We shouldn't have a Device Secret yet. Our clearAppBladeKeychain might not be working.");
    APB_WAIT_WHILE([[[AppBlade  sharedManager] tokenManager] isDeviceSecretBeingConfirmed], kNetworkPatience);
    NSString *deviceString = [[AppBlade sharedManager] appBladeDeviceSecret];
    STAssertTrue(([deviceString length] > 0), @"We could not retrieve a device secret:\n %@", [[AppBlade sharedManager] appBladeDeviceSecrets]);
}

- (void)test03checkApprovalQueuesAndSucceeds
{
    [[AppBlade sharedManager] registerWithAppBladePlist];
    [[AppBlade sharedManager] checkApproval];
    NSInteger approvalCheck = [[AppBlade  sharedManager] pendingRequestsOfType:AppBladeWebClientAPI_Permissions];
    NSString *errorString = [NSString stringWithFormat:@"Found %d queued aprovals", approvalCheck];
    STAssertTrue((approvalCheck == 1), errorString);
    APB_WAIT_WHILE(([[AppBlade  sharedManager] pendingRequestsOfType:AppBladeWebClientAPI_Permissions] > 0), kNetworkPatience);
    NSString *deviceString = [[AppBlade sharedManager] appBladeDeviceSecret];
    STAssertTrue(([deviceString length] > 0), @"We could not retrieve a device secret:\n %@", [[AppBlade sharedManager] appBladeDeviceSecrets]);
}

@end
