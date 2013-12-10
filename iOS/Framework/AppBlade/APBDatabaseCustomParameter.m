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
    +(NSArray *)columnDeclarations {
        return @[[AppBladeDatabaseColumn initColumnNamed:@"currentParams" withContraints: (AppBladeColumnConstraintAffinityNone) additionalArgs:nil],
                 [AppBladeDatabaseColumn initColumnNamed:@"createdAt" withContraints:(AppBladeColumnConstraintAffinityText | AppBladeColumnConstraintNotNull) additionalArgs:nil]];

    }
@end
