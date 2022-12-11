//
//  BugsnagThread+Private.h
//  Bugsnag
//
//  Created by Nick Dowell on 23/11/2020.
//  Copyright © 2020 Bugsnag Inc. All rights reserved.
//

#import "BSGDefines.h"
#import "BugsnagInternals.h"

NS_ASSUME_NONNULL_BEGIN

BSG_OBJC_DIRECT_MEMBERS
@interface BugsnagThread ()

- (instancetype)initWithId:(nullable NSString *)identifier
                      name:(nullable NSString *)name
      errorReportingThread:(BOOL)errorReportingThread
                      type:(BSGThreadType)type
                     state:(nullable NSString *)state
                stacktrace:(NSArray<BugsnagStackframe *> *)stacktrace;

- (instancetype)initWithThread:(NSDictionary *)thread binaryImages:(NSArray *)binaryImages;

@property (readonly, nullable, nonatomic) NSString *crashInfoMessage;

@property (readwrite, nonatomic) BOOL errorReportingThread;

+ (NSDictionary *)enhanceThreadInfo:(NSDictionary *)thread;

#if BSG_HAVE_MACH_THREADS
+ (nullable instancetype)mainThread;
#endif

+ (NSMutableArray<BugsnagThread *> *)threadsFromArray:(NSArray *)threads binaryImages:(NSArray *)binaryImages;

- (NSDictionary *)toDictionary;

@end

BSGThreadType BSGParseThreadType(NSString *type);

NSString *BSGSerializeThreadType(BSGThreadType type);

NS_ASSUME_NONNULL_END
