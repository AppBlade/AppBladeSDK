//
//  CrashSampleAppDelegate.m
//  CrashSample
//
//  Created by jkaufman on 9/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CrashSampleAppDelegate.h"
#import "CrashSampleViewController.h"
#import "AppBlade.h"

@implementation CrashSampleAppDelegate


@synthesize window=_window;

@synthesize viewController=_viewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
		// Populate with values from the project SDK settings
		// see README for details
    [[AppBlade sharedManager] setAppBladeProjectID:@"72143191-43cd-4d5a-a996-cfc10b25441a"];
    [[AppBlade sharedManager] setAppBladeProjectToken:@"d6ed480ad269f6899083f24a2abf3265"];
    [[AppBlade sharedManager] setAppBladeProjectSecret:@"7b8d05dd90f463736766591ce2654d88"];
    [[AppBlade sharedManager] setAppBladeProjectIssuedTimestamp:@"1328631126"];
    
    [[AppBlade sharedManager] catchAndReportCrashes];

    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    [[AppBlade sharedManager] allowFeedbackReporting];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

- (void)dealloc
{
    [_window release];
    [_viewController release];
    [super dealloc];
}

@end
