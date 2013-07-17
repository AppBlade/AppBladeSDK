//
//  FeedbackReporting
//  AppBlade
//
//  Created by AndrewTremblay on 7/15/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "FeedbackReportingManager.h"
#import "AppBlade.h"


@interface FeedbackReportingManager ()
- (void)setupFeedbackWithScreenshot:(NSString*)screenshot note:(NSString*)note console:(NSString*)console params:(NSDictionary*)paramsData;
@end

@implementation FeedbackReportingManager

- (id)initWithDelegate:(id<AppBladeWebClientDelegate>)delegate andFeedbackDictionary:(NSDictionary *)feedbackDictionary
{
    self = [super initWithDelegate:delegate];
    [self setApi: AppBladeWebClientAPI_Feedback];


    return self;
}


- (void)setupFeedbackWithScreenshot:(NSString*)screenshot note:(NSString*)note console:(NSString*)console params:(NSDictionary*)paramsData
{

}

@end
