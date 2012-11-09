//
//  AppBladeWebClient.h
//  AppBlade
//
//  Created by Craig Spitzkoff on 6/18/11.
//  Copyright 2011 AppBlade. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class AppBladeWebClient;

typedef enum {
	AppBladeWebClientAPI_Permissions,
    AppBladeWebClientAPI_ReportCrash,
    AppBladeWebClientAPI_Feedback
} AppBladeWebClientAPI;

@protocol AppBladeWebClientDelegate <NSObject>

@required

- (NSString *)appBladeHost;
- (NSString *)appBladeProjectID;
- (NSString *)appBladeProjectToken;
- (NSString *)appBladeProjectSecret;
- (NSString *)appBladeProjectIssuedTimestamp;

- (void)appBladeWebClientFailed:(AppBladeWebClient *)client;
- (void)appBladeWebClient:(AppBladeWebClient *)client receivedPermissions:(NSDictionary*)permissions;
- (void)appBladeWebClientCrashReported:(AppBladeWebClient *)client;
- (void)appBladeWebClientSentFeedback:(AppBladeWebClient*)client withSuccess:(BOOL)success;

@end

@interface AppBladeWebClient : NSObject {

@private

    // Delegate providing AppBlade configuration and accepting messages regarding request outcomes.
    id<AppBladeWebClientDelegate> _delegate;

    // Type of API call.
    AppBladeWebClientAPI _api;

    // HTTP request object for the API call.
    NSMutableURLRequest *_request;
    
    // Container for API response data.
    NSMutableData *_receivedData;
}

@property (nonatomic, assign) id<AppBladeWebClientDelegate> delegate;
@property (nonatomic, readonly) AppBladeWebClientAPI api;
@property (nonatomic, retain) NSDictionary* userInfo;
@property (nonatomic, retain) NSDictionary* responseHeaders;

- (id)initWithDelegate:(id<AppBladeWebClientDelegate>)delegate;

// AppBlade API.
- (void)checkPermissions;
- (void)reportCrash:(NSString *)crashReport;
- (void)sendFeedbackWithScreenshot:(NSString*)screenshot note:(NSString*)note console:(NSString*)console;

@end
