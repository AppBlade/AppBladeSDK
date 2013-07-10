//
//  AppBladeLogging.h
//  AppBlade
//
//  Created by AndrewTremblay on 6/5/13.
//  Copyright (c) 2013 Raizlabs Corporation. All rights reserved.
//

#ifndef AppBlade_AppBladeLogging_h

#define AppBlade_AppBladeLogging_h
        #define ABDebugLog_internal( s, ... ) NSLog( @"<%p %@:(%d)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#ifdef APPBLADE_DEBUG_LOGGING
    #else
 //       #define ABDebugLog_internal( s, ... )
    #endif
#define ABErrorLog( s, ... ) NSLog( @"< %@:(%d)> %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )

    #ifdef APPBLADE_ERROR_LOGGING
    #else
//        #define ABErrorLog( s, ... )
    #endif
#endif
