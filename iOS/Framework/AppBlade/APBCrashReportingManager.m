//
//  CrashReporting.m
//  AppBlade
//
//  Created by AndrewTremblay on 7/16/13.
//  Copyright (c) 2013 AppBlade. All rights reserved.
//

#import "APBCrashReportingManager.h"
#import "AppBlade+PrivateMethods.h"

#import "APBDatabaseCrashReport.h"

#import "AppBladeDatabaseColumn.h"

#import "PLCrashReporter.h"
#import "PLCrashReport.h"
#import "PLCrashReportTextFormatter.h"

NSString *reportCrashURLFormat       = @"%@/api/3/crash_reports";

static NSString* const kDbCrashReportDatabaseMainTableName = @"crashreports";
//columns are inside APBDatabaseCrashReport interface

static NSString* const kCrashDictCrashReportString  = @"_crashReportString";
static NSString* const kCrashDictQueuedFilePath     = @"_queuedFilePath";

@interface APBCrashReportingManager ()
    //redeclarations of readonly properties
    @property (nonatomic, strong, readwrite) NSString *dbMainTableName;
    @property (nonatomic, strong, readwrite) NSArray  *dbMainTableAdditionalColumns;

    - (APBWebOperation*) generateCrashReport:(NSString *)crashReport withParams:(NSDictionary *)paramsDict;
@end


@implementation APBCrashReportingManager
@synthesize delegate;

- (id)initWithDelegate:(id<APBWebOperationDelegate, APBDataManagerDelegate>)webOpAndDataManagerDelegate
{
    if((self = [super init])) {
        self.delegate = webOpAndDataManagerDelegate;
        self.dbMainTableName = kDbCrashReportDatabaseMainTableName;
    
        
        self.dbMainTableAdditionalColumns = [APBDatabaseCrashReport columnDeclarations];
        
        [self createTablesWithDelegate:webOpAndDataManagerDelegate];
    }
    
    return self;
}


#pragma mark - Web Request Generators
- (APBWebOperation*) generateCrashReportFromDictionary:(NSDictionary *)crashDictionary withParams:(NSDictionary *)paramsDict
{
    APBWebOperation *client = nil;
    NSString *crashReportString = [crashDictionary objectForKey:kCrashDictCrashReportString];
    NSString *queuedFilePath    = [crashDictionary objectForKey:kCrashDictQueuedFilePath];
    if(nil != crashReportString && nil != queuedFilePath){
        client = [self generateCrashReport:crashReportString  withParams:paramsDict];
        client.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:queuedFilePath,  kAppBladeCrashReportKeyFilePath, nil];
    }
    return client;
}

