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


typedef void (^AppBladeRequestPrepareBlock)(id preparationData);
typedef void (^AppBladeRequestCompletionBlock)(NSMutableURLRequest *request, id rawSentData, NSDictionary* responseHeaders, NSMutableData* receivedData, NSError *webError);
//AppBladeRequestCompletionBlock is our main workhorse, most of the logic is actually in manager handle* calls. 
typedef void (^AppBladeRequestSuccessBlock)(id data, NSError* error); //we can return an error and still be successful
typedef void (^AppBladeRequestFailureBlock)(id data, NSError* error);



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
extern NSString *authorizeURLFormat;
extern NSString *reportCrashURLFormat;
extern NSString *reportFeedbackURLFormat;
extern NSString *sessionURLFormat;
extern NSString *updateURLFormat;
extern NSString *deviceSecretHeaderField;


@protocol AppBladeWebOperationDelegate <NSObject>

@required
- (NSString *)appBladeHost;
- (NSString *)appBladeProjectSecret;
- (NSString *)appBladeDeviceSecret;

- (BOOL)containsOperationInPendingRequests:(AppBladeWebOperation *)webOperation;

- (void)appBladeWebClientFailed:(AppBladeWebOperation *)client;
- (void)appBladeWebClientFailed:(AppBladeWebOperation *)client withErrorString:(NSString*)errorString;
//Token
- (void)appBladeWebClient:(AppBladeWebOperation *)client receivedGenerateTokenResponse:(NSDictionary *)response;
- (void)appBladeWebClient:(AppBladeWebOperation *)client receivedConfirmTokenResponse:(NSDictionary *)response;
///Crash Report
- (void)appBladeWebClientCrashReported:(AppBladeWebOperation *)client;
///Session Report
- (void)appBladeWebClientSentSessions:(AppBladeWebOperation *)client withSuccess:(BOOL)success;

@end

@interface AppBladeWebOperation : NSOperation 

- (id)initWithDelegate:(id<AppBladeWebOperationDelegate>)delegate;

@property (nonatomic, weak) id<AppBladeWebOperationDelegate> delegate;
@property (nonatomic, readwrite) AppBladeWebClientAPI api;
@property (nonatomic) SEL finishedLoadingCallback;


@property (nonatomic, strong) NSDictionary* userInfo;
@property (nonatomic, strong) NSMutableURLRequest* request;
@property (nonatomic, strong) NSDictionary* responseHeaders;
@property (nonatomic, strong) NSMutableData* receivedData;
@property (nonatomic, strong) NSString* sentDeviceSecret;

@property (nonatomic, copy) AppBladeRequestPrepareBlock prepareBlock;
@property (nonatomic, copy) AppBladeRequestCompletionBlock requestCompletionBlock;
@property (nonatomic, copy) AppBladeRequestSuccessBlock successBlock;
@property (nonatomic, copy) AppBladeRequestFailureBlock failBlock;

-(int)getReceivedStatusCode;

// Request builder methods.
+ (NSString *)buildHostURL:(NSString *)customURLString;
- (NSMutableURLRequest *)requestForURL:(NSURL *)url;
- (NSString *)encodeBase64WithData:(NSData *)objData;
- (NSString *)genRandNumberLength:(int)len;
- (void)addSecurityToRequest:(NSMutableURLRequest *)request;

@end
