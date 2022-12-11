//
//  BugsnagEnabledBreadcrumbTest.m
//  Tests
//
//  Created by Jamie Lynch on 27/05/2020.
//  Copyright © 2020 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BugsnagConfiguration+Private.h"
#import "BugsnagTestConstants.h"

@interface BugsnagEnabledBreadcrumbTest : XCTestCase

@end

@implementation BugsnagEnabledBreadcrumbTest

- (void)testEnabledBreadcrumbNone {
    BugsnagConfiguration *config = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    config.enabledBreadcrumbTypes = BSGEnabledBreadcrumbTypeNone;
    XCTAssertTrue([config shouldRecordBreadcrumbType:BSGBreadcrumbTypeManual]);
    XCTAssertFalse([config shouldRecordBreadcrumbType:BSGBreadcrumbTypeError]);
    XCTAssertFalse([config shouldRecordBreadcrumbType:BSGBreadcrumbTypeLog]);
    XCTAssertFalse([config shouldRecordBreadcrumbType:BSGBreadcrumbTypeNavigation]);
    XCTAssertFalse([config shouldRecordBreadcrumbType:BSGBreadcrumbTypeProcess]);
    XCTAssertFalse([config shouldRecordBreadcrumbType:BSGBreadcrumbTypeRequest]);
    XCTAssertFalse([config shouldRecordBreadcrumbType:BSGBreadcrumbTypeState]);
    XCTAssertFalse([config shouldRecordBreadcrumbType:BSGBreadcrumbTypeUser]);
}

- (void)testEnabledBreadcrumbLog {
    BugsnagConfiguration *config = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    config.enabledBreadcrumbTypes = BSGEnabledBreadcrumbTypeLog;
    XCTAssertTrue([config shouldRecordBreadcrumbType:BSGBreadcrumbTypeManual]);
    XCTAssertFalse([config shouldRecordBreadcrumbType:BSGBreadcrumbTypeError]);
    XCTAssertTrue([config shouldRecordBreadcrumbType:BSGBreadcrumbTypeLog]);
    XCTAssertFalse([config shouldRecordBreadcrumbType:BSGBreadcrumbTypeNavigation]);
    XCTAssertFalse([config shouldRecordBreadcrumbType:BSGBreadcrumbTypeProcess]);
    XCTAssertFalse([config shouldRecordBreadcrumbType:BSGBreadcrumbTypeRequest]);
    XCTAssertFalse([config shouldRecordBreadcrumbType:BSGBreadcrumbTypeState]);
    XCTAssertFalse([config shouldRecordBreadcrumbType:BSGBreadcrumbTypeUser]);
}

- (void)testEnabledBreadcrumbMulti {
    BugsnagConfiguration *config = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    config.enabledBreadcrumbTypes = BSGEnabledBreadcrumbTypeState | BSGEnabledBreadcrumbTypeNavigation;
    XCTAssertTrue([config shouldRecordBreadcrumbType:BSGBreadcrumbTypeManual]);
    XCTAssertFalse([config shouldRecordBreadcrumbType:BSGBreadcrumbTypeError]);
    XCTAssertFalse([config shouldRecordBreadcrumbType:BSGBreadcrumbTypeLog]);
    XCTAssertTrue([config shouldRecordBreadcrumbType:BSGBreadcrumbTypeNavigation]);
    XCTAssertFalse([config shouldRecordBreadcrumbType:BSGBreadcrumbTypeProcess]);
    XCTAssertFalse([config shouldRecordBreadcrumbType:BSGBreadcrumbTypeRequest]);
    XCTAssertTrue([config shouldRecordBreadcrumbType:BSGBreadcrumbTypeState]);
    XCTAssertFalse([config shouldRecordBreadcrumbType:BSGBreadcrumbTypeUser]);
}

@end
