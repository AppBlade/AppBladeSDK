//
//  CrashReportingViewController.m
//  KitchenSink
//
//  Created by AndrewTremblay on 9/4/13.
//  Copyright (c) 2013 Raizlabs Corporation. All rights reserved.
//

#import "CrashReportingViewController.h"

@interface CrashReportingViewController ()

@end

@implementation CrashReportingViewController

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
    totalHeight = [self addView:self.headerWrapperView toScrollView:self.scrollView atVertOffset:totalHeight];
    totalHeight = [self addView:self.crashDescriptionView toScrollView:self.scrollView atVertOffset:totalHeight];
    totalHeight = [self addView:self.crashChoiceView toScrollView:self.scrollView atVertOffset:totalHeight];
    [self.scrollView setContentSize:CGSizeMake(self.view.bounds.size.width, totalHeight)];
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

- (void)throwDefaultNSException
{
    [self throwCustomTestNSException:@"Testing AppBlade Crash"];
}

- (void)throwCustomTestNSException:(NSString *)reason
{
    NSException *e = [NSException exceptionWithName:@"TestException" reason:reason userInfo:nil];
    @throw e;
}

//Nav Nav
- (IBAction)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:true];
}

- (IBAction)crashCustomNameChanged:(id)sender {
//don't need to do much except maybe sanitize
}

- (IBAction)crashCustomBeganEditing:(id)sender
{
    [self textFieldDidBeginEditing:sender];
}

- (IBAction)crashCustomEndedEditing:(id)sender
{
    [self textFieldDidEndEditing:sender];
}

- (IBAction)crashButtonPressed:(id)sender {
}
@end
