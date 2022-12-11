//
//  bsg_ksmachTests.m
//
//  Created by Karl Stenerud on 2012-03-03.
//
//  Copyright (c) 2012 Karl Stenerud. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall remain in place
// in this source code.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//


#import <XCTest/XCTest.h>

#import "BSG_KSMach.h"
#import "BSG_KSMachApple.h"
#import "BSGDefines.h"

#import <mach/mach_time.h>
#import <sys/sysctl.h>


@interface TestThread: NSThread

@property(nonatomic, readwrite, assign) thread_t thread;

@end

@implementation TestThread

@synthesize thread = _thread;

- (void) main
{
    self.thread = bsg_ksmachthread_self();
    while(!self.isCancelled)
    {
        [[self class] sleepForTimeInterval:0.1];
    }
}

@end


void * executeBlock(void *ptr)
{
    ((__bridge_transfer dispatch_block_t)ptr)();
    return NULL;
}


@interface bsg_ksmachTests : XCTestCase @end

@implementation bsg_ksmachTests

- (void) testExceptionName
{
    NSString* expected = @"EXC_ARITHMETIC";
    NSString* actual = [NSString stringWithCString:bsg_ksmachexceptionName(EXC_ARITHMETIC)
                                          encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(actual, expected, @"");
}

- (void) testVeryHighExceptionName
{
    const char* result = bsg_ksmachexceptionName(100000);
    XCTAssertTrue(result == NULL, @"");
}

- (void) testKernReturnCodeName
{
    NSString* expected = @"KERN_FAILURE";
    NSString* actual = [NSString stringWithCString:bsg_ksmachkernelReturnCodeName(KERN_FAILURE)
                                          encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(actual, expected, @"");
}

- (void) testArmExcBadAccessKernReturnCodeNames
{
    XCTAssertEqualObjects(@(bsg_ksmachkernelReturnCodeName(EXC_ARM_DA_ALIGN)), @"EXC_ARM_DA_ALIGN");
    XCTAssertEqualObjects(@(bsg_ksmachkernelReturnCodeName(EXC_ARM_DA_DEBUG)), @"EXC_ARM_DA_DEBUG");
    XCTAssertEqualObjects(@(bsg_ksmachkernelReturnCodeName(EXC_ARM_SP_ALIGN)), @"EXC_ARM_SP_ALIGN");
    XCTAssertEqualObjects(@(bsg_ksmachkernelReturnCodeName(EXC_ARM_SWP)), @"EXC_ARM_SWP");
}

- (void) testVeryHighKernReturnCodeName
{
    const char* result = bsg_ksmachkernelReturnCodeName(100000);
    XCTAssertTrue(result == NULL, @"");
}

#if BSG_HAVE_MACH_THREADS
- (void) testSuspendThreads
{
#if TARGET_CPU_X86_64 && defined(XCTSkipIf)
    int translated = 0;
    size_t size = sizeof(translated);
    sysctlbyname("sysctl.proc_translated", &translated, &size, NULL, 0);
    XCTSkipIf(translated, @"Can deadlock under Rosetta");
#endif
    
    // Just make sure that suspending and resuming doesn't hang the process.
    unsigned threadsCount = 0;
    thread_t *threads = bsg_ksmachgetAllThreads(&threadsCount);
    bsg_ksmachsuspendThreads(threads, threadsCount);
    bsg_ksmachresumeThreads(threads, threadsCount);
}
#endif

- (void) testCopyMem
{
    char buff[100];
    char buff2[100] = {1,2,3,4,5};
    
    kern_return_t result = bsg_ksmachcopyMem(buff2, buff, sizeof(buff));
    XCTAssertEqual(result, KERN_SUCCESS, @"");
    int memCmpResult = memcmp(buff, buff2, sizeof(buff));
    XCTAssertEqual(memCmpResult, 0, @"");
}

- (void) testCopyMemNull
{
    char buff[100];
    char* buff2 = NULL;
    
    kern_return_t result = bsg_ksmachcopyMem(buff2, buff, sizeof(buff));
    XCTAssertTrue(result != KERN_SUCCESS, @"");
}

- (void) testCopyMemBad
{
    char buff[100];
    char* buff2 = (char*)-1;
    
    kern_return_t result = bsg_ksmachcopyMem(buff2, buff, sizeof(buff));
    XCTAssertTrue(result != KERN_SUCCESS, @"");
}

- (void) testTimeDifferenceInSeconds
{
    uint64_t startTime = mach_absolute_time();
    CFAbsoluteTime cfStartTime = CFAbsoluteTimeGetCurrent();
    [NSThread sleepForTimeInterval:0.1];
    uint64_t endTime = mach_absolute_time();
    CFAbsoluteTime cfEndTime = CFAbsoluteTimeGetCurrent();
    double diff = bsg_ksmachtimeDifferenceInSeconds(endTime, startTime);
    double cfDiff = cfEndTime - cfStartTime;
    XCTAssertEqualWithAccuracy(diff, cfDiff, 0.001);
}

- (void) testGetQueueNameWithMainThread
{
    char name[32] = "";

    XCTAssertTrue(bsg_ksmachgetThreadQueueName(bsg_ksmachthread_self(),
                                               name, sizeof(name)));

    XCTAssertEqualObjects(@(name), @"com.apple.main-thread");
}

- (void) testGetQueueNameWithNonDispatchThread
{
    pthread_t thread;

    pthread_create(&thread, NULL, executeBlock,
                   (__bridge_retained void *)^{
        char name[32] = "";

        XCTAssertFalse(bsg_ksmachgetThreadQueueName(bsg_ksmachthread_self(),
                                                    name, sizeof(name)));
    });

    pthread_join(thread, NULL);
}

- (void) testGetQueueNameWithInvalidThread
{
    char name[32] = "";
    
    XCTAssertFalse(bsg_ksmachgetThreadQueueName(0xdeadbeef,
                                                name, sizeof(name)));
}

- (void) testGetQueueNameWithEphemeralThreads
{
    //
    // This test aims to trigger potential crashes when getting the queue name
    // of dying / recently deceased threads.
    //
    // For more effective detection of bugs, enable "Malloc Scribble" under the
    // Scheme's Diagnostics options, or set the "MallocScribble" environment
    // variable.
    //
    
    __block int finished = 0;
    
    dispatch_async(dispatch_queue_create(NULL, 0), ^{
        dispatch_group_t group = dispatch_group_create();

        for (int i = 0; i < 100000; i++) {
            char *label = NULL;
            asprintf(&label, "%d", i);
            dispatch_group_async(group, dispatch_queue_create(label, 0), ^{
                usleep(10);
            });
            free(label);
        }

        dispatch_group_notify(group, dispatch_queue_create(NULL, 0), ^{
            finished = 1;
        });
    });
    
    while (!finished) {
        char name[5];
        thread_act_array_t threads;
        mach_msg_type_number_t i, threadCount = 0;
        task_threads(mach_task_self(), &threads, &threadCount);

        for (i = 0; i < threadCount; i++) {
            bzero(name, sizeof(name));
            if (bsg_ksmachgetThreadQueueName(threads[i], name, sizeof(name))) {
                XCTAssertEqual(name[sizeof(name) - 1], '\0',
                               @"queue name must be NULL terminated");
            }
        }

        vm_deallocate(mach_task_self(), (vm_address_t)threads,
                      sizeof(threads[0]) * threadCount);
    }
}

#if BSG_HAVE_MACH_THREADS
- (void) testThreadState
{
    TestThread* thread = [[TestThread alloc] init];
    [thread start];
    [NSThread sleepForTimeInterval:0.1];
    kern_return_t kr;
    kr = thread_suspend(thread.thread);
    XCTAssertTrue(kr == KERN_SUCCESS, @"");
    
    _STRUCT_MCONTEXT machineContext;
    bool success = bsg_ksmachthreadState(thread.thread, &machineContext);
    XCTAssertTrue(success, @"");

    int numRegisters = bsg_ksmachnumRegisters();
    for(int i = 0; i < numRegisters; i++)
    {
        const char* name = bsg_ksmachregisterName(i);
        XCTAssertTrue(name != NULL, @"Register %d was NULL", i);
        bsg_ksmachregisterValue(&machineContext, i);
    }

    const char* name = bsg_ksmachregisterName(1000000);
    XCTAssertTrue(name == NULL, @"");
    uint64_t value = bsg_ksmachregisterValue(&machineContext, 1000000);
    XCTAssertTrue(value == 0, @"");
    
    uintptr_t address;
    address = bsg_ksmachframePointer(&machineContext);
    XCTAssertTrue(address != 0, @"");
    address = bsg_ksmachstackPointer(&machineContext);
    XCTAssertTrue(address != 0, @"");
    address = bsg_ksmachinstructionAddress(&machineContext);
    XCTAssertTrue(address != 0, @"");

    thread_resume(thread.thread);
    [thread cancel];
}

- (void) testFloatState
{
    TestThread* thread = [[TestThread alloc] init];
    [thread start];
    [NSThread sleepForTimeInterval:0.1];
    kern_return_t kr;
    kr = thread_suspend(thread.thread);
    XCTAssertTrue(kr == KERN_SUCCESS, @"");
    
    _STRUCT_MCONTEXT machineContext;
    bool success = bsg_ksmachfloatState(thread.thread, &machineContext);
    XCTAssertTrue(success, @"");
    thread_resume(thread.thread);
    [thread cancel];
}

- (void) testExceptionState
{
    TestThread* thread = [[TestThread alloc] init];
    [thread start];
    [NSThread sleepForTimeInterval:0.1];
    kern_return_t kr;
    kr = thread_suspend(thread.thread);
    XCTAssertTrue(kr == KERN_SUCCESS, @"");
    
    _STRUCT_MCONTEXT machineContext;
    bool success = bsg_ksmachexceptionState(thread.thread, &machineContext);
    XCTAssertTrue(success, @"");
    
    int numRegisters = bsg_ksmachnumExceptionRegisters();
    for(int i = 0; i < numRegisters; i++)
    {
        const char* name = bsg_ksmachexceptionRegisterName(i);
        XCTAssertTrue(name != NULL, @"Register %d was NULL", i);
        bsg_ksmachexceptionRegisterValue(&machineContext, i);
    }
    
    const char* name = bsg_ksmachexceptionRegisterName(1000000);
    XCTAssertTrue(name == NULL, @"");
    uint64_t value = bsg_ksmachexceptionRegisterValue(&machineContext, 1000000);
    XCTAssertTrue(value == 0, @"");

    bsg_ksmachfaultAddress(&machineContext);

    thread_resume(thread.thread);
    [thread cancel];
}
#endif

- (void) testStackGrowDirection
{
    bsg_ksmachstackGrowDirection();
}

- (void) testRemoveThreadsFromList
{
    thread_t src[] = {1, 2, 3};
    thread_t dst[] = {0, 0, 0};
    bsg_ksmachremoveThreadsFromList(src, 3, NULL, 0, dst, 2);
    XCTAssertEqual(1, dst[0]);
    XCTAssertEqual(2, dst[1]);
    XCTAssertEqual(0, dst[2]);
}

- (void) testRemoveThreadsFromList2
{
    thread_t src[] = {1, 2, 3, 4};
    thread_t omit[] = {2, 4};
    thread_t dst[] = {0, 0, 0, 0};
    int count = bsg_ksmachremoveThreadsFromList(src, 4, omit, 2, dst, 3);
    XCTAssertEqual(1, dst[0]);
    XCTAssertEqual(3, dst[1]);
    XCTAssertEqual(0, dst[2]);
    XCTAssertEqual(0, dst[3]);
    XCTAssertEqual(2, count);
}

- (void) testRemoveThreadsFromList3
{
    thread_t src[] = {1, 2, 3, 4, 5, 6};
    thread_t omit[] = {2, 4};
    thread_t dst[] = {0, 0, 0, 0, 0, 0};
    int count = bsg_ksmachremoveThreadsFromList(src, 6, omit, 2, dst, 3);
    XCTAssertEqual(1, dst[0]);
    XCTAssertEqual(3, dst[1]);
    XCTAssertEqual(5, dst[2]);
    XCTAssertEqual(0, dst[3]);
    XCTAssertEqual(0, dst[4]);
    XCTAssertEqual(0, dst[5]);
    XCTAssertEqual(3, count);
}

@end
