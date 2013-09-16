/*!
 @header  APBFeedbackReportingManager.h
 @abstract  Holds all methods pertaining to custom parameters, which affect the subsequent web calls.
 @framework AppBlade
 @author AndrewTremblay on 7/16/13.
 @copyright Raizlabs 2013. All rights reserved.
 */


#import <Foundation/Foundation.h>
#import "APBFeedbackDialogue.h"

#import "APBBasicFeatureManager.h"

/*!
 @class APBFeedbackReportingManager
 @abstract The AppBlade Feedback Reporting feature
 @discussion This manager contains the showFeedbackDialogueWithOptions call, includng storage of the feedback dictionary and web callbacks.
 */
@interface APBFeedbackReportingManager : NSObject<APBBasicFeatureManager>
    @property (nonatomic, strong) id<APBWebOperationDelegate> delegate;

@property (nonatomic, retain) NSMutableDictionary* feedbackDictionary;
@property (nonatomic, assign) BOOL showingFeedbackDialogue;
@property (nonatomic, retain) UITapGestureRecognizer* tapRecognizer;
@property (nonatomic, assign) UIWindow* feedbackWindow;


- (void)allowFeedbackReportingForWindow:(UIWindow *)window withOptions:(AppBladeFeedbackSetupOptions)options;
- (void)showFeedbackDialogueWithOptions:(AppBladeFeedbackDisplayOptions)options;
- (void)handleWebClientSentFeedback:(APBWebOperation *)client withSuccess:(BOOL)success;

#pragma mark - Web Request Generators
- (APBWebOperation*) generateFeedbackWithScreenshot:(NSString*)screenshot note:(NSString*)note console:(NSString*)console params:(NSDictionary*)paramsDict;

#pragma mark Stored Web Request Handling

- (void)handleBackloggedFeedback;
- (BOOL)hasPendingFeedbackReports;
- (void)removeIntermediateFeedbackFiles:(NSString *)feedbackPath;

@end

#ifndef SKIP_FEEDBACK
//Our additional requirements
@interface AppBlade (FeedbackReporting)  <APBWebOperationDelegate, APBFeedbackDialogueDelegate>

@property (nonatomic, retain) APBFeedbackReportingManager* feedbackManager;
@property (nonatomic, retain) NSOperationQueue* pendingRequests;//we want references to these private properties

- (void)promptFeedbackDialogue;
- (void)reportFeedback:(NSString*)feedback;
- (NSString*)captureScreen;
- (UIImage*)getContentBelowView;
- (UIImage *) rotateImage:(UIImage *)img angle:(int)angle;


@end

#endif