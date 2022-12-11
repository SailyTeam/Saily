//
//  BugsnagClient+Private.h
//  Bugsnag
//
//  Created by Nick Dowell on 26/11/2020.
//  Copyright © 2020 Bugsnag Inc. All rights reserved.
//

#import "BSGDefines.h"
#import "BugsnagInternals.h"

@class BSGAppHangDetector;
@class BSGEventUploader;
@class BugsnagAppWithState;
@class BugsnagBreadcrumbs;
@class BugsnagConfiguration;
@class BugsnagDeviceWithState;
@class BugsnagMetadata;
@class BugsnagNotifier;
@class BugsnagSessionTracker;
@class BugsnagSystemState;

NS_ASSUME_NONNULL_BEGIN

BSG_OBJC_DIRECT_MEMBERS
@interface BugsnagClient ()

#pragma mark Properties

@property (nonatomic) BOOL appDidCrashLastLaunch;

@property (nonatomic) BSGAppHangDetector *appHangDetector;

@property (nullable, nonatomic) BugsnagEvent *appHangEvent;

/// The App hang or OOM event that caused the last launch to crash.
@property (nullable, nonatomic) BugsnagEvent *eventFromLastLaunch;

@property (strong, nonatomic) BSGEventUploader *eventUploader;

@property (nonatomic) NSMutableDictionary *extraRuntimeInfo;

@property (nonatomic) BOOL started;

/// State related metadata
///
/// Upon change this is automatically persisted to disk, making it available when contructing OOM payloads.
/// Is it also added to KSCrashReports under `user.state` by `BSSerializeDataCrashHandler()`.
///
/// Example contents:
///
/// {
///     "app": {
///         "codeBundleId": "com.example.app",
///     },
///     "client": {
///         "context": "MyViewController",
///     },
///     "user": {
///         "id": "abc123",
///         "name": "bob"
///     }
/// }
@property (strong, nonatomic) BugsnagMetadata *state;

@property (strong, nonatomic) NSMutableArray *stateEventBlocks;

@property (strong, nonatomic) BugsnagSystemState *systemState;

#pragma mark Methods

- (void)start;

@end

NS_ASSUME_NONNULL_END
