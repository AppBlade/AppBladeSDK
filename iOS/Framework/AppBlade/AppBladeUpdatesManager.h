//
//  AppBladeUpdates.h
//  AppBlade
//
//  Created by AndrewTremblay on 7/16/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AppBladeBasicFeatureManager.h"
#import "AppBlade+PrivateMethods.h"

//This manager requires some UI interaction. She handles it herself.
@protocol AppBladeUpdatesManagerDelegate <UIAlertViewDelegate>
    // Is there an update of this application available?
    -(void) appBlade:(AppBlade *)appBlade updateAvailable:(BOOL)update updateMessage:(NSString*)message updateURL:(NSString*)url;
@end

@interface AppBladeUpdatesManager : NSObject<AppBladeBasicFeatureManager, AppBladeUpdatesManagerDelegate>
    @property (nonatomic, strong) id<AppBladeWebOperationDelegate> delegate;
    @property (nonatomic, retain) NSURL* upgradeLink;

    - (void)checkForUpdates;
    - (void)handleWebClient:(AppBladeWebOperation *)client receivedUpdate:(NSDictionary*)updateData;
    - (void)updateCallbackFailed:(AppBladeWebOperation *)client withErrorString:(NSString*)errorString;
@end

@interface AppBladeWebOperation (Updates)
    -(void) checkForUpdates;
@end

//Our additional requirements
@interface AppBlade (Updates)
    @property (nonatomic, strong) AppBladeUpdatesManager* updatesManager; // we need to make the manager visible to itself.
    - (void)appBladeWebClient:(AppBladeWebOperation *)client receivedUpdate:(NSDictionary*)updateData;
@end