- (APBWebOperation*) generateCrashReport:(NSString *)crashReport withParams:(NSDictionary *)paramsDict
{
    APBWebOperation *client = [[APBWebOperation alloc] initWithDelegate:self.delegate];
    [client setApi: AppBladeWebClientAPI_Feedback];

    @synchronized (self)
    {
        // Build report URL.
        NSString* urlCrashReportString = [NSString stringWithFormat:reportCrashURLFormat, [self.delegate appBladeHost]];
        NSURL* urlCrashReport = [NSURL URLWithString:urlCrashReportString];
        
        NSString *multipartBoundary = [NSString stringWithFormat:@"---------------------------%@", [client genRandNumberLength:64]];
        // Create the API request.
        NSMutableURLRequest* apiRequest = [client requestForURL:urlCrashReport];
        [apiRequest setValue:[@"multipart/form-data; boundary=" stringByAppendingString:multipartBoundary] forHTTPHeaderField:@"Content-Type"];
        [apiRequest setHTTPMethod:@"POST"];
        
        NSMutableData* body = [NSMutableData dataWithData:[[NSString stringWithFormat:@"--%@\r\n",multipartBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Disposition: form-data; name=\"file\"; filename=\"report.crash\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type: text/plain\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        
        NSData* data = [crashReport dataUsingEncoding:NSUTF8StringEncoding];
        [body appendData:data];
        
        if([NSPropertyListSerialization propertyList:paramsDict isValidForFormat:NSPropertyListXMLFormat_v1_0]){
            NSError* error = nil;
            NSData *paramsData = [NSPropertyListSerialization dataWithPropertyList:paramsDict format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
            if(error == nil){
                [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",multipartBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:[@"Content-Disposition: form-data; name=\"custom_params\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:[@"Content-Type: text/xml\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:paramsData];
                ABDebugLog_internal(@"Parsed params! They were included.");
            }
            else
            {
                ABErrorLog(@"Error parsing params. They weren't included. %@ ",error.debugDescription);
            }
        }
        
        [body appendData:[[[@"\r\n--" stringByAppendingString:multipartBoundary] stringByAppendingString:@"--"] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [apiRequest setHTTPBody:body];
        [apiRequest setValue:[NSString stringWithFormat:@"%d", [body length]] forHTTPHeaderField:@"Content-Length"];
        
        
        
        __block APBWebOperation *blocksafeClient = client;
        [client setPrepareBlock:^(id preparationData){
            NSMutableURLRequest* castRequest = (NSMutableURLRequest*)preparationData;
            [blocksafeClient addSecurityToRequest:castRequest];
        }];

        [client setRequestCompletionBlock:^(NSMutableURLRequest *request, id rawSentData, NSDictionary* responseHeaders, NSMutableData* receivedData, NSError *webError){
            // purge the crash report that was just reported.
            int status = [[responseHeaders valueForKey:@"statusCode"] intValue];
            BOOL success = (status == 201 || status == 200);
            if(success){ //we don't need to hold onto this crash.
                ABDebugLog_internal(@"Appblade: success sending crash report, response status code: %d", status);

                blocksafeClient.successBlock(nil, nil);
            }
            else
            {
                ABErrorLog(@"Appblade: error sending crash report, response status code: %d", status);

                blocksafeClient.failBlock(nil, nil);
            }

        }];
        
        [client setSuccessBlock:^(id data, NSError* error){
            [[PLCrashReporter sharedReporter] purgePendingCrashReport];
            NSString *pathOfCrashReport = [blocksafeClient.userInfo valueForKey:kAppBladeCrashReportKeyFilePath];
            [[NSFileManager defaultManager] removeItemAtPath:pathOfCrashReport error:nil];
            ABDebugLog_internal(@"Appblade: removed crash report, %@", pathOfCrashReport);
            
            if ([[PLCrashReporter sharedReporter] hasPendingCrashReport]){
                ABDebugLog_internal(@"Appblade: PLCrashReporter has more crash reports");
                [[AppBlade sharedManager] handleCrashReport];
            }
            else
            {
                ABDebugLog_internal(@"Appblade: PLCrashReporter has no more crash reports");
            }

        }];
        
        [client setFailBlock:^(id data, NSError* error){
            //No more crash reports for now. We might have bad internet access.
        }];

        
    }
    return client;
}

- (void)handleWebClientCrashReported:(APBWebOperation *)client
{
    ABDebugLog_internal(@"Appblade: Webclient reported crash successfully.");
}

- (void)crashReportCallbackFailed:(APBWebOperation *)client withErrorString:(NSString*)errorString
{
    if(errorString){
        ABErrorLog(@"ERROR sending crash %@", errorString);
    }
}

#pragma mark Stored Crash Handling

-(void)createTablesWithDelegate:(id<APBDataManagerDelegate>)databaseDelegate
{
    if([[databaseDelegate getDataManager] tableExistsWithName:self.dbMainTableName]){
        //table exists, see if we need to update it
#ifndef SKIP_CUSTOM_PARAMS
        //make sure we have a custom parameter column
        if(![[databaseDelegate getDataManager] table:self.dbMainTableName containsColumn:kDbCrashReportColumnNameCustomParamsRef]){
            APBDataTransaction addParameterColumn = ^(sqlite3 *dbRef){
                NSString *alterTableSQL = @"ALTER TABLE crash_reports ADD FOREIGN KEY customParamsId REFERENCES custom_params(id) ON DELETE CASCADE";
                const char *sqlStatement = [alterTableSQL UTF8String];
                char *error;
                sqlite3_exec(dbRef, sqlStatement, NULL, NULL, &error);
                if(error != nil){
                     NSLog(@"%s: ERROR Preparing: , %s", __FUNCTION__, sqlite3_errmsg(dbRef));
                }
            };
            [[databaseDelegate getDataManager] alterTable:self.dbMainTableName withTransaction:addParameterColumn];
        }
#else
        //make sure we don't have a custom parameter column
        if([[databaseDelegate getDataManager] table:self.dbMainTableName containsColumn:kDbCrashReportColumnNameCustomParamsRef]){
            APBDataTransaction removeParameterColumn = ^(sqlite3 *dbRef){
                //Sqlite has "Limited support for ALTER TABLE", which makes the process of changing tables a bit arduous
                NSString *colsToKeep = @[@"id", @"stackTrace", @"reportedAt"];
                NSString *alterTableSQL = [APBDataManager sqlQueryToTrimTable:kDbCrashReportDatabaseMainTableName toColumns:colsToKeep];
                const char *sqlStatement = [alterTableSQL UTF8String];
                char *error;
                sqlite3_exec(dbRef, sqlStatement, NULL, NULL, &error);
                if(error != nil){
                    NSLog(@"%s: ERROR Preparing: , %s", __FUNCTION__, sqlite3_errmsg(dbRef));
                }
                return;
            };
            [[databaseDelegate getDataManager] alterTable:self.dbMainTableName withTransaction:addParameterColumn];
        }
#endif
    }else{
        //table doesn't exist! we need to create it.
        [[databaseDelegate getDataManager] createTable:self.dbMainTableName withColumns:self.dbMainTableAdditionalColumns];
    }
}


-(void) catchAndReportCrashes
{
    ABDebugLog_internal(@"Catch and report crashes");
    [self checkForExistingCrashReports];

    PLCrashReporter *crashReporter = [PLCrashReporter sharedReporter];
    NSError *error;
    // Enable the Crash Reporter
    if (![crashReporter enableCrashReporterAndReturnError: &error])
        ABErrorLog(@"Warning: Could not enable crash reporter: %@", error);
}

- (void) checkForExistingCrashReports
{
    PLCrashReporter *crashReporter = [PLCrashReporter sharedReporter];
    // Check if we previously crashed
    if ([crashReporter hasPendingCrashReport]){
        [[AppBlade sharedManager] handleCrashReport];
    }
}
//see "NSDictionary+AppBladeDatabaseCrashReports.h"
- (NSDictionary *) handleCrashReportAsDictionary
{
    PLCrashReporter *crashReporter = [PLCrashReporter sharedReporter];
    NSData *crashData;
    NSError *error;
    NSString* reportString = nil;
    NSString *queuedFilePath = nil;
    // Try loading the crash report from the live file
    crashData = [crashReporter loadPendingCrashReportDataAndReturnError: &error];
    if (crashData != nil) {
        PLCrashReport *report = [[PLCrashReport alloc] initWithData: crashData error: &error];
        if (report != nil) {
            reportString = [PLCrashReportTextFormatter stringValueForCrashReport:report withTextFormat: PLCrashReportTextFormatiOS];
            //send pending crash report to a unique file name in the the queue
            queuedFilePath = [crashReporter saveCrashReportInQueue:reportString]; //file will stay in the queue until it's sent
            if(queuedFilePath == nil){
                ABErrorLog(@"error saving crash report");
            }
            else
            {
                ABDebugLog_internal(@"moved crash report to %@", queuedFilePath);
            }
        }
        else
        {
            ABErrorLog(@"Could not parse crash report");
        }
    }
    else
    {
        ABErrorLog(@"Could not load a crash report from live file");
    }
    [crashReporter purgePendingCrashReport]; //remove crash report from immediate file, we have it in the queue now
    
    if(queuedFilePath == nil){
        //we had no immediate crash, or an invalid save, grab any stored crash report
        queuedFilePath = [crashReporter getNextCrashReportPath];
        reportString = [NSString stringWithContentsOfFile:queuedFilePath encoding:NSUTF8StringEncoding error:&error];
    }
    if(queuedFilePath != nil){
        return [NSDictionary dictionaryWithObjectsAndKeys:queuedFilePath, kCrashDictQueuedFilePath, reportString, kCrashDictCrashReportString, nil];
    }
    else
    {
        ABDebugLog_internal(@"No crashes to report");
        return nil;
    }
}

@end


@implementation AppBlade (CrashReporting)
@dynamic crashManager;

- (void)appBladeWebClientCrashReported:(APBWebOperation *)client
{
#ifndef SKIP_CRASH_REPORTING
    [self.crashManager handleWebClientCrashReported:client];
#endif
}


@end


@implementation APBDataManager (CrashReporting)
    @dynamic db;

-(NSError *)addCrashReport:(APBDatabaseCrashReport *)crashReport {
    return [self writeData:crashReport toTable:kDbCrashReportDatabaseMainTableName];
}

/* returns first row result of the parameter, no order is specified*/
-(APBDatabaseCrashReport *)getCrashReportFromParameters:(NSString *)params {
    NSError *errorCheck = nil;
    APBDatabaseCrashReport *toRet = nil;
    sqlite3_stmt    *statement;
    if ([self prepareTransaction]  == SQLITE_OK)
    {
        NSString *querySQL = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@", kDbCrashReportDatabaseMainTableName, params];
        const char *query_stmt = [querySQL UTF8String];
        if (sqlite3_prepare_v2(self.db, query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            if (sqlite3_step(statement) == SQLITE_ROW)
            {
                toRet = [[APBDatabaseCrashReport alloc] init];
                errorCheck = [toRet readFromSQLiteStatement:statement];
                if(errorCheck != nil){
                    errorCheck = [APBDataManager dataBaseErrorWithMessage:@"error reading results"];
                }
            }
            sqlite3_finalize(statement);
        }
        [self finishTransaction];
    }
    if(errorCheck != nil){
        toRet = nil;
        ABErrorLog(@"%@", errorCheck);
    }
    return  toRet;
}

-(NSArray *)crashReports {
    NSError *errorCheck = nil;
    NSMutableArray *toRet = [NSMutableArray init];
    sqlite3_stmt    *statement;
    if ([self prepareTransaction]  == SQLITE_OK)
    {

        NSString *querySQL = [NSString stringWithFormat:@"SELECT * FROM %@", kDbCrashReportDatabaseMainTableName];
        const char *query_stmt = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(self.db, query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                APBDatabaseCrashReport* tempObj = [[APBDatabaseCrashReport alloc] init];
                errorCheck = [tempObj readFromSQLiteStatement:statement];
                if(errorCheck != nil){
                    errorCheck = [APBDataManager dataBaseErrorWithMessage:@"error reading results"];
                    break;
                }else{
                    [toRet addObject:tempObj];
                } //Match found (posssibly)
            }
            sqlite3_finalize(statement);
        }
        [self finishTransaction];
    }
    if(errorCheck != nil){
        toRet = nil;
        ABErrorLog(@"%@", errorCheck);
    }
    return  toRet;
}


@end


