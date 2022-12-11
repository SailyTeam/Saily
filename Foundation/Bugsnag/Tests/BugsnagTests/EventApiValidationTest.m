//
//  EventApiValidationTest.m
//  Bugsnag
//
//  Created by Jamie Lynch on 10/06/2020.
//  Copyright © 2020 Bugsnag Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <Bugsnag/Bugsnag.h>
#import "BugsnagEvent+Private.h"

/**
* Validates that the Event API interface handles any invalid input gracefully.
*/
@interface EventApiValidationTest : XCTestCase
@property BugsnagEvent *event;
@end

@implementation EventApiValidationTest

- (void)setUp {
    self.event = [[BugsnagEvent alloc] initWithKSReport:@{@"user": @{}}];
}

- (void)testValidContext {
    self.event.context = nil;
    XCTAssertNil(self.event.context);
    self.event.context = @"foo";
    XCTAssertEqualObjects(@"foo", self.event.context);
}

- (void)testValidSeverity {
    self.event.severity = BSGSeverityInfo;
    XCTAssertEqual(BSGSeverityInfo, self.event.severity);
    self.event.severity = BSGSeverityWarning;
    XCTAssertEqual(BSGSeverityWarning, self.event.severity);
    self.event.severity = BSGSeverityError;
    XCTAssertEqual(BSGSeverityError, self.event.severity);
}

- (void)testValidGroupingHash {
    self.event.groupingHash = nil;
    XCTAssertNil(self.event.groupingHash);
    self.event.groupingHash = @"1a0f";
    XCTAssertEqualObjects(@"1a0f", self.event.groupingHash);
}

- (void)testValidUser {
    [self.event setUser:nil withEmail:nil andName:nil];
    XCTAssertNotNil(self.event.user);
    XCTAssertNil(self.event.user.id);
    XCTAssertNil(self.event.user.email);
    XCTAssertNil(self.event.user.name);

    [self.event setUser:@"123" withEmail:@"joe@foo.com" andName:@"Joe"];
    XCTAssertNotNil(self.event.user);
    XCTAssertEqualObjects(@"123", self.event.user.id);
    XCTAssertEqualObjects(@"joe@foo.com", self.event.user.email);
    XCTAssertEqualObjects(@"Joe", self.event.user.name);
}

- (void)testValidAddMetadata {
    [self.event addMetadata:@{} toSection:@"foo"];
    XCTAssertNil([self.event getMetadataFromSection:@"foo"]);

    [self.event addMetadata:nil withKey:@"nom" toSection:@"foo"];
    [self.event addMetadata:@"" withKey:@"bar" toSection:@"foo"];
    XCTAssertNil([self.event getMetadataFromSection:@"foo" withKey:@"nom"]);
    XCTAssertEqualObjects(@"", [self.event getMetadataFromSection:@"foo" withKey:@"bar"]);
}

- (void)testValidClearMetadata {
    [self.event clearMetadataFromSection:@""];
    [self.event clearMetadataFromSection:@"" withKey:@""];
}

- (void)testValidGetMetadata {
    [self.event getMetadataFromSection:@""];
    [self.event getMetadataFromSection:@"" withKey:@""];
}

