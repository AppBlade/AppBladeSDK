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

#include "PLCrashFeatureConfig.h"

#if PLCRASH_FEATURE_MACH_EXCEPTIONS

#import "GTMSenTestCase.h"

#import "PLCrashMachExceptionServer.h"
#import "PLCrashMachExceptionPort.h"
#import "PLCrashHostInfo.h"
#import "PLCrashAsync.h"

#include <sys/mman.h>

@interface PLCrashMachExceptionServerTests : SenTestCase {
    plcrash_mach_exception_port_set_t _task_ports;
    plcrash_mach_exception_port_set_t _thread_ports;
}
@end

@implementation PLCrashMachExceptionServerTests

- (void) setUp {
    /*
     * Reset the current exception ports. Our tests interfere with any observing
     * debuggers, so we remove any task and thread exception ports here, and then
     * restore them in -tearDown.
     */
    kern_return_t kr;
    kr = task_swap_exception_ports(mach_task_self(),
                                   EXC_MASK_BAD_ACCESS,
                                   MACH_PORT_NULL,
                                   EXCEPTION_DEFAULT,
                                   THREAD_STATE_NONE,
                                   _task_ports.masks,
                                   &_task_ports.count,
                                   _task_ports.ports,
                                   _task_ports.behaviors,
                                   _task_ports.flavors);
    STAssertEquals(kr, KERN_SUCCESS, @"Failed to reset task ports");
    
    kr = thread_swap_exception_ports(pl_mach_thread_self(),
                                     EXC_MASK_BAD_ACCESS,
                                     MACH_PORT_NULL,
                                     EXCEPTION_DEFAULT,
                                     THREAD_STATE_NONE,
                                     _thread_ports.masks,
                                     &_thread_ports.count,
                                     _thread_ports.ports,
                                     _thread_ports.behaviors,
                                     _thread_ports.flavors);
    STAssertEquals(kr, KERN_SUCCESS, @"Failed to reset thread ports");
}

- (void) tearDown {
    kern_return_t kr;

    /* Restore the original exception ports */
    for (mach_msg_type_number_t i = 0; i < _task_ports.count; i++) {
        if (MACH_PORT_VALID(!_task_ports.ports[i]))
            continue;
    
        kr = task_set_exception_ports(mach_task_self(), _task_ports.masks[i], _task_ports.ports[i], _task_ports.behaviors[i], _task_ports.flavors);
        STAssertEquals(kr, KERN_SUCCESS, @"Failed to set task ports");
    }
    
    for (mach_msg_type_number_t i = 0; i < _thread_ports.count; i++) {
        if (MACH_PORT_VALID(!_thread_ports.ports[i]))
            continue;
        
        kr = thread_set_exception_ports(pl_mach_thread_self(), _thread_ports.masks[i], _thread_ports.ports[i], _thread_ports.behaviors[i], _thread_ports.flavors);
        STAssertEquals(kr, KERN_SUCCESS, @"Failed to set thread ports");
    }
}

static uint8_t crash_page[PAGE_SIZE] __attribute__((aligned(PAGE_SIZE)));

static kern_return_t exception_callback (task_t task,
                                thread_t thread,
                                exception_type_t exception_type,
                                mach_exception_data_t code,
                                mach_msg_type_number_t code_count,
                                void *context)
{
    mprotect(crash_page, sizeof(crash_page), PROT_READ|PROT_WRITE);
    
    if (code_count != 2) {
        crash_page[1] = 0xFA;
    } else if (code[1] != (uintptr_t) crash_page) {
        crash_page[1] = 0xFB;
    } else {
        // Success
        crash_page[1] = 0xFE;
    }

    BOOL *didRun = (BOOL *) context;
    if (didRun != NULL)
        *didRun = YES;

    return KERN_SUCCESS;
}

/**
 * Test inserting/removing the task mach exception server from the handler chain.
 */
- (void) testTaskServerInsertion {
    NSError *error;

    PLCrashMachExceptionServer *server = [[[PLCrashMachExceptionServer alloc] initWithCallBack: exception_callback
                                                                                       context: NULL
                                                                                         error: &error] autorelease];
    STAssertNotNil(server, @"Failed to initialize server");

    PLCrashMachExceptionPort *port = [server exceptionPortWithMask: EXC_MASK_BAD_ACCESS error: &error];
    STAssertNotNil(port, @"Failed to fetch server port: %@", error);

    STAssertTrue([port registerForTask: mach_task_self()
                       previousPortSet: NULL
                                 error: &error], @"Failed to configure handler: %@", error);

    mprotect(crash_page, sizeof(crash_page), 0);

    /* If the test doesn't lock up here, it's working */
    crash_page[0] = 0xCA;

    STAssertEquals(crash_page[0], (uint8_t)0xCA, @"Page should have been set to test value");
    STAssertEquals(crash_page[1], (uint8_t)0xFE, @"Crash callback did not run");
}

