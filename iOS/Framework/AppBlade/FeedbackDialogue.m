//
//  FeedbackDialogue.m
//  AppBlade
//
//  Created by Ben Johnson on 4/9/12.
//  Copyright (c) 2012 AppBlade. All rights reserved.
//

#import "FeedbackDialogue.h"
#import <QuartzCore/QuartzCore.h>
@implementation FeedbackDialogue

#define isPad()             UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad

#define feedbackWidthMin            isPad() ? 450 : 300
#define feedbackHeightMin           isPad() ? 350 : 200
#define textViewVerticalOffset      80
#define textViewHorizontalOffset    10
#define submitButtonWidth           100
#define submitButtonHeight          44

@synthesize textView = _textView;
@synthesize submitButton = _submitButton;
@synthesize delegate = _delegate;
@synthesize dialogueView = _dialogueView;
@synthesize feedbackTitle = _feedbackTitle;
@synthesize cancelButton = _cancelButton;
@synthesize headerView = _headerView;
@synthesize overlayView = _overlayView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        // overlay view
        self.backgroundColor = [UIColor clearColor];
        UIView *overlayView = [[UIView alloc] initWithFrame:self.frame];
        overlayView.alpha = 0.5;
        overlayView.backgroundColor = [UIColor blackColor];
        overlayView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
        [self addSubview:overlayView];
        self.overlayView = overlayView;
        [overlayView release];
        
        // overall dialogue view
        self.dialogueView = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width/2 - feedbackWidthMin/2, 0, feedbackWidthMin, feedbackHeightMin)];
        self.dialogueView.backgroundColor = [UIColor whiteColor];
        self.dialogueView.layer.cornerRadius = 7.0f;
        self.dialogueView.clipsToBounds = YES;
        self.dialogueView.layer.masksToBounds = YES;
        
        if (isPad()) {
            CGRect dialogueFrame = self.dialogueView.frame;
            dialogueFrame.origin.y = self.frame.size.height / 2 - dialogueFrame.size.height / 2;
            self.dialogueView.frame = dialogueFrame;
            self.dialogueView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin);
        }
        
        // Header bar
        self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, feedbackWidthMin, submitButtonHeight)];
        self.headerView.backgroundColor = [UIColor colorWithRed:233/255.0f green:234/255.0f blue:235/255.0f alpha:1.0];
        CAGradientLayer *topGradient = [CAGradientLayer layer];
        topGradient.frame = self.headerView.bounds;
        topGradient.colors = [NSArray arrayWithObjects:(id)[[UIColor clearColor] CGColor], (id)[[UIColor colorWithWhite:0.8 alpha:0.2] CGColor], (id)[[UIColor colorWithWhite:0.8 alpha:0.5] CGColor], nil];
        [self.headerView.layer addSublayer:topGradient];
        
        
        // header text
        self.feedbackTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, feedbackWidthMin, 44) ];
        self.feedbackTitle.textAlignment = UITextAlignmentCenter;
        self.feedbackTitle.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:18.0f];
        self.feedbackTitle.text = @"Feedback";
        self.feedbackTitle.textColor = [UIColor colorWithRed:175/255.0f green:33/255.0f blue:41/255.0f alpha:1.0];
        self.feedbackTitle.backgroundColor = [UIColor clearColor];
        
        
        self.textView = [[UITextView alloc] initWithFrame:CGRectMake(textViewHorizontalOffset, textViewVerticalOffset, self.dialogueView.frame.size.width - (2*textViewHorizontalOffset), self.dialogueView.frame.size.height - textViewVerticalOffset - 10)];
        [self.textView setContentInset:UIEdgeInsetsMake(10, 10, 10, 10)];
        
        // submit button
        self.submitButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.submitButton.frame = CGRectMake(self.dialogueView.frame.size.width - submitButtonWidth, 0,submitButtonWidth, submitButtonHeight);
        
        [self.submitButton setTitle:@"Submit" forState:UIControlStateNormal];
        
        self.submitButton.backgroundColor = [UIColor clearColor];
        self.submitButton.titleLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
        [self.submitButton addTarget:self action:@selector(submitPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        
        // cancel button
        self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.cancelButton.frame = CGRectMake(0, 0, submitButtonWidth, submitButtonHeight);
        [self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
        self.cancelButton.titleLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
        [self.cancelButton addTarget:self action:@selector(cancelPressed:) forControlEvents:UIControlEventTouchUpInside];

        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        
        
        
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    
    [self addSubview:self.dialogueView];
    [self.dialogueView addSubview:self.headerView];
    [self.dialogueView addSubview:self.textView];
    [self.dialogueView addSubview:self.cancelButton];
    [self.dialogueView addSubview:self.submitButton];
    [self.dialogueView addSubview:self.feedbackTitle];
}

- (void)cancelPressed:(UIButton*)sender{
    
    [self.delegate feedbackDidCancel];
    [self removeFromSuperview];
    
}

- (void)submitPressed:(UIButton*)sender{
    
    NSLog(@"Text Written = %@", self.textView.text);

    [self.delegate feedbackDidSubmitText:self.textView.text];
    
    [self removeFromSuperview];
    
}

- (void)keyboardWillShow:(NSNotification*)notification
{
    
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
        NSValue *frame = [[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
        CGRect keyboardInFrame = [frame CGRectValue];
        
        int newY = CGRectGetMinY(keyboardInFrame) - feedbackHeightMin - 10;
        newY = CGRectGetMinX(keyboardInFrame) - feedbackHeightMin - 10;
    
    
        CGRect finalFrame = self.dialogueView.frame;
        finalFrame.origin.y = 0;
        
        [UIView beginAnimations:@"SlideUp" context:NULL];
        [UIView setAnimationDuration:0.3];
        self.dialogueView.frame = finalFrame;
        [UIView commitAnimations];
        }
}

- (void)keyboardWillHide:(NSNotification*)notification
{

    CGRect finalFrame = CGRectMake(self.frame.size.width/2 - feedbackWidthMin/2, 0, feedbackWidthMin, feedbackHeightMin);
    if (isPad()) {
        finalFrame.origin.y = self.frame.size.height / 2 - finalFrame.size.height / 2;
    }
    
    [UIView beginAnimations:@"SlideDown" context:NULL];
    [UIView setAnimationDuration:0.3];
    self.dialogueView.frame = finalFrame;
    [UIView commitAnimations];
}


- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    
    [self.headerView removeFromSuperview];
    self.headerView = nil;
    
    [self.textView removeFromSuperview];
    self.textView = nil;
    
    [self.feedbackTitle removeFromSuperview];
    self.feedbackTitle = nil;
    
    [self.cancelButton removeFromSuperview];
    self.cancelButton = nil;
    self.delegate = nil;
    [super dealloc];
}

@end
