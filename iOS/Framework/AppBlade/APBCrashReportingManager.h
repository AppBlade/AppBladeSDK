/*!
 @header  APBCrashReportingManager.h
 @abstract  Holds all crash-reporting functionality
 @framework AppBlade
 @author AndrewTremblay on 7/16/13.
 @copyright AppBlade 2013. All rights reserved.
 */

#import <Foundation/Foundation.h>

#import "APBDatabaseCrashReport.h"


#import "APBBasicFeatureManager.h"
#import "APBDataManager.h"

/*!
 @class APBCrashReportingManager
 @abstract The AppBlade Crash Reporting feature
 @discussion This manager contains the catchAndReportCrashes call and callbacks. When an AppBlade-SDK-enabled app enables crash reporting, the SDK listens through the PLCrashReporter library to catch and store the crash logs, which it subsequenty sends to AppBlade for processing once the app is resumed.
 */
@interface APBCrashReportingManager : NSObject<APBBasicFeatureManager>
@property (nonatomic, strong) id<APBWebOperationDelegate, APBDataManagerDelegate> delegate;

@property (nonatomic, strong, readonly) NSString *dbMainTableName;
@property (nonatomic, strong, readonly) NSArray  *dbMainTableAdditionalColumns; //remember: all tables by design have an id column assigned


#pragma mark - Web Request Generators
- (APBWebOperation*) generateCrashReportFromDictionary:(NSDictionary *)crashDictionary withParams:(NSDictionary *)paramsDict;

- (void)handleWebClientCrashReported:(APBWebOperation *)client;
- (void)crashReportCallbackFailed:(APBWebOperation *)client withErrorString:(NSString*)errorString;

#pragma mark Stored Web Request Handling

#pragma mark Stored Crash Handling
- (void) catchAndReportCrashes;
- (void) checkForExistingCrashReports;
- (NSMutableDictionary *) handleCrashReportAsDictionary;

@end


//Our additional requirements
@interface AppBlade (CrashReporting)

@property (nonatomic, strong) APBCrashReportingManager*     crashManager;
//hasPendingCrashReport in PLCrashReporter
- (void)appBladeWebClientCrashReported:(APBWebOperation *)  client;


@end



@interface APBDataManager (CrashReporting)
@property (nonatomic) sqlite3 *db;


-(NSError *)addCrashReport:(APBDatabaseCrashReport *)crashReport;
-(APBDatabaseCrashReport *)getCrashReportFromParameters:(NSString *)parameterString;
-(NSArray *)crashReports; //array of APBDatabaseCrashReport

@end
