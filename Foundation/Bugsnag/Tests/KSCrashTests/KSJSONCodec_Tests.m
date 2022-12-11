//
//  KSJSONCodec_Tests.m
//
//  Created by Karl Stenerud on 2012-01-08.
//
//  Copyright (c) 2012 Karl Stenerud. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall remain in place
// in this source code.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//


#import <XCTest/XCTest.h>

#import "BSG_KSJSONCodec.h"


@interface KSJSONCodec_Tests : XCTestCase @end


@implementation KSJSONCodec_Tests

static int AddData(const char *data, size_t length, void *userData) {
    [(__bridge NSMutableData *)userData appendBytes:data length:length];
    return BSG_KSJSON_OK;
}

static NSString *JSONString(void (^ block)(BSG_KSJSONEncodeContext *context)) {
    NSMutableData *data = [NSMutableData data];
    BSG_KSJSONEncodeContext context = {0};
    bsg_ksjsonbeginEncode(&context, false, AddData, (__bridge void *)data);
    block(&context);
    bsg_ksjsonendEncode(&context);
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (void)testSerializeDeserializeArrayEmpty
{
    NSError* error = nil;
    NSString* expected = @"[]";
    id original = [NSArray array];
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginArray(context, NULL);
    });
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeArrayNull
{
    NSError* error = nil;
    NSString* expected = @"[null]";
    id original = @[[NSNull null]];
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginArray(context, NULL);
        bsg_ksjsonaddNullElement(context, NULL);
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeArrayBoolTrue
{
    NSError* error = nil;
    NSString* expected = @"[true]";
    id original = @[@YES];
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginArray(context, NULL);
        bsg_ksjsonaddBooleanElement(context, NULL, true);
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeArrayBoolFalse
{
    NSError* error = nil;
    NSString* expected = @"[false]";
    id original = @[@NO];
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginArray(context, NULL);
        bsg_ksjsonaddBooleanElement(context, NULL, false);
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

//- (void) testSerializeDeserializeArrayInteger
//{
//    NSError* error = (NSError*)self;
//    NSString* expected = @"[1]";
//    id original = @[@1];
//    NSString* jsonString = toString([BSG_KSJSONCodec encode:original
//                                                options:BSG_KSJSONEncodeOptionSorted
//                                                  error:&error]);
//    XCTAssertNotNil(jsonString, @"");
//    XCTAssertNil(error, @"");
//    XCTAssertEqualObjects(jsonString, expected, @"");
//    id result = [BSG_KSJSONCodec decode:toData(jsonString) error:&error];
//    XCTAssertNotNil(result, @"");
//    XCTAssertNil(error, @"");
//    XCTAssertEqualObjects(result, original, @"");
//}

- (void) testSerializeDeserializeArrayFloat
{
    NSError* error = nil;
    NSString* expected = @"[-2e-1]";
    id original = @[@(-0.2f)];
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginArray(context, NULL);
        bsg_ksjsonaddFloatingPointElement(context, NULL, -0.2f);
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqual([[result objectAtIndex:0] floatValue], -0.2f, @"");
    // This always fails on NSNumber filled with float.
    //XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeArrayFloat2
{
    NSError* error = nil;
    NSString* expected = @"[-2e-15]";
    id original = @[@(-2e-15f)];
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginArray(context, NULL);
        bsg_ksjsonaddFloatingPointElement(context, NULL, -2e-15f);
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqual([[result objectAtIndex:0] floatValue], -2e-15f, @"");
    // This always fails on NSNumber filled with float.
    //XCTAssertEqualObjects(result, original, @"");
}

- (void)testSerializeDeserializeArrayString
{
    NSError* error = nil;
    NSString* expected = @"[\"One\"]";
    id original = @[@"One"];
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginArray(context, NULL);
        bsg_ksjsonaddStringElement(context, NULL, "One", 3);
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void)testSerializeDeserializeArrayStringIntl
{
    NSError* error = nil;
    NSString* expected = @"[\"テスト\"]";
    id original = @[@"テスト"];
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginArray(context, NULL);
        const char *value = "テスト";
        bsg_ksjsonaddStringElement(context, NULL, value, strlen(value));
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void)testSerializeDeserializeArrayMultipleEntries
{
    NSError* error = nil;
    NSString* expected = @"[\"One\",1000,true]";
    id original = @[@"One",
            @1000,
            @YES];
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginArray(context, NULL);
        bsg_ksjsonaddStringElement(context, NULL, "One", 3);
        bsg_ksjsonaddIntegerElement(context, NULL, 1000);
        bsg_ksjsonaddBooleanElement(context, NULL, true);
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void)testSerializeDeserializeArrayWithArray
{
    NSError* error = nil;
    NSString* expected = @"[[]]";
    id original = @[[NSArray array]];
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginArray(context, NULL);
        bsg_ksjsonbeginArray(context, NULL);
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void)testSerializeDeserializeArrayWithArray2
{
    NSError* error = nil;
    NSString* expected = @"[[\"Blah\"]]";
    id original = @[@[@"Blah"]];
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginArray(context, NULL);
        bsg_ksjsonbeginArray(context, NULL);
        bsg_ksjsonaddStringElement(context, NULL, "Blah", 4);
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void)testSerializeDeserializeArrayWithDictionary
{
    NSError* error = nil;
    NSString* expected = @"[{}]";
    id original = @[[NSDictionary dictionary]];
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginArray(context, NULL);
        bsg_ksjsonbeginObject(context, NULL);
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void)testSerializeDeserializeArrayWithDictionary2
{
    NSError* error = nil;
    NSString* expected = @"[{\"Blah\":true}]";
    id original = @[@{@"Blah": @YES}];
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginArray(context, NULL);
        bsg_ksjsonbeginObject(context, NULL);
        bsg_ksjsonaddBooleanElement(context, "Blah", true);
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}


- (void)testSerializeDeserializeDictionaryEmpty
{
    NSError* error = nil;
    NSString* expected = @"{}";
    id original = [NSDictionary dictionary];
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginObject(context, NULL);
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeDictionaryNull
{
    NSError* error = nil;
    NSString* expected = @"{\"One\":null}";
    id original = @{@"One": [NSNull null]};
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginObject(context, NULL);
        bsg_ksjsonaddNullElement(context, "One");
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeDictionaryBoolTrue
{
    NSError* error = nil;
    NSString* expected = @"{\"One\":true}";
    id original = @{@"One": @YES};
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginObject(context, NULL);
        bsg_ksjsonaddBooleanElement(context, "One", true);
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeDictionaryBoolFalse
{
    NSError* error = nil;
    NSString* expected = @"{\"One\":false}";
    id original = @{@"One": @NO};
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginObject(context, NULL);
        bsg_ksjsonaddBooleanElement(context, "One", false);
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeDictionaryInteger
{
    NSError* error = nil;
    NSString* expected = @"{\"One\":1}";
    id original = @{@"One": @1};
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginObject(context, NULL);
        bsg_ksjsonaddIntegerElement(context, "One", 1);
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeDictionaryFloat
{
    NSError* error = nil;
    NSString* expected = @"{\"One\":5.4918e+1}";
    id original = @{@"One": @54.918F};
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginObject(context, NULL);
        bsg_ksjsonaddFloatingPointElement(context, "One", 54.918F);
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqual([((NSDictionary *) result)[@"One"] floatValue], 54.918f, @"");
    // This always fails on NSNumber filled with float.
    //XCTAssertEqualObjects(result, original, @"");
}

- (void) assertInt:(int64_t) value convertsTo:(NSString *)str
{
    NSString* expected = [NSString stringWithFormat:@"{\"One\":%@}", str];
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginObject(context, NULL);
        bsg_ksjsonaddIntegerElement(context, "One", value);
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
}

- (void) assertDouble:(double) value convertsTo:(NSString *)str
{
    NSString* expected = [NSString stringWithFormat:@"{\"One\":%@}", str];
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginObject(context, NULL);
        bsg_ksjsonaddFloatingPointElement(context, "One", value);
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
}

- (void) testIntConversions
{
    [self assertInt:0 convertsTo:@"0"];
    [self assertInt:1 convertsTo:@"1"];
    [self assertInt:-1 convertsTo:@"-1"];
    [self assertInt:127 convertsTo:@"127"];
    [self assertInt:-127 convertsTo:@"-127"];
    [self assertInt:128 convertsTo:@"128"];
    [self assertInt:-128 convertsTo:@"-128"];
    [self assertInt:255 convertsTo:@"255"];
    [self assertInt:-255 convertsTo:@"-255"];
    [self assertInt:256 convertsTo:@"256"];
    [self assertInt:-256 convertsTo:@"-256"];
    [self assertInt:65535 convertsTo:@"65535"];
    [self assertInt:-65535 convertsTo:@"-65535"];
    [self assertInt:65536 convertsTo:@"65536"];
    [self assertInt:-65536 convertsTo:@"-65536"];
    [self assertInt:4294967295 convertsTo:@"4294967295"];
    [self assertInt:-4294967295 convertsTo:@"-4294967295"];
    [self assertInt:4294967296 convertsTo:@"4294967296"];
    [self assertInt:-4294967296 convertsTo:@"-4294967296"];
    [self assertInt:INT64_MAX convertsTo:@"9223372036854775807"];
    [self assertInt:INT64_MIN convertsTo:@"-9223372036854775808"];
}

- (void) testFloatConversions
{
    [self assertDouble:100000000 convertsTo:@"1e+8"];
    [self assertDouble:10000000 convertsTo:@"1e+7"];
    [self assertDouble:1000000 convertsTo:@"1e+6"];
    [self assertDouble:100000 convertsTo:@"1e+5"];
    [self assertDouble:10000 convertsTo:@"1e+4"];
    [self assertDouble:1000 convertsTo:@"1e+3"];
    [self assertDouble:100 convertsTo:@"1e+2"];
    [self assertDouble:10 convertsTo:@"1e+1"];
    [self assertDouble:1 convertsTo:@"1"];
    [self assertDouble:0.1 convertsTo:@"1e-1"];
    [self assertDouble:0.01 convertsTo:@"1e-2"];
    [self assertDouble:0.001 convertsTo:@"1e-3"];
    [self assertDouble:0.0001 convertsTo:@"1e-4"];
    [self assertDouble:0.00001 convertsTo:@"1e-5"];
    [self assertDouble:0.000001 convertsTo:@"1e-6"];
    [self assertDouble:0.0000001 convertsTo:@"1e-7"];
    [self assertDouble:0.00000001 convertsTo:@"1e-8"];

    [self assertDouble:1.2 convertsTo:@"1.2"];
    [self assertDouble:0.12 convertsTo:@"1.2e-1"];
    [self assertDouble:12 convertsTo:@"1.2e+1"];
    [self assertDouble:9.5932455 convertsTo:@"9.593246"];
    [self assertDouble:1.456e+80 convertsTo:@"1.456e+80"];
    [self assertDouble:1.456e-80 convertsTo:@"1.456e-80"];
    [self assertDouble:-1.456e+80 convertsTo:@"-1.456e+80"];
    [self assertDouble:-1.456e-80 convertsTo:@"-1.456e-80"];
    [self assertDouble:1.5e-10 convertsTo:@"1.5e-10"];
    [self assertDouble:123456789123456789 convertsTo:@"1.234568e+17"];

    [self assertDouble:NAN convertsTo:@"nan"];
    [self assertDouble:INFINITY convertsTo:@"inf"];
    [self assertDouble:-INFINITY convertsTo:@"-inf"];

    // Check stepping over the 7 significant digit limit
    [self assertDouble:9999999 convertsTo:@"9.999999e+6"];
    [self assertDouble:99999994 convertsTo:@"9.999999e+7"];
    [self assertDouble:99999995 convertsTo:@"1e+8"];
    [self assertDouble:99999999 convertsTo:@"1e+8"];
}

- (void) testSerializeDeserializeDictionaryFloat2
{
    NSError* error = nil;
    NSString* expected = @"{\"One\":5e+20}";
    id original = @{@"One": @5e20F};
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginObject(context, NULL);
        bsg_ksjsonaddFloatingPointElement(context, "One", 5e20F);
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqual([((NSDictionary *) result)[@"One"] floatValue], 5e20f, @"");
    // This always fails on NSNumber filled with float.
    //XCTAssertEqualObjects(result, original, @"");
}

- (void)testSerializeDeserializeDictionaryString
{
    NSError* error = nil;
    NSString* expected = @"{\"One\":\"Value\"}";
    id original = @{@"One": @"Value"};
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginObject(context, NULL);
        bsg_ksjsonaddStringElement(context, "One", "Value", 5);
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void)testSerializeDeserializeDictionaryMultipleEntries
{
    NSError* error = nil;
    NSString* expected = @"{\"One\":\"Value\",\"Three\":true,\"Two\":1000}";
    id original = @{@"One": @"Value",
            @"Two": @1000,
            @"Three": @YES};
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginObject(context, NULL);
        bsg_ksjsonaddStringElement(context, "One", "Value", 5);
        bsg_ksjsonaddBooleanElement(context, "Three", true);
        bsg_ksjsonaddIntegerElement(context, "Two", 1000);
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void)testSerializeDeserializeDictionaryWithDictionary
{
    NSError* error = nil;
    NSString* expected = @"{\"One\":{}}";
    id original = @{@"One": [NSDictionary dictionary]};
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginObject(context, NULL);
        bsg_ksjsonbeginObject(context, "One");
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void)testSerializeDeserializeDictionaryWithDictionary2
{
    NSError* error = nil;
    NSString* expected = @"{\"One\":{\"Blah\":1}}";
    id original = @{@"One": @{@"Blah": @1}};
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginObject(context, NULL);
        bsg_ksjsonbeginObject(context, "One");
        bsg_ksjsonaddIntegerElement(context, "Blah", 1);
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void)testSerializeDeserializeDictionaryWithArray
{
    NSError* error = nil;
    NSString* expected = @"{\"Key\":[]}";
    id original = @{@"Key": [NSArray array]};
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginObject(context, NULL);
        bsg_ksjsonbeginArray(context, "Key");
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void)testSerializeDeserializeDictionaryWithArray2
{
    NSError* error = nil;
    NSString* expected = @"{\"Blah\":[true]}";
    id original = @{@"Blah": @[@YES]};
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginObject(context, NULL);
        bsg_ksjsonbeginArray(context, "Blah");
        bsg_ksjsonaddBooleanElement(context, NULL, true);
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void)testSerializeDeserializeBigDictionary
{
    NSError* error = nil;
    id original = @{@"0": @"0",
            @"1": @"1",
            @"2": @"2",
            @"3": @"3",
            @"4": @"4",
            @"5": @"5",
            @"6": @"6",
            @"7": @"7",
            @"8": @"8",
            @"9": @"9",
            @"10": @"10",
            @"11": @"11",
            @"12": @"12",
            @"13": @"13",
            @"14": @"14",
            @"15": @"15",
            @"16": @"16",
            @"17": @"17",
            @"18": @"18",
            @"19": @"19",
            @"20": @"20",
            @"21": @"21",
            @"22": @"22",
            @"23": @"23",
            @"24": @"24",
            @"25": @"25",
            @"26": @"26",
            @"27": @"27",
            @"28": @"28",
            @"29": @"29",
            @"30": @"30",
            @"31": @"31",
            @"32": @"32",
            @"33": @"33",
            @"34": @"34",
            @"35": @"35",
            @"36": @"36",
            @"37": @"37",
            @"38": @"38",
            @"39": @"39",
            @"40": @"40",
            @"41": @"41",
            @"42": @"42",
            @"43": @"43",
            @"44": @"44",
            @"45": @"45",
            @"46": @"46",
            @"47": @"47",
            @"48": @"48",
            @"49": @"49",
            @"50": @"50",
            @"51": @"51",
            @"52": @"52",
            @"53": @"53",
            @"54": @"54",
            @"55": @"55",
            @"56": @"56",
            @"57": @"57",
            @"58": @"58",
            @"59": @"59"};
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginObject(context, NULL);
        for (NSString *key in original) {
            const char *value = [[original objectForKey:key] UTF8String];
            bsg_ksjsonaddStringElement(context, key.UTF8String, value, strlen(value));
        }
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeControlChars2
{
    NSError* error = nil;
    NSString* expected = @"[\"\\b\\f\\n\\r\\t\"]";
    id original = @[@"\b\f\n\r\t"];
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginArray(context, NULL);
        const char *value = "\b\f\n\r\t"; 
        bsg_ksjsonaddStringElement(context, NULL, value, strlen(value));
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeControlChars3
{
    NSError* error = nil;
    NSString* expected = @"[\"Testing\\b escape \\f chars\\n\"]";
    id original = @[@"Testing\b escape \f chars\n"];
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginArray(context, NULL);
        const char *value = "Testing\b escape \f chars\n"; 
        bsg_ksjsonaddStringElement(context, NULL, value, strlen(value));
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeEscapedChars
{
    NSError* error = nil;
    NSString* expected = @"[\"\\\"\\\\\"]";
    id original = @[@"\"\\"];
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginArray(context, NULL);
        const char *value = "\"\\"; 
        bsg_ksjsonaddStringElement(context, NULL, value, strlen(value));
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeFloat
{
    NSError* error = nil;
    NSString* expected = @"[1.2]";
    id original = @[@1.2F];
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginArray(context, NULL);
        bsg_ksjsonaddFloatingPointElement(context, NULL, 1.2F);
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertTrue([[result objectAtIndex:0] floatValue] ==  [[original objectAtIndex:0] floatValue], @"");
}

- (void) testSerializeDeserializeDouble
{
    NSError* error = nil;
    NSString* expected = @"[1e-1]";
    id original = @[@0.1];
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginArray(context, NULL);
        bsg_ksjsonaddFloatingPointElement(context, NULL, 0.1);
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertTrue([[result objectAtIndex:0] floatValue] ==  [[original objectAtIndex:0] floatValue], @"");
}

- (void) testSerializeDeserializeChar
{
    NSError* error = nil;
    NSString* expected = @"[20]";
    id original = @[@20];
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginArray(context, NULL);
        bsg_ksjsonaddIntegerElement(context, NULL, 20);
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeShort
{
    NSError* error = nil;
    NSString* expected = @"[2000]";
    id original = @[@2000];
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginArray(context, NULL);
        bsg_ksjsonaddIntegerElement(context, NULL, 2000);
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeLong
{
    NSError* error = nil;
    NSString* expected = @"[2000000000]";
    id original = @[@2000000000];
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginArray(context, NULL);
        bsg_ksjsonaddIntegerElement(context, NULL, 2000000000);
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeLongLong
{
    NSError* error = nil;
    NSString* expected = @"[200000000000]";
    id original = @[@200000000000];
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginArray(context, NULL);
        bsg_ksjsonaddIntegerElement(context, NULL, 200000000000);
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeNegative
{
    NSError* error = nil;
    NSString* expected = @"[-2000]";
    id original = @[@(-2000)];
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginArray(context, NULL);
        bsg_ksjsonaddIntegerElement(context, NULL, -2000);
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserialize0
{
    NSError* error = nil;
    NSString* expected = @"[0]";
    id original = @[@0];
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginArray(context, NULL);
        bsg_ksjsonaddIntegerElement(context, NULL, 0);
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeEmptyString
{
    NSError* error = nil;
    NSString* string = @"";
    NSString* expected = @"[\"\"]";
    id original = @[string];
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginArray(context, NULL);
        bsg_ksjsonaddStringElement(context, NULL, "", 0);
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeBigString
{
    NSError* error = nil;

    int length = 500;
    NSMutableString* string = [NSMutableString stringWithCapacity:(NSUInteger)length];
    for(int i = 0; i < length; i++)
    {
        [string appendFormat:@"%d", i%10];
    }

    NSString* expected = [NSString stringWithFormat:@"[\"%@\"]", string];
    id original = @[string];
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginArray(context, NULL);
        const char *value = string.UTF8String;
        bsg_ksjsonaddStringElement(context, NULL, value, strlen(value));
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeHugeString
{
    NSError* error = nil;
    char buff[100000];
    memset(buff, '2', sizeof(buff));
    buff[sizeof(buff)-1] = 0;
    NSString* string = [NSString stringWithCString:buff encoding:NSUTF8StringEncoding];

    id original = @[string];
    NSString* jsonString = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginArray(context, NULL);
        const char *value = string.UTF8String;
        bsg_ksjsonaddStringElement(context, NULL, value, strlen(value));
    });
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    id result = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDictionaryBadCharacter
{
    NSString* result = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginObject(context, NULL);
        bsg_ksjsonaddStringElement(context, "blah\x01blah", "blah", 4);
    });
    XCTAssertEqualObjects(result, @"{\"blah\\u001Blah\":\"blah\"}");
}

- (void) testSerializeArrayBadCharacter
{
    NSString* result = JSONString(^(BSG_KSJSONEncodeContext *context) {
        bsg_ksjsonbeginArray(context, NULL);
        const char *value = "test\x01ing";
        bsg_ksjsonaddStringElement(context, NULL, value, strlen(value));
    });
    XCTAssertEqualObjects(result, @"[\"test\\u0001ing\"]");
}

- (void) testSerializeLongString
{
    // Long string with a leading escaped character to ensure it exceeds the length
    // of the buffer in one iteration
    id source = @"\"12345678901234567890123456789012345678901234567890"
                @"12345678901234567890123456789012345678901234567890"
                @"12345678901234567890123456789012345678901234567890"
                @"12345678901234567890123456789012345678901234567890"
                @"12345678901234567890123456789012345678901234567890"
                @"12345678901234567890123456789012345678901234567890"
                @"12345678901234567890123456789012345678901234567890"
                @"12345678901234567890123456789012345678901234567890"
                @"12345678901234567890123456789012345678901234567890"
                @"12345678901234567890123456789012345678901234567890"
                @"12345678901234567890123456789012345678901234567890"
                @"12345678901234567890123456789012345678901234567890"
                @"12345678901234567890123456789012345678901234567890"
                @"12345678901234567890123456789012345678901234567890"
                @"12345678901234567890123456789012345678901234567890"
                @"12345678901234567890123456789012345678901234567890"
                @"12345678901234567890123456789012345678901234567890"
                @"12345678901234567890123456789012345678901234567890"
                @"12345678901234567890123456789012345678901234567890"
                @"12345678901234567890123456789012345678901234567890";
    NSString* result = JSONString(^(BSG_KSJSONEncodeContext *context) {
        const char *value = [source UTF8String];
        bsg_ksjsonaddStringElement(context, NULL, value, strlen(value));
    });
    XCTAssertEqualObjects(result, @"\""
                          @"\\\"12345678901234567890123456789012345678901234567890"
                          @"12345678901234567890123456789012345678901234567890"
                          @"12345678901234567890123456789012345678901234567890"
                          @"12345678901234567890123456789012345678901234567890"
                          @"12345678901234567890123456789012345678901234567890"
                          @"12345678901234567890123456789012345678901234567890"
                          @"12345678901234567890123456789012345678901234567890"
                          @"12345678901234567890123456789012345678901234567890"
                          @"12345678901234567890123456789012345678901234567890"
                          @"12345678901234567890123456789012345678901234567890"
                          @"12345678901234567890123456789012345678901234567890"
                          @"12345678901234567890123456789012345678901234567890"
                          @"12345678901234567890123456789012345678901234567890"
                          @"12345678901234567890123456789012345678901234567890"
                          @"12345678901234567890123456789012345678901234567890"
                          @"12345678901234567890123456789012345678901234567890"
                          @"12345678901234567890123456789012345678901234567890"
                          @"12345678901234567890123456789012345678901234567890"
                          @"12345678901234567890123456789012345678901234567890"
                          @"12345678901234567890123456789012345678901234567890"
                          "\"");
}

- (void) testSerializeEscapeLongString
{
    id source = @"\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01"
                @"\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01"
                @"\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01"
                @"\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01"
                @"\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01"
                @"\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01"
                @"\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01"
                @"\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01"
                @"\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01"
                @"\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01";
    NSString* result = JSONString(^(BSG_KSJSONEncodeContext *context) {
        const char *value = [source UTF8String];
        bsg_ksjsonaddStringElement(context, NULL, value, strlen(value));
    });
    XCTAssertEqualObjects(result, @"\"\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001"
                                  @"\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001"
                                  @"\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001"
                                  @"\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001"
                                  @"\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001"
                                  @"\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001"
                                  @"\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001"
                                  @"\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001"
                                  @"\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001"
                                  @"\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\\u0001\"");
}

@end
