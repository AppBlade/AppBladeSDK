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
#import "AppBladeBasicFeatureManager.h"


@interface FeedbackReportingManager : NSObject<AppBladeBasicFeatureManager>
    @property (nonatomic, strong) id<AppBladeWebOperationDelegate> delegate;

#pragma mark - Web Request Generators
- (AppBladeWebOperation*) generateFeedbackWithScreenshot:(NSString*)screenshot note:(NSString*)note console:(NSString*)console params:(NSDictionary*)paramsDict;

#pragma mark Stored Web Request Handling

- (BOOL)hasPendingFeedbackReports;
- (void)removeIntermediateFeedbackFiles:(NSString *)feedbackPath;

@end
