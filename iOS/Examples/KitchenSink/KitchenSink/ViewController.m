//
//  ViewController.m
//  KitchenSink
//
//  Created by AppBlade on 7/15/13.
//  Copyright (c) 2013 Raizlabs Corporation. All rights reserved.
//

#import "ViewController.h"

#import "AppBlade.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
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
    if(sender == self.crashButtonSigabrt){
        [self sigabrt];
    }else if(sender == self.crashButtonCustomException){
        [self throwNSException];
    }else if(sender == self.crashButtonSigsev){
        [self sigsegv];
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
    
    }else if(sender == self.setNewParameterButton){
    
    }else if(sender == self.clearAllParamsButton){
        
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




#pragma mark - Crash "Helpers"
// credit to CrashKit for these .
//https://github.com/kaler/CrashKit
- (void)sigabrt
{
    abort();
}

- (void)sigbus
{
    void (*func)() = 0;
    func();
}

- (void)sigfpe
{
    int zero = 0;  // LLVM is smart and actually catches divide by zero if it is constant
    int i = 10/zero;
    NSLog(@"Int: %i", i);
}

- (void)sigill
{
    typedef void(*FUNC)(void);
    const static unsigned char insn[4] = { 0xff, 0xff, 0xff, 0xff };
    void (*func)() = (FUNC)insn;
    func();
}

- (void)sigpipe
{
    // Hmm, can't actually generate a SIGPIPE.
    FILE *f = popen("ls", "r");
    const char *buf[128];
    pwrite(fileno(f), buf, 128, 0);
}

- (void)sigsegv
{
    // This actually raises a SIGBUS.
    NSException *e = [NSException exceptionWithName:@"SIGSEGV" reason:@"Dummy SIGSEGV Reason" userInfo:nil];
    @throw e;
}

- (void)throwNSException
{
    NSException *e = [NSException exceptionWithName:@"TestException" reason:@"Testing AppBlade Crash" userInfo:nil];
    @throw e;
}



@end
