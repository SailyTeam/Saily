//
//  BugsnagPluginTest.m
//  Tests
//
//  Created by Jamie Lynch on 12/03/2020.
//  Copyright © 2020 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BugsnagTestConstants.h"
#import "Bugsnag.h"
#import "BugsnagClient+Private.h"
#import "BugsnagConfiguration+Private.h"

@interface BugsnagPluginTest : XCTestCase

@end

@interface FakePlugin: NSObject<BugsnagPlugin>
@property XCTestExpectation *expectation;
@end
@implementation FakePlugin
    - (void)load:(BugsnagClient *)client {
        [self.expectation fulfill];
    }
    - (void)unload {}
@end

@interface CrashyPlugin: NSObject<BugsnagPlugin>
@property XCTestExpectation *expectation;
@end
@implementation CrashyPlugin
    - (void)load:(BugsnagClient *)client {
        [NSException raise:@"WhoopsException" format:@"something went wrong"];
        [self.expectation fulfill];
    }
    - (void)unload {}
@end

@implementation BugsnagPluginTest

- (void)testAddPlugin {
    id<BugsnagPlugin> plugin = [FakePlugin new];
    BugsnagConfiguration *config = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    [config addPlugin:plugin];
    XCTAssertEqual([config.plugins anyObject], plugin);
}

- (void)testPluginLoaded {
    FakePlugin *plugin = [FakePlugin new];
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"Plugin Loaded by Bugsnag"];
    plugin.expectation = expectation;

    BugsnagConfiguration *config = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    [config addPlugin:plugin];
    BugsnagClient *client = [[BugsnagClient alloc] initWithConfiguration:config];
    [client start];
    [self waitForExpectations:@[expectation] timeout:3.0];
}

- (void)testCrashyPluginDoesNotCrashApp {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"Crashy plugin not loaded by Bugsnag"];
    expectation.inverted = YES;
    CrashyPlugin *plugin = [CrashyPlugin new];
    plugin.expectation = expectation;

    BugsnagConfiguration *config = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    [config addPlugin:plugin];
    BugsnagClient *client = [[BugsnagClient alloc] initWithConfiguration:config];
    [client start];
    [self waitForExpectations:@[expectation] timeout:3.0];
}

@end
