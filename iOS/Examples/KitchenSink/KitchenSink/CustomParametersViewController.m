//
//  CustomParametersViewController.m
//  KitchenSink
//
//  Created by AndrewTremblay on 9/4/13.
//  Copyright (c) 2013 Raizlabs Corporation. All rights reserved.
//

#import "CustomParametersViewController.h"
#import "AppBlade.h"
#import "APBCustomParametersManager.h"

NSString* kDefaultEmptyParamMessage = @"(you currently have no parameters)";

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
    self.viewList = [NSArray arrayWithObjects:
                     self.headerView,
                     self.addParamView,
                     self.currentParamView,
                     self.actionsView,
                     nil];
    
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
    [self buildViewListForScrollView:self.scrollView];
    [self updateUiFromCurrentParams];
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

//update the parameter
-(void)updateUiFromCurrentParams
{
//    self.currentParamView
   NSString *textViewMessage = [NSString stringWithString:kDefaultEmptyParamMessage];
   NSDictionary *params = [[AppBlade sharedManager] getCustomParams];
    if([params count] != 0){
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];
        if(!jsonData){
            textViewMessage = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
    }
    //set the content of the customParam text field
    [self.currentParamsTextView setText:textViewMessage];
    
    //update contentsize of customParamTextField
//    self.currentParamsTextView
    
    //update contentsize of the containing customParamWrapperView

    //move any views beneath the customParamWrapperView
    
    //update ContentSize of scrollview
 //   [self.scrollView setContentSize:CGSizeMake(self.scrollView.frame.size.width, [self getHeightOfViewList])];
}

- (IBAction)submitNewCustomParam:(id)sender {
}

- (IBAction)actionButtonPressed:(id)sender {
}


- (IBAction)infoButtonPressed:(id)sender {

}

- (IBAction)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
@end
