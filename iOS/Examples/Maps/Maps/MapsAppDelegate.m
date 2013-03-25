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
    blade.appBladeProjectID = @"ca460dcb-b7c2-43c1-ba50-8b6cda63f369";
    blade.appBladeProjectToken = @"8f1792db8a39108c14fa8c89663eec98";
    blade.appBladeProjectSecret = @"c8536a333fb292ba46fc98719c1cfdf6";
    blade.appBladeProjectIssuedTimestamp = @"1316609918";
    
    
    blade.appBladeProjectID = @"4e00b9c7-f80b-43ee-98ef-6144b9162c04";
    blade.appBladeProjectToken = @"412ceb21adf6214270a19854bd375ee7";
    blade.appBladeProjectSecret = @"8ddbfe87a73e55e2a4c13c0df0c4eae9";
    blade.appBladeProjectIssuedTimestamp = @"1359040311";

    
//    blade.appBladeHost = @"http://10.1.10.42:3000";
    
    // Check the app blade status of this application.
    
    // See AppBladeKeys.plist for the format in which to send your keys.
    // This is optional, but you should not set the keys yourself AND use the plist.
    // [blade loadSDKKeysFromPlist:[[NSBundle mainBundle] pathForResource:@"AppBladeKeys" ofType:@"plist"]]
    // Fill AppBladeKeys.plist with your own credentials to test
    [blade setCustomParam:@"CustomKey1" withValue:@"FirstSend"];
    
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
