//
//  ConfigurationApiValidationTest.m
//  Bugsnag
//
//  Created by Jamie Lynch on 10/06/2020.
//  Copyright © 2020 Bugsnag Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Bugsnag/Bugsnag.h>
#import "BugsnagConfiguration+Private.h"
#import "BugsnagPlugin.h"
#import "BugsnagTestConstants.h"
#import <TargetConditionals.h>

@interface FooPlugin: NSObject<BugsnagPlugin>
@end
@implementation FooPlugin
- (void)load:(BugsnagClient *_Nonnull)client {}
- (void)unload {}
@end

/**
* Validates that the Configuration API interface handles any invalid input gracefully.
*/
@interface ConfigurationApiValidationTest : XCTestCase
@property BugsnagConfiguration *config;
@end

@implementation ConfigurationApiValidationTest

- (void)setUp {
    self.config = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
}

- (void)testValidReleaseStage {
    self.config.releaseStage = @"prod";
    XCTAssertEqualObjects(@"prod", self.config.releaseStage);
    self.config.releaseStage = nil;
    XCTAssertNil(self.config.releaseStage);
}

- (void)testValidEnabledReleaseStages {
    self.config.enabledReleaseStages = nil;
    XCTAssertNil(self.config.enabledReleaseStages);

    NSSet *expected = [NSSet setWithArray:@[@"foo", @"bar"]];
    self.config.enabledReleaseStages = expected;
    XCTAssertEqualObjects(expected, self.config.enabledReleaseStages);
}

- (void)testValidRedactedKeys {
    self.config.redactedKeys = nil;
    XCTAssertNil(self.config.redactedKeys);

    NSSet *set = [NSSet setWithArray:@[@"password", @"foo"]];
    self.config.redactedKeys = set;
    XCTAssertEqualObjects(set, self.config.redactedKeys);

    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"a" options:0 error:nil];
    NSSet *regexSet = [NSSet setWithArray:@[@"password", @"foo", regex]];
    self.config.redactedKeys = regexSet;
    XCTAssertEqualObjects(regexSet, self.config.redactedKeys);
}

- (void)testValidContext {
    self.config.context = nil;
    XCTAssertNil(self.config.context);
    self.config.context = @"foo";
    XCTAssertEqualObjects(@"foo", self.config.context);
}

- (void)testValidAppVersion {
    self.config.appVersion = nil;
    XCTAssertNil(self.config.appVersion);
    self.config.appVersion = @"1.3";
    XCTAssertEqualObjects(@"1.3", self.config.appVersion);
}

- (void)testValidSession {
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    self.config.session = session;
    XCTAssertEqual(session, self.config.session);
}

- (void)testValidSendThreads {
#if !TARGET_OS_WATCH
    XCTAssertEqual(BSGThreadSendPolicyAlways, self.config.sendThreads);
    self.config.sendThreads = BSGThreadSendPolicyNever;
    XCTAssertEqual(BSGThreadSendPolicyNever, self.config.sendThreads);
    self.config.sendThreads = BSGThreadSendPolicyUnhandledOnly;
    XCTAssertEqual(BSGThreadSendPolicyUnhandledOnly, self.config.sendThreads);
#endif
}

- (void)testValidAutoDetectErrors {
    self.config.autoDetectErrors = true;
    XCTAssertTrue(self.config.autoDetectErrors);
    self.config.autoDetectErrors = false;
    XCTAssertFalse(self.config.autoDetectErrors);
}

- (void)testValidAutoTrackSessions {
    self.config.autoTrackSessions = true;
    XCTAssertTrue(self.config.autoTrackSessions);
    self.config.autoTrackSessions = false;
    XCTAssertFalse(self.config.autoTrackSessions);
}

- (void)testValidEnabledBreadcrumbTypes {
    self.config.enabledBreadcrumbTypes = BSGEnabledBreadcrumbTypeNone;
    XCTAssertEqual(BSGEnabledBreadcrumbTypeNone, self.config.enabledBreadcrumbTypes);
    self.config.enabledBreadcrumbTypes = BSGEnabledBreadcrumbTypeAll;
    XCTAssertEqual(BSGEnabledBreadcrumbTypeAll, self.config.enabledBreadcrumbTypes);
    self.config.enabledBreadcrumbTypes = BSGEnabledBreadcrumbTypeState & BSGEnabledBreadcrumbTypeNavigation;
    XCTAssertEqual(BSGEnabledBreadcrumbTypeState & BSGEnabledBreadcrumbTypeNavigation, self.config.enabledBreadcrumbTypes);
}

- (void)testValidBundleVersion {
    self.config.bundleVersion = nil;
    XCTAssertNil(self.config.bundleVersion);
    self.config.bundleVersion = @"1.3";
    XCTAssertEqualObjects(@"1.3", self.config.bundleVersion);
}

- (void)testValidAppType {
    self.config.appType = nil;
    XCTAssertNil(self.config.appType);
    self.config.appType = @"cocoa";
    XCTAssertEqualObjects(@"cocoa", self.config.appType);
}

- (void)testValidMaxPersistedEvents {
    self.config.maxPersistedEvents = 1;
    XCTAssertEqual(1, self.config.maxPersistedEvents);
    self.config.maxPersistedEvents = 100;
    XCTAssertEqual(100, self.config.maxPersistedEvents);
    self.config.maxPersistedEvents = 40;
    XCTAssertEqual(40, self.config.maxPersistedEvents);
}

