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
    // Configure AppBlade
    AppBlade *blade = [AppBlade sharedManager];

    // Populate with values from the project SDK settings or load keys from plist
    // see README for details
//    blade.appBladeProjectID = @""; //UUID
//    blade.appBladeProjectToken = @""; //Token
//    blade.appBladeProjectSecret = @""; //Secret
//    blade.appBladeProjectIssuedTimestamp = @""; //Issued at
    
    blade.appBladeHost = @"http://127.0.0.1:3000";
    blade.appBladeProjectID = @"559ec33b-2fab-47a8-945f-d718eb79845a";
    blade.appBladeProjectToken = @"def1323a15f61cffc4dfdbbbf4c0d194";
    blade.appBladeProjectSecret = @"87b9e7714d6f39f45a1c35f053554e98";
    blade.appBladeProjectIssuedTimestamp = @"1353360225";
  
    // See AppBladeKeys.plist for the format in which to send your keys.
    // This is optional, but you should not set the keys yourself AND use the plist.
    // [blade loadSDKKeysFromPlist:[[NSBundle mainBundle] pathForResource:@"AppBladeKeys" ofType:@"plist"]]
    // Fill AppBladeKeys.plist with your own credentials to test

    [blade catchAndReportCrashes];
    
    self.window.rootViewController = self.mainViewController;
    [self.window makeKeyAndVisible];
    
    [blade allowFeedbackReporting];

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
    
    // Check the app blade status of this application.
    [[AppBlade sharedManager] checkApproval];
    [AppBlade startSession];
    
    
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
