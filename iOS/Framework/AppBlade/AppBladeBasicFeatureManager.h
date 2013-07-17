//
//  AppBladeGenericFeatureManager.h
//  AppBlade
//
//  Created by AndrewTremblay on 7/17/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppBladeWebOperation.h"

@protocol AppBladeBasicFeatureManager

@required
    - (id)initWithDelegate:(id<AppBladeWebOperationDelegate>)delegate;
    - (AppBladeWebOperation*) generateWebRequest;

@end
