//
//  BSGDefinesTests.m
//  Bugsnag
//
//  Created by Nick Dowell on 23/06/2022.
//  Copyright © 2022 Bugsnag Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BSGDefines.h"

@interface BSGDefinesTests : XCTestCase

@end

@implementation BSGDefinesTests

- (void)testCoreFoundationVersion {
    if (@available(macOS 10.14, iOS 12.0, tvOS 12.0, watchOS 5.0, *)) {
        XCTAssertGreaterThanOrEqual(kCFCoreFoundationVersionNumber, kCFCoreFoundationVersionNumber_iOS_12_0);
    } else {
        XCTAssertLessThan(kCFCoreFoundationVersionNumber, kCFCoreFoundationVersionNumber_iOS_12_0);
    }
}

@end
