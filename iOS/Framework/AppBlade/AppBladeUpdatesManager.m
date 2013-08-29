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


-(void)handleWebClient:(AppBladeWebOperation *)client receivedUpdate:(NSDictionary *)updateData
{
    // determine if there is an update available
    NSDictionary* update = [updateData objectForKey:@"update"];
    if(update)
    {
        NSString* updateMessage = [update objectForKey:@"message"];
        NSString* updateURL = [update objectForKey:@"url"];
        
        if ([[[AppBlade sharedManager] delegate] respondsToSelector:@selector(appBlade:updateAvailable:updateMessage:updateURL:)]) {
            [[[AppBlade sharedManager] delegate] appBlade:[AppBlade sharedManager] updateAvailable:YES updateMessage:updateMessage updateURL:updateURL];
        }
    }
}

- (void)updateCallbackFailed:(AppBladeWebOperation *)client withErrorString:(NSString*)errorString
{

}


@end
