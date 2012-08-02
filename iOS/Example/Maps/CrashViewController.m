//
//  CrashViewController.m
//  Maps
//
//  Created by Craig Spitzkoff on 6/18/11.
//  Copyright 2011 Raizlabs Corporation. All rights reserved.
//

#import "CrashViewController.h"
#import "AppBlade.h"

@implementation CrashViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
    
    [crashLabels release];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    crashLabels = [[NSArray alloc] initWithObjects: 
                        @"SIGABRT",
                        @"SIGBUS",
                        @"SIGFPE",
                        @"SIGILL",
                        @"SIGPIPE",
                        @"SIGSEGV",
                        @"NSException", 
                        @"Feedback With Screenshot",
                        @"Feedback Without Screenshot",
                   nil] ;

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
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)cancelPressed:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
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
    NSString *str = [[NSString alloc] initWithUTF8String:"SIGSEGV STRING"];
    [str release];
    NSLog(@"String %@", str);
}

- (void)throwNSException
{
    NSException *e = [NSException exceptionWithName:@"TestException" reason:@"Testing AppBlade Crash" userInfo:nil];
    @throw e;
}  


#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return crashLabels.count;
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellID = @"crashCellID";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if(nil == cell)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID] autorelease];
    }
    
    cell.textLabel.text = [crashLabels objectAtIndex:indexPath.row];
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{    
    switch (indexPath.row) 
    {
        case 0:
            [self sigabrt];
            break;
        case 1:
            [self sigbus];
            break;
        case 2:
            [self sigfpe];
            break;
        case 3:
            [self sigill];
            break;
        case 4:
            [self sigpipe];
            break;
        case 5:
            [self sigsegv];
            break;
        case 6:
            [self throwNSException];
            break;
        case 7:
            [[AppBlade sharedManager] showFeedbackDialogueInView:self.view];
            break;
        case 8:
            [[AppBlade sharedManager] showFeedbackDialogueWithScreenshot:NO];
            break;
        default:
            break;
    }

}


@end
