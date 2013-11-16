//
//  AppBladeTokenRequestManager.m
//  AppBlade
//
//  Created by AndrewTremblay on 8/29/13.
//  Copyright (c) 2013 AppBlade. All rights reserved.
//

#import "APBTokenManager.h"
#import "APBApplicationInfoManager.h" //for isAppStoreBuild

#import "APBSimpleKeychain.h"
#import "AppBladeLogging.h"
#import "AppBlade+PrivateMethods.h"
#import "AppBladeLogging.h"

NSString *tokenGenerateURLFormat     = @"%@/api/3/authorize/new";
NSString *tokenConfirmURLFormat      = @"%@/api/3/authorize"; //keeping these separate for readiblilty and possible editing later

@interface APBTokenManager()
    @property (nonatomic, retain) NSOperationQueue* tokenRequests;
@end


@implementation APBTokenManager
    @synthesize appBladeDeviceSecret = _appbladeDeviceSecret;
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
    APBWebOperation * client = [[AppBlade sharedManager] generateWebOperation];
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
    
    APBWebOperation * client = [[AppBlade sharedManager] generateWebOperation];
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

#pragma mark Device Secret Methods

-(NSMutableDictionary*) appBladeDeviceSecrets
{
    NSMutableDictionary* appBlade_deviceSecret_dict = (NSMutableDictionary* )[APBSimpleKeychain load:kAppBladeKeychainDeviceSecretKey];
    if(nil == appBlade_deviceSecret_dict)
    {
        appBlade_deviceSecret_dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"", kAppBladeKeychainDeviceSecretKeyNew, @"", kAppBladeKeychainDeviceSecretKeyOld, @"", kAppBladeKeychainPlistHashKey, nil];
        [APBSimpleKeychain save:kAppBladeKeychainDeviceSecretKey data:appBlade_deviceSecret_dict];
        ABDebugLog_internal(@"Device Secrets were nil. Reinitialized.");
    }
    return appBlade_deviceSecret_dict;
}


- (NSString *)appBladeDeviceSecret
{
    //get the last available device secret
    NSMutableDictionary* appBlade_keychain_dict = [self appBladeDeviceSecrets];
    NSString* device_secret_stored = (NSString*)[appBlade_keychain_dict valueForKey:kAppBladeKeychainDeviceSecretKeyNew]; //assume we have the newest in new_secret key
    NSString* device_secret_stored_old = (NSString*)[appBlade_keychain_dict valueForKey:kAppBladeKeychainDeviceSecretKeyOld];
    if(nil == device_secret_stored || [device_secret_stored isEqualToString:@""])
    {
        ABDebugLog_internal(@"Device Secret from storage:%@, falling back to old value:(%@).", (device_secret_stored == nil  ? @"nil" : ( [device_secret_stored isEqualToString:@""] ? @"empty" : device_secret_stored) ), (device_secret_stored_old == nil  ? @"nil" : ( [device_secret_stored_old isEqualToString:@""] ? @"empty" : device_secret_stored_old) ));
        _appbladeDeviceSecret = (NSString*)[device_secret_stored_old copy];     //if we have no stored keys, returns default empty string
    }else
    {
        _appbladeDeviceSecret = (NSString*)[device_secret_stored copy];
    }
    
    return _appbladeDeviceSecret;
}

- (void) setAppBladeDeviceSecret:(NSString *)appBladeDeviceSecret
{
    //always store the last two device secrets
    NSMutableDictionary* appBlade_keychain_dict = [self appBladeDeviceSecrets];
    NSString* device_secret_latest_stored = [appBlade_keychain_dict objectForKey:kAppBladeKeychainDeviceSecretKeyNew]; //get the newest key (to our knowledge)
    if((nil != appBladeDeviceSecret) && ![device_secret_latest_stored isEqualToString:appBladeDeviceSecret]) //if we don't already have the "new" token as the newest token
    {
        [appBlade_keychain_dict setObject:[device_secret_latest_stored copy] forKey:kAppBladeKeychainDeviceSecretKeyOld]; //we don't care where the old key goes
        [appBlade_keychain_dict setObject:[appBladeDeviceSecret copy] forKey:kAppBladeKeychainDeviceSecretKeyNew];
        //update the newest key
    }
    //save the stored keychain
    [APBSimpleKeychain save:kAppBladeKeychainDeviceSecretKey data:appBlade_keychain_dict];
}


