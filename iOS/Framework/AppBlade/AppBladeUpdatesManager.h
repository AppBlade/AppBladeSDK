//
//  AppBladeUpdates.h
//  AppBlade
//
//  Created by AndrewTremblay on 7/16/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AppBladeBasicFeatureManager.h"

@interface AppBladeUpdatesManager : NSObject<AppBladeBasicFeatureManager>
@property (nonatomic, strong) id<AppBladeWebOperationDelegate> delegate;
@property (nonatomic, retain) NSURL* upgradeLink;

- (void)checkForUpdates;

@end


//Our additional requirements
@interface AppBlade (Updates)

@property (nonatomic, strong) AppBladeUpdatesManager*        updatesManager;


@end


