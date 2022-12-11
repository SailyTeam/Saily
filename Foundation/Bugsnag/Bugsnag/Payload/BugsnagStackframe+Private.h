//
//  BugsnagStackframe+Private.h
//  Bugsnag
//
//  Created by Nick Dowell on 20/11/2020.
//  Copyright © 2020 Bugsnag Inc. All rights reserved.
//

#import "BSGDefines.h"
#import "BugsnagInternals.h"

NS_ASSUME_NONNULL_BEGIN

BSG_OBJC_DIRECT_MEMBERS
@interface BugsnagStackframe ()

+ (NSArray<BugsnagStackframe *> *)stackframesWithBacktrace:(uintptr_t *)backtrace length:(NSUInteger)length;

/// Constructs a stackframe object from a KSCrashReport backtrace dictionary.
+ (nullable instancetype)frameFromDict:(NSDictionary<NSString *, id> *)dict withImages:(NSArray<NSDictionary<NSString *, id> *> *)binaryImages;

@property (nonatomic) BOOL needsSymbolication;

@end

NS_ASSUME_NONNULL_END
