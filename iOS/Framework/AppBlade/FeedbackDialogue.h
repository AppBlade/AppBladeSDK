//
//  FeedbackDialogue.h
//  AppBlade
//
//  Created by Ben Johnson on 4/9/12.
//  Copyright (c) 2012 AppBlade. All rights reserved.
//

#import <UIKit/UIKit.h>

#define isPad()             UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad

#define feedbackWidthMin            isPad() ? 450 : 300
#define feedbackHeightMin           isPad() ? 350 : 200

@class FeedbackBackgroundView;

@protocol FeedbackDialogueDelegate <NSObject>

-(void)feedbackDidSubmitText:(NSString*)feedbackText;
-(void)feedbackDidCancel;

@end

@interface FeedbackDialogue : UIView

@property (nonatomic, retain) UITextView *textView;
@property (nonatomic, retain) UIButton *submitButton;
@property (nonatomic, retain) UIButton *cancelButton;
@property (nonatomic, retain) FeedbackBackgroundView *dialogueView;
@property (nonatomic, retain) UILabel *feedbackTitle;
@property (nonatomic, retain) UIView* headerView;
@property (nonatomic, retain) UIView* overlayView;
@property (nonatomic, assign)  id<FeedbackDialogueDelegate> delegate;



@end
