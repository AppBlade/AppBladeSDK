//
//  APBAuthenticationManagerTests.m
//  AppBlade
//
//  Created by AndrewTremblay on 9/13/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "APBAuthenticationManagerTests.h"

#import "AppBlade.h"
#import "AppBlade+PrivateMethods.h"
#import "APBWebOperation.h"
#import "APBAuthenticationManager.h"
#import "AsyncTestMacros.h"
@implementation APBAuthenticationManagerTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

//essentially the checkApproval call without the queueing
-(void) test01CheckPermsissionCanGenerate
{
    APBWebOperation *testOp = [[AppBlade sharedManager] generateWebOperation];
    [testOp checkPermissions];
    
    STAssertEquals(testOp.api, AppBladeWebClientAPI_Permissions, @"API value should be AppBladeWebClientAPI_Permissions");
    
    
#ifdef APPBLADE_TEST_FAIRPLAY_ENCRYPTED
    APB_WAIT_WHILE_WITH_DESC(![[[AppBlade sharedManager] authenticationManager] withinStoredTTL], 5, @"TTL should have been set asynchronously");
    //our ttl should be set internally to never time out (largest possible integer as the interval)
    NSNumber expectedInterval = [NSNumber numberWithInt:INT_MAX]
    NSDictionary *appBlade_ttl = [[[AppBlade sharedManager] authenticationManager] currentTTL];
    NSNumber* ttlInterval = [appBlade_ttl objectForKey:@"ttlInterval"];
    STAssertTrue((expectedInterval == ttlInterval), @"TTL should have been set to %d, was set to %d", expectedInterval, ttlInterval);
#endif

}

-(void) test02TtlCanSetAndUpdate
{
    NSNumber *firstNumber = [NSNumber numberWithInt:2000];
    NSNumber *secondtNumber = [NSNumber numberWithInt:4000];
    
    [[[AppBlade sharedManager] authenticationManager] updateTTL:firstNumber];
    STAssertEquals([[[[AppBlade sharedManager] authenticationManager] currentTTL] objectForKey:kTtlDictTimeoutKey], firstNumber, @"API value could not be set from empty");

    [[[AppBlade sharedManager] authenticationManager] updateTTL:secondtNumber];
    STAssertEquals([[[[AppBlade sharedManager] authenticationManager] currentTTL] objectForKey:kTtlDictTimeoutKey], secondtNumber, @"API value could not be updated");
}

-(void) test03TtlIsWithinStoredTime
{
    
}

-(void) test04TtlCanClose
{
    
}

-(void) test04TtlCanDetectTimeTravel
{
    
}




@end
