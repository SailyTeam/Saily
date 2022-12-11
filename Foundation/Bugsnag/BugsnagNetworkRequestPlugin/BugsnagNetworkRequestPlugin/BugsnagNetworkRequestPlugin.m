//
//  BugsnagNetworkRequestPlugin.m
//  BugsnagNetworkRequestPlugin
//
//  Created by Karl Stenerud on 26.08.21.
//

// Replaces `NSURLSession.sessionWithConfiguration:delegate:delegateQueue:` and
// `NSURLSession.sharedSession` to inject a proxy delegate that responds to
// `URLSession:task:didFinishCollectingMetrics:` so that we can generate network
// breadcrumbs from all requests.

#import "BugsnagNetworkRequestPlugin.h"

#import "BSGURLSessionTracingDelegate.h"
#import "NSURLSession+Tracing.h"

#import <Bugsnag/BugsnagClient.h>

@implementation BugsnagNetworkRequestPlugin

+ (void)load {
    if (@available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *)) {
        bsg_installNSURLSessionTracing();
    }
}

- (void)load:(BugsnagClient *)client {
    [BSGURLSessionTracingDelegate setClient:client];
}

- (void)unload {
    [BSGURLSessionTracingDelegate setClient:nil];
}

@end
