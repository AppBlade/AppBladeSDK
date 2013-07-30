//
//  FeedbackReporting.h
//  AppBlade
//
//  Created by AndrewTremblay on 7/15/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FeedbackDialogue.h"

#import "AppBladeBasicFeatureManager.h"


@interface FeedbackReportingManager : NSObject<AppBladeBasicFeatureManager>
    @property (nonatomic, strong) id<AppBladeWebOperationDelegate> delegate;

- (void)allowFeedbackReportingForWindow:(UIWindow *)window withOptions:(AppBladeFeedbackSetupOptions)options;
- (void)showFeedbackDialogueWithOptions:(AppBladeFeedbackDisplayOptions)options;


#pragma mark - Web Request Generators
- (AppBladeWebOperation*) generateFeedbackWithScreenshot:(NSString*)screenshot note:(NSString*)note console:(NSString*)console params:(NSDictionary*)paramsDict;

#pragma mark Stored Web Request Handling

- (void)handleBackloggedFeedback;
- (BOOL)hasPendingFeedbackReports;
- (void)removeIntermediateFeedbackFiles:(NSString *)feedbackPath;

@end

#ifndef SKIP_FEEDBACK
//Our additional requirements
@interface AppBlade (FeedbackReporting)  <AppBladeWebOperationDelegate, FeedbackDialogueDelegate>


@property (nonatomic, strong) FeedbackReportingManager*      feedbackManager;


//Feedback variables need to stay in Appbade.h, as category interfaces cannot declare additional properties
@property (nonatomic, retain) NSMutableDictionary* feedbackDictionary;
@property (nonatomic, assign) BOOL showingFeedbackDialogue;
@property (nonatomic, retain) UITapGestureRecognizer* tapRecognizer;
@property (nonatomic, assign) UIWindow* window;
@property (nonatomic, retain) NSOperationQueue* pendingRequests;

- (void)promptFeedbackDialogue;
- (void)reportFeedback:(NSString*)feedback;
- (NSString*)captureScreen;
- (UIImage*)getContentBelowView;
- (UIImage *) rotateImage:(UIImage *)img angle:(int)angle;


@end

#endif