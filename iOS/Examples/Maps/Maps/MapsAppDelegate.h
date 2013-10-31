//
//  MapsAppDelegate.h
//  Maps
//
//  Created by Craig Spitzkoff on 5/31/11.
//  Copyright 2011 Raizlabs Corporation. All rights reserved.
//
#define APPBLADE_DEBUG_LOGGING 1
#define APPBLADE_ERROR_LOGGING 1
#import <UIKit/UIKit.h>

@class MainViewController;

@interface MapsAppDelegate : NSObject <UIApplicationDelegate, UIAlertViewDelegate> {
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet MainViewController *mainViewController;

@end