- (void)testValidApp {
    BugsnagAppWithState *app = self.event.app;
    XCTAssertNotNil(app);

    app.duration = nil;
    XCTAssertNil(app.duration);
    app.duration = @9001;
    XCTAssertEqualObjects(@9001, app.duration);

    app.durationInForeground = nil;
    XCTAssertNil(app.durationInForeground);
    app.durationInForeground = @500;
    XCTAssertEqualObjects(@500, app.durationInForeground);

    app.inForeground = true;
    XCTAssertTrue(app.inForeground);
    app.inForeground = false;
    XCTAssertFalse(app.inForeground);

    app.bundleVersion = nil;
    XCTAssertNil(app.bundleVersion);
    app.bundleVersion = @"1.2";
    XCTAssertEqualObjects(@"1.2", app.bundleVersion);

    app.codeBundleId = nil;
    XCTAssertNil(app.codeBundleId);
    app.codeBundleId = @"5.2";
    XCTAssertEqualObjects(@"5.2", app.codeBundleId);

    app.dsymUuid = nil;
    XCTAssertNil(app.dsymUuid);
    app.dsymUuid = @"0dce";
    XCTAssertEqualObjects(@"0dce", app.dsymUuid);

    app.id = nil;
    XCTAssertNil(app.id);
    app.id = @"com.example.Foo";
    XCTAssertEqualObjects(@"com.example.Foo", app.id);

    app.releaseStage = nil;
    XCTAssertNil(app.releaseStage);
    app.releaseStage = @"beta";
    XCTAssertEqualObjects(@"beta", app.releaseStage);

    app.type = nil;
    XCTAssertNil(app.type);
    app.type = @"rn";
    XCTAssertEqualObjects(@"rn", app.type);

    app.version = nil;
    XCTAssertNil(app.version);
    app.version = @"5.23";
    XCTAssertEqualObjects(@"5.23", app.version);
}

- (void)testValidDevice {
    BugsnagDeviceWithState *device = self.event.device;
    XCTAssertNotNil(device);

    device.freeDisk = nil;
    XCTAssertNil(device.freeDisk);
    device.freeDisk = @20983409;
    XCTAssertEqualObjects(@20983409, device.freeDisk);

    device.freeMemory = nil;
    XCTAssertNil(device.freeMemory);
    device.freeMemory = @509234092;
    XCTAssertEqualObjects(@509234092, device.freeMemory);

    device.totalMemory = nil;
    XCTAssertNil(device.totalMemory);
    device.totalMemory = @7508234092;
    XCTAssertEqualObjects(@7508234092, device.totalMemory);

    device.time = nil;
    XCTAssertNil(device.time);
    device.time = [NSDate dateWithTimeIntervalSince1970:0];
    XCTAssertEqualObjects([NSDate dateWithTimeIntervalSince1970:0], device.time);

    device.jailbroken = true;
    XCTAssertTrue(device.jailbroken);
    device.jailbroken = false;
    XCTAssertFalse(device.jailbroken);

    device.runtimeVersions = nil;
    XCTAssertNil(device.runtimeVersions);
    device.runtimeVersions = @{@"fooVersion": @"5.25"};
    XCTAssertEqualObjects(@{@"fooVersion": @"5.25"}, device.runtimeVersions);

    device.orientation = nil;
    XCTAssertNil(device.orientation);
    device.orientation = @"portrait";
    XCTAssertEqualObjects(@"portrait", device.orientation);

    device.id = nil;
    XCTAssertNil(device.id);
    device.id = @"5f0c";
    XCTAssertEqualObjects(@"5f0c", device.id);

    device.locale = nil;
    XCTAssertNil(device.locale);
    device.locale = @"yue";
    XCTAssertEqualObjects(@"yue", device.locale);

    device.manufacturer = nil;
    XCTAssertNil(device.manufacturer);
    device.manufacturer = @"Samsung";
    XCTAssertEqualObjects(@"Samsung", device.manufacturer);

    device.model = nil;
    XCTAssertNil(device.model);
    device.model = @"iPhone 5s";
    XCTAssertEqualObjects(@"iPhone 5s", device.model);

    device.modelNumber = nil;
    XCTAssertNil(device.modelNumber);
    device.modelNumber = @"iPhone SE";
    XCTAssertEqualObjects(@"iPhone SE", device.modelNumber);

    device.osName = nil;
    XCTAssertNil(device.osName);
    device.osName = @"iOS";
    XCTAssertEqualObjects(@"iOS", device.osName);

    device.osVersion = nil;
    XCTAssertNil(device.osVersion);
    device.osVersion = @"11.3";
    XCTAssertEqualObjects(@"11.3", device.osVersion);
}

- (void)testValidBreadcrumbs {
    self.event.breadcrumbs = @[];
    XCTAssertEqualObjects(@[], self.event.breadcrumbs);

    BugsnagBreadcrumb *crumb = [BugsnagBreadcrumb new];
    crumb.message = @"Hello";
    self.event.breadcrumbs = @[crumb];
    XCTAssertEqualObjects(@[crumb], self.event.breadcrumbs);
}

