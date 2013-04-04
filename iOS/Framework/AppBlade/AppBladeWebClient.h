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
    AppBladeWebClientAPI_Feedback,
    AppBladeWebClientAPI_Sessions,
    AppBladeWebClientAPI_UpdateCheck,
    AppBladeWebClientAPI_AllTypes
} AppBladeWebClientAPI;

extern NSString *defaultURLScheme;
extern NSString *defaultAppBladeHostURL;
extern NSString *approvalURLFormat    ;
extern NSString *reportCrashURLFormat  ;
extern NSString *reportFeedbackURLFormat ;
extern NSString *sessionURLFormat;


@protocol AppBladeWebClientDelegate <NSObject>

@required

- (NSString *)appBladeHost;
- (NSString *)appBladeProjectSecret;
- (NSString *)appBladeDeviceSecret;

- (void)appBladeWebClientFailed:(AppBladeWebClient *)client;
- (void)appBladeWebClientFailed:(AppBladeWebClient *)client withErrorString:(NSString*)errorString;

- (void)appBladeWebClient:(AppBladeWebClient *)client receivedPermissions:(NSDictionary *)permissions andShowUpdate:(BOOL)showUpdatePrompt;
- (void)appBladeWebClientCrashReported:(AppBladeWebClient *)client;
- (void)appBladeWebClientSentFeedback:(AppBladeWebClient *)client withSuccess:(BOOL)success;
- (void)appBladeWebClientSentSessions:(AppBladeWebClient *)client withSuccess:(BOOL)success;
- (void)appBladeWebClient:(AppBladeWebClient *)client receivedUpdate:(NSDictionary*)permissions;


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

+ (NSString *)buildHostURL:(NSString *)customURLString;

// AppBlade API.
- (void)checkPermissions:(BOOL)andForUpdates;
- (void)checkForUpdates;
- (void)reportCrash:(NSString *)crashReport withParams:(NSDictionary *)params;
- (void)sendFeedbackWithScreenshot:(NSString*)screenshot note:(NSString*)note console:(NSString*)console params:(NSDictionary*)paramsData;
- (void)postSessions:(NSArray *)sessions;

@end
