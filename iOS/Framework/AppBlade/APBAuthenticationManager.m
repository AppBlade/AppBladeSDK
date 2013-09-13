//
//  AppBladeAuthentication.m
//  AppBlade
//
//  Created by AndrewTremblay on 7/16/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "APBAuthenticationManager.h"
#import "APBApplicationInfoManager.h" //for isAppStoreBuild

#import "AppBlade+PrivateMethods.h"
#import "APBSimpleKeychain.h"

NSString *authorizeURLFormat         = @"%@/api/3/authorize"; //GET  request
NSString *kTtlDictTimeoutKey =  @"ttlDate";
NSString *kTtlDictDateSetKey =  @"ttlInterval";


@implementation APBAuthenticationManager
@synthesize delegate;

- (id)initWithDelegate:(id<APBWebOperationDelegate>)webOpDelegate
{
    if((self = [super init])) {
        self.delegate = webOpDelegate;
    }
    
    return self;
}


-(void)checkApproval
{
    APBWebOperation * client = [[AppBlade sharedManager] generateWebOperation] ;
    [client checkPermissions];
    [[AppBlade sharedManager] addPendingRequest:client];
}

- (void)handleWebClient:(APBWebOperation *)client receivedPermissions:(NSDictionary *)permissions
{
    NSString *errorString = [permissions objectForKey:@"error"];
    BOOL signalApproval = [[[AppBlade sharedManager] delegate] respondsToSelector:@selector(appBlade:applicationApproved:error:)];
    
    if ((errorString && ![self withinStoredTTL]) || [[client.responseHeaders valueForKey:@"statusCode"] intValue] == 403) {
        [self closeTTLWindow];
        NSDictionary* errorDictionary = [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(errorString, nil), NSLocalizedDescriptionKey,  NSLocalizedString(errorString, nil),  NSLocalizedFailureReasonErrorKey, nil];
        NSError* error = [NSError errorWithDomain:kAppBladeErrorDomain code:kAppBladePermissionError userInfo:errorDictionary];
        
        if (signalApproval) {
            [[[AppBlade sharedManager] delegate]  appBlade:[AppBlade sharedManager] applicationApproved:NO error:error];
        }
    }
    else {
        NSNumber *ttl = [permissions objectForKey:kAppBladeApiTokenResponseTimeToLiveKey];
        if (ttl) {
            [self updateTTL:ttl];
        }
        
        // tell the client the application was approved.
        if (signalApproval) {
            [[[AppBlade sharedManager] delegate] appBlade:[AppBlade sharedManager] applicationApproved:YES error:nil];
        }
    }
    
}


-(void) permissionCallbackFailed:(APBWebOperation *)client withErrorString:(NSString*)errorString
{
    BOOL canSignalDelegate = [[[AppBlade sharedManager] delegate] respondsToSelector:@selector(appBlade:applicationApproved:error:)];

    // if the connection failed, see if the application is still within the previous TTL window.
    // If it is, then let the application run. Otherwise, ensure that the TTL window is closed and
    // prevent the app from running until the request completes successfully. This will prevent
    // users from unlocking an app by simply changing their clock.
    if ([self withinStoredTTL]) {
        if(canSignalDelegate) {
            [[[AppBlade sharedManager] delegate] appBlade:[AppBlade sharedManager] applicationApproved:YES error:nil];
        }
    }
    else {
        [self closeTTLWindow];
        if(canSignalDelegate) {
            NSDictionary* errorDictionary = nil;
            NSError* error = nil;
            if(errorString){
                errorDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                   NSLocalizedString(errorString, nil), NSLocalizedDescriptionKey,
                                   NSLocalizedString(errorString, nil),  NSLocalizedFailureReasonErrorKey, nil];
                error = [NSError errorWithDomain:kAppBladeErrorDomain code:kAppBladeParsingError userInfo:errorDictionary];
                
            }
            else
            {
                errorDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                   NSLocalizedString(@"Please check your internet connection to gain access to this application", nil), NSLocalizedDescriptionKey,
                                   NSLocalizedString(@"Please check your internet connection to gain access to this application", nil),  NSLocalizedFailureReasonErrorKey, nil];
                error = [NSError errorWithDomain:kAppBladeErrorDomain code:kAppBladeOfflineError userInfo:errorDictionary];
            }
            [[[AppBlade sharedManager] delegate] appBlade:[AppBlade sharedManager] applicationApproved:NO error:error];
        }else{
            ABErrorLog(@"ERROR AppBlade could not signal the delegate on invalid permissions.");
        }
        
    }
}

#pragma mark TTL (Time To Live) Methods


- (void)closeTTLWindow
{
    [APBSimpleKeychain delete:kAppBladeKeychainTtlKey];
}

