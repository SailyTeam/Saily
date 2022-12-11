//
//  BSGFeatureFlagStoreTests.m
//  Bugsnag
//
//  Created by Nick Dowell on 11/11/2021.
//  Copyright © 2021 Bugsnag Inc. All rights reserved.
//

#import "BSGFeatureFlagStore.h"

#import <XCTest/XCTest.h>

@interface BSGFeatureFlagStoreTests : XCTestCase

@end

@implementation BSGFeatureFlagStoreTests

- (void)test {
    BSGFeatureFlagStore *store = [[BSGFeatureFlagStore alloc] init];
    XCTAssertEqualObjects(BSGFeatureFlagStoreToJSON(store), @[]);

    BSGFeatureFlagStoreAddFeatureFlag(store, @"featureC", @"checked");
    XCTAssertEqualObjects(BSGFeatureFlagStoreToJSON(store),
                          (@[@{@"featureFlag": @"featureC", @"variant": @"checked"}]));
    
    BSGFeatureFlagStoreAddFeatureFlag(store, @"featureA", @"enabled");
    XCTAssertEqualObjects(BSGFeatureFlagStoreToJSON(store),
                          (@[
                            @{@"featureFlag": @"featureC", @"variant": @"checked"},
                            @{@"featureFlag": @"featureA", @"variant": @"enabled"}
                          ]));

    BSGFeatureFlagStoreAddFeatureFlag(store, @"featureB", nil);
    XCTAssertEqualObjects(BSGFeatureFlagStoreToJSON(store),
                          (@[
                            @{@"featureFlag": @"featureC", @"variant": @"checked"},
                            @{@"featureFlag": @"featureA", @"variant": @"enabled"},
                            @{@"featureFlag": @"featureB"}
                          ]));


    BSGFeatureFlagStoreAddFeatureFlags(store, @[[BugsnagFeatureFlag flagWithName:@"featureA"]]);
    XCTAssertEqualObjects(BSGFeatureFlagStoreToJSON(store),
                          (@[
                            @{@"featureFlag": @"featureC", @"variant": @"checked"},
                            @{@"featureFlag": @"featureA"},
                            @{@"featureFlag": @"featureB"},
                          ]));

    XCTAssertEqualObjects(BSGFeatureFlagStoreToJSON(BSGFeatureFlagStoreFromJSON(BSGFeatureFlagStoreToJSON(store))),
                          BSGFeatureFlagStoreToJSON(store));
    
    BSGFeatureFlagStoreClear(store, @"featureB");
    XCTAssertEqualObjects(BSGFeatureFlagStoreToJSON(store),
                          (@[
                            @{@"featureFlag": @"featureC", @"variant": @"checked"},
                            @{@"featureFlag": @"featureA"}
                          ]));

    BSGFeatureFlagStoreClear(store, nil);
    XCTAssertEqualObjects(BSGFeatureFlagStoreToJSON(store), @[]);
}

- (void)testAddRemoveMany {
    // Tests that rebuildIfTooManyHoles works as expected

    BSGFeatureFlagStore *store = [[BSGFeatureFlagStore alloc] init];

    BSGFeatureFlagStoreAddFeatureFlag(store, @"blah", @"testing");
    for (int j = 0; j < 10; j++) {
        for (int i = 0; i < 1000; i++) {
            NSString *name = [NSString stringWithFormat:@"%d-%d", j, i];
            BSGFeatureFlagStoreAddFeatureFlag(store, name, nil);
            if (i < 999) {
                BSGFeatureFlagStoreClear(store, name);
            }
        }
    }

    XCTAssertEqualObjects(BSGFeatureFlagStoreToJSON(store),
                          (@[
                            @{@"featureFlag": @"blah", @"variant": @"testing"},
                            @{@"featureFlag": @"0-999"},
                            @{@"featureFlag": @"1-999"},
                            @{@"featureFlag": @"2-999"},
                            @{@"featureFlag": @"3-999"},
                            @{@"featureFlag": @"4-999"},
                            @{@"featureFlag": @"5-999"},
                            @{@"featureFlag": @"6-999"},
                            @{@"featureFlag": @"7-999"},
                            @{@"featureFlag": @"8-999"},
                            @{@"featureFlag": @"9-999"},
                          ]));
}

- (void)testAddFeatureFlagPerformance {
    BSGFeatureFlagStore *store = [[BSGFeatureFlagStore alloc] init];

    __auto_type block = ^{
        for (int i = 0; i < 1000; i++) {
            NSString *name = [NSString stringWithFormat:@"%d", i];
            BSGFeatureFlagStoreAddFeatureFlag(store, name, nil);
        }
    };

    block();

    [self measureBlock:block];
}

- (void)testDictionaryPerformance {
    // For comparision to show the best performance possible

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    __auto_type block = ^{
        for (int i = 0; i < 1000; i++) {
            NSString *name = [NSString stringWithFormat:@"%d", i];
            [dictionary setObject:[NSNull null] forKey:name];
        }
    };

    block();

    [self measureBlock:block];
}

@end
