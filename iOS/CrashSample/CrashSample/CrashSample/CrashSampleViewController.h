//
//  CrashSampleViewController.h
//  CrashSample
//
//  Created by jkaufman on 9/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CrashSampleViewController : UIViewController {
    
}


- (IBAction)raiseException;
- (IBAction)raiseSignal;
- (IBAction)triggerBadAccess;
- (IBAction)triggerWatchdogTimeout;

@end
