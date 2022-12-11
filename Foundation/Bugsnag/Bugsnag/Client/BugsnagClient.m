//
//  BugsnagClient.m
//
//  Created by Conrad Irwin on 2014-10-01.
//
//  Copyright (c) 2014 Bugsnag, Inc. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall remain in place
// in this source code.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "BugsnagClient+Private.h"

#import "BSGAppHangDetector.h"
#import "BSGAppKit.h"
#import "BSGConnectivity.h"
#import "BSGCrashSentry.h"
#import "BSGDefines.h"
#import "BSGEventUploader.h"
#import "BSGFileLocations.h"
#import "BSGHardware.h"
#import "BSGInternalErrorReporter.h"
#import "BSGJSONSerialization.h"
#import "BSGKeys.h"
#import "BSGNetworkBreadcrumb.h"
#import "BSGNotificationBreadcrumbs.h"
#import "BSGRunContext.h"
#import "BSGSerialization.h"
#import "BSGTelemetry.h"
#import "BSGUIKit.h"
#import "BSGUtils.h"
#import "BSG_KSCrashC.h"
#import "BSG_KSSystemInfo.h"
#import "Bugsnag.h"
#import "BugsnagApp+Private.h"
#import "BugsnagAppWithState+Private.h"
#import "BugsnagBreadcrumb+Private.h"
#import "BugsnagBreadcrumbs.h"
#import "BugsnagCollections.h"
#import "BugsnagConfiguration+Private.h"
#import "BugsnagDeviceWithState+Private.h"
#import "BugsnagError+Private.h"
#import "BugsnagErrorTypes.h"
#import "BugsnagEvent+Private.h"
#import "BugsnagFeatureFlag.h"
#import "BugsnagHandledState.h"
#import "BugsnagLastRunInfo+Private.h"
#import "BugsnagLogger.h"
#import "BugsnagMetadata+Private.h"
#import "BugsnagNotifier.h"
#import "BugsnagPlugin.h"
#import "BugsnagSession+Private.h"
#import "BugsnagSessionTracker.h"
#import "BugsnagStackframe+Private.h"
#import "BugsnagSystemState.h"
#import "BugsnagThread+Private.h"
#import "BugsnagUser+Private.h"

static struct {
    // Contains the user-specified metadata, including the user tab from config.
    char *metadataJSON;
    // Contains the Bugsnag configuration, all under the "config" tab.
    char *configJSON;
    // Contains notifier state under "deviceState", and crash-specific
    // information under "crash".
    char *stateJSON;
    // Usage telemetry, from BSGTelemetryCreateUsage()
    char *usageJSON;
    // User onCrash handler
    void (*onCrash)(const BSG_KSCrashReportWriter *writer);
} bsg_g_bugsnag_data;

static char *crashSentinelPath;

/**
 *  Handler executed when the application crashes. Writes information about the
 *  current application state using the crash report writer.
 *
 *  @param writer report writer which will receive updated metadata
 */
static void BSSerializeDataCrashHandler(const BSG_KSCrashReportWriter *writer) {
    BOOL isCrash = YES;
    BSGSessionWriteCrashReport(writer);

    if (isCrash) {
        writer->addJSONElement(writer, "config", bsg_g_bugsnag_data.configJSON);
        writer->addJSONElement(writer, "metaData", bsg_g_bugsnag_data.metadataJSON);
        writer->addJSONElement(writer, "state", bsg_g_bugsnag_data.stateJSON);

        writer->beginObject(writer, "app"); {
            if (bsg_runContext->memoryLimit) {
                writer->addUIntegerElement(writer, "freeMemory", bsg_runContext->memoryAvailable);
                writer->addUIntegerElement(writer, "memoryLimit", bsg_runContext->memoryLimit);
            }
            if (bsg_runContext->memoryFootprint) {
                writer->addUIntegerElement(writer, "memoryUsage", bsg_runContext->memoryFootprint);
            }
        }
        writer->endContainer(writer);

#if BSG_HAVE_BATTERY
        if (BSGIsBatteryStateKnown(bsg_runContext->batteryState)) {
            writer->addFloatingPointElement(writer, "batteryLevel", bsg_runContext->batteryLevel);
            writer->addBooleanElement(writer, "charging", BSGIsBatteryCharging(bsg_runContext->batteryState));
        }
#endif
#if TARGET_OS_IOS
        writer->addIntegerElement(writer, "orientation", bsg_runContext->lastKnownOrientation);
#endif
        writer->addBooleanElement(writer, "isLaunching", bsg_runContext->isLaunching);
        writer->addIntegerElement(writer, "thermalState", bsg_runContext->thermalState);

        BugsnagBreadcrumbsWriteCrashReport(writer);

        // Create a file to indicate that the crash has been handled by
        // the library. This exists in case the subsequent `onCrash` handler
        // crashes or otherwise corrupts the crash report file.
        int fd = open(crashSentinelPath, O_RDWR | O_CREAT, 0644);
        if (fd > -1) {
            close(fd);
        }
    }

    if (bsg_g_bugsnag_data.usageJSON) {
        writer->addJSONElement(writer, "_usage", bsg_g_bugsnag_data.usageJSON);
    }

    if (bsg_g_bugsnag_data.onCrash) {
        bsg_g_bugsnag_data.onCrash(writer);
    }
}

// =============================================================================

// MARK: -

BSG_OBJC_DIRECT_MEMBERS
@interface BugsnagClient () <BSGBreadcrumbSink>

@property (nonatomic) BSGNotificationBreadcrumbs *notificationBreadcrumbs;

@property (weak, nonatomic) NSTimer *appLaunchTimer;

@property (nullable, retain, nonatomic) BugsnagBreadcrumbs *breadcrumbStore;

@property (readwrite, nullable, nonatomic) BugsnagLastRunInfo *lastRunInfo;

@property (strong, nonatomic) BugsnagSessionTracker *sessionTracker;

@end

@interface BugsnagClient (/* not objc_direct */)

- (void)appLaunchTimerFired:(NSTimer *)timer;

- (void)applicationWillTerminate:(NSNotification *)notification;

@end

