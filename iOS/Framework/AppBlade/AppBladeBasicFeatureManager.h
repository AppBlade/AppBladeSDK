//
//  AppBladeGenericFeatureManager.h
//  AppBlade
//
//  Created by AndrewTremblay on 7/17/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppBlade.h"
#import "AppBladeWebOperation.h"
#import "AppBladeLogging.h"

@protocol AppBladeBasicFeatureManager

@required
    - (id)initWithDelegate:(id<AppBladeWebOperationDelegate>)delegate;

//Suggested pragma structure (after implementing the required methods, which should always be first)
#pragma mark - Web Request Generators
//wherein you generate the unique web request for the SDK
#pragma mark Stored Web Request Handling
//wherein you implement any storage behavior for pending API calls.
//...
//then whatever else you feel like
@end
