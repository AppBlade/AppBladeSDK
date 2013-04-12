//
//  MapsAppDelegate.m
//  Maps
//
//  Created by Craig Spitzkoff on 5/31/11.
//  Copyright 2011 Raizlabs Corporation. All rights reserved.
//

#import "MapsAppDelegate.h"
#import "MainViewController.h"
#import "AppBlade.h"

@implementation MapsAppDelegate


@synthesize window=_window;
@synthesize mainViewController=_mainViewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    AppBlade *blade = [AppBlade sharedManager];
    [blade registerWithAppBladePlist];
    [blade catchAndReportCrashes];
    
    self.window.rootViewController = self.mainViewController;
    [self.window makeKeyAndVisible];
    

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
    [AppBlade endSession];

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
    
    
    // Check the app blade update status of this application.
   
    [[AppBlade sharedManager] checkForUpdates];

    [AppBlade startSession];
    [[AppBlade sharedManager] allowFeedbackReporting]; //Not a necessary call, but useful for more immediate feedback to show up on Appblade (prompts a check for pending feedback and sends it)
    [[AppBlade sharedManager] checkForExistingCrashReports]; //Not a necessary call, but better for more immediate crash reporting.

}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
    [AppBlade endSession];

}



@end
