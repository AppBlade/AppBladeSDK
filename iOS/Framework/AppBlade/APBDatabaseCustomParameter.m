//
//  APBDatabaseCustomParameter.m
//  AppBlade
//
//  Created by AndrewTremblay on 12/9/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//

#import "APBDatabaseCustomParameter.h"
#import "AppBladeDatabaseColumn.h"

@implementation APBDatabaseCustomParameter
    -(id)initWithDictionary:(NSDictionary *)dictionary{
        self = [super init];
        if (self) {
            self.snapshotDate = [NSDate new];
            self.storedParams = dictionary;
        }
        return self;
    }


    +(NSArray *)columnDeclarations {
        return @[[AppBladeDatabaseColumn initColumnNamed:kDbCustomParamColumnNameDictBlob withContraints: (AppBladeColumnConstraintAffinityNone) additionalArgs:nil],
                 [AppBladeDatabaseColumn initColumnNamed:kDbCustomParamColumnNameSnapshotDate withContraints:(AppBladeColumnConstraintAffinityText | AppBladeColumnConstraintNotNull) additionalArgs:nil]];

    }

-(NSArray *)additionalColumnNames {
    return @[ kDbCustomParamColumnNameDictBlob, kDbCustomParamColumnNameSnapshotDate];
}

-(NSArray *)additionalColumnValues{
    return @[ [self sqlFormattedProperty:[self paramsAsString]], [self sqlFormattedProperty:self.snapshotDate] ];
}

-(NSString *)paramsAsString {
    NSError *error = nil;
    NSData *dataFromDictionary = [NSJSONSerialization dataWithJSONObject:self.storedParams options:0 error:&error];
    NSString *stringFromData = [dataFromDictionary base64EncodedStringWithOptions:NSDataBase64DecodingIgnoreUnknownCharacters];
    return stringFromData;
}

-(void)parseStringFromStorage:(NSString *)stringifiedParams {
    NSError *error = nil;
    NSData *dataFromString = [stringifiedParams dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dictFromString = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:dataFromString options:NSJSONReadingMutableContainers error:&error];    
    self.storedParams = dictFromString;
}


-(NSDictionary *)asDictionary {
    return self.storedParams;
#pragma warning finish this
}



@end
