//
//  BugsnagOnBreadcrumbTest.m
//  Tests
//
//  Created by Jamie Lynch on 19/03/2020.
//  Copyright © 2020 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "Bugsnag.h"
#import "BugsnagBreadcrumb+Private.h"
#import "BugsnagClient+Private.h"
#import "BugsnagConfiguration+Private.h"
#import "BugsnagTestConstants.h"
#import "BugsnagBreadcrumbs.h"

@interface BugsnagOnBreadcrumbTest : XCTestCase
@end

@implementation BugsnagOnBreadcrumbTest

- (void)setUp {
    [super setUp];
    [[[BugsnagBreadcrumbs alloc] initWithConfiguration:[[BugsnagConfiguration alloc] initWithApiKey:nil]] removeAllBreadcrumbs];
}

/**
 * Test that onBreadcrumb blocks get called once added
 */
- (void)testAddOnBreadcrumbBlock {

    // Setup
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"Remove On Breadcrumb Block"];
    BugsnagConfiguration *config = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    config.endpoints = [[BugsnagEndpointConfiguration alloc] initWithNotify:@"http://notreal.bugsnag.com"
                                                                   sessions:@"http://notreal.bugsnag.com"];
    XCTAssertEqual([[config onBreadcrumbBlocks] count], 0);
    BugsnagOnBreadcrumbBlock crumbBlock = ^(BugsnagBreadcrumb * _Nonnull crumb) {
        // We expect the breadcrumb block to be called
        [expectation fulfill];
        return YES;
    };
    [config addOnBreadcrumbBlock:crumbBlock];
    XCTAssertEqual([[config onBreadcrumbBlocks] count], 1);

    // Call onbreadcrumb blocks
    BugsnagClient *client = [[BugsnagClient alloc] initWithConfiguration:config];
    [client start];
    [client leaveBreadcrumbWithMessage:@"Hello"];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

/**
 * Test that onBreadcrumb blocks do not get called once they've been removed
 */
- (void)testRemoveOnBreadcrumbBlock {
    // Setup
    // We expect NOT to be called
    __block XCTestExpectation *calledExpectation = [self expectationWithDescription:@"Remove On Breadcrumb Block"];
    calledExpectation.inverted = YES;

    BugsnagConfiguration *config = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    config.endpoints = [[BugsnagEndpointConfiguration alloc] initWithNotify:@"http://notreal.bugsnag.com"
                                                                   sessions:@"http://notreal.bugsnag.com"];
    XCTAssertEqual([[config onBreadcrumbBlocks] count], 0);
    BugsnagOnBreadcrumbBlock crumbBlock = ^(BugsnagBreadcrumb * _Nonnull crumb) {
        [calledExpectation fulfill];
        return YES;
    };

    // It's there (and from other tests we know it gets called) and then it's not there
    BugsnagOnBreadcrumbRef callback = [config addOnBreadcrumbBlock:crumbBlock];
    XCTAssertEqual([[config onBreadcrumbBlocks] count], 1);
    [config removeOnBreadcrumb:callback];
    XCTAssertEqual([[config onBreadcrumbBlocks] count], 0);

    BugsnagClient *client = [[BugsnagClient alloc] initWithConfiguration:config];
    [client start];
    [client leaveBreadcrumbWithMessage:@"Hello"];

    // Wait a second NOT to be called
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}
/**
 * Test that an onBreadcrumb block is called after being added, then NOT called after being removed.
 * This test could be expanded to verify the behaviour when multiple blocks are added.
 */
- (void)testAddOnBreadcrumbBlockThenRemove {

    __block int called = 0; // A counter

    // Setup
    __block XCTestExpectation *expectation1 = [self expectationWithDescription:@"Remove On Breadcrumb Block 1"];
    __block XCTestExpectation *expectation2 = [self expectationWithDescription:@"Remove On Breadcrumb Block 2"];
    expectation2.inverted = YES;

    BugsnagConfiguration *config = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    config.endpoints = [[BugsnagEndpointConfiguration alloc] initWithNotify:@"http://notreal.bugsnag.com"
                                                                   sessions:@"http://notreal.bugsnag.com"];
    XCTAssertEqual([[config onBreadcrumbBlocks] count], 0);

    BugsnagOnBreadcrumbBlock crumbBlock = ^(BugsnagBreadcrumb * _Nonnull crumb) {
        switch (called) {
        case 0:
            [expectation1 fulfill];
            break;
        case 1:
            [expectation2 fulfill];
            break;
        }
        return YES;
    };

    BugsnagOnBreadcrumbRef callback = [config addOnBreadcrumbBlock:crumbBlock];
    XCTAssertEqual([[config onBreadcrumbBlocks] count], 1);

    // Call onbreadcrumb blocks
    BugsnagClient *client = [[BugsnagClient alloc] initWithConfiguration:config];
    [client start];
    [client leaveBreadcrumbWithMessage:@"Hello"];
    [self waitForExpectations:@[expectation1] timeout:1.0];

    // Check it's NOT called once the block's deleted
    called++;
    [client removeOnBreadcrumb:callback];
    
    [client leaveBreadcrumbWithMessage:@"Hello"];
    [self waitForExpectations:@[expectation2] timeout:1.0];
}

