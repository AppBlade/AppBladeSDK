//
//  FlipsideViewController.m
//  Maps
//
//  Created by Craig Spitzkoff on 5/31/11.
//  Copyright 2011 Raizlabs Corporation. All rights reserved.
//

#import "FlipsideViewController.h"
#import "CrashViewController.h"
#import "AppBlade.h"

@implementation FlipsideViewController

@synthesize delegate=_delegate;

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor viewFlipsideBackgroundColor];  
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

#pragma mark - Actions

- (IBAction)done:(id)sender
{
    [self.delegate flipsideViewControllerDidFinish:self];
}

- (IBAction)crashException:(id)sender {
    
    CrashViewController* crashVC = [[[CrashViewController alloc] initWithNibName:@"CrashViewController" bundle:nil] autorelease];
    [self presentModalViewController:crashVC animated:YES];
        
    //NSException *e = [NSException exceptionWithName:@"TestException" reason:@"Testing Appblade Crash" userInfo:nil];
    //@throw e;
}

- (IBAction)presentFeedback:(id)sender {
    
    AppBlade *blade = [AppBlade sharedManager];
    [blade showFeedbackDialogue];
    
}

@end
