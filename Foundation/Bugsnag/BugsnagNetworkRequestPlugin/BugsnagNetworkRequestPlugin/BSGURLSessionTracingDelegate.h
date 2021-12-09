//
//  BSGURLSessionTracingDelegate.h
//  
//
//  Created by Karl Stenerud on 07.09.21.
//

#import <Bugsnag/BugsnagBreadcrumb.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * BSGURLSessionTracingDelegate is a singleton delegate that receives metrics data from all NSURLSessionTask
 * operations and reports them as network breadcrumbs.
 *
 * It requires a common BSGBreadcrumbSink that all operations will be reported to (if the sink is nil, nothing gets reported).
 */
@interface BSGURLSessionTracingDelegate : NSObject<NSURLSessionTaskDelegate>

+ (BSGURLSessionTracingDelegate * _Nonnull)sharedDelegate;

/**
 * Set the sink that all network breadcrumbs will be reported to. If nil, nothing gets reported.
 */
+ (void)setSink:(nullable id<BSGBreadcrumbSink>) sink;

+ (nullable NSDictionary<NSString *, id> *)urlParamsForQueryItems:(nullable NSArray<NSURLQueryItem *> *)queryItems;

+ (nonnull NSString *)URLStringWithoutQueryForComponents:(nonnull NSURLComponents *)URLComponents;

@property(nonatomic, assign, readonly) BOOL canTrace;

@end

NS_ASSUME_NONNULL_END
