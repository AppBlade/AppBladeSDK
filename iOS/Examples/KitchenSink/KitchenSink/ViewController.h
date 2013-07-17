//
//  ViewController.h
//  KitchenSink
//
//  Created by AppBlade on 7/15/13.
//  Copyright (c) 2013 Raizlabs Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
//form display button
@property (strong, nonatomic) IBOutlet UIButton *showFormButton;
- (IBAction)showFormButtonPressed:(id)sender;
//crash buttons
@property (strong, nonatomic) IBOutlet UIButton *crashButtonSigabrt;
@property (strong, nonatomic) IBOutlet UIButton *crashButtonCustomException;
@property (strong, nonatomic) IBOutlet UIButton *crashButtonSigsev;
- (IBAction)crashButtonPressed:(id)sender;

@end
