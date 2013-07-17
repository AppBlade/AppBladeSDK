//
//  FeedbackReporting.h
//  AppBlade
//
//  Created by AndrewTremblay on 7/15/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FeedbackDialogue.h"

#import "AppBladeWebOperation.h"

typedef NS_OPTIONS(NSUInteger, AppBladeFeedbackSetupOptions) {
    AppBladeFeedbackSetupDefault                 = 0,      // default behavior
    AppBladeFeedbackSetupTripleFingerDoubleTap   = 1 <<  0,    // on all touch downs
    AppBladeFeedbackSetupCustomPrompt            = 1 <<  1    // on multiple touchdowns (tap count > 1)
};

typedef NS_OPTIONS(NSUInteger, AppBladeFeedbackDisplayOptions) {
    AppBladeFeedbackDisplayDefault                 = 0,      // default behavior
    AppBladeFeedbackDisplayWithScreenshot          = 1 <<  0,   // Take a screenshot oto send with the feedback (default)
    AppBladeFeedbackDisplayWithoutScreenshot       = 1 <<  1    // Do not take a screenshot
};


@interface FeedbackReportingManager : AppBladeWebOperation


-(id)initWithDelegate:(id<AppBladeWebClientDelegate>)delegate andFeedbackDictionary:(NSDictionary *)feedbackDictionary;


@end
