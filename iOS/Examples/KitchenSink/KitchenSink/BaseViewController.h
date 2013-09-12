//
//  BaseViewController.h
//  KitchenSink
//
//  Created by AndrewTremblay on 9/11/13.
//  Copyright (c) 2013 Raizlabs Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BaseViewController : UIViewController
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) UITextField *activeField;
@property (strong, nonatomic) NSArray *viewList;

-(CGFloat)buildViewListForScrollView:(UIScrollView*)scrollView;

-(void)setBackgroundImageInsets:(UIEdgeInsets)insets forButton:(UIButton*)button;
-(CGFloat)addView:(UIView *)view toScrollView:(UIScrollView *)scrollView atVertOffset:(CGFloat)height;

-(CGFloat)getHeightOfViewList;

- (void)textFieldDidBeginEditing:(UITextField *)textField;
- (void)textFieldDidEndEditing:(UITextField *)textField;

@end
