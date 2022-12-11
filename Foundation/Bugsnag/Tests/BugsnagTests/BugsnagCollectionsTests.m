//
//  BugsnagCollectionsTests.m
//  Tests
//
//  Created by Paul Zabelin on 7/1/19.
//  Copyright © 2019 Bugsnag. All rights reserved.
//

@import XCTest;
#import "BugsnagCollections.h"

@interface BugsnagCollectionsTests : XCTestCase
@end

@interface BugsnagCollectionsTests_DummyObject : NSObject
@end

@implementation BugsnagCollectionsTests

// MARK: BSGDictMergeTest

- (void)testSubarrayFromIndex {
    XCTAssertEqualObjects(BSGArraySubarrayFromIndex(@[@"foo", @"bar"], 0), (@[@"foo", @"bar"]));
    XCTAssertEqualObjects(BSGArraySubarrayFromIndex(@[@"foo", @"bar"], 1), @[@"bar"]);
    XCTAssertEqualObjects(BSGArraySubarrayFromIndex(@[@"foo", @"bar"], 2), @[]);
    XCTAssertEqualObjects(BSGArraySubarrayFromIndex(@[@"foo", @"bar"], 42), @[]);
    XCTAssertEqualObjects(BSGArraySubarrayFromIndex(@[@"foo", @"bar"], -1), @[]);
}

- (void)testBasicMerge {
    NSDictionary *combined = @{@"a": @"one",
                               @"b": @"two"};
    XCTAssertEqualObjects(combined, BSGDictMerge(@{@"a": @"one"}, @{@"b": @"two"}), @"should combine");
}

- (void)testOverwrite {
    id src = @{@"a": @"one"};
    XCTAssertEqualObjects(src, BSGDictMerge(src, @{@"a": @"two"}), @"should overwrite");
}

- (void)testSrcEmpty {
    id dst = @{@"b": @"two"};
    XCTAssertEqualObjects(dst, BSGDictMerge(@{}, dst), @"should copy");
}

- (void)testDstEmpty {
    id src = @{@"a": @"one"};
    XCTAssertEqualObjects(src, BSGDictMerge(src, @{}), @"should copy");
}

- (void)testDstNil {
    id src = @{@"a": @"one"};
    XCTAssertEqualObjects(src, BSGDictMerge(src, nil), @"should copy");
}

- (void)testSrcDict {
    id src = @{@"a": @{@"x": @"blah"}};
    XCTAssertEqualObjects(src, BSGDictMerge(src, @{@"a": @"two"}), @"should not overwrite");
}

- (void)testDstDict {
    id src = @{@"a": @"one"};
    XCTAssertEqualObjects(src, BSGDictMerge(src, @{@"a": @{@"x": @"blah"}}), @"should not overwrite");
}

- (void)testSrcDstDict {
    id src = @{@"a": @{@"x": @"blah"}};
    id dst = @{@"a": @{@"y": @"something"}};
    NSDictionary* expected = @{@"a": @{@"x": @"blah",
                                       @"y": @"something"}};
    XCTAssertEqualObjects(expected, BSGDictMerge(src, dst), @"should combine");
}

// MARK: BSGJSONDictionary

- (void)testBSGJSONDictionary {
    XCTAssertNil(BSGJSONDictionary(nil));
    
    id validDictionary = @{
        @"name": @"foobar",
        @"count": @1,
        @"userInfo": @{@"extra": @"hello"}
    };
    XCTAssertEqualObjects(BSGJSONDictionary(validDictionary), validDictionary);
    
    id invalidDictionary = @{
        @123: @"invalid key; should be ignored",
        @[]: @"this is backwards",
        @{}: @""
    };
    XCTAssertEqualObjects(BSGJSONDictionary(invalidDictionary), @{});
    
    id mixedDictionary = @{
        @"count": @42,
        @"dict": @{@"object": [[BugsnagCollectionsTests_DummyObject alloc] init]},
        @123: @"invalid key; should be ignored"
    };
    XCTAssertEqualObjects(BSGJSONDictionary(mixedDictionary),
                          (@{@"count": @42,
                             @"dict": @{@"object": @"Dummy object"}}));
}

@end

// MARK: -

@implementation BugsnagCollectionsTests_DummyObject

- (NSString *)description {
    return @"Dummy object";
}

@end
