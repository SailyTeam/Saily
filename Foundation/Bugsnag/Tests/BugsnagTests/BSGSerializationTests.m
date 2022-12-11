//
//  BSGSerializationTests.m
//  Bugsnag
//
//  Created by Nick Dowell on 28/07/2022.
//  Copyright © 2022 Bugsnag Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BSGSerialization.h"

@interface BSGSerializationTests : XCTestCase

@end

@implementation BSGSerializationTests

- (void)testSanitizeObject {
    XCTAssertEqualObjects(BSGSanitizeObject(@""), @"");
    XCTAssertEqualObjects(BSGSanitizeObject(@42), @42);
    XCTAssertEqualObjects(BSGSanitizeObject(@[@42]), @[@42]);
    XCTAssertEqualObjects(BSGSanitizeObject(@[self]), @[]);
    XCTAssertEqualObjects(BSGSanitizeObject(@{@"a": @"b"}), @{@"a": @"b"});
    XCTAssertEqualObjects(BSGSanitizeObject(@{@"self": self}), @{});
    XCTAssertNil(BSGSanitizeObject(@(INFINITY)));
    XCTAssertNil(BSGSanitizeObject(@(NAN)));
    XCTAssertNil(BSGSanitizeObject([NSDate date]));
    XCTAssertNil(BSGSanitizeObject([NSDecimalNumber notANumber]));
    XCTAssertNil(BSGSanitizeObject([NSNull null]));
    XCTAssertNil(BSGSanitizeObject(self));
}

- (void)testTruncateString {
    BSGTruncateContext context = {0};
    
    context.maxLength = NSUIntegerMax;
    XCTAssertEqualObjects(BSGTruncateString(&context, @"Hello, world!"), @"Hello, world!");
    XCTAssertEqual(context.strings, 0);
    XCTAssertEqual(context.length, 0);
    
    context.maxLength = 5;
    XCTAssertEqualObjects(BSGTruncateString(&context, @"Hello, world!"), @"Hello"
                          "\n***8 CHARS TRUNCATED***");
    XCTAssertEqual(context.strings, 1);
    XCTAssertEqual(context.length, 8);
    
    // Verify that emoji (composed character sequences) are not partially truncated
    // Note when adding tests that older OSes like iOS 9 don't understand more recently
    // added emoji like 🏴󠁧󠁢󠁥󠁮󠁧󠁿 and 👩🏾‍🚀 and therefore won't be able to avoid slicing them.
    
    context.maxLength = 10;
    XCTAssertEqualObjects(BSGTruncateString(&context, @"Emoji: 👍🏾"), @"Emoji: "
                          "\n***4 CHARS TRUNCATED***");
    XCTAssertEqual(context.strings, 2);
    XCTAssertEqual(context.length, 12);
}

- (void)testTruncateStringsWithString {
    BSGTruncateContext context = (BSGTruncateContext){.maxLength = 3};
    XCTAssertEqualObjects(BSGTruncateStrings(&context, @"foo bar"), @"foo"
                          "\n***4 CHARS TRUNCATED***");
    XCTAssertEqual(context.strings, 1);
    XCTAssertEqual(context.length, 4);
}

- (void)testTruncateStringsWithArray {
    BSGTruncateContext context = (BSGTruncateContext){.maxLength = 3};
    XCTAssertEqualObjects(BSGTruncateStrings(&context, @[@"foo bar"]),
                          @[@"foo"
                            "\n***4 CHARS TRUNCATED***"]);
    XCTAssertEqual(context.strings, 1);
    XCTAssertEqual(context.length, 4);
}

- (void)testTruncateStringsWithObject {
    BSGTruncateContext context = (BSGTruncateContext){.maxLength = 3};
    XCTAssertEqualObjects(BSGTruncateStrings(&context, @{@"name": @"foo bar"}),
                          @{@"name": @"foo"
                            "\n***4 CHARS TRUNCATED***"});
    XCTAssertEqual(context.strings, 1);
    XCTAssertEqual(context.length, 4);
}

- (void)testTruncateStringsWithNestedObjects {
    BSGTruncateContext context = (BSGTruncateContext){.maxLength = 3};
    XCTAssertEqualObjects(BSGTruncateStrings(&context, (@{@"one": @{@"key": @"foo bar"},
                                                          @"two": @{@"foo": @"Baa, Baa, Black Sheep"}})),
                          (@{@"one": @{@"key": @"foo"
                                       "\n***4 CHARS TRUNCATED***"},
                             @"two": @{@"foo": @"Baa"
                                       "\n***18 CHARS TRUNCATED***"}}));
    XCTAssertEqual(context.strings, 2);
    XCTAssertEqual(context.length, 22);
}

@end
