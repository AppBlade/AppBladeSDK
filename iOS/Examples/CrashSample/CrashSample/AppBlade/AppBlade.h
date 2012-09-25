//
//  AppBlade.h
//  AppBlade
//
//  Created by Craig Spitzkoff on 6/1/11.
//  Copyright 2011 Raizlabs Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class AppBlade;

@protocol AppBladeDelegate <NSObject>

- (void)appBlade:(AppBlade*)appBlade applicationApproved:(BOOL)approved data:(NSDictionary*)data;

@end

@interface AppBlade : NSObject <AppBladeDelegate, UIAlertViewDelegate> {
    @private
    id<AppBladeDelegate> _delegate;
    BOOL _AppBladeStarted;
    NSURL *_upgradeLink;
    
    NSString *_appBladeProjectID;
    NSString *_appBladeProjectToken;
    NSString *_appBladeProjectSecret;
    NSString *_appBladeProjectIssuedTimestamp;
}

// UUID of the project on AppBlade.
@property (nonatomic, retain) NSString* appBladeProjectID;

// AppBlade API token for the project.
@property (nonatomic, retain) NSString* appBladeProjectToken;

// AppBlade API secret for the project. 
@property (nonatomic, retain) NSString* appBladeProjectIssuedTimestamp;

// AppBlade API project issued time.
@property (nonatomic, retain) NSString* appBladeProjectSecret;

// The AppBlade delegate receives messages regarding device authentication and other events.
// See protocol declaration, above.
@property (nonatomic, assign) id<AppBladeDelegate> delegate;

// AppBlade manager singleton.
+ (AppBlade *)sharedManager;

// Checks if any crashes have ocurred sends logs to AppBlade.
- (void)catchAndReportCrashes;

/*
 *    WARNING: The following features aremethods only for ad hoc and enterprise applications. Shipping an app to the
 *    iTunes App store with a call to |-checkApproval|, for example, could result in app termination (and rejection).
 */

// Checks with the AppBlade server to see if the app is allowed to run on this device.
- (void)checkApproval;

@end
