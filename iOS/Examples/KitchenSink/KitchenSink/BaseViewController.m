//
//  BaseViewController.m
//  KitchenSink
//
//  Created by AndrewTremblay on 9/11/13.
//  Copyright (c) 2013 Raizlabs Corporation. All rights reserved.
//

#import "BaseViewController.h"

@interface BaseViewController ()

@end

@implementation BaseViewController
@synthesize scrollView;
@synthesize viewList;
@synthesize activeField;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}


//keyboard logic is base because it potentially can occur on any viewcontroller
- (void)viewWillAppear:(BOOL)animated
{
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(CGFloat)getHeightOfViewList
{
    CGFloat totalHeight = 0.0;
    if (self.viewList != nil) {
        for(UIView *v in self.viewList){
            totalHeight = totalHeight + v.frame.size.height;
        }
    }
    return totalHeight;

}

-(CGFloat)buildViewListForScrollView:(UIScrollView*)buildScrollView
{
    return [self addViews:self.viewList toScrollView:scrollView atVertOffset:0.0f];
}

-(CGFloat)addViews:(NSArray *)views toScrollView:(UIScrollView *)buildScrollView atVertOffset:(CGFloat)height
{
    CGFloat totalHeight = height;
    if (views != nil) {
        for(UIView *v in views){
            totalHeight = [self addView:v toScrollView:buildScrollView atVertOffset:totalHeight];
        }
        [buildScrollView setContentSize:CGSizeMake(self.view.bounds.size.width, totalHeight)];
    }
    return totalHeight;
}



-(CGFloat)addView:(UIView *)view toScrollView:(UIScrollView *)buildScrollView atVertOffset:(CGFloat)height
{
    [buildScrollView addSubview:view];
    CGRect viewFrame = view.frame;
    viewFrame.origin.y = height;
    [view setFrame:viewFrame];
    return height + viewFrame.size.height;
}

//used mostly for images
-(void)setBackgroundImageInsets:(UIEdgeInsets)insets forButton:(UIButton*)button
{
    UIImage *bgImageNormal = [UIImage imageNamed:@"card-btn-normal@2x.png"];
    UIImage *bgImagePressed = [UIImage imageNamed:@"card-btn-pressed@2x.png"];
    [button setBackgroundImage:[bgImageNormal resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch] forState:UIControlStateNormal];
    [button setBackgroundImage:[bgImagePressed resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch] forState:UIControlStateHighlighted];
}


#pragma mark - keyboard & textfield logic
// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    scrollView.contentInset = contentInsets;
    scrollView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your application might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    aRect.size.height -= kbSize.height;
    if (activeField!= nil && !CGRectContainsPoint(aRect, activeField.frame.origin) ) {
        CGPoint scrollPoint = CGPointMake(0.0, 438.0);
        [scrollView setContentOffset:scrollPoint animated:YES];
    }
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    scrollView.contentInset = contentInsets;
    scrollView.scrollIndicatorInsets = contentInsets;
    
    if(activeField != nil)
    {
        [activeField resignFirstResponder];
    }
}


- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    activeField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    activeField = nil;
}



@end
