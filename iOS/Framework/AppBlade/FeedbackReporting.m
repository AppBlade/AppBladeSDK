//
//  FeedbackReporting
//  AppBlade
//
//  Created by AndrewTremblay on 7/15/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "FeedbackReporting.h"
#import "AppBlade.h"


@interface FeedbackReporting ()
- (void)setupFeedbackWithScreenshot:(NSString*)screenshot note:(NSString*)note console:(NSString*)console params:(NSDictionary*)paramsData;
@end

@implementation FeedbackReporting

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
