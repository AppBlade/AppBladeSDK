//
//  AppBladeTokenRequestManager.m
//  AppBlade
//
//  Created by AndrewTremblay on 8/29/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "AppBladeTokenRequestManager.h"
#import "AppBlade+PrivateMethods.h"
#import "AppBladeLogging.h"

@interface AppBladeTokenRequestManager()
    @property (nonatomic, retain) NSOperationQueue* tokenRequests;
@end


@implementation AppBladeTokenRequestManager
    @synthesize tokenRequests = _tokenRequests;

-(NSOperationQueue *) tokenRequests {
    if(!_tokenRequests){
        _tokenRequests = [[NSOperationQueue alloc] init];
        _tokenRequests.name = @"AppBlade Token Queue";
        _tokenRequests.maxConcurrentOperationCount = 1;
    }
    return _tokenRequests;
}

-(NSOperationQueue *) addTokenRequest:(NSOperation *)request
{
    if(request){
        [self.tokenRequests addOperation:request];
    }
    return self.tokenRequests;
}

- (void)refreshToken:(NSString *)tokenToConfirm
{
    //ensure no other requests or confirms are already running.
    if([[AppBlade sharedManager] isDeviceSecretBeingConfirmed]) {
        ABDebugLog_internal(@"Refresh already in queue. Ignoring.");
        return;
    }else if (tokenToConfirm != nil && ![self isCurrentToken:tokenToConfirm]){
        ABDebugLog_internal(@"Token not current, refresh token request is out of sync. Ignoring.");
        return;
    }
    
    //If we got to this point then HOLD EVERYTHING. Bubble the request to the top.
    [[AppBlade sharedManager] pauseCurrentPendingRequests];
    AppBladeWebOperation * client = [[AppBlade sharedManager] generateWebOperation];
    [client refreshToken:[[AppBlade sharedManager] appBladeDeviceSecret]];
    [self addTokenRequest:client];
}

- (void)confirmToken:(NSString *)tokenToConfirm
{
    //ensure no other requests or confirms are already running.
    if([[AppBlade sharedManager] isDeviceSecretBeingConfirmed]) {
        ABDebugLog_internal(@"Confirm (or refresh) already in queue. Ignoring.");
        return;
    }else if (tokenToConfirm != nil && ![self isCurrentToken:tokenToConfirm]){
        ABDebugLog_internal(@"Token not current, confirm token request is out of sync. Ignoring.");
        return;
    }
    
    //If we got to this point then HOLD EVERYTHING. Bubble the request to the top.
    [[AppBlade sharedManager] pauseCurrentPendingRequests];
    
    AppBladeWebOperation * client = [[AppBlade sharedManager] generateWebOperation];
    [client confirmToken:[[AppBlade sharedManager] appBladeDeviceSecret]];
    [self addTokenRequest:client];
}


- (BOOL)isCurrentToken:(NSString *)token
{
    return (nil != token) && [[[AppBlade sharedManager] appBladeDeviceSecret] isEqualToString:token];
}

- (BOOL)tokenConfirmRequestPending
{
    NSInteger confirmTokenRequests = [[self.tokenRequests operations] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"api == %d", AppBladeWebClientAPI_ConfirmToken]];
    return confirmTokenRequests > 0;
}

- (BOOL)tokenRefreshRequestPending
{
    NSInteger confirmTokenRequests = [[self.tokenRequests operations] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"api == %d", AppBladeWebClientAPI_GenerateToken]];
    return confirmTokenRequests > 0;
}



@end
