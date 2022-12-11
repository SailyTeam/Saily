//
//  BugsnagInternals.h
//  Bugsnag
//
//  Created by Nick Dowell on 31/08/2022.
//  Copyright © 2022 Bugsnag Inc. All rights reserved.
//

#import <Bugsnag/Bugsnag.h>

/**
 * ** WARNING **
 *
 * The interfaces declared in this header file are for use by Bugsnag's other
 * platform notifiers such as bugsnag-cocos2ds, bugsnag-flutter, bugsnag-js,
 * bugsnag-unreal and bugsnag-unity.
 *
 * These interfaces may be changed, renamed or removed without warning in minor
 * or bugfix releases, and should not be used by projects outside of Bugsnag.
 */

#import "BugsnagHandledState.h"
#import "BugsnagNotifier.h"

@interface BSGFeatureFlagStore : NSObject <NSCopying>
@end

NS_ASSUME_NONNULL_BEGIN

#pragma mark -

@interface Bugsnag ()

@property (class, readonly, nonatomic) BOOL bugsnagStarted;

@property (class, readonly, nonatomic) BugsnagClient *client;

@end

#pragma mark -

@interface BugsnagAppWithState ()

+ (BugsnagAppWithState *)appFromJson:(NSDictionary *)json;

- (NSDictionary *)toDict;

@end

#pragma mark -

@interface BugsnagBreadcrumb ()

+ (nullable instancetype)breadcrumbFromDict:(NSDictionary *)dict;

- (nullable NSDictionary *)objectValue;

@end

BUGSNAG_EXTERN NSString * BSGBreadcrumbTypeValue(BSGBreadcrumbType type);

BUGSNAG_EXTERN BSGBreadcrumbType BSGBreadcrumbTypeFromString(NSString * _Nullable value);

#pragma mark -

typedef NS_ENUM(NSInteger, BSGClientObserverEvent) {
    BSGClientObserverAddFeatureFlag,    // value: BugsnagFeatureFlag
    BSGClientObserverClearFeatureFlag,  // value: NSString
    BSGClientObserverUpdateContext,     // value: NSString
    BSGClientObserverUpdateMetadata,    // value: BugsnagMetadata
    BSGClientObserverUpdateUser,        // value: BugsnagUser
};

typedef void (^ BSGClientObserver)(BSGClientObserverEvent event, _Nullable id value);

@interface BugsnagClient ()

@property (nullable, nonatomic) NSString *codeBundleId;

@property (retain, nonatomic) BugsnagConfiguration *configuration;

@property (readonly, nonatomic) BSGFeatureFlagStore *featureFlagStore;

@property (strong, nonatomic) BugsnagMetadata *metadata;

@property (readonly, nonatomic) BugsnagNotifier *notifier;

@property (nullable, nonatomic) BSGClientObserver observer;

/// The currently active (not paused) session.
@property (readonly, nullable, nonatomic) BugsnagSession *session;

- (void)addRuntimeVersionInfo:(NSString *)info withKey:(NSString *)key;

- (BugsnagAppWithState *)generateAppWithState:(NSDictionary *)systemInfo;

- (BugsnagDeviceWithState *)generateDeviceWithState:(NSDictionary *)systemInfo;

- (void)notifyInternal:(BugsnagEvent *)event block:(nullable BugsnagOnErrorBlock)block;

- (void)updateSession:(BugsnagSession * _Nullable (^)(BugsnagSession * _Nullable session))block;

@end

#pragma mark -

@interface BugsnagConfiguration ()

@property (nullable, nonatomic) BugsnagNotifier *notifier;

@property (nonatomic) NSMutableArray<BugsnagOnBreadcrumbBlock> *onBreadcrumbBlocks;

@property (nonatomic) NSMutableArray<BugsnagOnSendErrorBlock> *onSendBlocks;

@property (nonatomic) NSMutableArray<BugsnagOnSessionBlock> *onSessionBlocks;

@end

#pragma mark -

@interface BugsnagDeviceWithState ()

+ (instancetype)deviceFromJson:(NSDictionary *)json;

- (NSDictionary *)toDictionary;

@end

#pragma mark -

@interface BugsnagError ()

+ (BugsnagError *)errorFromJson:(NSDictionary *)json;

- (instancetype)initWithErrorClass:(NSString *)errorClass
                      errorMessage:(nullable NSString *)errorMessage
                         errorType:(BSGErrorType)errorType
                        stacktrace:(nullable NSArray<BugsnagStackframe *> *)stacktrace;

@end

#pragma mark -

@interface BugsnagEvent ()

- (instancetype)initWithApp:(BugsnagAppWithState *)app
                     device:(BugsnagDeviceWithState *)device
               handledState:(BugsnagHandledState *)handledState
                       user:(BugsnagUser *)user
                   metadata:(BugsnagMetadata *)metadata
                breadcrumbs:(NSArray<BugsnagBreadcrumb *> *)breadcrumbs
                     errors:(NSArray<BugsnagError *> *)errors
                    threads:(NSArray<BugsnagThread *> *)threads
                    session:(nullable BugsnagSession *)session;

- (instancetype)initWithJson:(NSDictionary *)json;

- (void)attachCustomStacktrace:(NSArray *)frames withType:(NSString *)type;

- (void)symbolicateIfNeeded;

- (NSDictionary *)toJsonWithRedactedKeys:(nullable NSSet *)redactedKeys;

@property (readwrite, strong, nonnull, nonatomic) BSGFeatureFlagStore *featureFlagStore;

@end

#pragma mark -

@interface BugsnagMetadata ()

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@property (readonly, nonatomic) NSMutableDictionary *dictionary;

- (NSDictionary *)toDictionary;

@end

#pragma mark -

@interface BugsnagSession ()

@property (readwrite, nonatomic) BugsnagApp *app;

@property (readwrite, nonatomic) BugsnagDevice *device;

@property (nonatomic) NSUInteger handledCount;

@property (nonatomic) NSUInteger unhandledCount;

@end

#pragma mark -

@interface BugsnagStackframe ()

+ (instancetype)frameFromJson:(NSDictionary *)json;

@property (copy, nullable, nonatomic) NSString *codeIdentifier;
@property (strong, nullable, nonatomic) NSNumber *columnNumber;
@property (copy, nullable, nonatomic) NSString *file;
@property (strong, nullable, nonatomic) NSNumber *inProject;
@property (strong, nullable, nonatomic) NSNumber *lineNumber;

/// Populates the method and symbolAddress via `dladdr()` if this object was created from a backtrace or callstack.
/// This can be a slow operation, so should be performed on a background thread.
- (void)symbolicateIfNeeded;

- (NSDictionary *)toDictionary;

@end

#pragma mark -

@interface BugsnagThread ()

+ (NSArray<BugsnagThread *> *)allThreads:(BOOL)allThreads callStackReturnAddresses:(NSArray<NSNumber *> *)callStackReturnAddresses;

+ (NSMutableArray *)serializeThreads:(nullable NSArray<BugsnagThread *> *)threads;

+ (instancetype)threadFromJson:(NSDictionary *)json;

@end

#pragma mark -

@interface BugsnagUser ()

- (instancetype)initWithDictionary:(nullable NSDictionary *)dict;

- (NSDictionary *)toJson;

@end

#pragma mark -

BUGSNAG_EXTERN NSString * BSGGetDefaultDeviceId(void);

BUGSNAG_EXTERN NSDictionary * BSGGetSystemInfo(void);

BUGSNAG_EXTERN NSTimeInterval BSGCrashSentryDeliveryTimeout;

NS_ASSUME_NONNULL_END
