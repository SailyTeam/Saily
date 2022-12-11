//
//  BSGNetworkBreadcrumb.h
//  Bugsnag
//
//  Created by Nick Dowell on 24/08/2022.
//  Copyright © 2022 Bugsnag Inc. All rights reserved.
//

#import <Bugsnag/Bugsnag.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0))
BugsnagBreadcrumb * _Nullable BSGNetworkBreadcrumbWithTaskMetrics(NSURLSessionTask *task, NSURLSessionTaskMetrics *metrics);

NSDictionary<NSString *, id> * _Nullable BSGURLParamsForQueryItems(NSArray<NSURLQueryItem *> * _Nullable queryItems);

NSString * _Nullable BSGURLStringForComponents(NSURLComponents * _Nullable URLComponents);

NS_ASSUME_NONNULL_END
