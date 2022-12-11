#import "BSGConfigurationBuilder.h"

#import "BSGDefines.h"
#import "BugsnagEndpointConfiguration.h"
#import "BugsnagLogger.h"

static id PopValue(NSMutableDictionary *dictionary, NSString *key) {
    id value = dictionary[key];
    dictionary[key] = nil;
    return value;
}

static void LoadBoolean     (BugsnagConfiguration *config, NSMutableDictionary *options, NSString *key);
static void LoadString      (BugsnagConfiguration *config, NSMutableDictionary *options, NSString *key);
static void LoadNumber      (BugsnagConfiguration *config, NSMutableDictionary *options, NSString *key);
static void LoadStringSet   (BugsnagConfiguration *config, NSMutableDictionary *options, NSString *key);
static void LoadEndpoints   (BugsnagConfiguration *config, NSMutableDictionary *options);
static void LoadSendThreads (BugsnagConfiguration *config, NSMutableDictionary *options);

#pragma mark -

BugsnagConfiguration * BSGConfigurationWithOptions(NSDictionary *options) {
    BugsnagConfiguration *config;
    NSMutableDictionary *dict = [options mutableCopy];

    NSString *apiKey = PopValue(dict, BSG_KEYPATH(config, apiKey));
    if (apiKey != nil && ![apiKey isKindOfClass:[NSString class]]) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Bugsnag apiKey must be a string" userInfo:nil];
    }

    config = [[BugsnagConfiguration alloc] initWithApiKey:apiKey];

    LoadBoolean     (config, dict, BSG_KEYPATH(config, attemptDeliveryOnCrash));
    LoadBoolean     (config, dict, BSG_KEYPATH(config, autoDetectErrors));
    LoadBoolean     (config, dict, BSG_KEYPATH(config, autoTrackSessions));
    LoadBoolean     (config, dict, BSG_KEYPATH(config, persistUser));
    LoadBoolean     (config, dict, BSG_KEYPATH(config, sendLaunchCrashesSynchronously));
    LoadEndpoints   (config, dict);
    LoadNumber      (config, dict, BSG_KEYPATH(config, launchDurationMillis));
    LoadNumber      (config, dict, BSG_KEYPATH(config, maxBreadcrumbs));
    LoadNumber      (config, dict, BSG_KEYPATH(config, maxPersistedEvents));
    LoadNumber      (config, dict, BSG_KEYPATH(config, maxPersistedSessions));
    LoadNumber      (config, dict, BSG_KEYPATH(config, maxStringValueLength));
    LoadSendThreads (config, dict);
    LoadString      (config, dict, BSG_KEYPATH(config, appType));
    LoadString      (config, dict, BSG_KEYPATH(config, appVersion));
    LoadString      (config, dict, BSG_KEYPATH(config, bundleVersion));
    LoadString      (config, dict, BSG_KEYPATH(config, releaseStage));
    LoadStringSet   (config, dict, BSG_KEYPATH(config, discardClasses));
    LoadStringSet   (config, dict, BSG_KEYPATH(config, enabledReleaseStages));
    LoadStringSet   (config, dict, BSG_KEYPATH(config, redactedKeys));

#if BSG_HAVE_APP_HANG_DETECTION
    LoadBoolean     (config, dict, BSG_KEYPATH(config, reportBackgroundAppHangs));
    LoadNumber      (config, dict, BSG_KEYPATH(config, appHangThresholdMillis));
#endif

    if (dict.count > 0) {
        bsg_log_warn(@"Ignoring unexpected Info.plist values: %@", dict);
    }

    return config;
}

static void LoadBoolean(BugsnagConfiguration *config, NSMutableDictionary *options, NSString *key) {
    id value = PopValue(options, key);
    if (value && CFGetTypeID((__bridge CFTypeRef)value) == CFBooleanGetTypeID()) {
        [config setValue:value forKey:key];
    }
}

static void LoadString(BugsnagConfiguration *config, NSMutableDictionary *options, NSString *key) {
    id value = PopValue(options, key);
    if ([value isKindOfClass:[NSString class]]) {
        [config setValue:value forKey:key];
    }
}

static void LoadNumber(BugsnagConfiguration *config, NSMutableDictionary *options, NSString *key) {
    id value = PopValue(options, key);
    if ([value isKindOfClass:[NSNumber class]]) {
        [config setValue:value forKey:key];
    }
}

static void LoadStringSet(BugsnagConfiguration *config, NSMutableDictionary *options, NSString *key) {
    id val = PopValue(options, key);
    if ([val isKindOfClass:[NSArray class]]) {
        for (NSString *obj in val) {
            if (![obj isKindOfClass:[NSString class]]) {
                return;
            }
        }
        [config setValue:[NSSet setWithArray:val] forKey:key];
    }
}

static void LoadEndpoints(BugsnagConfiguration *config, NSMutableDictionary *options) {
    NSDictionary *endpoints = PopValue(options, BSG_KEYPATH(config, endpoints));
    if ([endpoints isKindOfClass:[NSDictionary class]]) {
        NSString *notify = endpoints[BSG_KEYPATH(config.endpoints, notify)];
        if ([notify isKindOfClass:[NSString class]]) {
            config.endpoints.notify = notify;
        }
        NSString *sessions = endpoints[BSG_KEYPATH(config.endpoints, sessions)];
        if ([sessions isKindOfClass:[NSString class]]) {
            config.endpoints.sessions = sessions;
        }
    }
}

static void LoadSendThreads(BugsnagConfiguration *config, NSMutableDictionary *options) {
#if BSG_HAVE_MACH_THREADS
    NSString *sendThreads = [PopValue(options, BSG_KEYPATH(config, sendThreads)) lowercaseString];
    if ([sendThreads isKindOfClass:[NSString class]]) {
        if ([@"unhandledonly" isEqualToString:sendThreads]) {
            config.sendThreads = BSGThreadSendPolicyUnhandledOnly;
        } else if ([@"always" isEqualToString:sendThreads]) {
            config.sendThreads = BSGThreadSendPolicyAlways;
        } else if ([@"never" isEqualToString:sendThreads]) {
            config.sendThreads = BSGThreadSendPolicyNever;
        }
    }
#endif
}
