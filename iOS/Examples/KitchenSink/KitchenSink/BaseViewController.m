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
@synthesize viewList;

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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)buildViewListForScrollView:(UIScrollView*)scrollView
{
    if (self.viewList != nil) {
        CGFloat totalHeight = 0.0f;
        for(UIView *v in self.viewList){
            totalHeight = [self addView:v toScrollView:scrollView atVertOffset:totalHeight];
        }
        [scrollView setContentSize:CGSizeMake(self.view.bounds.size.width, totalHeight)];
    }    
}

-(void)setBackgroundImageInsets:(UIEdgeInsets)insets forButton:(UIButton*)button
{
    UIImage *bgImageNormal = [UIImage imageNamed:@"card-btn-normal@2x.png"];
    UIImage *bgImagePressed = [UIImage imageNamed:@"card-btn-pressed@2x.png"];
    [button setBackgroundImage:[bgImageNormal resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch] forState:UIControlStateNormal];
    [button setBackgroundImage:[bgImagePressed resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch] forState:UIControlStateHighlighted];
}

-(CGFloat)addView:(UIView *)view toScrollView:(UIScrollView *)scrollView atVertOffset:(CGFloat)height
{
    [scrollView addSubview:view];
    CGRect viewFrame = view.frame;
    viewFrame.origin.y = height;
    [view setFrame:viewFrame];
    return height + viewFrame.size.height;
}

@end
