//
// RFC3339DateTool_Tests.m
//
// Copyright (c) 2010 Karl Stenerud. All rights reserved.
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
#import "BSG_RFC3339DateTool.h"


@interface RFC3339DateTool_Tests : XCTestCase @end


@implementation RFC3339DateTool_Tests

- (NSDate *)newDateWithYear:(int) year month:(int)month day:(int)day hour:(int)hour minute:(int)minute second:(int)second nano:(int)nano tz:(NSString *)tz {
    NSDateComponents* comps = [[NSDateComponents alloc]init];
    comps.year = year;
    comps.month = month;
    comps.day = day;
    comps.hour = hour;
    comps.minute = minute;
    comps.second = second;
    comps.nanosecond = nano;
    comps.timeZone = [NSTimeZone timeZoneWithName:tz];
    NSCalendar* calendar = [NSCalendar currentCalendar];
    return [calendar dateFromComponents:comps];
}

- (void)assertString:(NSString*)asString isEquivalentToString:(NSString *)encodedString andYear:(int) year month:(int)month day:(int)day hour:(int)hour minute:(int)minute second:(int)second nano:(int)nano tz:(NSString *)tz {
    NSDate *expectedDate = [self newDateWithYear:year month:month day:day hour:hour minute:minute second:second nano:nano tz:tz];
    NSDate *actualDate = [BSG_RFC3339DateTool dateFromString:asString];
    NSString *actualString = [BSG_RFC3339DateTool stringFromDate:expectedDate];
    XCTAssertEqualObjects(encodedString, actualString);
    NSString *expectedInterval = [NSString stringWithFormat:@"%f", expectedDate.timeIntervalSince1970];
    NSString *actualInterval = [NSString stringWithFormat:@"%f", actualDate.timeIntervalSince1970];
    XCTAssertEqualObjects(expectedInterval, actualInterval);
}

- (void)testLegacyFormats {
    [self assertString:@"2020-05-14T11:41:20.123Z" isEquivalentToString:@"2020-05-14T11:41:20.123Z" andYear:2020 month:5 day:14 hour:11 minute:41 second:20 nano:123000000 tz:@"UTC"];
    [self assertString:@"2020-05-14T11:41:20Z" isEquivalentToString:@"2020-05-14T11:41:20.000Z" andYear:2020 month:5 day:14 hour:11 minute:41 second:20 nano:0 tz:@"UTC"];
    [self assertString:@"2020-05-14T11:41:20+000" isEquivalentToString:@"2020-05-14T11:41:20.000Z" andYear:2020 month:5 day:14 hour:11 minute:41 second:20 nano:0 tz:@"UTC"];
    [self assertString:@"2020-05-14T12:41:20+100" isEquivalentToString:@"2020-05-14T11:41:20.000Z" andYear:2020 month:5 day:14 hour:11 minute:41 second:20 nano:0 tz:@"UTC"];
}

- (NSDate*) gmtDateWithYear:(int) year
                      month:(int) month
                        day:(int) day
                       hour:(int) hour
                     minute:(int) minute
                     second:(int) second
{
    NSDateComponents* components = [[NSDateComponents alloc] init];
    components.year = year;
    components.month = month;
    components.day = day;
    components.hour = hour;
    components.minute = minute;
    components.second = second;
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    [calendar setTimeZone:(NSTimeZone* _Nonnull)[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    return [calendar dateFromComponents:components];
}

- (void) testStringFromDate
{
    NSDate* date = [self gmtDateWithYear:2000 month:1 day:2 hour:3 minute:4 second:5];
    NSString* expected = @"2000-01-02T03:04:05.000Z";
    NSString* actual = [BSG_RFC3339DateTool stringFromDate:date];

    XCTAssertEqualObjects(actual, expected, @"");
}

- (void) testDateFromString
{
    NSDate* expected = [self gmtDateWithYear:2000 month:1 day:2 hour:3 minute:4 second:5];
    NSDate* actual = [BSG_RFC3339DateTool dateFromString:@"2000-01-02T03:04:05Z"];

    XCTAssertEqualObjects(actual, expected, @"");
}

- (void) testDateFromStringWithTimezone
{
    NSDate* expected = [self gmtDateWithYear:2000 month:1 day:2 hour:3 minute:4 second:5];
    NSDate* actual = [BSG_RFC3339DateTool dateFromString:@"2000-01-02T03:04:05+0000"];

    XCTAssertEqualObjects(actual, expected, @"");
}

- (void) testDateFromStringWithTimezonePlus2
{
    NSDate* expected = [self gmtDateWithYear:2000 month:1 day:2 hour:1 minute:4 second:5];
    NSDate* actual = [BSG_RFC3339DateTool dateFromString:@"2000-01-02T03:04:05+0200"];

    XCTAssertEqualObjects(actual, expected, @"");
    
    // Convert back again to verify overall effect
    XCTAssertEqualObjects([BSG_RFC3339DateTool stringFromDate:actual], @"2000-01-02T01:04:05.000Z");
}

- (void) testStringFromUnixTimestamp
{
    NSDate* date = [self gmtDateWithYear:2000 month:1 day:2 hour:3 minute:4 second:5];
    NSString* expected = @"2000-01-02T03:04:05.000Z";
    NSString* actual = [BSG_RFC3339DateTool stringFromUNIXTimestamp:(unsigned long long)[date timeIntervalSince1970]];

    XCTAssertEqualObjects(actual, expected, @"");
}

@end
