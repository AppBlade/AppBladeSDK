//
//  CustomParametersViewController.m
//  KitchenSink
//
//  Created by AndrewTremblay on 9/4/13.
//  Copyright (c) 2013 Raizlabs Corporation. All rights reserved.
//

#import "CustomParametersViewController.h"

@interface CustomParametersViewController ()

@end

@implementation CustomParametersViewController

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
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillLayoutSubviews
{
    //Set Button Image insets
//    UIEdgeInsets insetsExample = UIEdgeInsetsMake(12, 12, 12, 12);
//    [self setBackgroundImageInsets:insetsExample forButton:self.showFormButton];
    
	//Build the cards in the scroll view
    CGFloat totalHeight = 0.0f;
    totalHeight = [self addView:self.headerView toScrollView:self.customParamsScrollView atVertOffset:totalHeight];
    totalHeight = [self addView:self.addParamView toScrollView:self.customParamsScrollView atVertOffset:totalHeight];
    totalHeight = [self addView:self.currentParamView toScrollView:self.customParamsScrollView atVertOffset:totalHeight];
    totalHeight = [self addView:self.actionsView toScrollView:self.customParamsScrollView atVertOffset:totalHeight];
    [self.customParamsScrollView setContentSize:CGSizeMake(self.view.bounds.size.width, totalHeight)];
}

-(CGFloat)addView:(UIView *)view toScrollView:(UIScrollView *)scrollView atVertOffset:(CGFloat)height {
    [scrollView addSubview:view];
    CGRect viewFrame = view.frame;
    viewFrame.origin.y = height;
    [view setFrame:viewFrame];
    return height + viewFrame.size.height;
}

-(void)setBackgroundImageInsets:(UIEdgeInsets)insets forButton:(UIButton*)button
{
    UIImage *bgImageNormal = [UIImage imageNamed:@"card-btn-normal@2x.png"];
    UIImage *bgImagePressed = [UIImage imageNamed:@"card-btn-pressed@2x.png"];
    [button setBackgroundImage:[bgImageNormal resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch] forState:UIControlStateNormal];
    [button setBackgroundImage:[bgImagePressed resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch] forState:UIControlStateHighlighted];
}

- (IBAction)submitNewCustomParam:(id)sender {
}

- (IBAction)actionButtonPressed:(id)sender {
}


- (IBAction)infoButtonPressed:(id)sender {
}
@end
