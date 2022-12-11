//
//  BSG_KSCrashStringConversionTest.m
//  Bugsnag
//
//  Created by Karl Stenerud on 01.06.22.
//  Copyright © 2022 Bugsnag Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BSG_KSCrashStringConversion.h"

@interface KSCrashStringConversionTests : XCTestCase
@end

#pragma mark -

@implementation KSCrashStringConversionTests

#define TEST_1_ARG(NAME, FUNCTION, ARG, EXPECTED) \
- (void)test##NAME { \
    char buff[1000]; \
    memset(buff, '~', sizeof(buff)); \
    FUNCTION(ARG, buff); \
    buff[sizeof(buff)-1] = 0; \
    XCTAssertEqualObjects([NSString stringWithUTF8String:buff], @EXPECTED); \
}

#define TEST_2_ARG(NAME, FUNCTION, ARG1, ARG2, EXPECTED) \
- (void)test##NAME { \
    char buff[1000]; \
    memset(buff, '~', sizeof(buff)); \
    FUNCTION(ARG1, buff, ARG2); \
    buff[sizeof(buff)-1] = 0; \
    XCTAssertEqualObjects([NSString stringWithUTF8String:buff], @EXPECTED); \
}

TEST_1_ARG(uint0, bsg_uint64_to_string, 0u, "0")
TEST_1_ARG(uint1, bsg_uint64_to_string, 1u, "1")
TEST_1_ARG(uint1000, bsg_uint64_to_string, 1000u, "1000")
TEST_1_ARG(uint1234567890, bsg_uint64_to_string, 1234567890u, "1234567890")
TEST_1_ARG(uint18446744073709551615, bsg_uint64_to_string, 18446744073709551615u, "18446744073709551615")

TEST_1_ARG(int0, bsg_int64_to_string, 0, "0")
TEST_1_ARG(int1, bsg_int64_to_string, 1, "1")
TEST_1_ARG(intn1, bsg_int64_to_string, -1, "-1")
TEST_1_ARG(int1234567890, bsg_int64_to_string, 1234567890, "1234567890")
TEST_1_ARG(intn1234567890, bsg_int64_to_string, -1234567890, "-1234567890")
TEST_1_ARG(int9223372036854775807, bsg_int64_to_string, 9223372036854775807, "9223372036854775807")
TEST_1_ARG(intn9223372036854775808, bsg_int64_to_string, -9223372036854775808, "-9223372036854775808")

TEST_2_ARG(hex0_0, bsg_uint64_to_hex, 0u, 0, "0")
TEST_2_ARG(hex0_1, bsg_uint64_to_hex, 0u, 1, "0")
TEST_2_ARG(hex0_2, bsg_uint64_to_hex, 0u, 2, "00")
TEST_2_ARG(hex0_3, bsg_uint64_to_hex, 0u, 3, "000")
TEST_2_ARG(hex0_16, bsg_uint64_to_hex, 0u, 16, "0000000000000000")
TEST_2_ARG(hex0_17, bsg_uint64_to_hex, 0u, 17, "0000000000000000")
TEST_2_ARG(hex9ad314_0, bsg_uint64_to_hex, 0x9ad314u, 0, "9ad314")
TEST_2_ARG(hex9ad314_4, bsg_uint64_to_hex, 0x9ad314u, 4, "9ad314")
TEST_2_ARG(hex9ad314_6, bsg_uint64_to_hex, 0x9ad314u, 6, "9ad314")
TEST_2_ARG(hex9ad314_7, bsg_uint64_to_hex, 0x9ad314u, 7, "09ad314")
TEST_2_ARG(hex9ad314_10, bsg_uint64_to_hex, 0x9ad314u, 10, "00009ad314")
TEST_2_ARG(hex123456789abcdef0_0, bsg_uint64_to_hex, 0x123456789abcdef0u, 0, "123456789abcdef0")
TEST_2_ARG(hex123456789abcdef0_16, bsg_uint64_to_hex, 0x123456789abcdef0u, 16, "123456789abcdef0")
TEST_2_ARG(hex123456789abcdef0_80, bsg_uint64_to_hex, 0x123456789abcdef0u, 80, "123456789abcdef0")

TEST_2_ARG(double0_0_0, bsg_double_to_string, 0.0, 0, "0")
TEST_2_ARG(double0_0_1, bsg_double_to_string, 0.0, 1, "0")
TEST_2_ARG(double0_1_0, bsg_double_to_string, 0.1, 0, "1e-1")
TEST_2_ARG(double0_1_1, bsg_double_to_string, 0.1, 1, "1e-1")
TEST_2_ARG(double0_1_2, bsg_double_to_string, 0.1, 2, "1e-1")
TEST_2_ARG(double0_24_1, bsg_double_to_string, 0.24, 1, "2e-1")
TEST_2_ARG(double0_25_1, bsg_double_to_string, 0.25, 1, "3e-1")
TEST_2_ARG(double942_29912354_10, bsg_double_to_string, 942.29912354, 10, "9.422991235e+2")

@end
