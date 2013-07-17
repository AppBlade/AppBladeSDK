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
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

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


#pragma mark - crashes
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
