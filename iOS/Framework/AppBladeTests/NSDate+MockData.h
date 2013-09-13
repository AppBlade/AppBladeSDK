//
//  NSDate+MockData.h
//  AppBlade
//
//  Created by AndrewTremblay on 9/13/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (MockData)
    +(void)setMockDate:(NSTimeInterval)timeSinceNow;

    +(NSDate *) mockCurrentDate;
@end
