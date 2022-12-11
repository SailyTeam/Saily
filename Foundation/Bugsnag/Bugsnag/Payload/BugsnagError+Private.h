//
//  BugsnagError+Private.h
//  Bugsnag
//
//  Created by Nick Dowell on 23/11/2020.
//  Copyright © 2020 Bugsnag Inc. All rights reserved.
//

#import "BSGDefines.h"
#import "BugsnagInternals.h"

NS_ASSUME_NONNULL_BEGIN

@class BugsnagThread;

BSG_OBJC_DIRECT_MEMBERS
@interface BugsnagError ()

- (instancetype)initWithKSCrashReport:(NSDictionary *)event stacktrace:(NSArray<BugsnagStackframe *> *)stacktrace;

/// The string representation of the BSGErrorType
@property (copy, nonatomic) NSString *typeString;

/// Parses the `__crash_info` message and updates the `errorClass` and `errorMessage` as appropriate.
- (void)updateWithCrashInfoMessage:(NSString *)crashInfoMessage;

- (NSDictionary *)toDictionary;

@end

NSString *BSGParseErrorClass(NSDictionary *error, NSString *errorType);

NSString * _Nullable BSGParseErrorMessage(NSDictionary *report, NSDictionary *error, NSString *errorType);

BSGErrorType BSGParseErrorType(NSString *errorType);

NSString *BSGSerializeErrorType(BSGErrorType errorType);

NS_ASSUME_NONNULL_END
