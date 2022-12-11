//
//  BSGTelemetryTests.m
//  Bugsnag
//
//  Created by Nick Dowell on 05/07/2022.
//  Copyright © 2022 Bugsnag Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <Bugsnag/Bugsnag.h>

#import "BSGTelemetry.h"
#import "BugsnagTestConstants.h"

@interface BSGTelemetryTests : XCTestCase

@end

@implementation BSGTelemetryTests

static void OnCrashHandler(const BSG_KSCrashReportWriter *writer) {}

- (BugsnagConfiguration *)createConfiguration {
    return [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
}

- (void)testEmptyWhenDefault {
    BugsnagConfiguration *configuration = [self createConfiguration];
    XCTAssertEqualObjects(BSGTelemetryCreateUsage(configuration), (@{@"callbacks": @{}, @"config": @{}}));
}

- (void)testCallbacks {
    BugsnagConfiguration *configuration = [self createConfiguration];
    [configuration addOnBreadcrumbBlock:^BOOL(BugsnagBreadcrumb * _Nonnull breadcrumb) { return NO; }];
    [configuration addOnSendErrorBlock:^BOOL(BugsnagEvent * _Nonnull event) { return NO; }];
    [configuration addOnSessionBlock:^BOOL(BugsnagSession * _Nonnull session) { return NO; }];
    configuration.onCrashHandler = OnCrashHandler;
    NSDictionary *expected = @{@"config": @{},
                               @"callbacks": @{
                                   @"onBreadcrumb": @1,
                                   @"onCrashHandler": @1,
                                   @"onSendError": @1,
                                   @"onSession": @1,
                               }};
    XCTAssertEqualObjects(BSGTelemetryCreateUsage(configuration), expected);
}

- (void)testConfigValues {
    BugsnagConfiguration *configuration = [self createConfiguration];
#if !TARGET_OS_WATCH
    configuration.appHangThresholdMillis = 250;
    configuration.sendThreads = BSGThreadSendPolicyUnhandledOnly;
#endif
    configuration.autoDetectErrors = NO;
    configuration.autoTrackSessions = NO;
    configuration.discardClasses = [NSSet setWithObject:@"SomeErrorClass"];
    configuration.launchDurationMillis = 1000;
    configuration.maxBreadcrumbs = 16;
    configuration.maxPersistedEvents = 4;
    configuration.maxPersistedSessions = 8;
    configuration.persistUser = NO;
    [configuration addPlugin:(id)[NSNull null]];
    NSDictionary *expected = @{@"callbacks": @{},
                               @"config": @{
#if !TARGET_OS_WATCH
                                   @"appHangThresholdMillis": @250,
                                   @"sendThreads": @"unhandledOnly",
#endif
                                   @"autoDetectErrors": @NO,
                                   @"autoTrackSessions": @NO,
                                   @"discardClassesCount": @1,
                                   @"launchDurationMillis": @1000,
                                   @"maxBreadcrumbs": @16,
                                   @"maxPersistedEvents": @4,
                                   @"maxPersistedSessions": @8,
                                   @"persistUser": @NO,
                                   @"pluginCount": @1,
                               }};
    XCTAssertEqualObjects(BSGTelemetryCreateUsage(configuration), expected);
}

- (void)testEnabledBreadcrumbTypes {
    BugsnagConfiguration *configuration = [self createConfiguration];
    configuration.enabledBreadcrumbTypes &= ~BSGEnabledBreadcrumbTypeNavigation;
    XCTAssertEqualObjects(BSGTelemetryCreateUsage(configuration),
                          (@{@"callbacks": @{}, @"config": @{
                              @"enabledBreadcrumbTypes": @"error,log,process,request,state,user"}}));
}

- (void)testEnabledErrorTypes {
    BugsnagConfiguration *configuration = [self createConfiguration];
    configuration.enabledErrorTypes.cppExceptions = NO;
#if TARGET_OS_WATCH
    NSString *expected = @"unhandledExceptions,unhandledRejections";
#else
    NSString *expected = @"appHangs,machExceptions,ooms,signals,thermalKills,unhandledExceptions,unhandledRejections";
#endif
    XCTAssertEqualObjects(BSGTelemetryCreateUsage(configuration),
                          (@{@"callbacks": @{}, @"config": @{
                              @"enabledErrorTypes": expected}}));
}

- (void)testNilWhenDisabled {
    BugsnagConfiguration *configuration = [self createConfiguration];
    configuration.telemetry &= ~BSGTelemetryUsage;
    XCTAssertNil(BSGTelemetryCreateUsage(configuration));
}

@end
