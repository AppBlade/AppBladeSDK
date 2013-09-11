//
//  CrashReportingViewController.h
//  KitchenSink
//
//  Created by AndrewTremblay on 9/4/13.
//  Copyright (c) 2013 Raizlabs Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CrashReportingViewController : UIViewController
@property (strong, nonatomic) IBOutlet UIScrollView *crashScrollView;
@property (strong, nonatomic) IBOutlet UIView *headerWrapperView;

@property (strong, nonatomic) IBOutlet UIView *crashChoiceView;

@property (strong, nonatomic) IBOutlet UIView *crashDescriptionView;


@property (strong, nonatomic) IBOutlet UIButton *backButton;
- (IBAction)backButtonPressed:(id)sender;


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
- (void)throwCustomTestNSException:(NSString *)reason;


@end
