//
//  FeedbackDialogue.m
//  AppBlade
//
//  Created by Ben Johnson on 4/9/12.
//  Copyright (c) 2012 AppBlade. All rights reserved.
//

#import "FeedbackDialogue.h"
#import "FeedbackBackgroundView.h"

@interface FeedbackDialogue ()

@property (nonatomic, assign) BOOL closing;

@end

@implementation FeedbackDialogue

#define textViewVerticalOffset      54
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
@synthesize closing = _closing;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        // overlay view
        self.backgroundColor = [UIColor clearColor];
        self.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
        UIView *overlayView = [[UIView alloc] initWithFrame:self.frame];
        overlayView.alpha = 0.0;
        overlayView.backgroundColor = [UIColor blackColor];
        overlayView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
        [self addSubview:overlayView];
        self.overlayView = overlayView;
        [overlayView release];
        
        
        // overall dialogue view
        int width = feedbackWidthMin;
        int originX = floor(self.frame.size.width / 2 - width / 2);
        self.dialogueView = [[FeedbackBackgroundView alloc] initWithFrame:CGRectMake(originX, 0, width, feedbackHeightMin)];
        [self.dialogueView setBackgroundColor:[UIColor clearColor]];
        
        if (isPad()) {
            CGRect dialogueFrame = self.dialogueView.frame;
            dialogueFrame.origin.y = self.frame.size.height / 2 - dialogueFrame.size.height / 2;
            self.dialogueView.frame = dialogueFrame;
            self.dialogueView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin);
        }
        
        // Header bar
        self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, feedbackWidthMin, submitButtonHeight)];
        
        
        // header text
        self.feedbackTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, feedbackWidthMin, 44) ];
        [self.feedbackTitle setTextAlignment:UITextAlignmentCenter ];
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
        self.submitButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
        [self.submitButton setTitleColor:[UIColor colorWithWhite:0.3 alpha:1.0] forState:UIControlStateNormal];
        [self.submitButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.submitButton addTarget:self action:@selector(submitPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        
        // cancel button
        self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.cancelButton.frame = CGRectMake(0, 0, submitButtonWidth, submitButtonHeight);
        [self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
        self.cancelButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
        [self.cancelButton setTitleColor:[UIColor colorWithWhite:0.3 alpha:1.0] forState:UIControlStateNormal];
        [self.cancelButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
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
    self.overlayView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
    
    if (isPad()) {
        self.dialogueView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin);
    }
    else {
        self.dialogueView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin);
    }
    
    [self.dialogueView addSubview:self.headerView];
    [self.dialogueView addSubview:self.textView];
    [self.dialogueView addSubview:self.cancelButton];
    [self.dialogueView addSubview:self.submitButton];
    [self.dialogueView addSubview:self.feedbackTitle];
    
    CGRect dialogueFrame = self.dialogueView.frame;
    CGRect finalFrame = dialogueFrame;
    finalFrame.origin.y = 0;
    
    dialogueFrame.origin.y = -dialogueFrame.size.height;
    self.dialogueView.frame = dialogueFrame;
    
    [self addSubview:self.dialogueView];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.dialogueView.frame = finalFrame;
        self.overlayView.alpha = 0.5;
    }];
    
}

- (void)cancelPressed:(UIButton*)sender{
    
    [self.delegate feedbackDidCancel];
    [self closeDialogue];
    
}

- (void)submitPressed:(UIButton*)sender{
    

    [self.delegate feedbackDidSubmitText:self.textView.text];
    
    [self closeDialogue];
    
}

- (void)closeDialogue
{
    self.closing = YES;
    [self.textView resignFirstResponder];
    CGRect dialogueFrame = self.dialogueView.frame;
    dialogueFrame.origin.y = -dialogueFrame.size.height;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.dialogueView.frame = dialogueFrame;
        self.overlayView.alpha = 0.0;
    }completion:^(BOOL finished){
        [self removeFromSuperview]; 
    }];
}

- (void)keyboardWillShow:(NSNotification*)notification
{
    
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
        
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
    if (!self.closing) {
        int width = feedbackWidthMin;
        int originX = floor(self.frame.size.width / 2 - width / 2);
        
        CGRect finalFrame = CGRectMake(originX, 0, width, feedbackHeightMin);
        if (isPad()) {
            finalFrame.origin.y = self.frame.size.height / 2 - finalFrame.size.height / 2;
        }
        
        [UIView beginAnimations:@"SlideDown" context:NULL];
        [UIView setAnimationDuration:0.3];
        self.dialogueView.frame = finalFrame;
        [UIView commitAnimations];
    }

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