/**
 * Make sure slightly invalid removals and duplicate additions don't break things
 */
- (void)testRemoveNonexistentOnBreadcrumbBlocks {
    BugsnagConfiguration *config = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    XCTAssertEqual([[config onBreadcrumbBlocks] count], 0);
    BugsnagOnBreadcrumbBlock crumbBlock1 = ^(BugsnagBreadcrumb * _Nonnull crumb) {
        return YES;
    };
    BugsnagOnBreadcrumbBlock crumbBlock2 = ^(BugsnagBreadcrumb * _Nonnull crumb) {
        return YES;
    };

    BugsnagOnBreadcrumbRef callback1 = [config addOnBreadcrumbBlock:crumbBlock1];
    XCTAssertEqual([[config onBreadcrumbBlocks] count], 1);
    [config removeOnBreadcrumb:crumbBlock2];
    XCTAssertEqual([[config onBreadcrumbBlocks] count], 1);
    [config removeOnBreadcrumb:callback1];
    XCTAssertEqual([[config onBreadcrumbBlocks] count], 0);
    [config removeOnBreadcrumb:crumbBlock2];
    XCTAssertEqual([[config onBreadcrumbBlocks] count], 0);
    [config removeOnBreadcrumb:callback1];
    XCTAssertEqual([[config onBreadcrumbBlocks] count], 0);

    [config addOnBreadcrumbBlock:crumbBlock1];
    XCTAssertEqual([[config onBreadcrumbBlocks] count], 1);
    [config addOnBreadcrumbBlock:crumbBlock1];
    XCTAssertEqual([[config onBreadcrumbBlocks] count], 2);
    [config addOnBreadcrumbBlock:crumbBlock1];
    XCTAssertEqual([[config onBreadcrumbBlocks] count], 3);
}

/**
 * Test that onBreadcrumb blocks mutate a crumb
 */
- (void)testAddOnBreadcrumbMutation {
    BugsnagConfiguration *config = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    config.endpoints = [[BugsnagEndpointConfiguration alloc] initWithNotify:@"http://notreal.bugsnag.com"
                                                                   sessions:@"http://notreal.bugsnag.com"];
    [config addOnBreadcrumbBlock:^(BugsnagBreadcrumb * _Nonnull crumb) {
        crumb.message = @"Foo";
        return YES;
    }];

    // Call onbreadcrumb blocks
    BugsnagClient *client = [[BugsnagClient alloc] initWithConfiguration:config];
    [client start];
    XCTAssertEqual([[config onBreadcrumbBlocks] count], 1);
    NSDictionary *crumb = [client.breadcrumbs.firstObject objectValue];
    XCTAssertEqualObjects(@"Foo", crumb[@"name"]);
}

/**
 * Test that onBreadcrumb blocks can discard crumbs
 */
- (void)testAddOnBreadcrumbRejection {
    BugsnagConfiguration *config = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    config.endpoints = [[BugsnagEndpointConfiguration alloc] initWithNotify:@"http://notreal.bugsnag.com"
                                                                   sessions:@"http://notreal.bugsnag.com"];
    [config addOnBreadcrumbBlock:^(BugsnagBreadcrumb * _Nonnull crumb) {
        return NO;
    }];
    BugsnagClient *client = [[BugsnagClient alloc] initWithConfiguration:config];
    [client start];

    // Not always zero - breadcrumbs from previous tests can appear due to async behaviour
    NSUInteger countBefore = client.breadcrumbs.count;

    // Call onbreadcrumb blocks
    [client leaveBreadcrumbWithMessage:@"Hello"];
    NSArray *breadcrumbs = client.breadcrumbs;
    XCTAssertEqual(breadcrumbs.count, countBefore, @"Expected %lu breadcrumbs, got %@",
                   (unsigned long)countBefore, [breadcrumbs valueForKeyPath:@"objectValue"]);
}

@end
