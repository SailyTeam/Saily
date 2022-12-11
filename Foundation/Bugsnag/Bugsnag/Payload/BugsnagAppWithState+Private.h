//
//  BugsnagAppWithState+Private.h
//  Bugsnag
//
//  Created by Nick Dowell on 04/12/2020.
//  Copyright © 2020 Bugsnag Inc. All rights reserved.
//

#import "BugsnagApp+Private.h"
#import "BugsnagInternals.h"

@class BugsnagConfiguration;

NS_ASSUME_NONNULL_BEGIN

@interface BugsnagAppWithState ()

+ (BugsnagAppWithState *)appWithDictionary:(NSDictionary *)event config:(BugsnagConfiguration *)config codeBundleId:(nullable NSString *)codeBundleId;

@end

NS_ASSUME_NONNULL_END
