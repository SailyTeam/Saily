//
//  BSGURLSessionTracingProxyTests.m
//  BugsnagNetworkRequestPlugin
//
//  Created by Nick Dowell on 13/10/2021.
//

#import <XCTest/XCTest.h>

#import <objc/runtime.h>

#include "BSGURLSessionTracingProxy.h"

#ifndef XCTSkip
#define XCTSkip(...) NSLog(__VA_ARGS__); return
#endif

@interface BSGURLSessionTracingProxyTests_DidReceiveDataStub : NSObject <NSURLSessionDataDelegate>
@property (nonatomic) BOOL didReceiveDataWasCalled;
@end

@interface BSGURLSessionTracingProxyTests_DidFinishCollectingMetricsStub : NSObject <NSURLSessionTaskDelegate>
@property (nonatomic) BOOL didFinishCollectingMetricsWasCalled;
@end

@interface BSGURLSessionTracingProxyTests_TracingStub : NSObject <NSURLSessionTaskDelegate>
@property (nonatomic) BOOL didFinishCollectingMetricsWasCalled;
@end

#pragma mark -

@interface BSGURLSessionTracingProxyTests : XCTestCase
@end

@implementation BSGURLSessionTracingProxyTests

- (void)testDidReceiveDataIsForwarded {
    BSGURLSessionTracingProxyTests_DidReceiveDataStub *sessionDelegate = [[BSGURLSessionTracingProxyTests_DidReceiveDataStub alloc] init];
    BSGURLSessionTracingProxyTests_TracingStub *tracingDelegate = [[BSGURLSessionTracingProxyTests_TracingStub alloc] init];
    id proxy = [[BSGURLSessionTracingProxy alloc] initWithDelegate:sessionDelegate tracingDelegate:(id)tracingDelegate];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.ephemeralSessionConfiguration];
    NSURLSessionDataTask *task = [[NSURLSessionDataTask alloc] init];
    
    XCTAssertTrue([proxy respondsToSelector:@selector(URLSession:dataTask:didReceiveData:)]);
    [proxy URLSession:session dataTask:task didReceiveData:[NSData data]];
    XCTAssertTrue(sessionDelegate.didReceiveDataWasCalled, @"The session delegate's method should be called");
}

- (void)testDidFinishCollectingMetricsIsForwardedToSessionDelegate {
    if (@available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *)) {
        BSGURLSessionTracingProxyTests_DidFinishCollectingMetricsStub *sessionDelegate =
        [[BSGURLSessionTracingProxyTests_DidFinishCollectingMetricsStub alloc] init];
        BSGURLSessionTracingProxyTests_TracingStub *tracingDelegate = [[BSGURLSessionTracingProxyTests_TracingStub alloc] init];
        id proxy = [[BSGURLSessionTracingProxy alloc] initWithDelegate:sessionDelegate tracingDelegate:(id)tracingDelegate];
        
        NSURLSession *session = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.ephemeralSessionConfiguration];
        NSURLSessionDataTask *task = [[NSURLSessionDataTask alloc] init];
        
        XCTAssertFalse([proxy respondsToSelector:@selector(URLSession:dataTask:didReceiveData:)]);
        XCTAssertTrue([proxy respondsToSelector:@selector(URLSession:task:didFinishCollectingMetrics:)]);
        [proxy URLSession:session task:task didFinishCollectingMetrics:[[NSURLSessionTaskMetrics alloc] init]];
        XCTAssertTrue(sessionDelegate.didFinishCollectingMetricsWasCalled, @"The session delegate's method should be called");
        XCTAssertTrue(tracingDelegate.didFinishCollectingMetricsWasCalled, @"The tracing delegate's method should be called");
    } else {
        XCTSkip(@"Required API is not available for this test.");
    };
}

