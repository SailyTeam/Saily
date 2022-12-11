//
//  BSGURLSessionTracingProxy.m
//  
//
//  Created by Karl Stenerud on 07.09.21.
//

#import "BSGURLSessionTracingProxy.h"
#import <objc/runtime.h>


@interface BSGURLSessionTracingProxy ()

@property (nonatomic, strong, nonnull) id delegate;
@property (nonatomic, strong, nonnull) BSGURLSessionTracingDelegate *tracingDelegate;

@end


@implementation BSGURLSessionTracingProxy

#define METRICS_SELECTOR @selector(URLSession:task:didFinishCollectingMetrics:)

- (instancetype)initWithDelegate:(nonnull id<NSURLSessionDelegate>)delegate
                 tracingDelegate:(nonnull BSGURLSessionTracingDelegate *) tracingDelegate {
    _delegate = delegate;
    _tracingDelegate = tracingDelegate;

    return self;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    if (self.tracingDelegate.canTrace && sel_isEqual(aSelector, METRICS_SELECTOR)) {
        return YES;
    }
    return [self.delegate respondsToSelector:aSelector];
}

// Implementing this method prevents a crash when used alongside NewRelic
- (id)forwardingTargetForSelector:(__unused SEL)aSelector {
    return self.delegate;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:self.delegate];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    // Note: We allow a race condition on self.tracingDelegate.canTrace because the
    //       caller has already determined that we respond to selector, and it would
    //       break things to stop "supporting" it now. We'll catch this edge case in
    //       forwardInvocation, and again in the call to tracingDelegate.
    if (sel_isEqual(aSelector, METRICS_SELECTOR)) {
        return [(NSObject *)self.tracingDelegate methodSignatureForSelector:aSelector];
    }
    return [(NSObject *)self.delegate methodSignatureForSelector:aSelector];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics
API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0)) {
    [self.tracingDelegate URLSession:session task:task didFinishCollectingMetrics:metrics];
    
    if ([self.delegate respondsToSelector:METRICS_SELECTOR]) {
        [self.delegate URLSession:session task:task didFinishCollectingMetrics:metrics];
    }
}

@end
