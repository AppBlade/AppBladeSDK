//
//  APBFeedbackReportAppTests.m
//  KitchenSink
//
//  Created by AndrewTremblay on 1/28/14.
//  Copyright (c) 2014 AppBlade Corporation. All rights reserved.
//

#import "APBFeedbackReportAppTests.h"

#import "AppBlade.h"
#import "AppBlade+PrivateMethods.h"

@implementation APBFeedbackReportAppTests

- (void)setUp
{
    [super setUp];
    // Set-up code here.
    [[AppBlade sharedManager] clearAppBladeKeychain]; //start with nothing every time (logic for this stuff is handled in the SDK test)
    [[AppBlade sharedManager] clearCacheDirectory];
    [[AppBlade sharedManager] setDisabled:false]; //also make sure we start enabled
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

-(void)test01FeedbackBehaviorInitialized
{
}


@end
