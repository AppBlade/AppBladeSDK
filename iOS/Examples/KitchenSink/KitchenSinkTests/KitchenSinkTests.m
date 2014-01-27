//
//  KitchenSinkTests.m
//  KitchenSinkTests
//
//  Created by AndrewTremblay on 7/15/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
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
    [[AppBlade sharedManager] clearAppBladeKeychain]; //start with nothing every time (logic for this stuff is handled in the SDK test)
    [[AppBlade sharedManager] clearCacheDirectory];
    [[AppBlade sharedManager] setDisabled:false]; //also make sure we're enabled

    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

// the special case init methods/helpers
-(void)disableAllWithAssert
{
    [[AppBlade sharedManager] setDisabled:true];
    STAssertTrue([[AppBlade sharedManager] isAllDisabled], @"Getter or setter doesn't work.");
}

-(void)assertNoPendingRequests:(NSString*)errorMessage
{
    NSInteger emptyCheck = [[AppBlade  sharedManager] pendingRequestsOfType:AppBladeWebClientAPI_AllTypes];
    STAssertTrue((emptyCheck == 0),errorMessage);
}


//The tests

- (void)test01AppDelegateExists
{
    id appDelegate = [[UIApplication sharedApplication] delegate];
    STAssertNotNil(appDelegate, @"UIApplication failed to find the AppDelegate");
}

- (void)test02InAppRegister
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


-(void)test04isAllDisabledAffectsWebCalls
{
    [self disableAllWithAssert];
//    [[AppBlade sharedManager] registerWithAppBladePlist]; would set isAllDisabled on an invalid call while fairplay encrypted
    [[AppBlade sharedManager] checkApproval];
    [self assertNoPendingRequests: @"checkApproval is not affected by isAllDisabled"];
    
    [[AppBlade sharedManager] checkForUpdates]; 
    [self assertNoPendingRequests: @"checkForUpdates is not affected by isAllDisabled"];


    [[AppBlade sharedManager] catchAndReportCrashes]; //TODO: start with a pending crash report
    [self assertNoPendingRequests: @"catchAndReportCrashes is not affected by isAllDisabled"];

    
    [[AppBlade sharedManager] allowFeedbackReporting];  //TODO: start with a pending feedback report
    [self assertNoPendingRequests:  @"allowFeedbackReporting is not affected by isAllDisabled"];


    [[AppBlade sharedManager] logSessionStart];  //TODO: start with a pending session
    //(for now though, let's just start/end/start. That'll kick off equivalent behavior)
    [[AppBlade sharedManager] logSessionEnd];
    [[AppBlade sharedManager] logSessionStart];
    [self assertNoPendingRequests:  @"logSessionStart/End  is not affected by isAllDisabled"];
}


-(void)test05isAllDisabledAffectsFeedback
{
    [self disableAllWithAssert];

}

-(void)test06isAllDisabledAffectsSessionLogging
{
    [self disableAllWithAssert];

}

-(void)test07isAllDisabledAffectsCustomParams
{
    [self disableAllWithAssert];

}

@end
