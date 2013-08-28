//
//  AppBladeAuthentication.m
//  AppBlade
//
//  Created by AndrewTremblay on 7/16/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "AppBladeAuthenticationManager.h"
#import "AppBlade+PrivateMethods.h"

@implementation AppBladeAuthenticationManager
@synthesize delegate;

- (id)initWithDelegate:(id<AppBladeWebOperationDelegate>)webOpDelegate
{
    if((self = [super init])) {
        self.delegate = webOpDelegate;
    }
    
    return self;
}


-(void)checkApproval
{
    AppBladeWebOperation * client = [[AppBlade sharedManager] generateWebOperation] ;
    [client checkPermissions];
    [[AppBlade sharedManager] addPendingRequest:client];
}


@end
