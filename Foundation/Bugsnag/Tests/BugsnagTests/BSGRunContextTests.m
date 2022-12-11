//
//  BSGRunContextTests.m
//  Bugsnag
//
//  Created by Nick Dowell on 14/07/2022.
//  Copyright © 2022 Bugsnag Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BSGFileLocations.h"
#import "BSGRunContext.h"

@interface BSGRunContextTests : XCTestCase

@end

@implementation BSGRunContextTests

- (void)setUp {
    if (!bsg_runContext) {
        BSGRunContextInit(BSGFileLocations.current.runContext);
    }
}

- (void)testMemory {
    unsigned long long physicalMemory = NSProcessInfo.processInfo.physicalMemory;
    
    XCTAssertGreaterThan(bsg_runContext->hostMemoryFree, 0);
    XCTAssertLessThan   (bsg_runContext->hostMemoryFree, physicalMemory);
    
    XCTAssertGreaterThan(bsg_runContext->memoryFootprint, 0);
    XCTAssertLessThan   (bsg_runContext->memoryFootprint, physicalMemory);
    
#if TARGET_OS_OSX || TARGET_OS_MACCATALYST || TARGET_OS_SIMULATOR
    XCTAssertEqual(bsg_runContext->memoryAvailable, 0);
    XCTAssertEqual(bsg_runContext->memoryLimit, 0);
#else
    if (@available(iOS 13.0, tvOS 13.0, watchOS 6.0, *)) {
        XCTAssertGreaterThan(bsg_runContext->memoryAvailable, 0);
        XCTAssertLessThan   (bsg_runContext->memoryAvailable, physicalMemory);
        
        XCTAssertGreaterThan(bsg_runContext->memoryLimit, 0);
        XCTAssertLessThan   (bsg_runContext->memoryLimit, physicalMemory);
    } else {
        XCTAssertEqual(bsg_runContext->memoryAvailable, 0);
        XCTAssertEqual(bsg_runContext->memoryLimit, 0);
    }
#endif
}

@end
