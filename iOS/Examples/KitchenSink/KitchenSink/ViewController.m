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
    
    //the contents of our scrollview and the order of our cells
    //edt this list to change the appearance of the list.
    self.viewList = [[NSArray alloc] initWithObjects:
                     self.headerWrapperView,
                     self.feedbackWrapperView,
                     self.crashReportWrapperView,
                     self.sessiontrackingWrapperView,
                     self.customParamsWrapperView,
                     self.updateCheckingWrapperView,
                     self.authenticationWrapperView,
                     nil];
    
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
    
    
	//Build the cards in the scroll view.
    [self buildViewListForScrollView:self.scrollView];
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
        [self.navigationController pushViewController:self.customParamsVC animated:YES];
    }else if(sender == self.setNewParameterButton){
        [[AppBlade sharedManager] setCustomParam:@"I was from the \"Set New Parameter\"" forKey:@"key_demo_val2"];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Demo" message:@"Parameter set! Now take a look at your parameters." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
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
    if (currentSession == nil || [currentSession objectForKey:kSessionStartDate] == nil) {
        [currentSessionStatus appendString:@"No Current Session"];
    }else{
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterNoStyle];
        [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
        
        NSDate *sessionStartDate = [currentSession objectForKey:kSessionStartDate];
        NSDate *sessionEndDate = [currentSession objectForKey:kSessionEndDate];
        float elapsedTimeSinceStart = 0.0f;
        if (sessionEndDate == nil) {
            elapsedTimeSinceStart = ([sessionStartDate timeIntervalSinceNow] * -1.0f);
            [currentSessionStatus appendFormat:@"Started: %@ \nElapsed: %f", [dateFormatter stringFromDate:sessionStartDate], elapsedTimeSinceStart];
        }else{
//            elapsedTimeSinceStart = ([sessionEndDate timeIntervalSinceDate:sessionStartDate]);
            [currentSessionStatus appendFormat:@"Started: %@ \nEnded: %@", [dateFormatter stringFromDate:sessionStartDate],[dateFormatter stringFromDate:sessionEndDate]];//], elapsedTimeSinceStart];
        }
    }
    
    [self.currentSessionDisplay setText:currentSessionStatus];
}



@end
