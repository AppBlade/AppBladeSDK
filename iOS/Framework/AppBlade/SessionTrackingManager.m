//
//  SessionTracking.m
//  AppBlade
//
//  Created by AndrewTremblay on 7/16/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "SessionTrackingManager.h"

@implementation SessionTrackingManager
@synthesize delegate;

- (id)initWithDelegate:(id<AppBladeWebOperationDelegate>)webOpDelegate
{
    if((self = [super init])) {
        self.delegate = webOpDelegate;
    }
    
    return self;
}

//Suggested pragma structure (after implementing the required methods, which should always be first)
#pragma mark - Web Request Generators
//wherein you generate the unique web request for the SDK
#pragma mark Stored Web Request Handling
//wherein you implement any storage behavior for pending API calls.
//...
//then whatever else you feel like

@end
