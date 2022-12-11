//
//  BSGAppHangDetector.m
//  Bugsnag
//
//  Created by Nick Dowell on 01/03/2021.
//  Copyright © 2021 Bugsnag Inc. All rights reserved.
//

#import "BSGAppHangDetector.h"

#if BSG_HAVE_APP_HANG_DETECTION

#import <Bugsnag/BugsnagConfiguration.h>
#import <Bugsnag/BugsnagErrorTypes.h>

#import "BSGRunContext.h"
#import "BSG_KSMach.h"
#import "BSG_KSSystemInfo.h"
#import "BugsnagCollections.h"
#import "BugsnagLogger.h"
#import "BugsnagThread+Private.h"


BSG_OBJC_DIRECT_MEMBERS
@interface BSGAppHangDetector ()

@property (weak, nonatomic) id<BSGAppHangDetectorDelegate> delegate;
@property (nonatomic) CFRunLoopObserverRef observer;
@property (atomic) dispatch_time_t processingDeadline;
@property (nonatomic) dispatch_semaphore_t processingStarted;
@property (nonatomic) dispatch_semaphore_t processingFinished;
@property (nonatomic) BOOL shouldStop;

@end


static void * DetectAppHangs(void *object);

BSG_OBJC_DIRECT_MEMBERS
@implementation BSGAppHangDetector

- (void)startWithDelegate:(id<BSGAppHangDetectorDelegate>)delegate {
    if (self.observer) {
        bsg_log_err(@"Attempted to call %s more than once", __PRETTY_FUNCTION__);
        return;
    }
    
    BugsnagConfiguration *configuration = delegate.configuration;
    if (!configuration.enabledErrorTypes.appHangs) {
        return;
    }
    
    if ([BSG_KSSystemInfo isRunningInAppExtension]) {
        // App extensions have a different life cycle and environment that make the hang detection mechanism unsuitable.
        // * Depending on the type of extension, the run loop is not necessarily dedicated to UI.
        // * The host app or other extensions run by it may trigger false positives.
        // * The system may kill app extensions without any notification.
        return;
    }
    
    if (NSProcessInfo.processInfo.environment[@"XCTestConfigurationFilePath"]) {
        // Disable functionality during unit testing to avoid crashes that can occur due to there
        // being many leaked BugsnagClient instances and BSGAppHangDetectors running while global
        // shared data structures are being reinitialized.
        return;
    }
    
    const BOOL fatalOnly = configuration.appHangThresholdMillis == BugsnagAppHangThresholdFatalOnly;
    const NSTimeInterval threshold = fatalOnly ? 2.0 : (double)configuration.appHangThresholdMillis / 1000.0;
    
    bsg_log_debug(@"Starting App Hang detector with threshold = %g seconds", threshold);
    
    self.delegate = delegate;
    self.processingStarted = dispatch_semaphore_create(0);
    self.processingFinished = dispatch_semaphore_create(0);
    
    __block BOOL isProcessing = NO;
    
    void (^ observerBlock)(CFRunLoopObserverRef, CFRunLoopActivity) =
    ^(__unused CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
        
        if (activity == kCFRunLoopAfterWaiting || activity == kCFRunLoopBeforeSources) {
            if (isProcessing) {
                // When busy, a run loop can go through many timers / sources iterations before kCFRunLoopBeforeWaiting.
                // Each iteration indicates a separate unit of work so the hang detection should be reset accordingly.
                dispatch_semaphore_signal(self.processingFinished);
            }
            self.processingDeadline = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(threshold * NSEC_PER_SEC));
            dispatch_semaphore_signal(self.processingStarted);
            isProcessing = YES;
            return;
        }
        
        if (activity == kCFRunLoopBeforeWaiting) {
            if (isProcessing) {
                dispatch_semaphore_signal(self.processingFinished);
                isProcessing = NO;
            }
            return;
        }
    };
    
    // A high `order` is required to ensure our kCFRunLoopBeforeWaiting observer runs after others that may introduce an app hang.
    // Once such culprit is -[UITableView tableView:didSelectRowAtIndexPath:] which is run in a
    // _afterCACommitHandler, which is invoked via a CFRunLoopObserver.
    CFIndex order = INT_MAX;
    CFRunLoopActivity activities = kCFRunLoopAfterWaiting | kCFRunLoopBeforeSources | kCFRunLoopBeforeWaiting;
    self.observer = CFRunLoopObserverCreateWithHandler(NULL, activities, true, order, observerBlock);
    
    // Start monitoring immediately so that app hangs during launch can be detected.
    self.processingDeadline = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(threshold * NSEC_PER_SEC));
    dispatch_semaphore_signal(self.processingStarted);
    isProcessing = YES;
    
    CFRunLoopAddObserver(CFRunLoopGetMain(), self.observer, kCFRunLoopCommonModes);
    
    pthread_t thread;
    pthread_create(&thread, NULL, DetectAppHangs, (__bridge void *)(self));
}