/**
 * Test inserting/removing the mach exception server from the handler chain.
 */
- (void) testThreadServerInsertion {
    NSError *error;

    BOOL taskRan = false;
    BOOL threadRan = false;
    
    PLCrashMachExceptionServer *task = [[[PLCrashMachExceptionServer alloc] initWithCallBack: exception_callback
                                                                                     context: &taskRan
                                                                                       error: &error] autorelease];
    STAssertNotNil(task, @"Failed to initialize server");

    PLCrashMachExceptionServer *thr = [[[PLCrashMachExceptionServer alloc] initWithCallBack: exception_callback
                                                                                    context: &threadRan
                                                                                      error: &error] autorelease];
    STAssertNotNil(thr, @"Failed to initialize server");
    
    PLCrashMachExceptionPort *taskPort = [task exceptionPortWithMask: EXC_MASK_BAD_ACCESS error: &error];
    STAssertNotNil(taskPort, @"Failed to fetch server port: %@", error);
    
    PLCrashMachExceptionPort *thrPort = [thr exceptionPortWithMask: EXC_MASK_BAD_ACCESS error: &error];
    STAssertNotNil(thrPort, @"Failed to fetch server port: %@", error);


    STAssertTrue([taskPort registerForTask: mach_task_self()
                           previousPortSet: NULL
                                     error: &error], @"Failed to configure handler: %@", error);

    STAssertTrue([thrPort registerForThread: pl_mach_thread_self()
                            previousPortSet: NULL
                                      error: &error], @"Failed to configure handler: %@", error);

    mprotect(crash_page, sizeof(crash_page), 0);
    
    /* If the test doesn't lock up here, it's working */
    crash_page[0] = 0xCA;
    
    STAssertEquals(crash_page[0], (uint8_t)0xCA, @"Page should have been set to test value");
    STAssertEquals(crash_page[1], (uint8_t)0xFE, @"Crash callback did not run");

    STAssertFalse(taskRan, @"Task handler ran");
    STAssertTrue(threadRan, @"Thread-specific handler did not run");
}

/**
 * Test forwarding implementation
 */
- (void) testForwardException {
    NSError *error;

    /* Set up a test server */
    BOOL didRun = false;
    PLCrashMachExceptionServer *server = [[[PLCrashMachExceptionServer alloc] initWithCallBack: exception_callback
                                                                                       context: &didRun
                                                                                         error: &error] autorelease];
    STAssertNotNil(server, @"Failed to initialize server");
    
    PLCrashMachExceptionPort *port = [server exceptionPortWithMask: EXC_MASK_BAD_ACCESS error: &error];
    STAssertNotNil(port, @"Failed to fetch server port: %@", error);
    
    STAssertTrue([port registerForTask: mach_task_self()
                       previousPortSet: NULL
                                 error: &error], @"Failed to configure handler: %@", error);


    /* Fetch the server's port set */
    PLCrashMachExceptionPortSet *portSet = [PLCrashMachExceptionPort exceptionPortsForTask: mach_task_self() mask: EXC_MASK_BAD_ACCESS error: &error];

    /* Attempt to forward the exception */
    mach_exception_data_type_t codes[2];
    codes[0] = 0x1;
    codes[1] = 0x2;

    plcrash_mach_exception_port_set_t port_set = portSet.asyncSafeRepresentation;
    kern_return_t kt = PLCrashMachExceptionForward(mach_task_self(),
                                                   pl_mach_thread_self(),
                                                   EXC_BAD_ACCESS,
                                                   codes,
                                                   2,
                                                   &port_set);

    /* Forwarding is documented as broken in the case where 64-bit codes are used, but
     * the mach_exc_* 64-bit APIs are not available. */
#if (PL_MACH64_EXC_API || !PL_MACH64_EXC_CODES)
    STAssertEquals(KERN_SUCCESS, kt, @"Callback did not return KERN_SUCCESS");
    STAssertTrue(didRun, @"Calback was not executed");
#else
    STAssertNotEquals(KERN_SUCCESS, kt, @"Callback returned KERN_SUCCESS despite missing mach_exc* APIs");
#endif
}

/**
 * Test basic copying of the send right.
 */
- (void) testCopySendRight {
    NSError *error;

    PLCrashMachExceptionServer *server = [[[PLCrashMachExceptionServer alloc] initWithCallBack: exception_callback
                                                                                       context: NULL
                                                                                         error: &error] autorelease];
    STAssertNotNil(server, @"Failed to initialize server");

    mach_port_t sendRight = [server copySendRightForServerAndReturningError: &error];
    STAssertTrue(MACH_PORT_VALID(sendRight), @"Failed to copy send right: %@", error);

    STAssertEquals(KERN_SUCCESS, mach_port_deallocate(mach_task_self(), sendRight), @"Failed to deallocate send right");
}

@end

#endif /* PLCRASH_FEATURE_MACH_EXCEPTIONS */
