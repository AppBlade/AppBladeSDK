//
//  ViewController.h
//  KitchenSink
//
//  Created by AppBlade on 7/15/13.
//  Copyright (c) 2013 Raizlabs Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "BaseFeatureViewController.h"
#import "CrashReportingViewController.h"
#import "CustomParametersViewController.h"

@interface ApplicationFeatureViewController : BaseFeatureViewController

@property (strong, nonatomic) CrashReportingViewController *crashVC;
@property (strong, nonatomic) CustomParametersViewController *customParamsVC;


@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

@property (strong, nonatomic) IBOutlet UIView *headerWrapperView;

#pragma mark - Feedback Report
@property (strong, nonatomic) IBOutlet UIView *feedbackWrapperView;
@property (strong, nonatomic) IBOutlet UIButton *showFormButton;
- (IBAction)showFormButtonPressed:(id)sender;

#pragma mark - Crash Report
@property (strong, nonatomic) IBOutlet UIView *crashReportWrapperView;
@property (strong, nonatomic) IBOutlet UIButton *crashButtonCustomException;
@property (strong, nonatomic) IBOutlet UIButton *crashOptionsListButton;
- (IBAction)crashButtonPressed:(id)sender;

#pragma mark - Session Tracking
@property (strong, nonatomic) IBOutlet UIView *sessiontrackingWrapperView;
@property (strong, nonatomic) IBOutlet UIButton *startSessionButton;
@property (strong, nonatomic) IBOutlet UIButton *endSessionButton;
- (IBAction)sessionButtonPressed:(id)sender;
@property (strong, nonatomic) IBOutlet UILabel *currentSessionDisplay;
-(void)updateCurrentSessionDisplay;

#pragma mark - Custom Params
@property (strong, nonatomic) IBOutlet UIView *customParamsWrapperView;
@property (strong, nonatomic) IBOutlet UIButton *seeCurrentParamsButton;
@property (strong, nonatomic) IBOutlet UIButton *setNewParameterButton;
@property (strong, nonatomic) IBOutlet UIButton *clearAllParamsButton;
- (IBAction)customParamButtonPressed:(id)sender;

#pragma mark - Automatic Updating
@property (strong, nonatomic) IBOutlet UIView *updateCheckingWrapperView;
@property (strong, nonatomic) IBOutlet UIButton *checkUpdatesButton;
-(IBAction)updateCheckButtonPressed:(id)sender;

#pragma mark - Authentication & Killswitch
@property (strong, nonatomic) IBOutlet UIView *authenticationWrapperView;
@property (strong, nonatomic) IBOutlet UIButton *authenticationButton;
- (IBAction)authenticationButtonPressed:(id)sender;

@end