#if BSG_HAVE_APP_HANG_DETECTION
@interface BugsnagClient () <BSGAppHangDetectorDelegate>
@end
#endif

// MARK: -

#if __clang_major__ >= 11 // Xcode 10 does not like the following attribute
__attribute__((annotate("oclint:suppress[long class]")))
__attribute__((annotate("oclint:suppress[too many methods]")))
#endif
BSG_OBJC_DIRECT_MEMBERS
@implementation BugsnagClient

- (instancetype)initWithConfiguration:(BugsnagConfiguration *)configuration {
    if ((self = [super init])) {
        // Take a shallow copy of the configuration
        _configuration = [configuration copy];
        
        if (!_configuration.user.id) { // populate with an autogenerated ID if no value set
            [_configuration setUser:[BSG_KSSystemInfo deviceAndAppHash] withEmail:_configuration.user.email andName:_configuration.user.name];
        }

        _featureFlagStore = [configuration.featureFlagStore copy];
        
        _state = [[BugsnagMetadata alloc] initWithDictionary:@{
            BSGKeyClient: @{
                BSGKeyContext: _configuration.context ?: [NSNull null],
                BSGKeyFeatureFlags: BSGFeatureFlagStoreToJSON(_featureFlagStore),
            },
            BSGKeyUser: [_configuration.user toJson] ?: @{}
        }];
        
        _notifier = _configuration.notifier ?: [[BugsnagNotifier alloc] init];

        BSGFileLocations *fileLocations = [BSGFileLocations current];
        
        NSString *crashPath = fileLocations.flagHandledCrash;
        crashSentinelPath = strdup(crashPath.fileSystemRepresentation);
        
        self.stateEventBlocks = [NSMutableArray new];
        self.extraRuntimeInfo = [NSMutableDictionary new];

        _eventUploader = [[BSGEventUploader alloc] initWithConfiguration:_configuration notifier:_notifier];
        bsg_g_bugsnag_data.onCrash = (void (*)(const BSG_KSCrashReportWriter *))self.configuration.onCrashHandler;

        _breadcrumbStore = [[BugsnagBreadcrumbs alloc] initWithConfiguration:self.configuration];

        // Start with a copy of the configuration metadata
        self.metadata = [[_configuration metadata] copy];
    }
    return self;
}

- (void)start {
    // Called here instead of in init so that a bad config will only throw an exception
    // from the start method.
    [self.configuration validate];

    // MUST be called before any code that accesses bsg_runContext
    BSGRunContextInit(BSGFileLocations.current.runContext);

    BSGCrashSentryInstall(self.configuration, BSSerializeDataCrashHandler);

    self.systemState = [[BugsnagSystemState alloc] initWithConfiguration:self.configuration];

    // add metadata about app/device
    NSDictionary *systemInfo = [BSG_KSSystemInfo systemInfo];
    [self.metadata addMetadata:BSGParseAppMetadata(@{@"system": systemInfo}) toSection:BSGKeyApp];
    [self.metadata addMetadata:BSGParseDeviceMetadata(@{@"system": systemInfo}) toSection:BSGKeyDevice];

    [self computeDidCrashLastLaunch];

    if (self.configuration.telemetry & BSGTelemetryInternalErrors) {
        BSGInternalErrorReporter.sharedInstance =
        [[BSGInternalErrorReporter alloc] initWithApiKey:self.configuration.apiKey
                                                endpoint:(NSURL *_Nonnull)self.configuration.notifyURL];
    } else {
        bsg_log_debug(@"Internal error reporting was disabled in config");
    }

    NSDictionary *usage = BSGTelemetryCreateUsage(self.configuration);
    if (usage) {
        bsg_g_bugsnag_data.usageJSON = BSGCStringWithData(BSGJSONDataFromDictionary(usage, NULL));
    }

    // These files can only be overwritten once the previous contents have been read; see -generateEventForLastLaunchWithError:
    NSData *configData = BSGJSONDataFromDictionary(self.configuration.dictionaryRepresentation, NULL);
    [configData writeToFile:BSGFileLocations.current.configuration options:NSDataWritingAtomic error:nil];
    bsg_g_bugsnag_data.configJSON = BSGCStringWithData(configData);
    [self.metadata setStorageBuffer:&bsg_g_bugsnag_data.metadataJSON file:BSGFileLocations.current.metadata];
    [self.state setStorageBuffer:&bsg_g_bugsnag_data.stateJSON file:BSGFileLocations.current.state];
    [self.breadcrumbStore removeAllBreadcrumbs];

#if BSG_HAVE_REACHABILITY
    [self setupConnectivityListener];
#endif

    self.notificationBreadcrumbs = [[BSGNotificationBreadcrumbs alloc] initWithConfiguration:self.configuration breadcrumbSink:self];
    [self.notificationBreadcrumbs start];

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

    [center addObserver:self
               selector:@selector(applicationWillTerminate:)
#if TARGET_OS_OSX
                   name:NSApplicationWillTerminateNotification
#else
                   name:UIApplicationWillTerminateNotification
#endif
                 object:nil];

    self.started = YES;

    id<BugsnagPlugin> reactNativePlugin = [NSClassFromString(@"BugsnagReactNativePlugin") new];
    if (reactNativePlugin) {
        [self.configuration.plugins addObject:reactNativePlugin];
    }
    for (id<BugsnagPlugin> plugin in self.configuration.plugins) {
        @try {
            [plugin load:self];
        } @catch (NSException *exception) {
            bsg_log_err(@"Plugin %@ threw exception in -load: %@", plugin, exception);
        }
    }

    self.sessionTracker = [[BugsnagSessionTracker alloc] initWithConfig:self.configuration client:self];
    [self.sessionTracker startWithNotificationCenter:center isInForeground:bsg_runContext->isForeground];

    // Record a "Bugsnag Loaded" message
    [self addAutoBreadcrumbOfType:BSGBreadcrumbTypeState withMessage:@"Bugsnag loaded" andMetadata:nil];

    if (self.configuration.launchDurationMillis > 0) {
        self.appLaunchTimer = [NSTimer scheduledTimerWithTimeInterval:(double)self.configuration.launchDurationMillis / 1000.0
                                                               target:self selector:@selector(appLaunchTimerFired:)
                                                             userInfo:nil repeats:NO];
    }
    
    if (self.lastRunInfo.crashedDuringLaunch && self.configuration.sendLaunchCrashesSynchronously) {
        [self sendLaunchCrashSynchronously];
    }
    
    if (self.eventFromLastLaunch) {
        [self.eventUploader uploadEvent:(BugsnagEvent * _Nonnull)self.eventFromLastLaunch completionHandler:nil];
        self.eventFromLastLaunch = nil;
    }
    
    [self.eventUploader uploadStoredEvents];
    
#if BSG_HAVE_APP_HANG_DETECTION
    // App hang detector deliberately started after sendLaunchCrashSynchronously (which by design may itself trigger an app hang)
    // Note: BSGAppHangDetector itself checks configuration.enabledErrorTypes.appHangs
    [self startAppHangDetector];
#endif
}

