//
//  BugsnagUser+Private.h
//  Bugsnag
//
//  Created by Nick Dowell on 04/12/2020.
//  Copyright © 2020 Bugsnag Inc. All rights reserved.
//

#import "BSGDefines.h"
#import "BugsnagInternals.h"

NS_ASSUME_NONNULL_BEGIN

BSG_OBJC_DIRECT_MEMBERS
@interface BugsnagUser ()

- (instancetype)initWithId:(nullable NSString *)id name:(nullable NSString *)name emailAddress:(nullable NSString *)emailAddress;

/// Returns the receiver if it has a non-nil `id`, or a copy of the receiver with a `id` set to `[BSG_KSSystemInfo deviceAndAppHash]`. 
- (BugsnagUser *)withId;

@end

BugsnagUser * BSGGetPersistedUser(void);

void BSGSetPersistedUser(BugsnagUser *_Nullable user);

NS_ASSUME_NONNULL_END
