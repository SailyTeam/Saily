//
//  NSURLSession+Tracing.h
//  
//
//  Created by Karl Stenerud on 07.09.21.
//

#ifndef NSURLSession_Tracing_h
#define NSURLSession_Tracing_h

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Performs all swizzling necesary to install tracing for network breadcrumb reporting.
 * This only lays the groundwork; you still need to set BSGURLSessionTracingDelegate.sink before anything gets reported.
 *
 * All of the initialisation for network breadcrumbs is coordinated from BugsnagNetworkRequestPlugin.
 */
void bsg_installNSURLSessionTracing(void);

#ifdef __cplusplus
}
#endif

#endif /* NSURLSession_Tracing_h */