- (void)appLaunchTimerFired:(__unused NSTimer *)timer {
    [self markLaunchCompleted];
}

- (void)markLaunchCompleted {
    bsg_log_debug(@"App has finished launching");
    [self.appLaunchTimer invalidate];
    bsg_runContext->isLaunching = NO;
    BSGRunContextUpdateTimestamp();
}

- (void)sendLaunchCrashSynchronously {
    if (self.configuration.session.delegateQueue == NSOperationQueue.currentQueue) {
        bsg_log_warn(@"Cannot send launch crash synchronously because session.delegateQueue is set to the current queue.");
        return;
    }
    bsg_log_info(@"Sending launch crash synchronously.");
    dispatch_time_t deadline = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_block_t completionHandler = ^{
        bsg_log_debug(@"Sent launch crash.");
        dispatch_semaphore_signal(semaphore);
    };
    if (self.eventFromLastLaunch) {
        [self.eventUploader uploadEvent:(BugsnagEvent * _Nonnull)self.eventFromLastLaunch completionHandler:completionHandler];
        self.eventFromLastLaunch = nil;
    } else {
        [self.eventUploader uploadLatestStoredEvent:completionHandler];
    }
    if (dispatch_semaphore_wait(semaphore, deadline)) {
        bsg_log_debug(@"Timed out waiting for launch crash to be sent.");
    }
}

- (void)computeDidCrashLastLaunch {
    BOOL didCrash = NO;
    
    // Did the app crash in a way that was detected by KSCrash?
    if (bsg_kscrashstate_currentState()->crashedLastLaunch || !access(crashSentinelPath, F_OK)) {
        bsg_log_info(@"Last run terminated due to a crash.");
        unlink(crashSentinelPath);
        didCrash = YES;
    }
#if BSG_HAVE_APP_HANG_DETECTION
    // Was the app terminated while the main thread was hung?
    else if ((self.eventFromLastLaunch = [self loadAppHangEvent]).unhandled) {
        bsg_log_info(@"Last run terminated during an app hang.");
        didCrash = YES;
    }
#endif
#if !TARGET_OS_WATCH
    else if (self.configuration.autoDetectErrors && BSGRunContextWasKilled()) {
        if (BSGRunContextWasCriticalThermalState()) {
            bsg_log_info(@"Last run terminated during a critical thermal state.");
            if (self.configuration.enabledErrorTypes.thermalKills) {
                self.eventFromLastLaunch = [self generateThermalKillEvent];
            }
            didCrash = YES;
        }
#if BSG_HAVE_OOM_DETECTION
        else {
            bsg_log_info(@"Last run terminated unexpectedly; possible Out Of Memory.");
            if (self.configuration.enabledErrorTypes.ooms) {
                self.eventFromLastLaunch = [self generateOutOfMemoryEvent];
            }
            didCrash = YES;
        }
#endif
    }
#endif
    
    self.appDidCrashLastLaunch = didCrash;
    
    BOOL didCrashDuringLaunch = didCrash && BSGRunContextWasLaunching();
    if (didCrashDuringLaunch) {
        self.systemState.consecutiveLaunchCrashes++;
    } else {
        self.systemState.consecutiveLaunchCrashes = 0;
    }
    
    self.lastRunInfo = [[BugsnagLastRunInfo alloc] initWithConsecutiveLaunchCrashes:self.systemState.consecutiveLaunchCrashes
                                                                            crashed:didCrash
                                                                crashedDuringLaunch:didCrashDuringLaunch];
}

- (void)setCodeBundleId:(NSString *)codeBundleId {
    _codeBundleId = codeBundleId;
    [self.state addMetadata:codeBundleId withKey:BSGKeyCodeBundleId toSection:BSGKeyApp];
    [self.systemState setCodeBundleID:codeBundleId];
    self.sessionTracker.codeBundleId = codeBundleId;
}

/**
 * Removes observers and listeners to prevent allocations when the app is terminated
 */
- (void)applicationWillTerminate:(__unused NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self.sessionTracker];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#if BSG_HAVE_REACHABILITY
    [BSGConnectivity stopMonitoring];
#endif

#if BSG_HAVE_BATTERY
    BSGGetDevice().batteryMonitoringEnabled = FALSE;
#endif

#if TARGET_OS_IOS
    [[UIDEVICE currentDevice] endGeneratingDeviceOrientationNotifications];
#endif
}

// =============================================================================
// MARK: - Session Tracking
// =============================================================================

- (void)startSession {
    [self.sessionTracker startNewSession];
}

- (void)pauseSession {
    [self.sessionTracker pauseSession];
}

- (BOOL)resumeSession {
    return [self.sessionTracker resumeSession];
}

- (BugsnagSession *)session {
    return self.sessionTracker.runningSession;
}

- (void)updateSession:(BugsnagSession * (^)(BugsnagSession *session))block {
    self.sessionTracker.currentSession =  block(self.sessionTracker.currentSession);
    BSGSessionUpdateRunContext(self.sessionTracker.runningSession);
}

// =============================================================================
// MARK: - Connectivity Listener
// =============================================================================

#if BSG_HAVE_REACHABILITY
/**
 * Monitor the Bugsnag endpoint to detect changes in connectivity,
 * flush pending events when (re)connected and report connectivity
 * changes as breadcrumbs, if configured to do so.
 */
