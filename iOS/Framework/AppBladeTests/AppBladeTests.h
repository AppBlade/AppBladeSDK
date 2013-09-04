//
//  AppBladeTests.h
//  AppBladeTests
//
//  Created by AndrewTremblay on 7/30/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>


//Macros ripped straight outta github
//https://raw.github.com/hfossli/AGWaitForAsyncTestHelper/master/Source/AGWaitForAsyncTestHelper.h
/**
 * @param whileTrue Can be anything
 * @param seconds NSTimeInterval
 */
#define AG_STALL_RUNLOPP_WHILE(whileTrue, limitInSeconds) ({\
NSDate *giveUpDate = [NSDate dateWithTimeIntervalSinceNow:limitInSeconds];\
while ((whileTrue) && [giveUpDate timeIntervalSinceNow] > 0)\
{\
NSDate *loopIntervalDate = [NSDate dateWithTimeIntervalSinceNow:0.01];\
[[NSRunLoop currentRunLoop] runUntilDate:loopIntervalDate];\
}\
})

/**
 * @param whileTrue Can be anything
 * @param seconds NSTimeInterval
 */
#define WAIT_WHILE(whileTrue, seconds)\
({\
WAIT_WHILE_WITH_DESC(whileTrue, seconds, nil);\
})

/**
 * @param whileTrue Can be anything
 * @param seconds NSTimeInterval
 * @param description NSString format
 * @param ... Arguments for description string format
 */
#define WAIT_WHILE_WITH_DESC(whileTrue, seconds, description, ...)\
({\
NSTimeInterval castedLimit = seconds;\
NSString *conditionString = [NSString stringWithFormat:@"(%s) should NOT be true after async operation completed", #whileTrue];\
if(!(whileTrue))\
{\
NSString *failString = AGWW_CREATE_FAIL_STRING_1(conditionString, description, ##__VA_ARGS__);\
STFail(failString);\
}\
else\
{\
AG_STALL_RUNLOPP_WHILE(whileTrue, castedLimit);\
if(whileTrue)\
{\
NSString *failString = AGWW_CREATE_FAIL_STRING_2(conditionString, castedLimit, description, ##__VA_ARGS__);\
STFail(failString);\
}\
}\
})

static NSString * AGWW_CREATE_FAIL_STRING_1(NSString *conditionString, NSString *description, ...) {
    va_list args;
    va_start(args, description);
    
    NSString *outputFormat = [NSString stringWithFormat:@"Was already right before 'wait' on async operation. %@. %@", conditionString, description];
    NSString *outputString = [[NSString alloc] initWithFormat:outputFormat arguments:args];
    va_end(args);
    
    return outputString;
}

static NSString * AGWW_CREATE_FAIL_STRING_2(NSString *conditionString, NSTimeInterval seconds, NSString *description, ...) {
    va_list args;
    va_start(args, description);
    
    NSString *outputFormat = [NSString stringWithFormat:@"Spent too much time (%.2f seconds). %@. %@", (NSTimeInterval) seconds, conditionString, description];
    NSString *outputString = [[NSString alloc] initWithFormat:outputFormat arguments:args];
    va_end(args);
    
    return outputString;
}

@interface AppBladeTests : SenTestCase

@end
