//
//  CustomParametersViewController.h
//  KitchenSink
//
//  Created by AndrewTremblay on 9/4/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "BaseFeatureViewController.h"

@interface CustomParametersViewController : BaseFeatureViewController

@property (strong, nonatomic) IBOutlet UIView *addParamView;
@property (strong, nonatomic) IBOutlet UITextField *keyTextField;
@property (strong, nonatomic) IBOutlet UITextField *valueTextField;
- (IBAction)didBeginEditingTextField:(id)sender;

- (IBAction)didExitValueTextField:(id)sender;
- (IBAction)didExitKeyTextField:(id)sender;

- (IBAction)submitNewCustomParam:(id)sender;


@property (strong, nonatomic) IBOutlet UIButton *keyInfoButton;
@property (strong, nonatomic) IBOutlet UIButton *valueInfoButton;
- (IBAction)infoButtonPressed:(id)sender;


@property (strong, nonatomic) IBOutlet UIView *currentParamView;
@property (strong, nonatomic) IBOutlet UITextView *currentParamsTextView;

@property (strong, nonatomic) IBOutlet UIView *actionsView;
@property (strong, nonatomic) IBOutlet UIButton *showFeedbackDialogButton;
@property (strong, nonatomic) IBOutlet UIButton *clearParamsButton;
- (IBAction)actionButtonPressed:(id)sender;

@end
