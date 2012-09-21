/*
 * Author: Landon Fuller <landonf@plausiblelabs.com>
 *
 * Copyright (c) 2008-2009 Plausible Labs Cooperative, Inc.
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

#import "PLCrashReportSystemInfo.h"

/**
 * @ingroup constants
 *
 * The current host's operating system.
 */
PLCrashReportOperatingSystem PLCrashReportHostOperatingSystem =
#if TARGET_IPHONE_SIMULATOR
    PLCrashReportOperatingSystemiPhoneSimulator;
#elif TARGET_OS_IPHONE
    PLCrashReportOperatingSystemiPhoneOS;
#elif TARGET_OS_MAC
    PLCrashReportOperatingSystemMacOSX;
#else
    #error Unknown operating system
#endif




/**
 * @ingroup constants
 *
 * The current host's architecture.
 */
PLCrashReportArchitecture PLCrashReportHostArchitecture =
#ifdef __x86_64__
    PLCrashReportArchitectureX86_64;
#elif defined(__i386__)
    PLCrashReportArchitectureX86_32;
#elif defined(__ARM_ARCH_6K__)
    PLCrashReportArchitectureARMv6;
#elif defined(__ARM_ARCH_7A__)
    PLCrashReportArchitectureARMv7;
#elif defined(__ARM_ARCH_7S__)
    PLCrashReportArchitectureARMv7s;
#elif defined(__ppc__)
    PLCrashReportArchitecturePPC;
#else
    #error Unknown machine architecture
#endif


/**
 * Crash log host data.
 *
 * This contains information about the host system, including operating system and architecture.
 */
@implementation PLCrashReportSystemInfo

/**
 * Initialize the system info data object.
 *
 * @param operatingSystem Operating System
 * @param operatingSystemVersion OS version
 * @param architecture Architecture
 * @param timestamp Timestamp (may be nil).
 */
- (id) initWithOperatingSystem: (PLCrashReportOperatingSystem) operatingSystem 
        operatingSystemVersion: (NSString *) operatingSystemVersion
                  architecture: (PLCrashReportArchitecture) architecture
                     timestamp: (NSDate *) timestamp
{
    return [self initWithOperatingSystem: operatingSystem
                  operatingSystemVersion: operatingSystemVersion
                    operatingSystemBuild: nil
                            architecture: architecture
                               timestamp: timestamp];
}

/**
 * Initialize the system info data object.
 *
 * @param operatingSystem Operating System
 * @param operatingSystemVersion OS version
 * @param operatingSystemBuild OS build (may be nil).
 * @param architecture Architecture
 * @param timestamp Timestamp (may be nil).
 */
- (id) initWithOperatingSystem: (PLCrashReportOperatingSystem) operatingSystem 
        operatingSystemVersion: (NSString *) operatingSystemVersion
          operatingSystemBuild: (NSString *) operatingSystemBuild
                  architecture: (PLCrashReportArchitecture) architecture
                     timestamp: (NSDate *) timestamp
{
    if ((self = [super init]) == nil)
        return nil;
    
    _operatingSystem = operatingSystem;
    _osVersion = [operatingSystemVersion retain];
    _osBuild = [operatingSystemBuild retain];
    _architecture = architecture;
    _timestamp = [timestamp retain];
    
    return self;
}

- (void) dealloc {
    [_osVersion release];
    [_osBuild release];
    [_timestamp release];
    [super dealloc];
}

@synthesize operatingSystem = _operatingSystem;
@synthesize operatingSystemVersion = _osVersion;
@synthesize operatingSystemBuild = _osBuild;
@synthesize architecture = _architecture;
@synthesize timestamp = _timestamp;

@end
