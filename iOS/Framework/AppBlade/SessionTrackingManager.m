//
//  SessionTracking.m
//  AppBlade
//
//  Created by AndrewTremblay on 7/16/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "SessionTrackingManager.h"
#import "AppBlade+PrivateMethods.h"

@implementation SessionTrackingManager
@synthesize delegate;
@synthesize sessionStartDate;


- (id)initWithDelegate:(id<AppBladeWebOperationDelegate>)webOpDelegate
{
    if((self = [super init])) {
        self.delegate = webOpDelegate;
    }
    
    return self;
}

- (void)logSessionStart
{
    NSString* sessionFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeSessionFile];
    ABDebugLog_internal(@"Checking Session Path: %@", sessionFilePath);
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:sessionFilePath]) {
        NSArray* sessions = (NSArray*)[[AppBlade sharedManager] readFile:sessionFilePath];
        ABDebugLog_internal(@"%d Sessions Exist, posting them", [sessions count]);
        
        if(![[AppBlade sharedManager]  hasPendingSessions]){
            AppBladeWebOperation * client = [[AppBlade sharedManager] generateWebOperation];
            [client postSessions:sessions];
            [[AppBlade sharedManager] addPendingRequest:client];
        }
    }
    self.sessionStartDate = [NSDate date];
}

- (void)logSessionEnd
{
    NSDictionary* sessionDict = [NSDictionary dictionaryWithObjectsAndKeys:[self  sessionStartDate], @"started_at", [NSDate date], @"ended_at", [[AppBlade sharedManager] getCustomParams], @"custom_params", nil];
    
    NSMutableArray* pastSessions = nil;
    NSString* sessionFilePath = [[AppBlade cachesDirectoryPath] stringByAppendingPathComponent:kAppBladeSessionFile];
    if ([[NSFileManager defaultManager] fileExistsAtPath:sessionFilePath]) {
        NSArray* sessions = (NSArray*)[[AppBlade sharedManager] readFile:sessionFilePath];
        pastSessions = [sessions mutableCopy] ;
    }
    else {
        pastSessions = [NSMutableArray arrayWithCapacity:1];
    }
    
    [pastSessions addObject:sessionDict];
    
    NSData* sessionData = [NSKeyedArchiver archivedDataWithRootObject:pastSessions];
    [sessionData writeToFile:sessionFilePath atomically:YES];    
}


@end
