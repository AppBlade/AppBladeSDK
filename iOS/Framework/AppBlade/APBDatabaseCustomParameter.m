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

@implementation APBDatabaseCustomParameter
    -(id)initWithDictionary:(NSDictionary *)dictionary{
        self = [super init];
        if (self) {
            [self takeFreshSnapshot];
            self.snapshotDate = [NSDate new];
            self.storedParams = dictionary;
        }
        return self;
    }


    +(NSArray *)columnDeclarations {
        return @[[AppBladeDatabaseColumn initColumnNamed:kDbCustomParamColumnNameDictRaw withContraints: (AppBladeColumnConstraintAffinityNone) additionalArgs:nil],
                 [AppBladeDatabaseColumn initColumnNamed:kDbCustomParamColumnNameSnapshotDate withContraints:(AppBladeColumnConstraintAffinityText | AppBladeColumnConstraintNotNull) additionalArgs:nil]];

    }

-(NSArray *)additionalColumnNames {
    return @[ kDbCustomParamColumnNameDictRaw, kDbCustomParamColumnNameSnapshotDate];
}

-(NSArray *)additionalColumnValues{
    return @[ [self sqlFormattedProperty:[self paramsAsString]], [self sqlFormattedProperty:self.snapshotDate] ];
}



-(NSError *)readFromSQLiteStatement:(sqlite3_stmt *)statement {
    NSError *toRet = [super readFromSQLiteStatement:statement];
    if(toRet != nil)
        return toRet;
    self.snapshotDate = [self readDateInAdditionalColumn:[NSNumber numberWithInt:kDbCustomParamColumnIndexOffsetSnapshotDate] fromFromSQLiteStatement:statement];
    NSString *paramsText = [self readStringInAdditionalColumn:[NSNumber numberWithInt:kDbCustomParamColumnIndexOffsetDictRaw] fromFromSQLiteStatement:statement];
    if(paramsText){
        [self parseStringFromStorage:paramsText];
    }else{
        toRet = [APBDataManager dataBaseErrorWithMessage:@"stored param data could not be parsed"];
    }
    return toRet;
}


-(NSString *)paramsAsString {
    NSError *error = nil;
    BOOL paramCheck = [NSJSONSerialization isValidJSONObject:self.storedParams];
    NSData *dataFromDictionary = (NSData *)[NSJSONSerialization dataWithJSONObject:self.storedParams options:0 error:&error]; //create NSData from JSONSerialization
    NSString *stringFromData = [dataFromDictionary base64EncodedString]; //stringify the NSData
    return stringFromData; //return stringified NSData
}

-(void)parseStringFromStorage:(NSString *)stringifiedParams {
    NSError *error = nil;
    NSData *dataFromString = [NSData dataFromBase64String:stringifiedParams]; //Decode the stringified NSData back into NSData
    NSDictionary *dictFromString = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:dataFromString options:NSJSONReadingMutableContainers error:&error];  //JSONSerialize the NSData back into an NSDictionary
    self.storedParams = dictFromString;
}


-(NSDictionary *)asDictionary {
    return self.storedParams;
}



@end
