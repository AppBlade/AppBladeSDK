//
//  APBDatabaseCustomParameter.m
//  AppBlade
//
//  Created by AndrewTremblay on 12/9/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//

#import "APBDatabaseCustomParameter.h"
#import "AppBladeDatabaseColumn.h"
#import "APBDataManager.h"
#import "APBBase64Encoder.h"
#import "AppBladeLogging.h"


@implementation APBDatabaseCustomParameter
    -(id)initFromSQLiteStatement:(sqlite3_stmt *)statement
    {
        self = [super init];
        if (self) {
            self.tableName = kDbCustomParametersMainTableName;
            NSError *errorCheck = [self readFromSQLiteStatement:statement];
            if(errorCheck){
                ABErrorLog(@"%@", [errorCheck debugDescription]);
                return nil;
            }
        }
        return self;
    }

    -(id)initWithDictionary:(NSDictionary *)dictionary{
        self = [super init];
        if (self) {
            [self takeFreshSnapshot];
            self.tableName = kDbCustomParametersMainTableName;
            self.snapshotDate = [NSDate new];
            self.storedParams = dictionary;
        }
        return self;
    }


    +(NSArray *)columnDeclarations {
        return @[[AppBladeDatabaseColumn initColumnNamed:kDbCustomParamColumnNameDictRaw
                                          withContraints: (AppBladeColumnConstraintAffinityText)
                                          additionalArgs:nil],
                 [AppBladeDatabaseColumn initColumnNamed:kDbCustomParamColumnNameSnapshotDate
                                          withContraints:(AppBladeColumnConstraintAffinityText | AppBladeColumnConstraintNotNull)
                                          additionalArgs:nil]];

    }

-(NSArray *)additionalColumnNames {
    return @[ kDbCustomParamColumnNameDictRaw, kDbCustomParamColumnNameSnapshotDate];
}

-(NSArray *)additionalColumnValues{
    return @[ [self sqlFormattedProperty:[self paramsAsString]], [self sqlFormattedProperty:self.snapshotDate] ];
}



-(NSError *)readFromSQLiteStatement:(sqlite3_stmt *)statement {
    ABDebugLog_internal(@"READING IN CUSTOM PARAM VALUES");
    NSError *toRet = [super readFromSQLiteStatement:statement];
    if(toRet != nil){
        ABErrorLog(@"DB: error reading base values %@", [toRet debugDescription]);
        return toRet;
    }
    NSString *paramsText = [self readStringInAdditionalColumn:[NSNumber numberWithInt:kDbCustomParamColumnIndexOffsetDictRaw] fromSQLiteStatement:statement];
    if(paramsText){
        [self parseStringFromStorage:paramsText];
    }else{
        toRet = [APBDataManager dataBaseErrorWithMessage:@"stored param data could not be parsed"];
    }

    self.snapshotDate = [self readDateInAdditionalColumn:[NSNumber numberWithInt:kDbCustomParamColumnIndexOffsetSnapshotDate] fromSQLiteStatement:statement];

    return toRet;
}


-(NSString *)paramsAsString {
    NSError *error = nil;
    BOOL paramIsValid = [NSJSONSerialization isValidJSONObject:self.storedParams];
    if (!paramIsValid) {
        NSLog(@"Something is very wrong with your params, they could not be converted to json");
        return @"";
    }
    
    NSData *dataFromDictionary = [NSJSONSerialization dataWithJSONObject:self.storedParams options:0 error:&error]; //create NSData from JSONSerialization
    NSString *stringFromData = [APBBase64Encoder base64EncodedStringFromData:dataFromDictionary];
    //newlines separate every 64 characters
    NSString *stringforStorage = [stringFromData stringByReplacingOccurrencesOfString:@"\r\n" withString:@""];
    return stringforStorage; //return stringified NSData
}

-(void)parseStringFromStorage:(NSString *)stringifiedParams {
    NSError *error = nil;
    NSData *dataFromString = [APBBase64Encoder dataFromBase64String:stringifiedParams]; //Decode the stringified NSData back into NSData
    NSDictionary *dictFromString = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:dataFromString options:NSJSONReadingMutableContainers error:&error];  //JSONSerialize the NSData back into an NSDictionary
    self.storedParams = dictFromString;
}


-(NSDictionary *)asDictionary {
    return self.storedParams;
}



@end
