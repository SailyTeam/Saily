//
//  TestSupport.h
//  Bugsnag
//
//  Created by Karl Stenerud on 25.09.20.
//  Copyright © 2020 Bugsnag Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Support code for common things required in tests.
 */
@interface TestSupport : NSObject

/**
 * Purge persistent data and the cached Bugsnag client to start with a clean slate.
 */
+ (void) purgePersistentData;

@end

NS_ASSUME_NONNULL_END
