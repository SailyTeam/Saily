//
//  BSGJSONSerializationTests.m
//  Bugsnag
//
//  Created by Karl Stenerud on 03.09.20.
//  Copyright © 2020 Bugsnag Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BSGJSONSerialization.h"

@interface BSGJSONSerializationTests : XCTestCase
@end

@implementation BSGJSONSerializationTests

- (void)testBadJSONKey {
    id badDict = @{@123: @"string"};
    NSData* badJSONData = [@"{123=\"test\"}" dataUsingEncoding:NSUTF8StringEncoding];
    id result;
    NSError* error;
    result = BSGJSONDataFromDictionary(badDict, &error);
    XCTAssertNotNil(error);
    XCTAssertNil(result);
    error = nil;
    
    result = BSGJSONDictionaryFromData(badJSONData, 0, &error);
    XCTAssertNotNil(error);
    XCTAssertNil(result);
    error = nil;
}

- (void)testJSONFileSerialization {
    id validJSON = @{@"foo": @"bar"};
    id invalidJSON = @{@"foo": [NSDate date]};
    
    NSString *file = [NSTemporaryDirectory() stringByAppendingPathComponent:@(__PRETTY_FUNCTION__)];
    
    XCTAssertTrue(BSGJSONWriteToFileAtomically(validJSON, file, nil));

    XCTAssertEqualObjects(BSGJSONDictionaryFromFile(file, 0, nil), @{@"foo": @"bar"});
    
    [[NSFileManager defaultManager] removeItemAtPath:file error:nil];
    
    NSError *error = nil;
    XCTAssertFalse(BSGJSONWriteToFileAtomically(invalidJSON, file, &error));
    XCTAssertNotNil(error);
    
    error = nil;
    XCTAssertNil(BSGJSONDictionaryFromFile(file, 0, &error));
    XCTAssertNotNil(error);

    NSString *unwritablePath = @"/System/Library/foobar";
    
    error = nil;
    XCTAssertFalse(BSGJSONWriteToFileAtomically(validJSON, unwritablePath, &error));
    XCTAssertNotNil(error);
    
    error = nil;
    XCTAssertNil(BSGJSONDictionaryFromFile(file, 0, &error));
    XCTAssertNotNil(error);
}

- (void)testExceptionHandling {
    NSError *error = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    XCTAssertNil(BSGJSONDictionaryFromData(nil, 0, &error));
#pragma clang diagnostic pop
    XCTAssertNotNil(error);
    id underlyingError = error.userInfo[NSUnderlyingErrorKey];
    XCTAssert(!underlyingError || [underlyingError isKindOfClass:[NSError class]], @"The value of %@ should be an NSError", NSUnderlyingErrorKey);
}

@end