- (void)setupConnectivityListener {
    NSURL *url = self.configuration.notifyURL;

    // ARC Reference - 4.2 __weak Semantics
    // http://clang.llvm.org/docs/AutomaticReferenceCounting.html
    // Avoid potential strong reference cycle between the 'client' instance and
    // the BSGConnectivity static storage.
    __weak typeof(self) weakSelf = self;
    [BSGConnectivity monitorURL:url
                  usingCallback:^(BOOL connected, NSString *connectionType) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (connected) {
            [strongSelf.eventUploader uploadStoredEvents];
            [strongSelf.sessionTracker.sessionUploader processStoredSessions];
        }

        [strongSelf addAutoBreadcrumbOfType:BSGBreadcrumbTypeState
                                withMessage:@"Connectivity changed"
                                andMetadata:@{@"type": connectionType}];
    }];
}
#endif

// =============================================================================
// MARK: - Breadcrumbs
// =============================================================================

- (void)leaveBreadcrumbWithMessage:(NSString *_Nonnull)message {
    [self leaveBreadcrumbWithMessage:message metadata:nil andType:BSGBreadcrumbTypeManual];
}

- (void)leaveBreadcrumbForNotificationName:(NSString *_Nonnull)notificationName {
    [self.notificationBreadcrumbs startListeningForStateChangeNotification:notificationName];
}

- (void)leaveBreadcrumbWithMessage:(NSString *_Nonnull)message
                          metadata:(NSDictionary *_Nullable)metadata
                           andType:(BSGBreadcrumbType)type {
    NSDictionary *JSONMetadata = BSGJSONDictionary(metadata ?: @{});
    if (JSONMetadata != metadata && metadata) {
        bsg_log_warn("Breadcrumb metadata is not a valid JSON object: %@", metadata);
    }
    
    BugsnagBreadcrumb *breadcrumb = [BugsnagBreadcrumb new];
    breadcrumb.message = message;
    breadcrumb.metadata = JSONMetadata ?: @{};
    breadcrumb.type = type;
    [self.breadcrumbStore addBreadcrumb:breadcrumb];
    
    BSGRunContextUpdateTimestamp();
}

- (void)leaveNetworkRequestBreadcrumbForTask:(NSURLSessionTask *)task
                                     metrics:(NSURLSessionTaskMetrics *)metrics {
    if (!(self.configuration.enabledBreadcrumbTypes & BSGEnabledBreadcrumbTypeRequest)) {
        return;
    }
    BugsnagBreadcrumb *breadcrumb = BSGNetworkBreadcrumbWithTaskMetrics(task, metrics);
    if (!breadcrumb) {
        return;
    }
    [self.breadcrumbStore addBreadcrumb:breadcrumb];
    BSGRunContextUpdateTimestamp();
}

- (NSArray<BugsnagBreadcrumb *> *)breadcrumbs {
    return self.breadcrumbStore.breadcrumbs ?: @[];
}

// =============================================================================
// MARK: - User
// =============================================================================

- (BugsnagUser *)user {
    @synchronized (self.configuration) {
        return self.configuration.user;
    }
}

- (void)setUser:(NSString *)userId withEmail:(NSString *)email andName:(NSString *)name {
    @synchronized (self.configuration) {
        [self.configuration setUser:userId withEmail:email andName:name];
        [self.state addMetadata:[self.configuration.user toJson] toSection:BSGKeyUser];
        if (self.observer) {
            self.observer(BSGClientObserverUpdateUser, self.user);
        }
    }
}

// =============================================================================
// MARK: - onSession
// =============================================================================

- (nonnull BugsnagOnSessionRef)addOnSessionBlock:(nonnull BugsnagOnSessionBlock)block {
    return [self.configuration addOnSessionBlock:block];
}

- (void)removeOnSession:(nonnull BugsnagOnSessionRef)callback {
    [self.configuration removeOnSession:callback];
}

- (void)removeOnSessionBlock:(BugsnagOnSessionBlock _Nonnull )block {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [self.configuration removeOnSessionBlock:block];
#pragma clang diagnostic pop
}

// =============================================================================
// MARK: - onBreadcrumb
// =============================================================================

- (nonnull BugsnagOnBreadcrumbRef)addOnBreadcrumbBlock:(nonnull BugsnagOnBreadcrumbBlock)block {
    return [self.configuration addOnBreadcrumbBlock:block];
}

- (void)removeOnBreadcrumb:(nonnull BugsnagOnBreadcrumbRef)callback {
    [self.configuration removeOnBreadcrumb:callback];
}

- (void)removeOnBreadcrumbBlock:(BugsnagOnBreadcrumbBlock _Nonnull)block {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [self.configuration removeOnBreadcrumbBlock:block];
#pragma clang diagnostic pop
}

// =============================================================================
// MARK: - Context
// =============================================================================

- (void)setContext:(nullable NSString *)context {
    self.configuration.context = context;
    [self.state addMetadata:context withKey:BSGKeyContext toSection:BSGKeyClient];
    if (self.observer) {
        self.observer(BSGClientObserverUpdateContext, context);
    }
}

- (NSString *)context {
    return self.configuration.context;
}

// MARK: - Notify

// note - some duplication between notifyError calls is required to ensure
// the same number of stackframes are used for each call.
// see notify:handledState:block for further info

- (void)notifyError:(NSError *)error {
    bsg_log_debug(@"%s %@", __PRETTY_FUNCTION__, error);
    [self notifyErrorOrException:error block:nil];
}

- (void)notifyError:(NSError *)error block:(BugsnagOnErrorBlock)block {
    bsg_log_debug(@"%s %@", __PRETTY_FUNCTION__, error);
    [self notifyErrorOrException:error block:block];
}

- (void)notify:(NSException *)exception {
    bsg_log_debug(@"%s %@", __PRETTY_FUNCTION__, exception);
    [self notifyErrorOrException:exception block:nil];
}

- (void)notify:(NSException *)exception block:(BugsnagOnErrorBlock)block {
    bsg_log_debug(@"%s %@", __PRETTY_FUNCTION__, exception);
    [self notifyErrorOrException:exception block:block];
}

