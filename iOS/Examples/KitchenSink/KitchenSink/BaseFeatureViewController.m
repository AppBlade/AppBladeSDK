//
//  BaseViewController.m
//  KitchenSink
//
//  Created by AndrewTremblay on 9/11/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//

#import "BaseFeatureViewController.h"

@interface BaseFeatureViewController ()

@end

@implementation BaseFeatureViewController
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
    
    [[UINavigationBar appearance] setBackgroundColor:[UIColor colorWithRed:225.0f/255.0f green:0.0f/255.0f blue:0.0f/255.0f alpha:1.0f]];
    NSDictionary *titleTextAttributes = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:UITextAttributeTextColor];

//for backwards compatibility
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
//        [[UINavigationBar appearance] setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
        [[UINavigationBar appearance] setBackgroundColor:[UIColor colorWithRed:225.0f/255.0f green:0.0f/255.0f blue:0.0f/255.0f alpha:1.0f]];
    }else{
        [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:225.0f/255.0f green:0.0f/255.0f blue:0.0f/255.0f alpha:1.0f]];
        [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    }
    
    [[UINavigationBar appearance] setTitleTextAttributes:titleTextAttributes];

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

/* 
 Builders
*/
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


/*
 Resizers
 Resizes currently only respect new heights, not new widths.
 */

//unknown behavior if subView is not really a direct child of view 
-(CGFloat)resizeSubView:(UIView*)subView ofViewListElement:(UIView *)view fromSize:(CGSize)oldSize toSize:(CGSize)newSize
{
    NSLog(@"old subview size %f", oldSize.height);
    NSLog(@"new subview height %f", newSize.height);

    NSUInteger index = [self.viewList indexOfObject:view];
    if(index != NSNotFound){
        CGFloat heightDiff = newSize.height - oldSize.height ;
        CGRect subF = subView.frame;
        [subView setFrame:CGRectMake(subF.origin.x, subF.origin.y, subF.size.width, subF.size.height + heightDiff)];
        NSLog(@"subview delta %f", heightDiff);        
        CGRect viewF = view.frame;
        NSLog(@"old height %f", viewF.size.height);
        [view setFrame:CGRectMake(viewF.origin.x, viewF.origin.y, viewF.size.width, (viewF.size.height + heightDiff))];
        NSLog(@"new height %f", view.frame.size.height);

        [self resizeViewsFromIndex:index];
    }else{
        NSLog(@"ERROR: could not find view");
    }
    return [self getHeightOfViewList];
}


-(CGFloat)resizeViewListElement:(UIView*)view toSize:(CGSize)newSize
{
    NSUInteger index = [self.viewList indexOfObject:view];
    if(index != NSNotFound){
        CGRect r = view.frame;
        NSLog(@"old height %f", view.frame.size.height);
        [view setFrame:CGRectMake(r.origin.x, r.origin.y, newSize.width, newSize.height)];
        NSLog(@"new height %f", view.frame.size.height);
        [self resizeViewsFromIndex:index];
    }else{
        NSLog(@"ERROR: could not find view");
    }
    return [self getHeightOfViewList];
}


-(void)resizeViewsFromIndex:(NSUInteger) startIndex
{
    UIView *v = [self.viewList objectAtIndex:startIndex];
    CGFloat offset = v.frame.origin.y + v.frame.size.height;
    
    for(NSUInteger i = (startIndex + 1); i < self.viewList.count; i++){
        v = [self.viewList objectAtIndex:i];
        CGRect r = v.frame;
        v.frame = CGRectMake(r.origin.x, offset, r.size.width, r.size.height);
        offset = v.frame.origin.y + v.frame.size.height;
    }
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
