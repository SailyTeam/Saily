//
//  BSGClientObserverTests.m
//  Tests
//
//  Created by Jamie Lynch on 18/03/2020.
//  Copyright © 2020 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "Bugsnag.h"
#import "BugsnagClient+Private.h"
#import "BugsnagConfiguration.h"
#import "BugsnagTestConstants.h"
#import "BugsnagMetadata+Private.h"
#import "BugsnagUser+Private.h"

@interface BSGClientObserverTests : XCTestCase
@property BugsnagClient *client;
@property BSGClientObserverEvent event;
@property id value;
@end

@implementation BSGClientObserverTests

- (void)setUp {
    BugsnagConfiguration *config = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    self.client = [Bugsnag startWithConfiguration:config];

    __weak __typeof__(self) weakSelf = self;
    self.client.observer = ^(BSGClientObserverEvent event, id value) {
        weakSelf.event = event;
        weakSelf.value = value;
    };
}

- (void)testUserUpdate {
    [self.client setUser:@"123" withEmail:@"test@example.com" andName:@"Jamie"];

    XCTAssertEqual(self.event, BSGClientObserverUpdateUser);

    NSDictionary *dict = [self.value toJson];
    XCTAssertEqualObjects(@"123", dict[@"id"]);
    XCTAssertEqualObjects(@"Jamie", dict[@"name"]);
    XCTAssertEqualObjects(@"test@example.com", dict[@"email"]);
}

- (void)testContextUpdate {
    [self.client setContext:@"Foo"];
    XCTAssertEqual(self.event, BSGClientObserverUpdateContext);
    XCTAssertEqualObjects(self.value, @"Foo");
}

- (void)testMetadataUpdate {
    [self.client addMetadata:@"Bar" withKey:@"Foo2" toSection:@"test"];
    XCTAssertEqualObjects(self.value, self.client.metadata);
}

- (void)testRemoveObserver {
    self.event = -1;
    self.value = nil;
    self.client.observer = nil;
    [self.client setUser:@"123" withEmail:@"test@example.com" andName:@"Jamie"];
    [self.client setContext:@"Foo"];
    [self.client addMetadata:@"Bar" withKey:@"Foo" toSection:@"test"];
    XCTAssertEqual(self.event, -1);
}

- (void)testAddObserverTriggersCallback {
    [self.client setUser:@"123" withEmail:@"test@example.com" andName:@"Jamie"];
    [self.client setContext:@"Foo"];
    [self.client addMetadata:@"Bar" withKey:@"Foo" toSection:@"test"];
    [self.client addFeatureFlagWithName:@"Testing" variant:@"unit"];

    __block NSDictionary *user;
    __block NSString *context;
    __block BugsnagMetadata *metadata;
    __block BugsnagFeatureFlag *featureFlag;

    BSGClientObserver observer = ^(BSGClientObserverEvent event, id value) {
        switch (event) {
            case BSGClientObserverAddFeatureFlag:
                featureFlag = value;
                break;
            case BSGClientObserverClearFeatureFlag:
                XCTFail(@"BSGClientObserverClearFeatureFlag should not be sent when setting observer");
                break;
            case BSGClientObserverUpdateContext:
                context = value;
                break;
            case BSGClientObserverUpdateMetadata:
                metadata = value;
                break;
            case BSGClientObserverUpdateUser:
                user = [(BugsnagUser *)value toJson];
                break;
        }
    };
    XCTAssertNil(user);
    XCTAssertNil(context);
    XCTAssertNil(metadata);
    self.client.observer = observer;

    NSDictionary *expectedUser = @{@"id": @"123", @"email": @"test@example.com", @"name": @"Jamie"};
    XCTAssertEqualObjects(expectedUser, user);
    XCTAssertEqualObjects(@"Foo", context);
    XCTAssertEqualObjects(self.client.metadata, metadata);
    XCTAssertEqualObjects(featureFlag.name, @"Testing");
    XCTAssertEqualObjects(featureFlag.variant, @"unit");
}

- (void)testFeatureFlags {
    [self.client addFeatureFlags:@[[BugsnagFeatureFlag flagWithName:@"foo" variant:@"bar"]]];
    XCTAssertEqual(self.event, BSGClientObserverAddFeatureFlag);
    XCTAssertEqualObjects([self.value name], @"foo");
    XCTAssertEqualObjects([self.value variant], @"bar");
    
    [self.client addFeatureFlagWithName:@"baz"];
    XCTAssertEqual(self.event, BSGClientObserverAddFeatureFlag);
    XCTAssertEqualObjects([self.value name], @"baz");
    XCTAssertNil([self.value variant]);
    
    [self.client addFeatureFlagWithName:@"baz" variant:@"vvv"];
    XCTAssertEqual(self.event, BSGClientObserverAddFeatureFlag);
    XCTAssertEqualObjects([self.value name], @"baz");
    XCTAssertEqualObjects([self.value variant], @"vvv");
    
    [self.client clearFeatureFlagWithName:@"baz"];
    XCTAssertEqual(self.event, BSGClientObserverClearFeatureFlag);
    XCTAssertEqualObjects(self.value, @"baz");
    
    [self.client clearFeatureFlags];
    XCTAssertEqual(self.event, BSGClientObserverClearFeatureFlag);
    XCTAssertNil(self.value);
}

@end
