//
//  BSGNetworkBreadcrumbTests.m
//  Bugsnag
//
//  Created by Nick Dowell on 22/09/2021.
//

#import "BSGNetworkBreadcrumb.h"

#import <XCTest/XCTest.h>

@interface BSGNetworkBreadcrumbTests : XCTestCase

@end

@implementation BSGNetworkBreadcrumbTests

- (void)testUrlParamsForQueryItems {
#define TEST(url, expected) \
XCTAssertEqualObjects(BSGURLParamsForQueryItems([NSURLComponents componentsWithString:url].queryItems), expected)
    
    TEST(@"http://example.com", nil);
    
    TEST(@"http://example.com?", @{});
    
    TEST(@"http://example.com?foo=bar", @{@"foo": @"bar"});
    
    TEST(@"http://example.com?foo=bar&bar=baz", (@{@"foo": @"bar", @"bar": @"baz"}));
    
    // Multiple query items with the same name should be represented as arrays.
    TEST(@"http://example.com?foo=bar&foo=baz", (@{@"foo": @[@"bar", @"baz"]}));
    
    // Query items with no value should be represented as empty string.
    TEST(@"http://example.com?foo=bar&foo=baz&foo=&sort=name", (@{@"foo": @[@"bar", @"baz", @""], @"sort": @"name"}));
    
    TEST(@"http://example.com?foo", @{@"foo": [NSNull null]});
    
    TEST(@"http://example.com?=bar", @{@"": @"bar"});
    
    TEST(@"http://example.com?foo=bar&", (@{@"foo": @"bar", @"": [NSNull null]}));
    
    TEST(@"http://example.com?foo=bar&baz", (@{@"foo": @"bar", @"baz": [NSNull null]}));
    
    TEST(@"http://example.com?foo=bar&baz&baz", (@{@"foo": @"bar", @"baz": @[[NSNull null], [NSNull null]]}));
    
#undef TEST
}

- (void)testURLStringWithoutQueryForComponents {
#define TEST(url, expected) \
XCTAssertEqualObjects(BSGURLStringForComponents([NSURLComponents componentsWithString:url]), expected)
    
    TEST(@"http://example.com",
         @"http://example.com");
    
    TEST(@"http://example.com/",
         @"http://example.com/");
    
    TEST(@"http://example.com?foo=bar",
         @"http://example.com");
    
    TEST(@"http://example.com/?foo=bar",
         @"http://example.com/");
    
    TEST(@"http://example.com/page.html?foo=bar",
         @"http://example.com/page.html");
    
    TEST(@"http://example.com/page.html?foo=bar#some-anchor",
         @"http://example.com/page.html#some-anchor");
    
    // In this example what look like query parameters are actually part of the fragment
    TEST(@"http://example.com/page.html#some-anchor?foo=bar",
         @"http://example.com/page.html#some-anchor?foo=bar");
    
#undef TEST
}

@end
