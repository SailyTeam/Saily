//
//  KSSysCtl_Tests.m
//
//  Created by Karl Stenerud on 2013-01-26.
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

#import "BSG_KSSysCtl.h"


@interface KSSysCtl_Tests : XCTestCase @end


@implementation KSSysCtl_Tests

- (void) testSysCtlInt32ForName
{
    int32_t result = bsg_kssysctl_int32ForName("hw.ncpu");
    XCTAssertTrue(result > 0, @"");
}

- (void) testSysCtlInt32ForNameInvalid
{
    int32_t result = bsg_kssysctl_int32ForName("kernblah.posix1version");
    XCTAssertTrue(result == 0, @"");
}

- (void) testSysCtlStringForName
{
    char buff[100] = {0};
    bool success = bsg_kssysctl_stringForName("kern.ostype", buff, sizeof(buff));
    XCTAssertTrue(success, @"");
    XCTAssertTrue(buff[0] != 0, @"");
}

- (void) testSysCtlStringForNameInvalid
{
    char buff[100] = {0};
    bool success = bsg_kssysctl_stringForName("kernblah.ostype", buff, sizeof(buff));
    XCTAssertFalse(success, @"");
    XCTAssertTrue(buff[0] == 0, @"");
}

- (void) testGetMacAddress
{
    unsigned char macAddress[6] = {0};
    bool success = bsg_kssysctl_getMacAddress("en0", (char*)macAddress);
    XCTAssertTrue(success, @"");
    unsigned int result = 0;
    for(size_t i = 0; i < sizeof(macAddress); i++)
    {
        result |= macAddress[i];
    }
    XCTAssertTrue(result != 0, @"");
}

- (void) testGetMacAddressInvalid
{
    unsigned char macAddress[6] = {0};
    bool success = bsg_kssysctl_getMacAddress("blah blah", (char*)macAddress);
    XCTAssertFalse(success, @"");
}

@end
