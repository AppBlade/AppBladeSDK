//
//  AppBladeUpdates.m
//  AppBlade
//
//  Created by AndrewTremblay on 7/16/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "AppBladeUpdatesManager.h"
#import "AppBlade+PrivateMethods.h"

@implementation AppBladeUpdatesManager
@synthesize delegate;
@synthesize upgradeLink;

- (id)initWithDelegate:(id<AppBladeWebOperationDelegate>)webOpDelegate
{
    if((self = [super init])) {
        self.delegate = webOpDelegate;
    }
    
    return self;
}


- (void)checkForUpdates
{
    ABDebugLog_internal(@"Checking for updates");
    AppBladeWebOperation * client = [[AppBlade sharedManager] generateWebOperation];
    [client checkForUpdates];
    [[AppBlade sharedManager] addPendingRequest:client];
}


@end
