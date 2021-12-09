//
//  BSGURLSessionTracingProxy.h
//  
//
//  Created by Karl Stenerud on 07.09.21.
//

#import "BSGURLSessionTracingDelegate.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * BSGURLSessionTracingProxy sits in between an NSURLSession and NSURLSessionDelegate to also invoke the shared
 * BSGURLSessionTracingDelegate (which captures NSURLSessionTaskMetrics to send as network breadcrumbs).
 */
@interface BSGURLSessionTracingProxy : NSProxy<NSURLSessionDelegate>

- (instancetype)initWithDelegate:(nonnull id<NSURLSessionDelegate>)delegate
                 tracingDelegate:(nonnull BSGURLSessionTracingDelegate *)tracingDelegate;

@end

NS_ASSUME_NONNULL_END