- (void)updateTTL:(NSNumber*)ttl
{
    NSDate* ttlDate = [NSDate date];
    NSDictionary* appBlade = [NSDictionary dictionaryWithObjectsAndKeys:ttlDate, kTtlDictDateSetKey, ttl, kTtlDictDateSetKey, nil];
    [APBSimpleKeychain save:kAppBladeKeychainTtlKey data:appBlade];
}

// determine if we are within the range of the stored TTL for this application
- (BOOL)withinStoredTTL
{
    NSDictionary* appBlade_ttl = [APBSimpleKeychain load:kAppBladeKeychainTtlKey];
    NSDate* ttlDate = [appBlade_ttl objectForKey:kTtlDictDateSetKey];
    NSNumber* ttlInterval = [appBlade_ttl objectForKey:kTtlDictDateSetKey];
    
    // if we don't have either value, we're definitely not within a stored TTL
    if(nil == ttlInterval || nil == ttlDate)
        return NO;
    
    // if the current date is earlier than our last ttl date, the user has turned their clock back. Invalidate.
    NSDate* currentDate = [NSDate date];
    if ([currentDate compare:ttlDate] == NSOrderedAscending) {
        return NO;
    }
    
    // if the current date is later than the ttl date adjusted with the TTL, the window has expired
    NSDate* adjustedTTLDate = [ttlDate dateByAddingTimeInterval:[ttlInterval integerValue]];
    if ([currentDate compare:adjustedTTLDate] == NSOrderedDescending) {
        return NO;
    }
    
    return YES;
}


-(NSDictionary *)currentTTL
{
    NSDictionary* appBlade_ttl = [APBSimpleKeychain load:kAppBladeKeychainTtlKey];
    return appBlade_ttl;
}

@end


@implementation APBWebOperation (Authorization)
- (void)checkPermissions
{
    [self setApi: AppBladeWebClientAPI_Permissions];
    BOOL hasFairplay = [[AppBlade sharedManager] isAppStoreBuild];
    if(hasFairplay){
        //we're signed by apple, skip authentication. Go straight to delegate.
        ABDebugLog_internal(@"Binary signed by Apple, skipping permissions check forever");
        NSDictionary *fairplayPermissions = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:INT_MAX], kAppBladeApiTokenResponseTimeToLiveKey, nil];
        APBWebOperation *selfReference = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[AppBlade sharedManager] appBladeWebClient:selfReference receivedPermissions:fairplayPermissions];
        });
    }
    else
    {
        //SET THE BLOCKS
        __block APBWebOperation *blocksafeSelf = self;
        
        // Create the request.
        self.prepareBlock = ^(id preparationData){ //preparationData not used in this case
            NSString* urlString = [NSString stringWithFormat:authorizeURLFormat, [blocksafeSelf.delegate appBladeHost]];
            NSURL* projectUrl = [NSURL URLWithString:urlString];
            NSMutableURLRequest* apiRequest = [blocksafeSelf requestForURL:projectUrl];
            [apiRequest setHTTPMethod:@"GET"];
            [apiRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"]; //we want json
            [blocksafeSelf addSecurityToRequest:apiRequest];
        };

        self.requestCompletionBlock = ^(NSMutableURLRequest *request, id rawSentData, NSDictionary* responseHeaders, NSMutableData* receivedData, NSError *webError){
            NSError *parseError = nil;
            NSDictionary *plist = [NSJSONSerialization JSONObjectWithData:receivedData options:nil error:&parseError];
            //BOOL showUpdatePrompt = [self.request valueForHTTPHeaderField:@"SHOULD_PROMPT"];
            if (plist && parseError == NULL) {
                APBWebOperation *selfReference = blocksafeSelf;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[AppBlade sharedManager] appBladeWebClient:selfReference receivedPermissions:plist];
                });
            }
            else
            {
                ABErrorLog(@"Error parsing permisions json: %@", [parseError debugDescription]);
                APBWebOperation *selfReference = blocksafeSelf;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[AppBlade sharedManager] appBladeWebClient:selfReference failedPermissions:@"An invalid response was received from AppBlade; please contact support"];
                });
            }
        };
    }
    
    [self setRequestCompletionBlock:^(NSMutableURLRequest *request, id rawSentData, NSDictionary* responseHeaders, NSMutableData* receivedData, NSError *webError){
        
    }];
    
    [self setSuccessBlock:^(id data, NSError* error){
        
    }];
    
    [self setFailBlock:^(id data, NSError* error){
        
    }];

}

@end



@implementation AppBlade (Authorization)
    @dynamic authenticationManager; //dynamic so the compiler won't create an overriding implementation

    - (void)appBladeWebClient:(APBWebOperation *)client receivedPermissions:(NSDictionary *)permissions
    {
        [self.authenticationManager handleWebClient:client receivedPermissions:permissions];
    }

    - (void)appBladeWebClient:(APBWebOperation *)client failedPermissions:(NSString *)errorString
    {
        [self.authenticationManager permissionCallbackFailed:client withErrorString:errorString];
    }

@end

