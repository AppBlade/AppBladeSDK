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
static const int kAppBladeParsingError;
static const int kAppBladePermissionError;
static NSString* const kAppBladeCacheDirectory;
@class AppBlade;

@protocol AppBladeDelegate <NSObject>

// Was the application approved to run?
-(void) appBlade:(AppBlade *)appBlade applicationApproved:(BOOL)approved error:(NSError*)error;

// Is there an update of this application available?
-(void) appBlade:(AppBlade *)appBlade updateAvailable:(BOOL)update updateMessage:(NSString*)message updateURL:(NSString*)url;

@end

@interface AppBlade : NSObject <AppBladeDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate> 

// AppBlade host name //Include neither http:// nor https://, we'll handle that.
@property (nonatomic, retain) NSString* appBladeHost;

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

// Returns SDK Version
+ (NSString*)sdkVersion;

// Log SDK Version
+ (void)logSDKVersion;

// AppBlade manager singleton.
+ (AppBlade *)sharedManager;

// Pass in the full path to the plist
- (void)loadSDKKeysFromPlist:(NSString*)plist;

// Sets up variables & Checks if any crashes have ocurred, sends logs to AppBlade.
- (void)catchAndReportCrashes;

//method to call if you want to attempt to send crash reports more often than ususal 
- (void)checkForExistingCrashReports;



//Define special custom fields to be sent back to Appblade in your Feedback reports or Crash reports
-(NSDictionary *)getCustomParams;
-(void)setCustomParams:(NSDictionary *)newFieldValues;
-(void)setCustomParam:(id)newObject withValue:(NSString*)key;
-(void)clearAllCustomParams;


/*
 *    WARNING: The following features below are only for ad hoc and enterprise applications. Shipping an app to the iTunes App
 *    store with a call to |-checkApproval|, for example, could result in app termination or rejection.
 */

// Checks with AppBlade to see if the app is allowed to run on this device.
- (void)checkApproval;

+ (NSString*)cachesDirectoryPath;

// Sets up a 3-finger double tap for reporting feedback
- (void)allowFeedbackReporting;

// In case you only want 3-finger double tap feedback in a specific window.
- (void)allowFeedbackReportingForWindow:(UIWindow*)window;

// In case you want feedback but want to handle prompting it yourself (no 3-finger double tap).
- (void)setupCustomFeedbackReporting;

- (void)setupCustomFeedbackReportingForWindow:(UIWindow*)window;

// Shows a feedback dialogue and handles screenshot
- (void)showFeedbackDialogue;


+ (void)startSession;
+ (void)endSession;


@end
