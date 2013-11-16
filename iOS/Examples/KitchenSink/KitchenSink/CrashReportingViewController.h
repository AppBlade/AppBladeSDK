//
//  CrashReportingViewController.h
//  KitchenSink
//
//  Created by AndrewTremblay on 9/4/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CrashReportingViewController : UIViewController


#pragma mark - Crash "Helpers"
// credit to CrashKit for these .
//https://github.com/kaler/CrashKit
- (void)sigabrt;
- (void)sigbus;
- (void)sigfpe;
- (void)sigill;
- (void)sigpipe;
- (void)sigsegv;
- (void)throwDefaultNSException;
- (void)throwCustomNSException:(NSString *)reason;


@end
