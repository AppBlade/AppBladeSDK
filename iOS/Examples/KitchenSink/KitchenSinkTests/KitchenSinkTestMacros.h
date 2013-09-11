//
//  KitchenSinkTestMacros.h
//  KitchenSink
//
//  Created by AndrewTremblay on 9/11/13.
//  Copyright (c) 2013 Raizlabs Corporation. All rights reserved.
//

#ifndef KitchenSink_KitchenSinkTestMacros_h
#define KitchenSink_KitchenSinkTestMacros_h


//Macros ripped straight outta github
//https://raw.github.com/hfossli/AGWaitForAsyncTestHelper/master/Source/AGWaitForAsyncTestHelper.h
/**
 * @param whileTrue Can be anything
 * @param seconds NSTimeInterval
 */
#define APB_STALL_RUNLOPP_WHILE(whileTrue, limitInSeconds) ({\
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
#define APB_WAIT_WHILE(whileTrue, seconds)\
({\
APB_WAIT_WHILE_WITH_DESC(whileTrue, seconds, nil);\
})

/**
 * @param whileTrue Can be anything
 * @param seconds NSTimeInterval
 * @param description NSString format
 * @param ... Arguments for description string format
 */
#define APB_WAIT_WHILE_WITH_DESC(whileTrue, seconds, description, ...)\
({\
NSTimeInterval castedLimit = seconds;\
NSString *conditionString = [NSString stringWithFormat:@"(%s) should NOT be true after async operation completed", #whileTrue];\
if(!(whileTrue))\
{\
NSString *failString = APB_CREATE_FAIL_STRING_1(conditionString, description, ##__VA_ARGS__);\
STFail(failString);\
}\
else\
{\
APB_STALL_RUNLOPP_WHILE(whileTrue, castedLimit);\
if(whileTrue)\
{\
NSString *failString = APB_CREATE_FAIL_STRING_2(conditionString, castedLimit, description, ##__VA_ARGS__);\
STFail(failString);\
}\
}\
})

static NSString * APB_CREATE_FAIL_STRING_1(NSString *conditionString, NSString *description, ...) {
    va_list args;
    va_start(args, description);
    
    NSString *outputFormat = [NSString stringWithFormat:@"Was already right before 'wait' on async operation. %@. %@", conditionString, description];
    NSString *outputString = [[NSString alloc] initWithFormat:outputFormat arguments:args];
    va_end(args);
    
    return outputString;
}

static NSString * APB_CREATE_FAIL_STRING_2(NSString *conditionString, NSTimeInterval seconds, NSString *description, ...) {
    va_list args;
    va_start(args, description);
    
    NSString *outputFormat = [NSString stringWithFormat:@"Spent too much time (%.2f seconds). %@. %@", (NSTimeInterval) seconds, conditionString, description];
    NSString *outputString = [[NSString alloc] initWithFormat:outputFormat arguments:args];
    va_end(args);
    
    return outputString;
}

#endif