- (void)testValidThreads {
    self.event.threads = @[];
    XCTAssertEqualObjects(@[], self.event.threads);

    BugsnagThread *emptyThread = [BugsnagThread new];
    emptyThread.id = nil;
    XCTAssertNil(emptyThread.id);
    emptyThread.name = nil;
    XCTAssertNil(emptyThread.name);

    BugsnagThread *thread = [BugsnagThread new];
    thread.id = @"1";
    XCTAssertEqualObjects(@"1", thread.id);
    thread.name = @"thread-delivery";
    XCTAssertEqualObjects(@"thread-delivery", thread.name);
    thread.type = BSGThreadTypeReactNativeJs;
    XCTAssertEqual(BSGThreadTypeReactNativeJs, thread.type);

    NSArray *expected = @[thread, emptyThread];
    self.event.threads = expected;
    XCTAssertEqualObjects(expected, self.event.threads);
}

- (void)testValidErrors {
    self.event.errors = @[];
    XCTAssertEqualObjects(@[], self.event.errors);

    BugsnagError *emptyError = [BugsnagError new];
    emptyError.errorMessage = nil;
    XCTAssertNil(emptyError.errorMessage);
    emptyError.errorClass = nil;
    XCTAssertNil(emptyError.errorClass);

    BugsnagError *error = [BugsnagError new];
    error.errorMessage = @"Something went wrong";
    XCTAssertEqualObjects(@"Something went wrong", error.errorMessage);
    error.errorClass = @"FooException";
    XCTAssertEqualObjects(@"FooException", error.errorClass);
    error.type = BSGErrorTypeC;
    XCTAssertEqual(BSGErrorTypeC, error.type);

    NSArray *expected = @[error, emptyError];
    self.event.errors = expected;
    XCTAssertEqualObjects(expected, self.event.errors);
}

- (void)testValidStackframes {
    BugsnagStackframe *stackframe = [BugsnagStackframe new];

    stackframe.isPc = true;
    XCTAssertTrue(stackframe.isPc);
    stackframe.isPc = false;
    XCTAssertFalse(stackframe.isPc);

    stackframe.isLr = true;
    XCTAssertTrue(stackframe.isLr);
    stackframe.isLr = false;
    XCTAssertFalse(stackframe.isLr);

    stackframe.method = nil;
    XCTAssertNil(stackframe.method);
    stackframe.method = @"[Object object]";
    XCTAssertEqualObjects(@"[Object object]", stackframe.method);

    stackframe.machoFile = nil;
    XCTAssertNil(stackframe.machoFile);
    stackframe.machoFile = @"/usr/bin/foo";
    XCTAssertEqualObjects(@"/usr/bin/foo", stackframe.machoFile);

    stackframe.machoUuid = nil;
    XCTAssertNil(stackframe.machoUuid);
    stackframe.machoUuid = @"0dc3";
    XCTAssertEqualObjects(@"0dc3", stackframe.machoUuid);

    stackframe.frameAddress = nil;
    XCTAssertNil(stackframe.frameAddress);
    stackframe.frameAddress = @0x509234092;
    XCTAssertEqualObjects(@0x509234092, stackframe.frameAddress);

    stackframe.machoVmAddress = nil;
    XCTAssertNil(stackframe.machoVmAddress);
    stackframe.machoVmAddress = @0x2093409234;
    XCTAssertEqualObjects(@0x2093409234, stackframe.machoVmAddress);

    stackframe.symbolAddress = nil;
    XCTAssertNil(stackframe.symbolAddress);
    stackframe.symbolAddress = @0x72093402;
    XCTAssertEqualObjects(@0x72093402, stackframe.symbolAddress);

    stackframe.machoLoadAddress = nil;
    XCTAssertNil(stackframe.machoLoadAddress);
    stackframe.machoLoadAddress = @0x820982340;
    XCTAssertEqualObjects(@0x820982340, stackframe.machoLoadAddress);
}

@end