- (void)testDidFinishCollectingMetricsIsNotImplementedBySessionDelegate {
    if (@available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *)) {
        BSGURLSessionTracingProxyTests_DidReceiveDataStub *sessionDelegate =
        [[BSGURLSessionTracingProxyTests_DidReceiveDataStub alloc] init];
        BSGURLSessionTracingProxyTests_TracingStub *tracingDelegate = [[BSGURLSessionTracingProxyTests_TracingStub alloc] init];
        id proxy = [[BSGURLSessionTracingProxy alloc] initWithDelegate:sessionDelegate tracingDelegate:(id)tracingDelegate];
        
        NSURLSession *session = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.ephemeralSessionConfiguration];
        NSURLSessionDataTask *task = [[NSURLSessionDataTask alloc] init];
        
        XCTAssertTrue([proxy respondsToSelector:@selector(URLSession:task:didFinishCollectingMetrics:)]);
        XCTAssertNoThrow([proxy URLSession:session task:task didFinishCollectingMetrics:[[NSURLSessionTaskMetrics alloc] init]]);
        XCTAssertTrue(tracingDelegate.didFinishCollectingMetricsWasCalled, @"The tracing delegate's method should be called");
    } else {
        XCTSkip(@"Required API is not available for this test.");
    };
}

#pragma mark - NSProxy correctness

- (void)testConformsToProtocol {
    id sessionDelegate = [[BSGURLSessionTracingProxyTests_DidReceiveDataStub alloc] init];
    id tracingDelegate = [[BSGURLSessionTracingProxyTests_TracingStub alloc] init];
    id proxy = [[BSGURLSessionTracingProxy alloc] initWithDelegate:sessionDelegate tracingDelegate:tracingDelegate];
    XCTAssertTrue([proxy conformsToProtocol:@protocol(NSURLSessionDataDelegate)]);
    XCTAssertFalse([proxy conformsToProtocol:@protocol(NSURLSessionStreamDelegate)]);
}

- (void)testExceptionIsThrownForUnimplementedMethod {
    id sessionDelegate = [[BSGURLSessionTracingProxyTests_DidReceiveDataStub alloc] init];
    id tracingDelegate = [[BSGURLSessionTracingProxyTests_TracingStub alloc] init];
    id proxy = [[BSGURLSessionTracingProxy alloc] initWithDelegate:sessionDelegate tracingDelegate:tracingDelegate];
    XCTAssertThrowsSpecificNamed([proxy testExceptionIsThrownForUnimplementedMethod], NSException, NSInvalidArgumentException);
}

- (void)testIsKindOfClass {
    id sessionDelegate = [[BSGURLSessionTracingProxyTests_DidReceiveDataStub alloc] init];
    id tracingDelegate = [[BSGURLSessionTracingProxyTests_TracingStub alloc] init];
    id proxy = [[BSGURLSessionTracingProxy alloc] initWithDelegate:sessionDelegate tracingDelegate:tracingDelegate];
    XCTAssertTrue([proxy isKindOfClass:[NSObject class]]);
    XCTAssertTrue([proxy isKindOfClass:[sessionDelegate class]]);
    XCTAssertFalse([proxy isKindOfClass:[tracingDelegate class]]);
}

- (void)testRespondsToSelector {
    id sessionDelegate = [[BSGURLSessionTracingProxyTests_DidReceiveDataStub alloc] init];
    id tracingDelegate = [[BSGURLSessionTracingProxyTests_TracingStub alloc] init];
    id proxy = [[BSGURLSessionTracingProxy alloc] initWithDelegate:sessionDelegate tracingDelegate:tracingDelegate];
    XCTAssertTrue([proxy respondsToSelector:@selector(URLSession:dataTask:didReceiveData:)]);
    XCTAssertTrue([proxy respondsToSelector:@selector(URLSession:task:didFinishCollectingMetrics:)]);
    XCTAssertFalse([sessionDelegate respondsToSelector:@selector(URLSession:task:didFinishCollectingMetrics:)]);
}

@end

#pragma mark -

@implementation BSGURLSessionTracingProxyTests_DidReceiveDataStub

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    self.didReceiveDataWasCalled = YES;
}

@end

#pragma mark -

@implementation BSGURLSessionTracingProxyTests_DidFinishCollectingMetricsStub

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics
API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0)) {
    self.didFinishCollectingMetricsWasCalled = YES;
}

@end

#pragma mark -

@implementation BSGURLSessionTracingProxyTests_TracingStub

- (BOOL)canTrace {
    return YES;
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics
API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0)) {
    self.didFinishCollectingMetricsWasCalled = YES;
}

@end