- (void)clearAppBladeKeychain
{
    NSMutableDictionary* appBlade_keychain_dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"", kAppBladeKeychainDeviceSecretKeyNew, @"", kAppBladeKeychainDeviceSecretKeyOld, @"", kAppBladeKeychainPlistHashKey, nil];
    [APBSimpleKeychain save:kAppBladeKeychainDeviceSecretKey data:appBlade_keychain_dict];
}

- (void)clearStoredDeviceSecrets
{
    NSMutableDictionary* appBlade_keychain_dict = [self appBladeDeviceSecrets];
    if(nil != appBlade_keychain_dict)
    {
        [appBlade_keychain_dict setValue:@"" forKey:kAppBladeKeychainDeviceSecretKeyNew];
        [appBlade_keychain_dict setValue:@"" forKey:kAppBladeKeychainDeviceSecretKeyOld];
        [APBSimpleKeychain save:kAppBladeKeychainDeviceSecretKey data:appBlade_keychain_dict];
        ABDebugLog_internal(@"Cleared device secrets.");
    }
}


-(BOOL)hasDeviceSecret
{
    return [self appBladeDeviceSecret] != nil && [[self appBladeDeviceSecret] length] != 0;
}

- (BOOL)isDeviceSecretBeingConfirmed
{
    BOOL tokenRequestInProgress = ([[self tokenRequests] operationCount]) != 0;
    BOOL processIsNotFinished = tokenRequestInProgress; //if we have a process, assume it's not finished, if we have one then of course it's finished
    if(tokenRequestInProgress) { //the queue has a maximum concurrent process size of one, that's why we can do what comes next
        APBWebOperation *process = (APBWebOperation *)[[[self tokenRequests] operations] objectAtIndex:0];
        processIsNotFinished = ![process isFinished];
    }
    return tokenRequestInProgress && processIsNotFinished;
}


@end

@implementation APBWebOperation (TokenManager)


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
        APBWebOperation *selfReference = self;
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
            APBWebOperation *selfReference = self;
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


@implementation AppBlade (TokenManager)
@dynamic tokenManager;



- (void)appBladeWebClient:(APBWebOperation *)client receivedGenerateTokenResponse:(NSDictionary *)response
{
    NSString *deviceSecretString = [response objectForKey:kAppBladeApiTokenResponseDeviceSecretKey];
    if(deviceSecretString != nil) {
        ABDebugLog_internal(@"Updating token ");
        [self setAppBladeDeviceSecret:deviceSecretString]; //updating new device secret
        //immediately confirm we have a new token stored
        ABDebugLog_internal(@"token from request %@", [client sentDeviceSecret]);
        ABDebugLog_internal(@"confirming new token %@", [self appBladeDeviceSecret]);
        [self.tokenManager confirmToken:[self appBladeDeviceSecret]];
    }
    else {
        ABDebugLog_internal(@"ERROR parsing token refresh response, keeping last valid token %@", self.appBladeDeviceSecret);
        int statusCode = [[client.responseHeaders valueForKey:@"statusCode"] intValue];
        ABDebugLog_internal(@"token refresh response status code %d", statusCode);
        if(statusCode == kTokenInvalidStatusCode){
            [self.delegate appBlade:self applicationApproved:NO error:nil];
        }else if (statusCode == kTokenRefreshStatusCode){
            [self.tokenManager refreshToken:[self appBladeDeviceSecret]];
        }else{
            [self resumeCurrentPendingRequests]; //resume requests (in case it went through.)
        }
    }
}

- (void)appBladeWebClient:(APBWebOperation *)client receivedConfirmTokenResponse:(NSDictionary *)response
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
            [self.tokenManager refreshToken:[self appBladeDeviceSecret]];
        }else{
            [self resumeCurrentPendingRequests]; //resume requests (in case it went through.)
        }
    }
}



@end