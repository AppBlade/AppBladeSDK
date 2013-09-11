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
    totalHeight = [self addView:self.headerWrapperView toScrollView:self.crashScrollView atVertOffset:totalHeight];
    totalHeight = [self addView:self.crashDescriptionView toScrollView:self.crashScrollView atVertOffset:totalHeight];
    totalHeight = [self addView:self.crashChoiceView toScrollView:self.crashScrollView atVertOffset:totalHeight];
    [self.crashScrollView setContentSize:CGSizeMake(self.view.bounds.size.width, totalHeight)];
}

-(CGFloat)addView:(UIView *)view toScrollView:(UIScrollView *)scrollView atVertOffset:(CGFloat)height {
    [scrollView addSubview:view];
    CGRect viewFrame = view.frame;
    viewFrame.origin.y = height;
    [view setFrame:viewFrame];
    return height + viewFrame.size.height;
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
@end
