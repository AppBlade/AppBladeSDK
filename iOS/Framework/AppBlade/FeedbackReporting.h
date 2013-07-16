//
//  FeedbackReporting.h
//  AppBlade
//
//  Created by AndrewTremblay on 7/15/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FeedbackDialogue.h"

#import "AppBladeWebClient.h"

typedef NS_OPTIONS(NSUInteger, ABFeedbackSetupOptions) {
    ABFeedbackSetupDefault                 = 0,      // default behavior
    ABFeedbackSetupTripleFingerDoubleTap   = 1 <<  0,    // on all touch downs
    ABFeedbackSetupCustomPrompt            = 1 <<  1    // on multiple touchdowns (tap count > 1)
};

typedef NS_OPTIONS(NSUInteger, ABFeedbackDisplayOptions) {
    ABFeedbackDisplayDefault                 = 0,      // default behavior
    ABFeedbackDisplayWithScreenshot          = 1 <<  0,   // Take a screenshot oto send with the feedback (default)
    ABFeedbackDisplayWithoutScreenshot       = 1 <<  1    // Do not take a screenshot
};


@interface FeedbackReporting : AppBladeWebClient



@end
