//
//  AppDelegate.m
//  KitchenSink
//
//  Created by AppBlade on 7/15/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//

#import "AppDelegate.h"
#import "ApplicationFeatureViewController.h"
//Use these defines to enable logging of internal AppBlade calls.
//these calls are only recommended in the case that you think
//something's wrong with the AppBlade SDK
#define APPBLADE_DEBUG_LOGGING 1  //Debug-level logs are turned on.
#define APPBLADE_ERROR_LOGGING 1  //Non-critical Error-level logs are on.

#import "AppBlade.h" //Don't forget to actually import the library!

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.viewController = [[ApplicationFeatureViewController alloc] initWithNibName:@"ApplicationFeatureViewController_iPhone" bundle:nil];
    // Override point for customization after application launch.
//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
//        self.viewController = [[ViewController alloc] initWithNibName:@"ViewController_iPhone" bundle:nil];
//    } else {
//        self.viewController = [[ViewController alloc] initWithNibName:@"ViewController_iPad" bundle:nil];
//    }
    
    // Configure Window
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self.viewController];
    [navigationController setNavigationBarHidden:YES animated:NO];
   
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        [[UINavigationBar appearance] setTintColor:[UIColor colorWithRed:225.0f/255.0f green:0.0f/255.0f blue:0.0f/255.0f alpha:1.0f]];
    }

    [self.window setRootViewController:navigationController];
    [self.window makeKeyAndVisible];

    /******************************************
     APPBLADE SETUP CALL
     ******************************************/
    AppBlade *blade = [AppBlade sharedManager];
    [blade registerWithAppBladePlist];
    
    /******************************************
     CRASH REPORTING CALL
     ******************************************/
    [blade catchAndReportCrashes];
    
    /******************************************
     FEEDBACK REPORTING SETUP CALL
     Must be called after window is keyed and visible, so make sure this is called after 
     [self.window makeKeyAndVisible];
     ******************************************/
    [blade allowFeedbackReporting]; //basic call that links a three-finger double-tap with the feedback modal
    //[blade setupCustomFeedbackReporting]; //custom call that sets up feedback reporting but doesn't link it with an action
    //call the modal from the interface with
    //[blade showFeedbackDialogue];
    //[blade showFeedbackDialogue:takeScreenshot]; has an optional takeScreenshot BOOL variable if you don't want to send a screnshot to AppBlade.
    
    
    /******************************************
     CUSTOM PARAMETERS CALL
    Can be called anywhere after registration. The changed custom parameters will affect all following API calls.
    ******************************************/
    [blade setCustomParam:@"I was set inside \"didFinishLaunchingWithOptions\" (on launch)" forKey:@"key_demo_val1"];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
