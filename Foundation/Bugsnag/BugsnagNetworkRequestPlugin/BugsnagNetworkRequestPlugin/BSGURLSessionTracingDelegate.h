//
//  BSGURLSessionTracingDelegate.h
//  
//
//  Created by Karl Stenerud on 07.09.21.
//

#import <Bugsnag/Bugsnag.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * BSGURLSessionTracingDelegate is a singleton delegate that receives metrics data from all NSURLSessionTask
 * operations and forwards them to the BugsnagClient.
 */
@interface BSGURLSessionTracingDelegate : NSObject<NSURLSessionTaskDelegate>

+ (BSGURLSessionTracingDelegate * _Nonnull)sharedDelegate;

+ (void)setClient:(nullable BugsnagClient *)client;

@property(nonatomic, assign, readonly) BOOL canTrace;

@end

NS_ASSUME_NONNULL_END
