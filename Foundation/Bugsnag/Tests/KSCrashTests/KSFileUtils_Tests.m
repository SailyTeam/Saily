//
//  KSFileUtils_Tests.m
//
//  Created by Karl Stenerud on 2012-01-28.
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


#import "FileBasedTestCase.h"

#import "BSG_KSFileUtils.h"


@interface KSFileUtils_Tests : FileBasedTestCase @end


@implementation KSFileUtils_Tests

- (void) testLastPathEntry
{
    NSString* path = @"some/kind/of/path";
    NSString* expected = @"path";
    NSString* actual = [NSString stringWithCString:bsg_ksfulastPathEntry([path cStringUsingEncoding:NSUTF8StringEncoding])
                                          encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(actual, expected, @"");
}

- (void) testWriteBytesToFD
{
    NSError* error = nil;
    NSString* path = [self.tempPath stringByAppendingPathComponent:@"test.txt"];
    NSString* expected = @"testing a bunch of stuff.\nOh look, a newline!";
    int stringLength = (int)[expected length];

    int fd = open([path UTF8String], O_RDWR | O_CREAT | O_EXCL, 0644);
    XCTAssertTrue(fd >= 0, @"");
    bool result = bsg_ksfuwriteBytesToFD(fd, [expected cStringUsingEncoding:NSUTF8StringEncoding], stringLength);
    XCTAssertTrue(result, @"");
    NSString* actual = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(actual, expected, @"");
}

@end
