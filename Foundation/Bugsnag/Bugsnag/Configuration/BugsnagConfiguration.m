//
//  BugsnagConfiguration.m
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

#import "BugsnagConfiguration+Private.h"

#import "BSGConfigurationBuilder.h"
#import "BSGDefines.h"
#import "BSGFeatureFlagStore.h"
#import "BSGKeys.h"
#import "BugsnagApiClient.h"
#import "BugsnagEndpointConfiguration.h"
#import "BugsnagErrorTypes.h"
#import "BugsnagLogger.h"
#import "BugsnagMetadata+Private.h"
#import "BugsnagUser+Private.h"

const NSUInteger BugsnagAppHangThresholdFatalOnly = INT_MAX;

static const int BSGApiKeyLength = 32;

// =============================================================================
// MARK: - BugsnagConfiguration
// =============================================================================

BSG_OBJC_DIRECT_MEMBERS
@implementation BugsnagConfiguration

+ (instancetype _Nonnull)loadConfig {
    NSDictionary *options = [[NSBundle mainBundle] infoDictionary][@"bugsnag"];
    return BSGConfigurationWithOptions(options);
}

// -----------------------------------------------------------------------------
// MARK: - <NSCopying>
// -----------------------------------------------------------------------------

/**
 * Produce a shallow copy of the BugsnagConfiguration object.
 *
 * @param zone This parameter is ignored. Memory zones are no longer used by Objective-C.
 */
- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    BugsnagConfiguration *copy = [[BugsnagConfiguration alloc] initWithApiKey:[self.apiKey copy]];
    // Omit apiKey - it's set explicitly in the line above
#if BSG_HAVE_APP_HANG_DETECTION
    [copy setAppHangThresholdMillis:self.appHangThresholdMillis];
    [copy setReportBackgroundAppHangs:self.reportBackgroundAppHangs];
#endif
    [copy setAppType:self.appType];
    [copy setAppVersion:self.appVersion];
    [copy setAutoDetectErrors:self.autoDetectErrors];
    [copy setAutoTrackSessions:self.autoTrackSessions];
    [copy setBundleVersion:self.bundleVersion];
    [copy setContext:self.context];
    [copy setEnabledBreadcrumbTypes:self.enabledBreadcrumbTypes];
    [copy setEnabledErrorTypes:self.enabledErrorTypes];
    [copy setEnabledReleaseStages:self.enabledReleaseStages];
    copy.discardClasses = self.discardClasses;
    [copy setRedactedKeys:self.redactedKeys];
    [copy setLaunchDurationMillis:self.launchDurationMillis];
    [copy setSendLaunchCrashesSynchronously:self.sendLaunchCrashesSynchronously];
    [copy setAttemptDeliveryOnCrash:self.attemptDeliveryOnCrash];
    [copy setMaxPersistedEvents:self.maxPersistedEvents];
    [copy setMaxPersistedSessions:self.maxPersistedSessions];
    [copy setMaxStringValueLength:self.maxStringValueLength];
    [copy setMaxBreadcrumbs:self.maxBreadcrumbs];
    [copy setNotifier:self.notifier];
    [copy setFeatureFlagStore:self.featureFlagStore];
    [copy setMetadata:self.metadata];
    [copy setEndpoints:self.endpoints];
    [copy setOnCrashHandler:self.onCrashHandler];
    [copy setPersistUser:self.persistUser];
    [copy setPlugins:[self.plugins mutableCopyWithZone:zone]];
    [copy setReleaseStage:self.releaseStage];
    copy.session = self.session; // NSURLSession does not declare conformance to NSCopying
#if BSG_HAVE_MACH_THREADS
    [copy setSendThreads:self.sendThreads];
#endif
    [copy setUser:self.user.id
        withEmail:self.user.email
          andName:self.user.name];

    // retain original blocks to allow removing blocks added in config
    // as creating a copy of the array would prevent this
    [copy setOnBreadcrumbBlocks:self.onBreadcrumbBlocks];
    [copy setOnSendBlocks:self.onSendBlocks];
    [copy setOnSessionBlocks:self.onSessionBlocks];
    [copy setTelemetry:self.telemetry];
    return copy;
}