- (void)testValidMaxPersistedSessions {
    self.config.maxPersistedSessions = 1;
    XCTAssertEqual(1, self.config.maxPersistedSessions);
    self.config.maxPersistedSessions = 100;
    XCTAssertEqual(100, self.config.maxPersistedSessions);
    self.config.maxPersistedSessions = 40;
    XCTAssertEqual(40, self.config.maxPersistedSessions);
}

- (void)testValidMaxBreadcrumbs {
    self.config.maxBreadcrumbs = 0;
    XCTAssertEqual(0, self.config.maxBreadcrumbs);
    self.config.maxBreadcrumbs = 100;
    XCTAssertEqual(100, self.config.maxBreadcrumbs);
    self.config.maxBreadcrumbs = 40;
    XCTAssertEqual(40, self.config.maxBreadcrumbs);
}

- (void)testInvalidMaxBreadcrumbs {
    self.config.maxBreadcrumbs = 0;
    self.config.maxBreadcrumbs = -1;
    XCTAssertEqual(0, self.config.maxBreadcrumbs);
    self.config.maxBreadcrumbs = 590;
    XCTAssertEqual(0, self.config.maxBreadcrumbs);
}

- (void)testValidPersistUser {
    self.config.persistUser = true;
    XCTAssertTrue(self.config.persistUser);
    self.config.persistUser = false;
    XCTAssertFalse(self.config.persistUser);
}

- (void)testValidEnabledErrorTypes {
    BugsnagErrorTypes *types = [BugsnagErrorTypes new];
#if !TARGET_OS_WATCH
    types.ooms = true;
#endif
    types.cppExceptions = false;
    self.config.enabledErrorTypes = types;
    XCTAssertEqualObjects(types, self.config.enabledErrorTypes);
    XCTAssertTrue(types.unhandledExceptions);
    XCTAssertFalse(types.cppExceptions);
    XCTAssertTrue(types.unhandledRejections);
#if !TARGET_OS_WATCH
    XCTAssertTrue(types.signals);
    XCTAssertTrue(types.machExceptions);
    XCTAssertTrue(types.ooms);
#endif
}

- (void)testValidEndpoints {
    self.config.endpoints = [[BugsnagEndpointConfiguration alloc] initWithNotify:@"http://notify.example.com"
                                                                        sessions:@"http://sessions.example.com"];
    BugsnagEndpointConfiguration *endpoints = self.config.endpoints;
    XCTAssertNotNil(endpoints);
    XCTAssertEqualObjects(@"http://notify.example.com", endpoints.notify);
    XCTAssertEqualObjects(@"http://sessions.example.com", endpoints.sessions);
}

- (void)testValidUser {
    [self.config setUser:nil withEmail:nil andName:nil];
    XCTAssertNotNil(self.config.user);
    XCTAssertNil(self.config.user.id);
    XCTAssertNil(self.config.user.email);
    XCTAssertNil(self.config.user.name);

    [self.config setUser:@"123" withEmail:@"joe@foo.com" andName:@"Joe"];
    XCTAssertNotNil(self.config.user);
    XCTAssertEqualObjects(@"123", self.config.user.id);
    XCTAssertEqualObjects(@"joe@foo.com", self.config.user.email);
    XCTAssertEqualObjects(@"Joe", self.config.user.name);
}

- (void)testValidOnSessionBlock {
    BOOL (^block)(BugsnagSession *) = ^BOOL(BugsnagSession *session) {
        return NO;
    };
    BugsnagOnSessionRef callback = [self.config addOnSessionBlock:block];
    XCTAssertEqual(1, [self.config.onSessionBlocks count]);
    [self.config removeOnSession:callback];
    XCTAssertEqual(0, [self.config.onSessionBlocks count]);
}

- (void)testValidOnSendErrorBlock {
    BOOL (^block)(BugsnagEvent *) = ^BOOL(BugsnagEvent *event) {
        return NO;
    };
    BugsnagOnSendErrorRef callback = [self.config addOnSendErrorBlock:block];
    XCTAssertEqual(1, [self.config.onSendBlocks count]);
    [self.config removeOnSendError:callback];
    XCTAssertEqual(0, [self.config.onSendBlocks count]);
}

- (void)testValidOnBreadcrumbBlock {
    BOOL (^block)(BugsnagBreadcrumb *) = ^BOOL(BugsnagBreadcrumb *breadcrumb) {
        return NO;
    };
    BugsnagOnBreadcrumbRef callback = [self.config addOnBreadcrumbBlock:block];
    XCTAssertEqual(1, [self.config.onBreadcrumbBlocks count]);
    [self.config removeOnBreadcrumb:callback];
    XCTAssertEqual(0, [self.config.onBreadcrumbBlocks count]);
}

- (void)testValidAddPlugin {
    [self.config addPlugin:[FooPlugin new]];
    XCTAssertEqual(1, [self.config.plugins count]);
}

- (void)testValidAddMetadata {
    [self.config addMetadata:@{} toSection:@"foo"];
    XCTAssertNil([self.config getMetadataFromSection:@"foo"]);

    [self.config addMetadata:nil withKey:@"nom" toSection:@"foo"];
    [self.config addMetadata:@"" withKey:@"bar" toSection:@"foo"];
    XCTAssertNil([self.config getMetadataFromSection:@"foo" withKey:@"nom"]);
    XCTAssertEqualObjects(@"", [self.config getMetadataFromSection:@"foo" withKey:@"bar"]);
}

- (void)testValidClearMetadata {
    [self.config clearMetadataFromSection:@""];
    [self.config clearMetadataFromSection:@"" withKey:@""];
}

- (void)testValidGetMetadata {
    [self.config getMetadataFromSection:@""];
    [self.config getMetadataFromSection:@"" withKey:@""];
}

@end
