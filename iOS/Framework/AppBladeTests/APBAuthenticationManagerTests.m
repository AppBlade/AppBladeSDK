//
//  APBAuthenticationManagerTests.m
//  AppBlade
//
//  Created by AndrewTremblay on 9/13/13.
//  Copyright (c) 2013 AppBlade. All rights reserved.
//

#import "APBAuthenticationManagerTests.h"

#import "AppBlade.h"
#import "AppBlade+PrivateMethods.h"
#import "APBWebOperation.h"
#import "APBAuthenticationManager.h"
#import "AsyncTestMacros.h"


//We gotta swizzle our NSDate so we can time-travel
#import "NSObject+MethodSwizzling.h"
#import "NSDate+MockData.h"


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
    NSNumber* ttlInterval = [appBlade_ttl objectForKey:kTtlDictTimeoutKey];
    STAssertTrue((expectedInterval == ttlInterval), @"TTL should have been set to %d, was set to %d", expectedInterval, ttlInterval);
#endif

}

-(void) test02TtlCanSetAndUpdate
{
    NSNumber *firstNumber = [NSNumber numberWithInt:2000];
    NSNumber *secondtNumber = [NSNumber numberWithInt:4000];
    
    [[[AppBlade sharedManager] authenticationManager] updateTTL:firstNumber];
    
    NSNumber *storedTimeout = [[[[AppBlade sharedManager] authenticationManager] currentTTL] objectForKey:kTtlDictTimeoutKey];
    STAssertEquals([storedTimeout integerValue], [firstNumber integerValue], @"API value could not be set from empty");

    [[[AppBlade sharedManager] authenticationManager] updateTTL:secondtNumber];
    
    storedTimeout = [[[[AppBlade sharedManager] authenticationManager] currentTTL] objectForKey:kTtlDictTimeoutKey];
    STAssertEquals([storedTimeout integerValue], [secondtNumber integerValue], @"API value could not be updated");
}

-(void) test03TtlIsWithinStoredTime
{
    NSNumber *testTimeout = [NSNumber numberWithInt:1000];
    [[[AppBlade sharedManager] authenticationManager] updateTTL:testTimeout];
    STAssertTrue(([[[AppBlade sharedManager] authenticationManager] withinStoredTTL]), @"TTL should have been set and valid");
}

-(void) test04TtlCanClose
{
    NSNumber *testTimeout = [NSNumber numberWithInt:1000];
    [[[AppBlade sharedManager] authenticationManager] updateTTL:testTimeout];
    STAssertTrue(([[[AppBlade sharedManager] authenticationManager] withinStoredTTL]), @"TTL should have been set and valid");
    [[[AppBlade sharedManager] authenticationManager] closeTTLWindow];
    STAssertFalse(([[[AppBlade sharedManager] authenticationManager] withinStoredTTL]), @"TTL should have been invalidted");
}

-(void) test05TtlCanTimeout
{
    NSNumber *oneSecondTimeout = [NSNumber numberWithInt:1];
    [[[AppBlade sharedManager] authenticationManager] updateTTL:oneSecondTimeout];
    APB_STALL_RUNLOPP_WHILE(true, 2); //wait for two seconds
    STAssertFalse(([[[AppBlade sharedManager] authenticationManager] withinStoredTTL]), @"TTL should have expired by now");

}

-(void) test06TtlCanDetectTimeTravel
{
    NSLog(@"Date is: %@", [NSDate date]);
    SwizzleClassMethod([NSDate class], @selector(date), @selector(mockCurrentDate));  //mock date must replace date
    [NSDate setMockDate:-1000];
    NSLog(@"Date is: %@", [NSDate date]);
    STAssertFalse(([[[AppBlade sharedManager] authenticationManager] withinStoredTTL]), @"TTL should have been detected as out of scope");
}


@end