// -----------------------------------------------------------------------------
// MARK: - Class Methods
// -----------------------------------------------------------------------------

/**
 * Determine the apiKey-validity of a passed-in string:
 * Exactly 32 hexadecimal digits.
 *
 * @param apiKey The API key.
 * @returns A boolean representing whether the apiKey is valid.
 */
+ (BOOL)isValidApiKey:(NSString *)apiKey {
    NSCharacterSet *chars = [[NSCharacterSet
        characterSetWithCharactersInString:@"0123456789ABCDEF"] invertedSet];

    BOOL isHex = (NSNotFound == [[apiKey uppercaseString] rangeOfCharacterFromSet:chars].location);

    return isHex && [apiKey length] == BSGApiKeyLength;
}

// -----------------------------------------------------------------------------
// MARK: - Initializers
// -----------------------------------------------------------------------------

/**
 * Should not be called, but if it _is_ then fail meaningfully rather than silently
 */
- (instancetype)init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:
            @"-[BugsnagConfiguration init] is unavailable.  Use -[BugsnagConfiguration initWithApiKey:] instead." userInfo:nil];
}

/**
 * The designated initializer.
 */
- (instancetype)initWithApiKey:(NSString *)apiKey {
    if (!(self = [super init])) {
        return nil;
    }
    if (apiKey) {
        [self setApiKey:apiKey];
    }
    _featureFlagStore = [[BSGFeatureFlagStore alloc] init];
    _metadata = [[BugsnagMetadata alloc] init];
    _endpoints = [BugsnagEndpointConfiguration new];
    _autoDetectErrors = YES;
#if BSG_HAVE_APP_HANG_DETECTION
    _appHangThresholdMillis = BugsnagAppHangThresholdFatalOnly;
#endif
    _onSendBlocks = [NSMutableArray new];
    _onSessionBlocks = [NSMutableArray new];
    _onBreadcrumbBlocks = [NSMutableArray new];
    _plugins = [NSMutableSet new];
    _enabledReleaseStages = nil;
    _redactedKeys = [NSSet setWithArray:@[@"password"]];
    _enabledBreadcrumbTypes = BSGEnabledBreadcrumbTypeAll;
    _launchDurationMillis = 5000;
    _sendLaunchCrashesSynchronously = YES;
    _attemptDeliveryOnCrash = NO;
    _maxBreadcrumbs = 100;
    _maxPersistedEvents = 32;
    _maxPersistedSessions = 128;
    _maxStringValueLength = 10000;
    _autoTrackSessions = YES;
#if BSG_HAVE_MACH_THREADS
    _sendThreads = BSGThreadSendPolicyAlways;
#else
    _sendThreads = BSGThreadSendPolicyNever;
#endif
    // Default to recording all error types
    _enabledErrorTypes = [BugsnagErrorTypes new];

    // Enabling OOM detection only happens in release builds, to avoid triggering
    // the heuristic when killing/restarting an app in Xcode or similar.
    _persistUser = YES;
    // persistUser isn't settable until post-init.
    _user = BSGGetPersistedUser();

    if ([NSURLSession class]) {
        _session = [NSURLSession
            sessionWithConfiguration:[NSURLSessionConfiguration
                                         defaultSessionConfiguration]];
    }
    
    _telemetry = BSGTelemetryAll;
    
    NSString *releaseStage = nil;
    #if defined(DEBUG) && DEBUG
        releaseStage = BSGKeyDevelopment;
    #else
        releaseStage = BSGKeyProduction;
    #endif

    NSString *appType = nil;
    #if TARGET_OS_TV
        appType = @"tvOS";
    #elif TARGET_OS_IOS
        appType = @"iOS";
    #elif TARGET_OS_OSX
        appType = @"macOS";
    #elif TARGET_OS_WATCH
        appType = @"watchOS";
    #else
        appType = @"unknown";
    #endif

    [self setAppType:appType];
    [self setReleaseStage:releaseStage];
    [self setAppVersion:NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"]];
    [self setBundleVersion:NSBundle.mainBundle.infoDictionary[@"CFBundleVersion"]];

    return self;
}

- (instancetype)initWithDictionaryRepresentation:(NSDictionary<NSString *, id> *)dictionaryRepresentation {
    if (!(self = [super init])) {
        return nil;
    }
    _appType = dictionaryRepresentation[BSGKeyAppType];
    _appVersion = dictionaryRepresentation[BSGKeyAppVersion];
    _bundleVersion = dictionaryRepresentation[BSGKeyBundleVersion];
    _context = dictionaryRepresentation[BSGKeyContext];
    _enabledReleaseStages = dictionaryRepresentation[BSGKeyEnabledReleaseStages];
    _featureFlagStore = [[BSGFeatureFlagStore alloc] init];
    _releaseStage = dictionaryRepresentation[BSGKeyReleaseStage];
    return self;
}

// -----------------------------------------------------------------------------
// MARK: - Instance Methods
// -----------------------------------------------------------------------------

- (NSDictionary<NSString *, id> *)dictionaryRepresentation {
    NSMutableDictionary *dictionaryRepresentation = [NSMutableDictionary dictionary];
    dictionaryRepresentation[BSGKeyAppType] = self.appType;
    dictionaryRepresentation[BSGKeyAppVersion] = self.appVersion;
    dictionaryRepresentation[BSGKeyBundleVersion] = self.bundleVersion;
    dictionaryRepresentation[BSGKeyContext] = self.context;
    dictionaryRepresentation[BSGKeyEnabledReleaseStages] = self.enabledReleaseStages.allObjects;
    dictionaryRepresentation[BSGKeyReleaseStage] = self.releaseStage;
    return dictionaryRepresentation;
}

/**
 *  Whether reports should be sent, based on release stage options
 *
 *  @return YES if reports should be sent based on this configuration
 */
- (BOOL)shouldSendReports {
    return self.enabledReleaseStages.count == 0 ||
           [self.enabledReleaseStages containsObject:self.releaseStage ?: @""];
}

- (void)setUser:(NSString *)userId withEmail:(NSString *)email andName:(NSString *)name {
    BugsnagUser *user = [[BugsnagUser alloc] initWithId:userId name:name emailAddress:email]; 
    self.user = user;
    if (self.persistUser) {
        BSGSetPersistedUser(user);
    }
}

// =============================================================================
// MARK: - onSendBlock
// =============================================================================

- (BugsnagOnSendErrorRef)addOnSendErrorBlock:(BugsnagOnSendErrorBlock)block {
    BugsnagOnSendErrorBlock callback = [block copy];
    [self.onSendBlocks addObject:callback];
    return callback;
}

- (void)removeOnSendError:(BugsnagOnSendErrorRef)callback {
    if (![callback isKindOfClass:NSClassFromString(@"NSBlock")]) {
        bsg_log_err(@"Invalid object type passed to %@", NSStringFromSelector(_cmd));
        return;
    }
    [self.onSendBlocks removeObject:(id)callback];
}

- (void)removeOnSendErrorBlock:(BugsnagOnSendErrorBlock)block {
    [self.onSendBlocks removeObject:block];
}

// =============================================================================
// MARK: - onSessionBlock
// =============================================================================

- (BugsnagOnSessionRef)addOnSessionBlock:(BugsnagOnSessionBlock)block {
    BugsnagOnSessionBlock callback = [block copy];
    [self.onSessionBlocks addObject:callback];
    return callback;
}

- (void)removeOnSession:(BugsnagOnSessionRef)callback {
    if (![callback isKindOfClass:NSClassFromString(@"NSBlock")]) {
        bsg_log_err(@"Invalid object type passed to %@", NSStringFromSelector(_cmd));
        return;
    }
    [self.onSessionBlocks removeObject:(id)callback];
}

- (void)removeOnSessionBlock:(BugsnagOnSessionBlock)block {
    [self.onSessionBlocks removeObject:block];
}

// =============================================================================
// MARK: - onBreadcrumbBlock
// =============================================================================

- (BugsnagOnBreadcrumbRef)addOnBreadcrumbBlock:(BugsnagOnBreadcrumbBlock)block {
    BugsnagOnBreadcrumbBlock callback = [block copy];
    [self.onBreadcrumbBlocks addObject:callback];
    return callback;
}

- (void)removeOnBreadcrumb:(BugsnagOnBreadcrumbRef)callback {
    if (![callback isKindOfClass:NSClassFromString(@"NSBlock")]) {
        bsg_log_err(@"Invalid object type passed to %@", NSStringFromSelector(_cmd));
        return;
    }
    [self.onBreadcrumbBlocks removeObject:(id)callback];
}

- (void)removeOnBreadcrumbBlock:(BugsnagOnBreadcrumbBlock)block {
    [self.onBreadcrumbBlocks removeObject:block];
}

// =============================================================================
// MARK: -
// =============================================================================

- (void)setEndpoints:(BugsnagEndpointConfiguration *)endpoints {
    if ([self isValidURLString:endpoints.notify]) {
        _endpoints.notify = [endpoints.notify copy];
    } else {
        // This causes a crash under DEBUG but is ignored in production
        NSAssert(NO, @"Invalid URL supplied for notify endpoint");
        _endpoints.notify = @"";
    }
    if ([self isValidURLString:endpoints.sessions]) {
        _endpoints.sessions = [endpoints.sessions copy];
    } else {
        bsg_log_err(@"Invalid URL supplied for session endpoint");
        _endpoints.sessions = @"";
    }
}

- (BOOL)isValidURLString:(NSString *)URLString {
    NSURL *url = [NSURL URLWithString:URLString];
    return url != nil && url.scheme != nil && url.host != nil;
}

// MARK: - User Persistence

- (void)setPersistUser:(BOOL)persistUser {
    _persistUser = persistUser;
    BSGSetPersistedUser(persistUser ? self.user : nil);
}

// -----------------------------------------------------------------------------
// MARK: - Properties: Getters and Setters
// -----------------------------------------------------------------------------

- (void)setAppHangThresholdMillis:(NSUInteger)appHangThresholdMillis {
    if (appHangThresholdMillis >= 250) {
        _appHangThresholdMillis = appHangThresholdMillis;
    } else {
        bsg_log_err(@"Invalid configuration value detected. Option appHangThresholdMillis "
                    "should be greater than or equal to 250. Supplied value is %lu",
                    (unsigned long)appHangThresholdMillis);
    }
}

- (void)setMaxPersistedEvents:(NSUInteger)maxPersistedEvents {
    if (maxPersistedEvents >= 1) {
        _maxPersistedEvents = maxPersistedEvents;
    } else {
        bsg_log_err(@"Invalid configuration value detected. Option maxPersistedEvents "
                    "should be a non-zero integer. Supplied value is %lu",
                    (unsigned long)maxPersistedEvents);
    }
}

- (void)setMaxPersistedSessions:(NSUInteger)maxPersistedSessions {
    if (maxPersistedSessions >= 1) {
        _maxPersistedSessions = maxPersistedSessions;
    } else {
        bsg_log_err(@"Invalid configuration value detected. Option maxPersistedSessions "
                    "should be a non-zero integer. Supplied value is %lu",
                    (unsigned long)maxPersistedSessions);
    }
}

- (void)setMaxBreadcrumbs:(NSUInteger)newValue {
    static const NSUInteger maxAllowed = 500;
    if (newValue > maxAllowed) {
        bsg_log_err(@"Invalid configuration value detected. "
                    "Option maxBreadcrumbs should be an integer between 0-%lu. "
                    "Supplied value is %lu",
                    (unsigned long)maxAllowed,
                    (unsigned long)newValue);
        return;
    }
    _maxBreadcrumbs = newValue;
}

- (NSURL *)notifyURL {
    return self.endpoints.notify.length ? [NSURL URLWithString:self.endpoints.notify] : nil;
}

- (NSURL *)sessionURL {
    return self.endpoints.sessions.length ? [NSURL URLWithString:self.endpoints.sessions] : nil;
}

- (BOOL)shouldDiscardErrorClass:(NSString *)errorClass {
    for (id obj in self.discardClasses) {
        if ([obj isKindOfClass:[NSString class]]) {
            if ([obj isEqualToString:errorClass]) {
                return YES;
            }
        } else if ([obj isKindOfClass:[NSRegularExpression class]]) {
            if ([obj firstMatchInString:errorClass options:0 range:NSMakeRange(0, errorClass.length)]) {
                return YES;
            }
        }
    }
    return NO;
}

/**
 * Specific types of breadcrumb should be recorded if either enabledBreadcrumbTypes
 * is None, or contains the type.
 *
 * @param type The breadcrumb type to test
 * @returns Whether to record the breadcrumb
 */
- (BOOL)shouldRecordBreadcrumbType:(BSGBreadcrumbType)type {
    // enabledBreadcrumbTypes is BSGEnabledBreadcrumbTypeNone
    if (self.enabledBreadcrumbTypes == BSGEnabledBreadcrumbTypeNone && type != BSGBreadcrumbTypeManual) {
        return NO;
    }

    switch (type) {
        case BSGBreadcrumbTypeManual:
            return YES;
        case BSGBreadcrumbTypeError :
            return (self.enabledBreadcrumbTypes & BSGEnabledBreadcrumbTypeError) != 0;
        case BSGBreadcrumbTypeLog:
            return (self.enabledBreadcrumbTypes & BSGEnabledBreadcrumbTypeLog) != 0;
        case BSGBreadcrumbTypeNavigation:
            return (self.enabledBreadcrumbTypes & BSGEnabledBreadcrumbTypeNavigation) != 0;
        case BSGBreadcrumbTypeProcess:
            return (self.enabledBreadcrumbTypes & BSGEnabledBreadcrumbTypeProcess) != 0;
        case BSGBreadcrumbTypeRequest:
            return (self.enabledBreadcrumbTypes & BSGEnabledBreadcrumbTypeRequest) != 0;
        case BSGBreadcrumbTypeState:
            return (self.enabledBreadcrumbTypes & BSGEnabledBreadcrumbTypeState) != 0;
        case BSGBreadcrumbTypeUser:
            return (self.enabledBreadcrumbTypes & BSGEnabledBreadcrumbTypeUser) != 0;
    }
    return NO;
}

// MARK: -

- (void)validate {
    if (self.apiKey.length == 0) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:
                @"No Bugsnag API key has been provided" userInfo:nil];
    }

    if (![BugsnagConfiguration isValidApiKey:self.apiKey]) {
        bsg_log_warn(@"Invalid apiKey: expected a 32-character hexademical string, got \"%@\"", self.apiKey);
    }
}

// MARK: -

- (void)addPlugin:(id<BugsnagPlugin> _Nonnull)plugin {
    [self.plugins addObject:plugin];
}

// MARK: - <BugsnagFeatureFlagStore>

- (void)addFeatureFlagWithName:(NSString *)name variant:(nullable NSString *)variant {
    BSGFeatureFlagStoreAddFeatureFlag(self.featureFlagStore, name, variant);
}

- (void)addFeatureFlagWithName:(NSString *)name {
    BSGFeatureFlagStoreAddFeatureFlag(self.featureFlagStore, name, nil);
}

- (void)addFeatureFlags:(NSArray<BugsnagFeatureFlag *> *)featureFlags {
    BSGFeatureFlagStoreAddFeatureFlags(self.featureFlagStore, featureFlags);
}

- (void)clearFeatureFlagWithName:(NSString *)name {
    BSGFeatureFlagStoreClear(self.featureFlagStore, name);
}

- (void)clearFeatureFlags {
    BSGFeatureFlagStoreClear(self.featureFlagStore, nil);
}

// MARK: - <MetadataStore>

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

- (NSMutableDictionary *)getMetadataFromSection:(NSString *_Nonnull)sectionName
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

@end
