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


@implementation AppBladeWebOperation (Updates)

- (void)checkForUpdates
{
    BOOL hasFairplay = [[AppBlade sharedManager] isAppStoreBuild];
    if(hasFairplay){
        //we're signed by apple, skip updating. Go straight to delegate.
        ABDebugLog_internal(@"Binary signed by Apple, skipping update check forever");
        NSDictionary *fairplayPermissions = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:INT_MAX], @"ttl", nil];
        AppBladeWebOperation *selfReference = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[AppBlade sharedManager] appBladeWebClient:selfReference receivedUpdate:fairplayPermissions];
        });
    }
    else
    {
        // Create the request.
        [self setApi: AppBladeWebClientAPI_UpdateCheck];
        NSString* urlString = [NSString stringWithFormat:updateURLFormat, [self.delegate appBladeHost]];
        NSURL* projectUrl = [NSURL URLWithString:urlString];
        NSMutableURLRequest* apiRequest = [self requestForURL:projectUrl];
        [apiRequest setHTTPMethod:@"GET"];
        [apiRequest addValue:@"true" forHTTPHeaderField:@"USE_ANONYMOUS"];
        [self addSecurityToRequest:apiRequest]; //don't need security, but we could do better with it.
        [apiRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"]; //we want json
        ABDebugLog_internal(@"Update call %@", urlString);
    }
}

@end


@implementation AppBlade (Updates)
@dynamic updatesManager;

- (void)appBladeWebClient:(AppBladeWebOperation *)client receivedUpdate:(NSDictionary*)updateData
{
#ifndef SKIP_AUTO_UPDATING
    [self.updatesManager handleWebClient:client receivedUpdate:updateData];
#endif
}

@end