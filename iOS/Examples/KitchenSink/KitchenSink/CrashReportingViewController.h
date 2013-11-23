//
//  CrashReportingViewController.h
//  KitchenSink
//
//  Created by AndrewTremblay on 9/4/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseFeatureViewController.h"


@interface CrashReportingViewController : BaseFeatureViewController
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

- (IBAction)crashButtonPressed:(id)sender;

//each crash button has a corresponding crash function
@property (strong, nonatomic) IBOutlet UIButton *sigabrtCrashBtn;
@property (strong, nonatomic) IBOutlet UIButton *sigbusCrashBtn;
@property (strong, nonatomic) IBOutlet UIButton *sigfpeCrashBtn;
@property (strong, nonatomic) IBOutlet UIButton *sigillCrashBtn;
@property (strong, nonatomic) IBOutlet UIButton *sigpipeCrashBtn;
@property (strong, nonatomic) IBOutlet UIButton *sigsegvCrashBtn;
@property (strong, nonatomic) IBOutlet UIButton *nsExDefaultCrashBtn;
@property (strong, nonatomic) IBOutlet UIButton *nsExCustomCrashBtn;

@property (strong, nonatomic) IBOutlet UIView *crashChoiceView;

@property (strong, nonatomic) IBOutlet UIView *crashDescriptionView;
@property (weak, nonatomic) IBOutlet UITextField *crashCustomNameTextField;
- (IBAction)crashCustomNameChanged:(id)sender;
- (IBAction)crashCustomBeganEditing:(id)sender;
- (IBAction)crashCustomEndedEditing:(id)sender;


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
