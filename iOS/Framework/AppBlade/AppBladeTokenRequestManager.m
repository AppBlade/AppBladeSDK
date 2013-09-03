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

NSString *tokenGenerateURLFormat     = @"%@/api/3/authorize/new";
NSString *tokenConfirmURLFormat      = @"%@/api/3/authorize"; //keeping these separate for readiblilty and possible editing later

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

@implementation AppBladeWebOperation (AppBladeTokenRequestManager)


- (void)refreshToken:(NSString *)tokenToConfirm
{
    [self setApi: AppBladeWebClientAPI_GenerateToken];
    BOOL hasFairplay = [[AppBlade sharedManager] isAppStoreBuild];
    if(hasFairplay){
        //we're signed by apple, skip tokens. Go straight to delegate.
        ABDebugLog_internal(@"Binary signed by Apple, skipping token generation");
    }
    else
    {
        // Create the request.
        NSString* urlString = [NSString stringWithFormat:tokenGenerateURLFormat, [self.delegate appBladeHost]];
        NSURL* projectUrl = [NSURL URLWithString:urlString];
        NSMutableURLRequest* apiRequest = [self requestForURL:projectUrl];
        [apiRequest setHTTPMethod:@"GET"];
        [apiRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"]; //we want json
        
        //THE BLOCKS
        AppBladeWebOperation *selfReference = self;
        [self setPrepareBlock:^(id preparationData){
            [selfReference addSecurityToRequest:apiRequest];
        }];
        
        [self setRequestCompletionBlock:^(NSMutableURLRequest *request, id rawSentData, NSDictionary* responseHeaders, NSMutableData* receivedData, NSError *webError){
            NSError *error = nil;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:receivedData options:nil error:&error];
            ABDebugLog_internal(@"Parsed JSON: %@", json);
            dispatch_async(dispatch_get_main_queue(), ^{
                [[AppBlade sharedManager] appBladeWebClient:selfReference receivedGenerateTokenResponse:json];
            });
        }];
        
        [self setSuccessBlock:^(id data, NSError* error){
            
        }];
        
        [self setFailBlock:^(id data, NSError* error){
            
        }];
    }
}

- (void)confirmToken:(NSString *)tokenToConfirm
{
    ABDebugLog_internal(@"confirming token (client)");
    [self setApi: AppBladeWebClientAPI_ConfirmToken];
    BOOL hasFairplay = [[AppBlade sharedManager] isAppStoreBuild];
    if(hasFairplay){
        //we're signed by apple, skip authentication. Go straight to delegate.
        ABDebugLog_internal(@"Binary signed by Apple, skipping token confirmation");
        //        [self.delegate appBladeWebClient:self receivedPermissions: ];
    }
    else
    {
        //NSString *storedSecret = [[AppBlade sharedManager] appBladeDeviceSecret];
        //ABDebugLog_internal(@"storedSecret %@", storedSecret);
        ABDebugLog_internal(@"tokenToConfirm %@", tokenToConfirm);
        
        
        if(nil != tokenToConfirm && ![tokenToConfirm isEqualToString:@""]){
            // Create the request.
            NSString* urlString = [NSString stringWithFormat:tokenConfirmURLFormat, [self.delegate appBladeHost]];
            NSURL* projectUrl = [NSURL URLWithString:urlString];
            NSMutableURLRequest* apiRequest = [self requestForURL:projectUrl];
            [apiRequest setHTTPMethod:@"POST"];
            [apiRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"]; //we want json
          
            //THE BLOCKS
            AppBladeWebOperation *selfReference = self;
            [self setPrepareBlock:^(id preparationData){
                [selfReference addSecurityToRequest:apiRequest];
            }];

            [self setRequestCompletionBlock:^(NSMutableURLRequest *request, id rawSentData, NSDictionary* responseHeaders, NSMutableData* receivedData, NSError *webError){
                NSError *error = nil;
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:receivedData options:nil error:&error];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[AppBlade sharedManager] appBladeWebClient:selfReference receivedConfirmTokenResponse:json];
                });
            }];
            
            [self setSuccessBlock:^(id data, NSError* error){
                
            }];
            
            [self setFailBlock:^(id data, NSError* error){
                
            }];
        }
        else
        {
            ABDebugLog_internal(@"We have no stored secret");
        }
    }
}
@end


@implementation AppBlade (AppBladeTokenRequestManager)


- (void)appBladeWebClient:(AppBladeWebOperation *)client receivedGenerateTokenResponse:(NSDictionary *)response
{
    NSString *deviceSecretString = [response objectForKey:kAppBladeApiTokenResponseDeviceSecretKey];
    if(deviceSecretString != nil) {
        ABDebugLog_internal(@"Updating token ");
        [self setAppBladeDeviceSecret:deviceSecretString]; //updating new device secret
        //immediately confirm we have a new token stored
        ABDebugLog_internal(@"token from request %@", [client sentDeviceSecret]);
        ABDebugLog_internal(@"confirming new token %@", [self appBladeDeviceSecret]);
        [self confirmToken:[self appBladeDeviceSecret]];
    }
    else {
        ABDebugLog_internal(@"ERROR parsing token refresh response, keeping last valid token %@", self.appBladeDeviceSecret);
        int statusCode = [[client.responseHeaders valueForKey:@"statusCode"] intValue];
        ABDebugLog_internal(@"token refresh response status code %d", statusCode);
        if(statusCode == kTokenInvalidStatusCode){
            [self.delegate appBlade:self applicationApproved:NO error:nil];
        }else if (statusCode == kTokenRefreshStatusCode){
            [self refreshToken:[self appBladeDeviceSecret]];
        }else{
            [self resumeCurrentPendingRequests]; //resume requests (in case it went through.)
        }
    }
}

- (void)appBladeWebClient:(AppBladeWebOperation *)client receivedConfirmTokenResponse:(NSDictionary *)response
{
    NSString *deviceSecretTimeout = [response objectForKey:kAppBladeApiTokenResponseTimeToLiveKey];
    if(deviceSecretTimeout != nil) {
        ABDebugLog_internal(@"Token confirmed. Business as usual.");
        [self resumeCurrentPendingRequests]; //continue requests that we could have had pending. they will be ignored if they fail with the old token.
    }
    else {
        ABDebugLog_internal(@"ERROR parsing token confirm response, keeping last valid token %@", self.appBladeDeviceSecret);
        int statusCode = [[client.responseHeaders valueForKey:@"statusCode"] intValue];
        ABDebugLog_internal(@"token confirm response status code %d", statusCode);
        if(statusCode == kTokenInvalidStatusCode){
            [self.delegate appBlade:self applicationApproved:NO error:nil];
        }else if (statusCode == kTokenRefreshStatusCode){
            [self refreshToken:[self appBladeDeviceSecret]];
        }else{
            [self resumeCurrentPendingRequests]; //resume requests (in case it went through.)
        }
    }
}



@end