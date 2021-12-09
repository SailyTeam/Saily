//
//  NSURLSession+Tracing.m
//  
//
//  Created by Karl Stenerud on 07.09.21.
//

#import "NSURLSession+Tracing.h"
#import "BSGURLSessionTracingDelegate.h"
#import "BSGURLSessionTracingProxy.h"
#import <objc/runtime.h>


static IMP set_class_imp(Class _Nonnull class, SEL selector, id _Nonnull implementationBlock) {
    Method method = class_getClassMethod(class, selector);
    if (method) {
        return method_setImplementation(method, imp_implementationWithBlock(implementationBlock));
    } else {
        NSLog(@"WARNING: Could not set IMP for selector %s on class %@", sel_getName(selector), class);
        return nil;
    }
}

static void replace_NSURLSession_sessionWithConfigurationDelegateQueue() {
    Class class = NSURLSession.class;
    SEL selector = @selector(sessionWithConfiguration:delegate:delegateQueue:);
    typedef NSURLSession *(*IMPPrototype)(id, SEL, NSURLSessionConfiguration *,
                                          id<NSURLSessionDelegate>, NSOperationQueue *);
    __block IMPPrototype originalIMP = (IMPPrototype)set_class_imp(class,
                                                                   selector,
                                                                   ^(id self,
                                                                     NSURLSessionConfiguration *configuration,
                                                                     id<NSURLSessionDelegate> delegate,
                                                                     NSOperationQueue *queue) {
        BSGURLSessionTracingDelegate *tracingDelegate = BSGURLSessionTracingDelegate.sharedDelegate;
        if (delegate) {
            delegate = [[BSGURLSessionTracingProxy alloc] initWithDelegate:delegate tracingDelegate:tracingDelegate];
        } else {
            delegate = tracingDelegate;
        }
        return originalIMP(self, selector, configuration, delegate, queue);
    });
}

static void replace_NSURLSession_sharedSession() {
    set_class_imp(NSURLSession.class, @selector(sharedSession), ^(__unused id self) {
        static NSURLSession *session;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            // The shared session uses the shared NSURLCache, NSHTTPCookieStorage,
            // and NSURLCredentialStorage objects, uses a shared custom networking
            // protocol list (configured with registerClass: and unregisterClass:),
            // and is based on a default configuration.
            // https://developer.apple.com/documentation/foundation/nsurlsession/1409000-sharedsession
            session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                    delegate:nil delegateQueue:nil];
        });

        return session;
    });
}

void bsg_installNSURLSessionTracing() {
    replace_NSURLSession_sessionWithConfigurationDelegateQueue();
    replace_NSURLSession_sharedSession();
}
