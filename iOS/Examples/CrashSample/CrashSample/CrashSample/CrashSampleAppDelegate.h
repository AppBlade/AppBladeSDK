//
//  CrashSampleAppDelegate.h
//  CrashSample
//
//  Created by jkaufman on 9/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CrashSampleViewController;

@interface CrashSampleAppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet CrashSampleViewController *viewController;

@end
