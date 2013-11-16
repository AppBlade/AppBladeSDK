//
//  AppBladeLogging.h
//  AppBlade
//
//  Created by AndrewTremblay on 6/5/13.
//  Copyright (c) 2013 AppBlade Corporation. All rights reserved.
//

#import "APBWebOperation.h"
/*!
 @header AppBladeLogging
 @brief Header containing the helper macro for our internal logging.
 To enable the AppBlade internal logs, set the following:
 #define APPBLADE_DEBUG_LOGGING 1
 #define APPBLADE_ERROR_LOGGING 1
*/



#ifndef AppBlade_AppBladeLogging_h
//Add
//#define APPBLADE_DEBUG_LOGGING 1
//#define APPBLADE_ERROR_LOGGING 1
//To enable the AppBlade internal logs

#define AppBlade_AppBladeLogging_h
    #ifdef APPBLADE_DEBUG_LOGGING
        #define ABDebugLog_internal( s, ... )\
        ({\
            NSLog( @"<%@:(%d)> %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] ); \
        })
    #else
        #define ABDebugLog_internal( s, ... )\
        ({ }) //Do nothing
    #endif

    #ifdef APPBLADE_ERROR_LOGGING
        #define ABErrorLog( s, ... )\
        ({\
            NSLog( @"<%@:(%d)> %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] ); \
        })
    #else
        #define ABErrorLog( s, ... )\
        ({ }) //Do nothing
    #endif
#endif
