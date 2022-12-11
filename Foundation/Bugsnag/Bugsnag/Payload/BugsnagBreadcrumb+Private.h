//
//  BugsnagBreadcrumb+Private.h
//  Bugsnag
//
//  Created by Nick Dowell on 04/12/2020.
//  Copyright © 2020 Bugsnag Inc. All rights reserved.
//

#import "BSGDefines.h"
#import "BugsnagInternals.h"

NS_ASSUME_NONNULL_BEGIN

BSG_OBJC_DIRECT_MEMBERS
@interface BugsnagBreadcrumb ()

- (BOOL)isValid;

/// String representation of `timestamp` used to avoid unnecessary date <--> string conversions
@property (copy, nullable, nonatomic) NSString *timestampString;

@end

NS_ASSUME_NONNULL_END