// MARK: - Notify (Internal)

- (void)notifyErrorOrException:(id)errorOrException block:(BugsnagOnErrorBlock)block {
    NSDictionary *systemInfo = [BSG_KSSystemInfo systemInfo];
    BugsnagMetadata *metadata = [self.metadata copy];
    
    NSArray<NSNumber *> *callStack = nil;
    NSString *context = self.context;
    NSString *errorClass = nil;
    NSString *errorMessage = nil;
    BugsnagHandledState *handledState = nil;
    
    if ([errorOrException isKindOfClass:[NSException class]]) {
        NSException *exception = errorOrException;
        callStack = exception.callStackReturnAddresses;
        errorClass = exception.name;
        errorMessage = exception.reason;
        handledState = [BugsnagHandledState handledStateWithSeverityReason:HandledException];
        NSMutableDictionary *meta = [NSMutableDictionary dictionary];
        NSDictionary *userInfo = exception.userInfo ? BSGJSONDictionary((NSDictionary *_Nonnull)exception.userInfo) : nil;
        meta[@"nsexception"] = [NSDictionary dictionaryWithObjectsAndKeys:exception.name, @"name", userInfo, @"userInfo", nil];
        meta[@"reason"] = exception.reason;
        meta[@"type"] = @"nsexception";
        [metadata addMetadata:meta toSection:@"error"];
    }
    else if ([errorOrException isKindOfClass:[NSError class]]) {
        NSError *error = errorOrException;
        if (!context) {
            context = [NSString stringWithFormat:@"%@ (%ld)", error.domain, (long)error.code];
        }
        errorClass = NSStringFromClass([error class]);
        errorMessage = error.localizedDescription;
        handledState = [BugsnagHandledState handledStateWithSeverityReason:HandledError];
        NSMutableDictionary *meta = [NSMutableDictionary dictionary];
        meta[@"code"] = @(error.code);
        meta[@"domain"] = error.domain;
        meta[@"reason"] = error.localizedFailureReason;
        meta[@"userInfo"] = BSGJSONDictionary(error.userInfo);
        [metadata addMetadata:meta toSection:@"nserror"];
    }
    else {
        bsg_log_warn(@"Unsupported error type passed to notify: %@", NSStringFromClass([errorOrException class]));
        return;
    }
    
    /**
     * Stack frames starting from this one are removed by setting the depth.
     * This helps remove bugsnag frames from showing in NSErrors as their
     * trace is synthesized.
     *
     * For example, for [Bugsnag notifyError:block:], bugsnag adds the following
     * frames which must be removed:
     *
     * 1. +[Bugsnag notifyError:block:]
     * 2. -[BugsnagClient notifyError:block:]
     * 3. -[BugsnagClient notify:handledState:block:]
     */
    NSUInteger depth = 3;
    
    if (!callStack.count) {
        // If the NSException was not raised by the Objective-C runtime, it will be missing a call stack.
        // Use the current call stack instead.
        callStack = BSGArraySubarrayFromIndex(NSThread.callStackReturnAddresses, depth);
    }
    
#if BSG_HAVE_MACH_THREADS
    BOOL recordAllThreads = self.configuration.sendThreads == BSGThreadSendPolicyAlways;
    NSArray *threads = recordAllThreads ? [BugsnagThread allThreads:YES callStackReturnAddresses:callStack] : @[];
#else
    NSArray *threads = @[];
#endif
    
    NSArray<BugsnagStackframe *> *stacktrace = [BugsnagStackframe stackframesWithCallStackReturnAddresses:callStack];
    
    BugsnagError *error = [[BugsnagError alloc] initWithErrorClass:errorClass
                                                      errorMessage:errorMessage
                                                         errorType:BSGErrorTypeCocoa
                                                        stacktrace:stacktrace];

    BugsnagEvent *event = [[BugsnagEvent alloc] initWithApp:[self generateAppWithState:systemInfo]
                                                     device:[self generateDeviceWithState:systemInfo]
                                               handledState:handledState
                                                       user:[self.user withId]
                                                   metadata:metadata
                                                breadcrumbs:[self breadcrumbs]
                                                     errors:@[error]
                                                    threads:threads
                                                    session:nil /* the session's event counts have not yet been incremented! */];
    event.apiKey = self.configuration.apiKey;
    event.context = context;
    event.originalError = errorOrException;

    [self notifyInternal:event block:block];
}

/**
 *  Notify Bugsnag of an exception. Used for user-reported (handled) errors, React Native, and Unity.
 *
 *  @param event    the event
 *  @param block     Configuration block for adding additional report information
 */
- (void)notifyInternal:(BugsnagEvent *_Nonnull)event
                 block:(BugsnagOnErrorBlock)block
{
    NSString *errorClass = event.errors.firstObject.errorClass;
    if ([self.configuration shouldDiscardErrorClass:errorClass]) {
        bsg_log_info(@"Discarding event because errorClass \"%@\" matched configuration.discardClasses", errorClass);
        return;
    }
    
#if TARGET_OS_WATCH
    // Update BSGRunContext because we cannot observe battery level or state on watchOS :-(
    bsg_runContext->batteryLevel = BSGGetDevice().batteryLevel;
    bsg_runContext->batteryState = BSGGetDevice().batteryState;
#endif
    [event.metadata addMetadata:BSGAppMetadataFromRunContext(bsg_runContext) toSection:BSGKeyApp];
    [event.metadata addMetadata:BSGDeviceMetadataFromRunContext(bsg_runContext) toSection:BSGKeyDevice];

    // App hang events will already contain feature flags
    if (!event.featureFlagStore.count) {
        @synchronized (self.featureFlagStore) {
            event.featureFlagStore = [self.featureFlagStore copy];
        }
    }

    event.user = [event.user withId];

    BOOL originalUnhandledValue = event.unhandled;
    @try {
        if (block != nil && !block(event)) { // skip notifying if callback false
            return;
        }
    } @catch (NSException *exception) {
        bsg_log_err(@"Error from onError callback: %@", exception);
    }
    if (event.unhandled != originalUnhandledValue) {
        [event notifyUnhandledOverridden];
    }

    [self.sessionTracker incrementEventCountUnhandled:event.handledState.unhandled];
    event.session = self.sessionTracker.runningSession;

    event.usage = BSGTelemetryCreateUsage(self.configuration);

    if (event.unhandled) {
        // Unhandled Javscript exceptions from React Native result in the app being terminated shortly after the
        // call to notifyInternal, so the event needs to be persisted to disk for sending in the next session.
        // The fatal "RCTFatalException" / "Unhandled JS Exception" is explicitly ignored by
        // BugsnagReactNativePlugin's OnSendErrorBlock.
        [self.eventUploader storeEvent:event];
        // Replicate previous delivery mechanism's behaviour of waiting 1 second before delivering the event.
        // This should prevent potential duplicate uploads of unhandled errors where the app subsequently terminates.
        [self.eventUploader uploadStoredEventsAfterDelay:1];
    } else {
        [self.eventUploader uploadEvent:event completionHandler:nil];
    }

    [self addAutoBreadcrumbForEvent:event];
}

