//
//  AppBladeUpdates.m
//  AppBlade
//
//  Created by AndrewTremblay on 7/16/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "AppBladeUpdatesManager.h"

@implementation AppBladeUpdatesManager

- (id)initWithDelegate:(id<AppBladeWebOperationDelegate>)delegate
{
    if((self = [super init])) {
        self.delegate = delegate;
    }
    
    return self;
}

@end