- (void)detectAppHangs {
    NSThread.currentThread.name = @"com.bugsnag.app-hang-detector";
    
    while (!self.shouldStop) {
        @autoreleasepool {
            if (dispatch_semaphore_wait(self.processingStarted, DISPATCH_TIME_FOREVER) != 0) {
                bsg_log_err(@"BSGAppHangDetector: dispatch_semaphore_wait failed unexpectedly");
                return;
            }

            const dispatch_time_t deadline = self.processingDeadline;

            if (dispatch_semaphore_wait(self.processingFinished, deadline) == 0) {
                // Run loop finished within the deadline
                continue;
            }

            BOOL shouldReportAppHang = YES;

            if (dispatch_time(DISPATCH_TIME_NOW, 0) > dispatch_time(deadline, 1 * NSEC_PER_SEC)) {
                // If this thread has woken up long after the deadline, the app may have been suspended.
                bsg_log_debug(@"Ignoring potential false positive app hang");
                shouldReportAppHang = NO;
            }

#if defined(DEBUG) && DEBUG
            if (shouldReportAppHang && bsg_ksmachisBeingTraced()) {
                bsg_log_debug(@"Ignoring app hang because debugger is attached");
                shouldReportAppHang = NO;
            }
#endif

            if (shouldReportAppHang && !bsg_runContext->isForeground && !self.delegate.configuration.reportBackgroundAppHangs) {
                bsg_log_debug(@"Ignoring app hang because app is in the background");
                shouldReportAppHang = NO;
            }

            if (shouldReportAppHang) {
                [self appHangDetected];
            }

            dispatch_semaphore_wait(self.processingFinished, DISPATCH_TIME_FOREVER);

            if (shouldReportAppHang) {
                [self appHangEnded];
            }
        }
    }
}

- (void)appHangDetected {
    bsg_log_info(@"App hang detected");
    
    // Record the date and state before performing any operations like symbolication or loading
    // breadcrumbs from disk that could introduce delays and lead to misleading event contents.
    
    NSDate *date = [NSDate date];
    NSDictionary *systemInfo = [BSG_KSSystemInfo systemInfo];
    id<BSGAppHangDetectorDelegate> delegate = self.delegate;
    
    NSArray<BugsnagThread *> *threads = nil;
    if (delegate.configuration.sendThreads == BSGThreadSendPolicyAlways) {
        threads = [BugsnagThread allThreads:YES callStackReturnAddresses:NSThread.callStackReturnAddresses];
        // By default the calling thread is marked as "Error reported from this thread", which is not correct case for app hangs.
        [threads enumerateObjectsUsingBlock:^(BugsnagThread * _Nonnull thread, NSUInteger idx,
                                              __unused BOOL * _Nonnull stop) {
            thread.errorReportingThread = idx == 0;
        }];
    } else {
        threads = BSGArrayWithObject([BugsnagThread mainThread]);
    }
    
    [delegate appHangDetectedAtDate:date withThreads:threads systemInfo:systemInfo];
}

- (void)appHangEnded {
    bsg_log_info(@"App hang has ended");
    
    [self.delegate appHangEnded];
}

- (void)stop {
    self.shouldStop = YES;
    self.processingDeadline = DISPATCH_TIME_FOREVER;
    dispatch_semaphore_signal(self.processingStarted);
    dispatch_semaphore_signal(self.processingFinished);
    if (self.observer) {
        CFRunLoopObserverInvalidate(self.observer);
        self.observer = nil;
    }
}

@end

static void * DetectAppHangs(void *object) {
    [(__bridge BSGAppHangDetector *)object detectAppHangs];
    return NULL;
}

#endif
