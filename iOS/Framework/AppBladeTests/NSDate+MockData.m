//
//  NSDate+MockData.m
//  AppBlade
//
//  Created by AndrewTremblay on 9/13/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "NSDate+MockData.h"

@implementation NSDate (MockData)
    static NSDate *_mockDate;

    +(NSDate *)mockCurrentDate
    {
        return _mockDate;
    }

    +(void)setMockDate:(NSTimeInterval)timeSinceNow
    {
        _mockDate = [NSDate dateWithTimeIntervalSinceNow:timeSinceNow];
    }

@end
