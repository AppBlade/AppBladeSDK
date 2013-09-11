//
//  ViewController.m
//  KitchenSink
//
//  Created by AppBlade on 7/15/13.
//  Copyright (c) 2013 Raizlabs Corporation. All rights reserved.
//

#import "ViewController.h"

#import "AppBlade.h"
#import "APBSessionTrackingManager.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.crashVC = [[CrashReportingViewController alloc] init];
    self.customParamsVC = [[CustomParametersViewController alloc] init];
    
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self
                                   selector:@selector(updateCurrentSessionDisplay) userInfo:nil repeats:YES];
}

-(void)viewWillLayoutSubviews
{
    //Set Button Image insets
    UIEdgeInsets insetsExample = UIEdgeInsetsMake(12, 12, 12, 12);
    [self setBackgroundImageInsets:insetsExample forButton:self.showFormButton];
    [self setBackgroundImageInsets:insetsExample forButton:self.crashButtonCustomException];
    [self setBackgroundImageInsets:insetsExample forButton:self.crashOptionsListButton];
    [self setBackgroundImageInsets:insetsExample forButton:self.startSessionButton];
    [self setBackgroundImageInsets:insetsExample forButton:self.endSessionButton];
    [self setBackgroundImageInsets:insetsExample forButton:self.seeCurrentParamsButton];
    [self setBackgroundImageInsets:insetsExample forButton:self.setNewParameterButton];
    [self setBackgroundImageInsets:insetsExample forButton:self.clearAllParamsButton];
    [self setBackgroundImageInsets:insetsExample forButton:self.checkUpdatesButton];
    [self setBackgroundImageInsets:insetsExample forButton:self.authenticationButton];
    
    
	//Build the cards in the scroll view
    CGFloat totalHeight = 0.0f;
    totalHeight = [self addView:self.headerWrapperView toScrollView:self.scrollView atVertOffset:totalHeight];
    totalHeight = [self addView:self.feedbackWrapperView toScrollView:self.scrollView atVertOffset:totalHeight];
    totalHeight = [self addView:self.crashReportWrapperView toScrollView:self.scrollView atVertOffset:totalHeight];
    totalHeight = [self addView:self.sessiontrackingWrapperView toScrollView:self.scrollView atVertOffset:totalHeight];
    totalHeight = [self addView:self.customParamsWrapperView toScrollView:self.scrollView atVertOffset:totalHeight];
    totalHeight = [self addView:self.updateCheckingWrapperView toScrollView:self.scrollView atVertOffset:totalHeight];
    totalHeight = [self addView:self.authenticationWrapperView toScrollView:self.scrollView atVertOffset:totalHeight];
    [self.scrollView setContentSize:CGSizeMake(self.view.bounds.size.width, totalHeight)];

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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




#pragma mark - Button Handling

- (IBAction)showFormButtonPressed:(id)sender {
    [[AppBlade sharedManager] showFeedbackDialogue];
}


- (IBAction)crashButtonPressed:(id)sender {
    if(sender == self.crashButtonCustomException){
        [self.crashVC throwDefaultNSException];
    }else if(sender == self.crashOptionsListButton){
        [[self navigationController] pushViewController:self.crashVC animated:true];
    }else {
        NSLog(@"Error causing error: Unknown sender.");
    }
}

- (IBAction)sessionButtonPressed:(id)sender
{
    if(sender == self.startSessionButton){
        [[AppBlade sharedManager] logSessionStart];
    }else if(sender == self.endSessionButton){
        [[AppBlade sharedManager] logSessionEnd];
    }else{
        NSLog(@"Error triggering session: Unknown sender.");
    }
}


-(IBAction)customParamButtonPressed:(id)sender
{
    if(sender == self.seeCurrentParamsButton){
        //TODO: prompt custom params view controller
    }else if(sender == self.setNewParameterButton){
        [[AppBlade sharedManager] setCustomParam:@"Test" forKey:@"SimpleTestVar"];
    }else if(sender == self.clearAllParamsButton){
        [[AppBlade sharedManager] clearAllCustomParams];
    }else{
        NSLog(@"Error triggering custom Params function: Unknown sender.");
    }
}


-(IBAction)updateCheckButtonPressed:(id)sender
{
    if(sender == self.checkUpdatesButton){
        [[AppBlade sharedManager] checkForUpdates];
    }else{
        NSLog(@"Error triggering update check: Unknown sender.");
    }
}


-(IBAction)authenticationButtonPressed:(id)sender
{
    if(sender == self.authenticationButton)
    {
        [[AppBlade sharedManager] checkApproval];
    }else{
        NSLog(@"Error triggering authentication: Unknown sender.");
    }
}


-(void)updateCurrentSessionDisplay
{
    
    NSMutableString *currentSessionStatus = [NSMutableString stringWithString:@"Current Session Status:\n"];
    NSDictionary *currentSession = [[AppBlade sharedManager] currentSession];
    if (currentSession == nil) {
        [currentSessionStatus appendString:@"No Current Session"];
    }else{
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterNoStyle];
        [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
        
        NSDate *sessionStartDate =[currentSession objectForKey:kSessionStartDate];
        [currentSessionStatus appendFormat:@"Started: %@ \nElapsed:%f", [dateFormatter stringFromDate:sessionStartDate], [sessionStartDate timeIntervalSinceNow]];
    }
    
    [self.currentSessionDisplay setText:currentSessionStatus];
}



@end
