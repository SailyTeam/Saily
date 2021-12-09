//
//  BugsnagNetworkRequestPlugin.h
//  BugsnagNetworkRequestPlugin
//
//  Created by Karl Stenerud on 26.08.21.
//

#import <Bugsnag/BugsnagPlugin.h>

/**
 * BugsnagNetworkRequestPlugin produces network breadcrumbs for all URL requests made via NSURLSession.
 */
API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0))
@interface BugsnagNetworkRequestPlugin : NSObject<BugsnagPlugin>
@end
