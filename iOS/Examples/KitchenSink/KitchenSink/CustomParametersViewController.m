//
//  CustomParametersViewController.m
//  KitchenSink
//
//  Created by AndrewTremblay on 9/4/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//

#import "CustomParametersViewController.h"
#import "AppBlade.h"
#import "APBCustomParametersManager.h"

NSString* kDefaultEmptyParamMessage = @"(you currently have no parameters)";
NSInteger kMaxParamTextFieldHeight = 2000;
NSInteger kMinParamTextFieldHeight = 113;

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
    self.title = @"Custom Parameters";
    
    // Do any additional setup after loading the view from its nib.
    self.viewList = [NSArray arrayWithObjects:
                     self.addParamView,
                     self.currentParamView,
                     self.actionsView,
                     nil];
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
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
   BOOL centerText = true;
   NSString *textViewMessage = [NSString stringWithString:kDefaultEmptyParamMessage];
   NSDictionary *params = [[AppBlade sharedManager] getCustomParams];
    if([params count] != 0){
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:&error];
        if(jsonData){
            textViewMessage = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            centerText = false;
        }
    }
    //set the content of the customParam text field
    CGSize oldSize = self.currentParamsTextView.contentSize;//[self.currentParamsTextView.text sizeWithFont:self.currentParamsTextView.font constrainedToSize:CGSizeMake(self.currentParamsTextView.frame.size.width, kMaxParamTextFieldHeight)lineBreakMode:NSLineBreakByWordWrapping];
    
    [self.currentParamsTextView setText:textViewMessage];
    [self.currentParamsTextView setTextAlignment:(centerText ? NSTextAlignmentCenter : NSTextAlignmentLeft)];
    [self.currentParamsTextView sizeToFit];
    //update contentsize of customParamTextField
    CGSize newSize = self.currentParamsTextView.contentSize;//[textViewMessage sizeWithFont:self.currentParamsTextView.font constrainedToSize:CGSizeMake(oldSize.width, kMaxParamTextFieldHeight)lineBreakMode:NSLineBreakByWordWrapping];
    //update contentsize of the containing customParamWrapperView
    //and move any views beneath the customParamWrapperView
    CGFloat newHeight = [self resizeSubView:self.currentParamsTextView ofViewListElement:self.currentParamView fromSize:oldSize toSize:newSize];
    
    newHeight = MAX(newHeight, self.scrollView.bounds.size.height);
    
    
    //update ContentSize of scrollview
    [self.scrollView setContentSize:CGSizeMake(self.scrollView.frame.size.width, newHeight)];
}

- (IBAction)submitNewCustomParam:(id)sender {
    if(self.valueTextField.text.length == 0 ||     self.keyTextField.text.length == 0){
        NSLog(@"Invalid input");
        [self.valueTextField resignFirstResponder];
        [self.keyTextField resignFirstResponder];

    }else{
        NSString *value = [NSString stringWithString:self.valueTextField.text];
        NSString *key = [NSString stringWithString:self.keyTextField.text];
        [self.valueTextField resignFirstResponder];
        [self.keyTextField resignFirstResponder];

        [[AppBlade sharedManager] setCustomParam:value forKey:key];
        [self updateUiFromCurrentParams];
    }
}



- (IBAction)actionButtonPressed:(id)sender {
    if(sender == self.clearParamsButton){
        [[AppBlade sharedManager] clearAllCustomParams];
        [self updateUiFromCurrentParams];
    }else if(sender == self.showFeedbackDialogButton){
        [[AppBlade sharedManager] showFeedbackDialogue];
    }
}


- (IBAction)infoButtonPressed:(id)sender {

}


- (IBAction)didBeginEditingTextField:(id)sender {
    [self textFieldDidBeginEditing:sender];
}

- (IBAction)didExitValueTextField:(id)sender {
    [self.valueTextField resignFirstResponder];
}

- (IBAction)didExitKeyTextField:(id)sender {
    [self.keyTextField resignFirstResponder];
    [self.valueTextField becomeFirstResponder];

}
@end
