//
//  AppBladeUpdates.m
//  AppBlade
//
//  Created by AndrewTremblay on 7/16/13.
//  Copyright (c) 2013 AppBlade. All rights reserved.
//

#import "APBUpdatesManager.h"
#import "APBApplicationInfoManager.h" //for isAppStoreBuild
#import "AppBlade+PrivateMethods.h"

NSString *updateURLFormat            = @"%@/api/3/updates";

@implementation APBUpdatesManager
@synthesize delegate;
@synthesize upgradeLink;

- (id)initWithDelegate:(id<APBWebOperationDelegate>)webOpDelegate
{
    if((self = [super init])) {
        self.delegate = webOpDelegate;
    }
    
    return self;
}


- (void)checkForUpdates
{
    ABDebugLog_internal(@"Checking for updates");
    APBWebOperation * client = [[AppBlade sharedManager] generateWebOperation];
    [client checkForUpdates];
    [[AppBlade sharedManager] addPendingRequest:client];
}


-(void)handleWebClient:(APBWebOperation *)client receivedUpdate:(NSDictionary *)updateData
{
    // determine if there is an update available
    NSDictionary* update = [updateData objectForKey:@"update"];
    if(update)
    {
        NSString* updateMessage = [update objectForKey:@"message"];
        NSString* updateURL = [update objectForKey:@"url"];
        
        if ([[[AppBlade sharedManager] updatesManager] respondsToSelector:@selector(appBlade:updateAvailable:updateMessage:updateURL:)]) {
            [[[AppBlade sharedManager] updatesManager] appBlade:[AppBlade sharedManager] updateAvailable:YES updateMessage:updateMessage updateURL:updateURL];
        }
    }
}

- (void)updateCallbackFailed:(APBWebOperation *)client withErrorString:(NSString*)errorString
{

}

#pragma AppBladeUpdatesManagerDelegate

-(void) appBlade:(AppBlade *)appBlade updateAvailable:(BOOL)update updateMessage:(NSString*)message updateURL:(NSString*)url
{
    if (update) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Update Available"
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Upgrade", nil];
        alert.tag = kUpdateAlertTag;
        self.upgradeLink = [NSURL URLWithString:url];
        [alert show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == kUpdateAlertTag) {
        if (buttonIndex == 1  && self.upgradeLink != nil) {
            [[UIApplication sharedApplication] openURL:self.upgradeLink];
            self.upgradeLink = nil;
            exit(0);
        }
    }
}

@end


@implementation APBWebOperation (Updates)

- (void)checkForUpdates
{
    BOOL hasFairplay = [[AppBlade sharedManager] isAppStoreBuild];
    if(hasFairplay){
        //we're signed by apple, skip updating. Go straight to delegate.
        ABDebugLog_internal(@"Binary signed by Apple, skipping update check forever");
        NSDictionary *fairplayPermissions = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:INT_MAX], @"ttl", nil];
        APBWebOperation *selfReference = self;
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
        [apiRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"]; //we want json
        ABDebugLog_internal(@"Update call %@", urlString);
    }
    
    __block APBWebOperation* blocksafeSelf = self;

    [self setPrepareBlock:^(NSMutableURLRequest *request){
        [blocksafeSelf addSecurityToRequest:request]; 
    }];
    
    [self setRequestCompletionBlock:^(NSMutableURLRequest *request, id rawSentData, NSDictionary* responseHeaders, NSMutableData* receivedData, NSError *webError){
        NSError *error = nil;
        NSString* receivedString = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
        if(receivedString)
            ABDebugLog_internal(@"Received Update Response from AppBlade: %@", receivedString);
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:receivedData options:nil error:&error];
        if (json && error == NULL) {
            if(blocksafeSelf.successBlock){
                blocksafeSelf.successBlock(json, error);
            }
        }
        else
        {
            if(blocksafeSelf.failBlock != nil){
                blocksafeSelf.failBlock(json, error);
            }
        }
    }];
    
    [self setSuccessBlock:^(id data, NSError* error){
        [[AppBlade sharedManager] appBladeWebClient:blocksafeSelf receivedUpdate:data];
    }];
    
    [self setFailBlock:^(id data, NSError* error){
        ABErrorLog(@"Error parsing update plist: %@", [error debugDescription]);
        APBWebOperation *selfReference = blocksafeSelf;
        id<APBWebOperationDelegate> delegateReference = blocksafeSelf.delegate;
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegateReference appBladeWebClientFailed:selfReference withErrorString:@"An invalid update response was received from AppBlade; please contact support"];
        });
        

    }];

}

@end


@implementation AppBlade (Updates)
@dynamic updatesManager;

- (void)appBladeWebClient:(APBWebOperation *)client receivedUpdate:(NSDictionary*)updateData
{
#ifndef SKIP_AUTO_UPDATING
    [self.updatesManager handleWebClient:client receivedUpdate:updateData];
#endif
}


@end