// MARK: - Breadcrumbs

- (void)addAutoBreadcrumbForEvent:(BugsnagEvent *)event {
    // A basic set of event metadata
    NSMutableDictionary *metadata = [NSMutableDictionary dictionary];
    metadata[BSGKeyErrorClass] = event.errors[0].errorClass;
    metadata[BSGKeyUnhandled] = @(event.handledState.unhandled);
    metadata[BSGKeySeverity] = BSGFormatSeverity(event.severity);

    // Only include the eventMessage if it contains something
    NSString *eventMessage = event.errors[0].errorMessage;
    if (eventMessage.length) {
        [metadata setValue:eventMessage forKey:BSGKeyName];
    }

    [self addAutoBreadcrumbOfType:BSGBreadcrumbTypeError
                      withMessage:event.errors[0].errorClass ?: @""
                      andMetadata:metadata];
}

/**
 * A convenience safe-wrapper for conditionally recording automatic breadcrumbs
 * based on the configuration.
 *
 * @param breadcrumbType The type of breadcrumb
 * @param message The breadcrumb message
 * @param metadata The breadcrumb metadata.  If nil this is substituted by an empty dictionary.
 */
- (void)addAutoBreadcrumbOfType:(BSGBreadcrumbType)breadcrumbType
                    withMessage:(NSString * _Nonnull)message
                    andMetadata:(NSDictionary *)metadata
{
    if ([[self configuration] shouldRecordBreadcrumbType:breadcrumbType]) {
        [self leaveBreadcrumbWithMessage:message metadata:metadata andType:breadcrumbType];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// MARK: - <BugsnagFeatureFlagStore>

- (void)addFeatureFlagWithName:(NSString *)name variant:(nullable NSString *)variant {
    @synchronized (self.featureFlagStore) {
        BSGFeatureFlagStoreAddFeatureFlag(self.featureFlagStore, name, variant);
        [self.state addMetadata:BSGFeatureFlagStoreToJSON(self.featureFlagStore) withKey:BSGKeyFeatureFlags toSection:BSGKeyClient];
    }
    if (self.observer) {
        self.observer(BSGClientObserverAddFeatureFlag, [BugsnagFeatureFlag flagWithName:name variant:variant]);
    }
}

- (void)addFeatureFlagWithName:(NSString *)name {
    @synchronized (self.featureFlagStore) {
        BSGFeatureFlagStoreAddFeatureFlag(self.featureFlagStore, name, nil);
        [self.state addMetadata:BSGFeatureFlagStoreToJSON(self.featureFlagStore) withKey:BSGKeyFeatureFlags toSection:BSGKeyClient];
    }
    if (self.observer) {
        self.observer(BSGClientObserverAddFeatureFlag, [BugsnagFeatureFlag flagWithName:name]);
    }
}

- (void)addFeatureFlags:(NSArray<BugsnagFeatureFlag *> *)featureFlags {
    @synchronized (self.featureFlagStore) {
        BSGFeatureFlagStoreAddFeatureFlags(self.featureFlagStore, featureFlags);
        [self.state addMetadata:BSGFeatureFlagStoreToJSON(self.featureFlagStore) withKey:BSGKeyFeatureFlags toSection:BSGKeyClient];
    }
    if (self.observer) {
        for (BugsnagFeatureFlag *featureFlag in featureFlags) {
            self.observer(BSGClientObserverAddFeatureFlag, featureFlag);
        }
    }
}

- (void)clearFeatureFlagWithName:(NSString *)name {
    @synchronized (self.featureFlagStore) {
        BSGFeatureFlagStoreClear(self.featureFlagStore, name);
        [self.state addMetadata:BSGFeatureFlagStoreToJSON(self.featureFlagStore) withKey:BSGKeyFeatureFlags toSection:BSGKeyClient];
    }
    if (self.observer) {
        self.observer(BSGClientObserverClearFeatureFlag, name);
    }
}

- (void)clearFeatureFlags {
    @synchronized (self.featureFlagStore) {
        BSGFeatureFlagStoreClear(self.featureFlagStore, nil);
        [self.state addMetadata:BSGFeatureFlagStoreToJSON(self.featureFlagStore) withKey:BSGKeyFeatureFlags toSection:BSGKeyClient];
    }
    if (self.observer) {
        self.observer(BSGClientObserverClearFeatureFlag, nil);
    }
}

// MARK: - <BugsnagMetadataStore>

- (void)addMetadata:(NSDictionary *_Nonnull)metadata
          toSection:(NSString *_Nonnull)sectionName
{
    [self.metadata addMetadata:metadata toSection:sectionName];
}

- (void)addMetadata:(id _Nullable)metadata
            withKey:(NSString *_Nonnull)key
          toSection:(NSString *_Nonnull)sectionName
{
    [self.metadata addMetadata:metadata withKey:key toSection:sectionName];
}

- (id _Nullable)getMetadataFromSection:(NSString *_Nonnull)sectionName
                               withKey:(NSString *_Nonnull)key
{
    return [self.metadata getMetadataFromSection:sectionName withKey:key];
}

- (NSMutableDictionary *_Nullable)getMetadataFromSection:(NSString *_Nonnull)sectionName
{
    return [self.metadata getMetadataFromSection:sectionName];
}

- (void)clearMetadataFromSection:(NSString *_Nonnull)sectionName
{
    [self.metadata clearMetadataFromSection:sectionName];
}

- (void)clearMetadataFromSection:(NSString *_Nonnull)sectionName
                       withKey:(NSString *_Nonnull)key
{
    [self.metadata clearMetadataFromSection:sectionName withKey:key];
}

// MARK: - event data population

- (BugsnagAppWithState *)generateAppWithState:(NSDictionary *)systemInfo {
    BugsnagAppWithState *app = [BugsnagAppWithState appWithDictionary:@{BSGKeySystem: systemInfo}
                                                               config:self.configuration codeBundleId:self.codeBundleId];
    app.isLaunching = bsg_runContext->isLaunching;
    return app;
}

- (BugsnagDeviceWithState *)generateDeviceWithState:(NSDictionary *)systemInfo {
    BugsnagDeviceWithState *device = [BugsnagDeviceWithState deviceWithKSCrashReport:@{BSGKeySystem: systemInfo}];
    device.time = [NSDate date]; // default to current time for handled errors
    [device appendRuntimeInfo:self.extraRuntimeInfo];
#if TARGET_OS_IOS
    device.orientation = BSGStringFromDeviceOrientation(bsg_runContext->lastKnownOrientation);
#endif
    return device;
}

// MARK: - methods used by React Native

- (void)addRuntimeVersionInfo:(NSString *)info
                      withKey:(NSString *)key {
    [self.sessionTracker addRuntimeVersionInfo:info
                                       withKey:key];
    if (info != nil && key != nil) {
        self.extraRuntimeInfo[key] = info;
    }
    [self.state addMetadata:self.extraRuntimeInfo withKey:BSGKeyExtraRuntimeInfo toSection:BSGKeyDevice];
}

- (void)setObserver:(BSGClientObserver)observer {
    _observer = observer;
    if (observer) {
        observer(BSGClientObserverUpdateContext, self.context);
        observer(BSGClientObserverUpdateUser, self.user);
        
        observer(BSGClientObserverUpdateMetadata, self.metadata);
        self.metadata.observer = ^(BugsnagMetadata *metadata) {
            observer(BSGClientObserverUpdateMetadata, metadata);
        };
        
        @synchronized (self.featureFlagStore) {
            for (BugsnagFeatureFlag *flag in self.featureFlagStore.allFlags) {
                observer(BSGClientObserverAddFeatureFlag, flag);
            }
        }
    } else {
        self.metadata.observer = nil;
    }
}

// MARK: - App Hangs

#if BSG_HAVE_APP_HANG_DETECTION
- (void)startAppHangDetector {
    [NSFileManager.defaultManager removeItemAtPath:BSGFileLocations.current.appHangEvent error:nil];

    self.appHangDetector = [[BSGAppHangDetector alloc] init];
    [self.appHangDetector startWithDelegate:self];
}
#endif

- (void)appHangDetectedAtDate:(NSDate *)date withThreads:(NSArray<BugsnagThread *> *)threads systemInfo:(NSDictionary *)systemInfo {
#if BSG_HAVE_APP_HANG_DETECTION
    NSString *message = [NSString stringWithFormat:@"The app's main thread failed to respond to an event within %d milliseconds",
                         (int)self.configuration.appHangThresholdMillis];

    BugsnagError *error =
    [[BugsnagError alloc] initWithErrorClass:@"App Hang"
                                errorMessage:message
                                   errorType:BSGErrorTypeCocoa
                                  stacktrace:threads.firstObject.stacktrace];

    BugsnagHandledState *handledState =
    [[BugsnagHandledState alloc] initWithSeverityReason:AppHang
                                               severity:BSGSeverityWarning
                                              unhandled:NO
                                    unhandledOverridden:NO
                                              attrValue:nil];

    BugsnagAppWithState *app = [self generateAppWithState:systemInfo];

    BugsnagDeviceWithState *device = [self generateDeviceWithState:systemInfo];
    device.time = date;

    NSArray<BugsnagBreadcrumb *> *breadcrumbs = [self.breadcrumbStore breadcrumbsBeforeDate:date];

    BugsnagMetadata *metadata = [self.metadata copy];

    [metadata addMetadata:BSGAppMetadataFromRunContext(bsg_runContext) toSection:BSGKeyApp];
    [metadata addMetadata:BSGDeviceMetadataFromRunContext(bsg_runContext) toSection:BSGKeyDevice];

    self.appHangEvent =
    [[BugsnagEvent alloc] initWithApp:app
                               device:device
                         handledState:handledState
                                 user:[self.user withId]
                             metadata:metadata
                          breadcrumbs:breadcrumbs
                               errors:@[error]
                              threads:threads
                              session:self.sessionTracker.runningSession];

    self.appHangEvent.context = self.context;

    @synchronized (self.featureFlagStore) {
        self.appHangEvent.featureFlagStore = [self.featureFlagStore copy];
    }
    
    [self.appHangEvent symbolicateIfNeeded];
    
    NSError *writeError = nil;
    NSDictionary *json = [self.appHangEvent toJsonWithRedactedKeys:self.configuration.redactedKeys];
    if (!BSGJSONWriteToFileAtomically(json, BSGFileLocations.current.appHangEvent, &writeError)) {
        bsg_log_err(@"Could not write app_hang.json: %@", writeError);
    }
#endif
}

- (void)appHangEnded {
#if BSG_HAVE_APP_HANG_DETECTION
    NSError *error = nil;
    if (![NSFileManager.defaultManager removeItemAtPath:BSGFileLocations.current.appHangEvent error:&error]) {
        bsg_log_err(@"Could not delete app_hang.json: %@", error);
    }

    const BOOL fatalOnly = self.configuration.appHangThresholdMillis == BugsnagAppHangThresholdFatalOnly;
    if (!fatalOnly && self.appHangEvent) {
        [self notifyInternal:(BugsnagEvent * _Nonnull)self.appHangEvent block:nil];
    }
    self.appHangEvent = nil;
#endif
}

#if BSG_HAVE_APP_HANG_DETECTION
- (nullable BugsnagEvent *)loadAppHangEvent {
    NSError *error = nil;
    NSDictionary *json = BSGJSONDictionaryFromFile(BSGFileLocations.current.appHangEvent, 0, &error);
    if (!json) {
        if (!(error.domain == NSCocoaErrorDomain && error.code == NSFileReadNoSuchFileError)) {
            bsg_log_err(@"Could not read app_hang.json: %@", error);
        }
        return nil;
    }

    BugsnagEvent *event = [[BugsnagEvent alloc] initWithJson:json];
    if (!event) {
        bsg_log_err(@"Could not parse app_hang.json");
        return nil;
    }

    // Receipt of the willTerminateNotification indicates that an app hang was not the cause of the termination, so treat as non-fatal.
    if (BSGRunContextWasTerminating()) {
        if (self.configuration.appHangThresholdMillis == BugsnagAppHangThresholdFatalOnly) {
            return nil;
        }
        event.session.handledCount++;
        return event;
    }

    // Update event to reflect that the app hang was fatal.
    event.errors.firstObject.errorMessage = @"The app was terminated while unresponsive";
    // Cannot set event.severity directly because that sets severityReason.type to "userCallbackSetSeverity"
    event.handledState = [[BugsnagHandledState alloc] initWithSeverityReason:AppHang
                                                                    severity:BSGSeverityError
                                                                   unhandled:YES
                                                         unhandledOverridden:NO
                                                                   attrValue:nil];
    event.session.unhandledCount++;

    return event;
}
#endif

// MARK: - Event generation

- (nullable BugsnagEvent *)generateOutOfMemoryEvent {
    return [self generateEventForLastLaunchWithError:
            [[BugsnagError alloc] initWithErrorClass:@"Out Of Memory"
                                        errorMessage:@"The app was likely terminated by the operating system while in the foreground"
                                           errorType:BSGErrorTypeCocoa
                                          stacktrace:nil]
                                        handledState:[BugsnagHandledState handledStateWithSeverityReason:LikelyOutOfMemory]];
}

- (nullable BugsnagEvent *)generateThermalKillEvent {
    return [self generateEventForLastLaunchWithError:
            [[BugsnagError alloc] initWithErrorClass:@"Thermal Kill"
                                        errorMessage:@"The app was terminated by the operating system due to a critical thermal state"
                                           errorType:BSGErrorTypeCocoa
                                          stacktrace:nil]
                                        handledState:[BugsnagHandledState handledStateWithSeverityReason:ThermalKill]];
}

- (nullable BugsnagEvent *)generateEventForLastLaunchWithError:(BugsnagError *)error handledState:(BugsnagHandledState *)handledState {
    if (!bsg_lastRunContext) {
        return nil;
    }
    
    NSDictionary *stateDict = BSGJSONDictionaryFromFile(BSGFileLocations.current.state, 0, nil);

    NSDictionary *appDict = self.systemState.lastLaunchState[SYSTEMSTATE_KEY_APP];
    BugsnagAppWithState *app = [BugsnagAppWithState appFromJson:appDict];
    app.dsymUuid = appDict[BSGKeyMachoUUID];
    app.inForeground = bsg_lastRunContext->isForeground;
    app.isLaunching = bsg_lastRunContext->isLaunching;

    NSDictionary *configDict = BSGJSONDictionaryFromFile(BSGFileLocations.current.configuration, 0, nil);
    if (configDict) {
        [app setValuesFromConfiguration:[[BugsnagConfiguration alloc] initWithDictionaryRepresentation:configDict]];
    }

    NSDictionary *deviceDict = self.systemState.lastLaunchState[SYSTEMSTATE_KEY_DEVICE];
    BugsnagDeviceWithState *device = [BugsnagDeviceWithState deviceFromJson:deviceDict];
    device.manufacturer = @"Apple";
#if TARGET_OS_IOS
    device.orientation = BSGStringFromDeviceOrientation(bsg_lastRunContext->lastKnownOrientation);
#endif
    if (bsg_lastRunContext->timestamp > 0) {
        device.time = [NSDate dateWithTimeIntervalSinceReferenceDate:bsg_lastRunContext->timestamp];
    }
    device.freeMemory = @(bsg_lastRunContext->hostMemoryFree);

    NSDictionary *metadataDict = BSGJSONDictionaryFromFile(BSGFileLocations.current.metadata, 0, nil);
    BugsnagMetadata *metadata = [[BugsnagMetadata alloc] initWithDictionary:metadataDict ?: @{}];
    
    [metadata addMetadata:BSGAppMetadataFromRunContext((const struct BSGRunContext *_Nonnull)bsg_lastRunContext) toSection:BSGKeyApp];
    [metadata addMetadata:BSGDeviceMetadataFromRunContext((const struct BSGRunContext *_Nonnull)bsg_lastRunContext) toSection:BSGKeyDevice];
    
#if BSG_HAVE_OOM_DETECTION
    if (BSGRunContextWasMemoryWarning()) {
        [metadata addMetadata:@YES
                      withKey:BSGKeyLowMemoryWarning
                    toSection:BSGKeyDevice];
    }
#endif

    NSDictionary *userDict = stateDict[BSGKeyUser];
    BugsnagUser *user = [[BugsnagUser alloc] initWithDictionary:userDict];

    BugsnagSession *session = BSGSessionFromLastRunContext(app, device, user);
    session.unhandledCount += 1;

    BugsnagEvent *event =
    [[BugsnagEvent alloc] initWithApp:app
                               device:device
                         handledState:handledState
                                 user:user
                             metadata:metadata
                          breadcrumbs:[self.breadcrumbStore cachedBreadcrumbs] ?: @[]
                               errors:@[error]
                              threads:@[]
                              session:session];

    event.context = stateDict[BSGKeyClient][BSGKeyContext];

    id featureFlags = stateDict[BSGKeyClient][BSGKeyFeatureFlags];
    event.featureFlagStore = BSGFeatureFlagStoreFromJSON(featureFlags);

    return event;
}

@end
