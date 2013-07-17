//
//  AppBladeWebClient.h
//  AppBlade
//
//  Created by Craig Spitzkoff on 6/18/11.
//  Copyright 2011 AppBlade. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class AppBladeWebOperation;

typedef enum {
    AppBladeWebClientAPI_GenerateToken,
    AppBladeWebClientAPI_ConfirmToken,
	AppBladeWebClientAPI_Permissions,
    AppBladeWebClientAPI_ReportCrash,
    AppBladeWebClientAPI_Feedback,
    AppBladeWebClientAPI_Sessions,
    AppBladeWebClientAPI_UpdateCheck,
    AppBladeWebClientAPI_AllTypes
} AppBladeWebClientAPI;

extern NSString *defaultURLScheme;
extern NSString *defaultAppBladeHostURL;
extern NSString *approvalURLFormat;
extern NSString *reportCrashURLFormat;
extern NSString *reportFeedbackURLFormat;
extern NSString *sessionURLFormat;

extern NSString *deviceSecretHeaderField;


@protocol AppBladeWebClientDelegate <NSObject>

@required

- (NSString *)appBladeHost;
- (NSString *)appBladeProjectSecret;
- (NSString *)appBladeDeviceSecret;

- (void)appBladeWebClientFailed:(AppBladeWebOperation *)client;
- (void)appBladeWebClientFailed:(AppBladeWebOperation *)client withErrorString:(NSString*)errorString;

- (void)appBladeWebClient:(AppBladeWebOperation *)client receivedGenerateTokenResponse:(NSDictionary *)response;
- (void)appBladeWebClient:(AppBladeWebOperation *)client receivedConfirmTokenResponse:(NSDictionary *)response;
- (void)appBladeWebClient:(AppBladeWebOperation *)client receivedPermissions:(NSDictionary *)permissions;
- (void)appBladeWebClientCrashReported:(AppBladeWebOperation *)client;
- (void)appBladeWebClientSentFeedback:(AppBladeWebOperation *)client withSuccess:(BOOL)success;
- (void)appBladeWebClientSentSessions:(AppBladeWebOperation *)client withSuccess:(BOOL)success;
- (void)appBladeWebClient:(AppBladeWebOperation *)client receivedUpdate:(NSDictionary*)permissions;

@end

@interface AppBladeWebOperation : NSOperation 

@property (nonatomic, weak) id<AppBladeWebClientDelegate> delegate;
@property (nonatomic, readwrite) AppBladeWebClientAPI api;

@property (nonatomic, strong) NSDictionary* userInfo;
@property (nonatomic, strong) NSMutableURLRequest* request;
@property (nonatomic, strong) NSDictionary* responseHeaders;
@property (nonatomic, strong) NSMutableData* receivedData;

@property (nonatomic, strong) NSString* sentDeviceSecret;
-(int)getReceivedStatusCode;

- (id)initWithDelegate:(id<AppBladeWebClientDelegate>)delegate;

+ (NSString *)buildHostURL:(NSString *)customURLString;

// AppBlade API.
- (void)refreshToken:(NSString *)tokenToConfirm;
- (void)confirmToken:(NSString *)tokenToConfirm;

- (void)checkPermissions;
- (void)checkForUpdates;
- (void)reportCrash:(NSString *)crashReport withParams:(NSDictionary *)params;
- (void)sendFeedbackWithScreenshot:(NSString*)screenshot note:(NSString*)note console:(NSString*)console params:(NSDictionary*)paramsData;
- (void)postSessions:(NSArray *)sessions;
@end
