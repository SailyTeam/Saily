//
//  BugsnagApiValidationTest.m
//  Bugsnag
//
//  Created by Jamie Lynch on 10/06/2020.
//  Copyright © 2020 Bugsnag Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Bugsnag/Bugsnag.h>
#import "BugsnagTestConstants.h"
#import "TestSupport.h"

/**
 * Validates that the Bugsnag API interface handles any invalid input gracefully.
 */
@interface BugsnagApiValidationTest : XCTestCase

@end

@implementation BugsnagApiValidationTest

- (void)setUp {
    [TestSupport purgePersistentData];
    [Bugsnag startWithApiKey:DUMMY_APIKEY_32CHAR_1];
}

- (void)testAppDidCrashLastLaunch {
    XCTAssertFalse(Bugsnag.lastRunInfo.crashed);
}

- (void)testValidNotify {
    [Bugsnag notify:[NSException exceptionWithName:@"FooException" reason:@"whoops" userInfo:nil]];
}

- (void)testValidNotifyBlock {
    NSException *exc = [NSException exceptionWithName:@"FooException" reason:@"whoops" userInfo:nil];
    [Bugsnag notify:exc block:nil];
    [Bugsnag notify:exc block:^BOOL(BugsnagEvent *event) {
        return NO;
    }];
}

- (void)testValidNotifyError {
    NSError *error = [NSError errorWithDomain:@"BarError" code:500 userInfo:nil];
    [Bugsnag notifyError:error];
}

- (void)testValidNotifyErrorBlock {
    NSError *error = [NSError errorWithDomain:@"BarError" code:500 userInfo:nil];
    [Bugsnag notifyError:error block:nil];
    [Bugsnag notifyError:error block:^BOOL(BugsnagEvent *event) {
        return NO;
    }];
}

- (void)testValidLeaveBreadcrumbWithMessage {
    [Bugsnag leaveBreadcrumbWithMessage:@"Foo"];
}

- (void)testValidLeaveBreadcrumbForNotificationName {
    [Bugsnag leaveBreadcrumbForNotificationName:@"some invalid value"];
}

- (void)testValidLeaveBreadcrumbWithMessageMetadata {
    [Bugsnag leaveBreadcrumbWithMessage:@"Foo" metadata:nil andType:BSGBreadcrumbTypeProcess];
    [Bugsnag leaveBreadcrumbWithMessage:@"Foo" metadata:@{@"test": @2} andType:BSGBreadcrumbTypeState];
}

- (void)testValidStartSession {
    [Bugsnag startSession];
}

- (void)testValidPauseSession {
    [Bugsnag pauseSession];
}

- (void)testValidResumeSession {
    [Bugsnag resumeSession];
}

- (void)testValidContext {
    Bugsnag.context = nil;
    XCTAssertNil(Bugsnag.context);
    Bugsnag.context = @"Foo";
    XCTAssertEqualObjects(@"Foo", Bugsnag.context);
}

- (void)testValidAppDidCrashLastLaunch {
    XCTAssertFalse(Bugsnag.lastRunInfo.crashed);
}

- (void)testValidUser {
    [Bugsnag setUser:nil withEmail:nil andName:nil];
    XCTAssertNotNil(Bugsnag.user);
    XCTAssertNil(Bugsnag.user.id);
    XCTAssertNil(Bugsnag.user.email);
    XCTAssertNil(Bugsnag.user.name);

    [Bugsnag setUser:@"123" withEmail:@"joe@foo.com" andName:@"Joe"];
    XCTAssertNotNil(Bugsnag.user);
    XCTAssertEqualObjects(@"123", Bugsnag.user.id);
    XCTAssertEqualObjects(@"joe@foo.com", Bugsnag.user.email);
    XCTAssertEqualObjects(@"Joe", Bugsnag.user.name);
}

- (void)testValidOnSessionBlock {
    BugsnagOnSessionRef callback = [Bugsnag addOnSessionBlock:^BOOL(BugsnagSession *session) {
        return NO;
    }];
    [Bugsnag removeOnSession:callback];
}

- (void)testValidOnBreadcrumbBlock {
    BugsnagOnBreadcrumbRef callback = [Bugsnag addOnBreadcrumbBlock:^BOOL(BugsnagBreadcrumb *breadcrumb) {
        return NO;
    }];
    [Bugsnag removeOnBreadcrumb:callback];
}

- (void)testValidAddMetadata {
    [Bugsnag addMetadata:@{} toSection:@"foo"];
    XCTAssertNil([Bugsnag getMetadataFromSection:@"foo"]);

    [Bugsnag addMetadata:nil withKey:@"nom" toSection:@"foo"];
    [Bugsnag addMetadata:@"" withKey:@"bar" toSection:@"foo"];
    XCTAssertNil([Bugsnag getMetadataFromSection:@"foo" withKey:@"nom"]);
    XCTAssertEqualObjects(@"", [Bugsnag getMetadataFromSection:@"foo" withKey:@"bar"]);
}

- (void)testValidClearMetadata {
    [Bugsnag clearMetadataFromSection:@""];
    [Bugsnag clearMetadataFromSection:@"" withKey:@""];
}

- (void)testValidGetMetadata {
    [Bugsnag getMetadataFromSection:@""];
    [Bugsnag getMetadataFromSection:@"" withKey:@""];
}

@end
