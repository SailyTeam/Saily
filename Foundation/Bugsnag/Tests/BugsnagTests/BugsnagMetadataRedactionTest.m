//
//  BugsnagMetadataRedactionTest.m
//  Tests
//
//  Created by Jamie Lynch on 15/04/2020.
//  Copyright © 2020 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BugsnagBreadcrumb+Private.h"
#import "BugsnagEvent+Private.h"

@interface BugsnagMetadataRedactionTest : XCTestCase

@end

@implementation BugsnagMetadataRedactionTest

- (void)testEmptyRedaction {
    BugsnagEvent *event = [self generateEventWithMetadata:@{
            @"password": @"hunter2",
            @"some_key": @"2fa0"
    }];

    NSDictionary *payload = [event toJsonWithRedactedKeys:nil];
    NSDictionary *section = payload[@"metaData"][@"custom"];
    XCTAssertNotNil(section);
    XCTAssertEqualObjects(@"hunter2", section[@"password"]);
    XCTAssertEqualObjects(@"2fa0", section[@"some_key"]);
}

- (void)testDefaultRedaction {
    BugsnagEvent *event = [self generateEventWithMetadata:@{
            @"password": @"hunter2",
            @"some_key": @"2fa0"
    }];

    NSDictionary *payload = [event toJsonWithRedactedKeys:[NSSet setWithArray:@[@"password"]]];
    NSDictionary *section = payload[@"metaData"][@"custom"];
    XCTAssertNotNil(section);
    XCTAssertEqualObjects(@"[REDACTED]", section[@"password"]);
    XCTAssertEqualObjects(@"2fa0", section[@"some_key"]);
}

- (void)testNestedRedaction {
    BugsnagEvent *event = [self generateEventWithMetadata:@{
            @"user_auth": @{
                    @"password": @"123456",
                    @"authority": @"admin",
                    @"meta": @{
                            @"password": @"fff455"
                    }
            },
            @"some_key": @"2fa0"
    }];

    NSDictionary *payload = [event toJsonWithRedactedKeys:[NSSet setWithArray:@[@"password"]]];
    NSDictionary *section = payload[@"metaData"][@"custom"];
    XCTAssertNotNil(section);
    XCTAssertEqualObjects(@"[REDACTED]", section[@"user_auth"][@"meta"][@"password"]);
    XCTAssertEqualObjects(@"[REDACTED]", section[@"user_auth"][@"password"]);
    XCTAssertEqualObjects(@"admin", section[@"user_auth"][@"authority"]);
    XCTAssertEqualObjects(@"2fa0", section[@"some_key"]);
}

- (void)testNonDefaultKeys {
    BugsnagEvent *event = [self generateEventWithMetadata:@{
            @"user_auth": @{
                    @"password": @"123456",
                    @"authority": @"admin"
            },
            @"some_key": @"2fa0",
            @"foo": @"gasdf"
    }];

    NSDictionary *payload = [event toJsonWithRedactedKeys:[NSSet setWithArray:@[@"authority", @"some_key"]]];
    NSDictionary *section = payload[@"metaData"][@"custom"];
    XCTAssertNotNil(section);
    XCTAssertEqualObjects(@"123456", section[@"user_auth"][@"password"]);
    XCTAssertEqualObjects(@"[REDACTED]", section[@"user_auth"][@"authority"]);
    XCTAssertEqualObjects(@"[REDACTED]", section[@"some_key"]);
}

- (BugsnagEvent *)generateEventWithMetadata:(NSDictionary *)data {
    return [[BugsnagEvent alloc] initWithKSReport:@{
            @"user": @{
                    @"metaData": @{
                            @"custom": data
                    }
            }
    }];
}

- (void)testRegexRedaction {
    BugsnagEvent *event = [self generateEventWithMetadata:@{
            @"password": @"hunter2",
            @"somekey9": @"2fa0",
            @"somekey": @"ba09"
    }];
    // disallow any numeric characters
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[0-9]" options:0 error:nil];

    NSDictionary *payload = [event toJsonWithRedactedKeys:[NSSet setWithArray:@[@"password", regex]]];
    NSDictionary *section = payload[@"metaData"][@"custom"];
    XCTAssertNotNil(section);
    XCTAssertEqualObjects(@"[REDACTED]", section[@"password"]);
    XCTAssertEqualObjects(@"[REDACTED]", section[@"somekey9"]);
    XCTAssertEqualObjects(@"ba09", section[@"somekey"]);
}

- (void)testCaseInsensitiveKeys {
    BugsnagEvent *event = [self generateEventWithMetadata:@{
            @"password": @"hunter2",
            @"somekey9": @"2fa0",
            @"somekey": @"ba09",
            @"CaseInsensitiveKey" : @"CaseInsensitiveValue",
            @"caseInsensitiveKey" : @"CaseInsensitiveValue",
            @"caseInsensitiveKeyX" : @"CaseInsensitiveValue",
    }];
    
    // Note: this redacts both keys

    NSDictionary *payload = [event toJsonWithRedactedKeys:[NSSet setWithArray:@[@"password", @"Caseinsensitivekey"]]];
    NSDictionary *section = payload[@"metaData"][@"custom"];
    XCTAssertNotNil(section);
    XCTAssertEqualObjects(@"[REDACTED]", section[@"password"]);
    XCTAssertEqualObjects(@"[REDACTED]", section[@"CaseInsensitiveKey"]);
    XCTAssertEqualObjects(@"[REDACTED]", section[@"caseInsensitiveKey"]);
    XCTAssertEqualObjects(@"CaseInsensitiveValue", section[@"caseInsensitiveKeyX"]);
    XCTAssertEqualObjects(@"ba09", section[@"somekey"]);
}

- (void)testBreadcrumbMetadataRedaction {
    BugsnagBreadcrumb *breadcrumb = [[BugsnagBreadcrumb alloc] init];
    breadcrumb.message = @"message cannot be empty";
    breadcrumb.metadata = @{
        @"foo" : @"not redacted",
        @"password" : @"secret",
        @"x" : @{
            @"bar" : @"not redacted",
            @"password" : @"123456"
        }
    };
    
    BugsnagEvent *event = [self generateEventWithMetadata:@{}];
    event.breadcrumbs = @[breadcrumb];
    
    NSDictionary *eventPayload = [event toJsonWithRedactedKeys:[NSSet setWithArray:@[@"password"]]];
    NSDictionary *metaData = eventPayload[@"breadcrumbs"][0][@"metaData"];
    XCTAssertEqualObjects(metaData[@"foo"], @"not redacted");
    XCTAssertEqualObjects(metaData[@"password"], @"[REDACTED]");
    XCTAssertEqualObjects(metaData[@"x"][@"bar"], @"not redacted");
    XCTAssertEqualObjects(metaData[@"x"][@"password"], @"[REDACTED]");
}

@end
