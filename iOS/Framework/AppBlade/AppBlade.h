//
//  AppBlade.h
//  AppBlade
//
//  Created by Craig Spitzkoff on 6/1/11.
//  Copyright 2011 AppBlade. All rights reserved.
//
//  For instructions on how to use this library, please look at the README.
//
//  Support and FAQ can be found at http://support.appblade.com
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static NSString* const kAppBladeErrorDomain;
static const int kAppBladeOfflineError;
static NSString* const kAppBladeCacheDirectory;
@class AppBlade;

@protocol AppBladeDelegate <NSObject>

// Was the application approved to run?
-(void) appBlade:(AppBlade *)appBlade applicationApproved:(BOOL)approved error:(NSError*)error;

// Is there an update of this application available?
-(void) appBlade:(AppBlade *)appBlade updateAvailable:(BOOL)update updateMessage:(NSString*)message updateURL:(NSString*)url;

@end

@interface AppBlade : NSObject <AppBladeDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate> {

@private

    id<AppBladeDelegate> _delegate;
    NSURL *_upgradeLink;
   
    NSString *_appBladeHost;
    NSString *_appBladeProjectID;
    NSString *_appBladeProjectToken;
    NSString *_appBladeProjectSecret;
    NSString *_appBladeProjectIssuedTimestamp;
}

// AppBlade host name
@property (nonatomic, retain) NSString* appBladeHost;

// UUID of the project on AppBlade.
@property (nonatomic, retain) NSString* appBladeProjectID;

// AppBlade API token for the project.
@property (nonatomic, retain) NSString* appBladeProjectToken;

// AppBlade API secret for the project. 
@property (nonatomic, retain) NSString* appBladeProjectIssuedTimestamp;

// AppBlade API project issued time.
@property (nonatomic, retain) NSString* appBladeProjectSecret;

// AppBlade custom fields 
@property (nonatomic, retain, readonly) NSDictionary* appBladeParams;

// Should OAuth be used to authenticate. Default is YES.
@property (nonatomic, assign, readonly) BOOL useOAuth;

// The AppBlade delegate receives messages regarding device authentication and other events.
// See protocol declaration, above.
@property (nonatomic, assign) id<AppBladeDelegate> delegate;

// Returns SDK Version
+ (NSString*)sdkVersion;

// Returns Caches Directory Path
+ (NSString*)cachesDirectoryPath;

// Log SDK Version
+ (void)logSDKVersion;

// AppBlade manager singleton.
+ (AppBlade *)sharedManager;

#pragma mark TODO: Make all of these class methods.

// Pass in the full path to the plist
- (void)loadSDKKeysFromPlist:(NSString*)plist;

// Checks if any crashes have ocurred sends logs to AppBlade.
- (void)catchAndReportCrashes;

/*
 *    WARNING: The following features are only for ad hoc and enterprise applications. Shipping an app to the iTunes App
 *    store with a call to |-checkApproval|, for example, could result in app termination or rejection.
 */

// Checks for OAuth token, if none shows an OAuth sheet to authenticate
- (void)checkApproval;

// Pass in NO to use the old system which uses UDID. Passing in YES is the same as -checkApproval
- (void)checkApprovalWithOAuth:(BOOL)useOAuth;

// Shows a feedback dialogue, with option to specify the view and whether or not to take a screenshot.
- (void)showFeedbackDialogueInView:(UIView*)view;
- (void)showFeedbackDialogueWithScreenshot:(BOOL)takeScreenshot inView:(UIView*)view;

// Sets up a 3-finger double tap for reporting feedback
- (void)allowFeedbackReporting;

// In case you only want feedback in a specific window.
- (void)allowFeedbackReportingForWindow:(UIWindow*)window;

// Update custom params dictionary sent to AppBlade

// Will overrite everything
- (void)setCustomParams:(NSDictionary*)params; 

// Update a single key/value pair
- (void)updateCustomParam:(id)key withValue:(id)value;

// Clears everything
- (void)clearAllCustomParams;

/*
 * OAuth
 */

- (void)showOAuthSheet;
- (void)clearOAuthSession;

/*
 * Device
 */

//  Returns either an OAuth token, or UDID if OAuth is disabled
- (NSString*)deviceIdentifier;

/*
 * Session counting
 */

+ (void)startSession;
+ (void)endSession;

@end
