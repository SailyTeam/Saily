//
//  BSGTelemetry.m
//  Bugsnag
//
//  Created by Nick Dowell on 05/07/2022.
//  Copyright © 2022 Bugsnag Inc. All rights reserved.
//

#import "BSGTelemetry.h"

#import "BSGDefines.h"
#import "BSG_KSMachHeaders.h"
#import "BugsnagConfiguration+Private.h"
#import "BugsnagErrorTypes.h"

static NSNumber *_Nullable BooleanValue(BOOL actual, BOOL defaultValue) {
    return actual != defaultValue ? (actual ? @YES : @NO) : nil;
}

static NSNumber *_Nullable IntegerValue(NSUInteger actual, NSUInteger defaultValue) {
    return actual != defaultValue ? @(actual) : nil;
}

static BOOL IsStaticallyLinked(void) {
    return bsg_mach_headers_get_self_image() == bsg_mach_headers_get_main_image();
}

static NSDictionary * ConfigValue(BugsnagConfiguration *configuration) {
    NSMutableDictionary *config = [NSMutableDictionary dictionary];
    
    BugsnagConfiguration *defaults = [[BugsnagConfiguration alloc] initWithApiKey:nil]; 
    
#if BSG_HAVE_APP_HANG_DETECTION
    config[@"appHangThresholdMillis"] = IntegerValue(configuration.appHangThresholdMillis, defaults.appHangThresholdMillis);
    config[@"reportBackgroundAppHangs"] = BooleanValue(configuration.reportBackgroundAppHangs, defaults.reportBackgroundAppHangs);
#endif
    
    config[@"attemptDeliveryOnCrash"] = BooleanValue(configuration.attemptDeliveryOnCrash, defaults.attemptDeliveryOnCrash);
    config[@"autoDetectErrors"] = BooleanValue(configuration.autoDetectErrors, defaults.autoDetectErrors);
    config[@"autoTrackSessions"] = BooleanValue(configuration.autoTrackSessions, defaults.autoTrackSessions);
    config[@"discardClassesCount"] = IntegerValue(configuration.discardClasses.count, 0);
    config[@"launchDurationMillis"] = IntegerValue(configuration.launchDurationMillis, defaults.launchDurationMillis);
    config[@"maxBreadcrumbs"] = IntegerValue(configuration.maxBreadcrumbs, defaults.maxBreadcrumbs);
    config[@"maxPersistedEvents"] = IntegerValue(configuration.maxPersistedEvents, defaults.maxPersistedEvents);
    config[@"maxPersistedSessions"] = IntegerValue(configuration.maxPersistedSessions, defaults.maxPersistedSessions);
    config[@"persistUser"] = BooleanValue(configuration.persistUser, defaults.persistUser);
    config[@"pluginCount"] = IntegerValue(configuration.plugins.count, 0);
    config[@"staticallyLinked"] = BooleanValue(IsStaticallyLinked(), NO);
    
    BSGEnabledBreadcrumbType enabledBreadcrumbTypes = configuration.enabledBreadcrumbTypes;
    if (enabledBreadcrumbTypes != defaults.enabledBreadcrumbTypes) {
        NSMutableArray *array = [NSMutableArray array];
        if (enabledBreadcrumbTypes & BSGEnabledBreadcrumbTypeError)         { [array addObject:@"error"]; }
        if (enabledBreadcrumbTypes & BSGEnabledBreadcrumbTypeLog)           { [array addObject:@"log"]; }
        if (enabledBreadcrumbTypes & BSGEnabledBreadcrumbTypeNavigation)    { [array addObject:@"navigation"]; }
        if (enabledBreadcrumbTypes & BSGEnabledBreadcrumbTypeProcess)       { [array addObject:@"process"]; }
        if (enabledBreadcrumbTypes & BSGEnabledBreadcrumbTypeRequest)       { [array addObject:@"request"]; }
        if (enabledBreadcrumbTypes & BSGEnabledBreadcrumbTypeState)         { [array addObject:@"state"]; }
        if (enabledBreadcrumbTypes & BSGEnabledBreadcrumbTypeUser)          { [array addObject:@"user"]; }
        config[@"enabledBreadcrumbTypes"] = [array componentsJoinedByString:@","];
    }
    
    BugsnagErrorTypes *enabledErrorTypes = configuration.enabledErrorTypes;
    if (!enabledErrorTypes.cppExceptions ||
#if !TARGET_OS_WATCH
        !enabledErrorTypes.appHangs ||
        !enabledErrorTypes.ooms ||
        !enabledErrorTypes.thermalKills ||
        !enabledErrorTypes.signals ||
        !enabledErrorTypes.machExceptions ||
#endif
        !enabledErrorTypes.unhandledExceptions ||
        !enabledErrorTypes.unhandledRejections) {
        NSMutableArray *array = [NSMutableArray array];
#if !TARGET_OS_WATCH
        if (enabledErrorTypes.appHangs)             { [array addObject:@"appHangs"]; }
        if (enabledErrorTypes.machExceptions)       { [array addObject:@"machExceptions"]; }
        if (enabledErrorTypes.ooms)                 { [array addObject:@"ooms"]; }
        if (enabledErrorTypes.signals)              { [array addObject:@"signals"]; }
        if (enabledErrorTypes.thermalKills)         { [array addObject:@"thermalKills"]; }
#endif
        if (enabledErrorTypes.cppExceptions)        { [array addObject:@"cppExceptions"]; }
        if (enabledErrorTypes.unhandledExceptions)  { [array addObject:@"unhandledExceptions"]; }
        if (enabledErrorTypes.unhandledRejections)  { [array addObject:@"unhandledRejections"]; }
        [array sortedArrayUsingSelector:@selector(compare:)];
        config[@"enabledErrorTypes"] = [array componentsJoinedByString:@","];
    }
    
#if BSG_HAVE_MACH_THREADS
    if (configuration.sendThreads != defaults.sendThreads) {
        switch (configuration.sendThreads) {
            case BSGThreadSendPolicyAlways:
                config[@"sendThreads"] = @"always";
                break;
            case BSGThreadSendPolicyUnhandledOnly:
                config[@"sendThreads"] = @"unhandledOnly";
                break;
            case BSGThreadSendPolicyNever:
                config[@"sendThreads"] = @"never";
                break;
            default:
                break;
        }
    }
#endif
    
    return config;
}

NSDictionary * BSGTelemetryCreateUsage(BugsnagConfiguration *configuration) {
    if (!(configuration.telemetry & BSGTelemetryUsage)) {
        return nil;
    }
    
    NSMutableDictionary *callbacks = [NSMutableDictionary dictionary];
    callbacks[@"onBreadcrumb"] = IntegerValue(configuration.onBreadcrumbBlocks.count, 0);
    callbacks[@"onCrashHandler"] = configuration.onCrashHandler ? @1 : nil;
    callbacks[@"onSendError"] = IntegerValue(configuration.onSendBlocks.count, 0);
    callbacks[@"onSession"] = IntegerValue(configuration.onSessionBlocks.count, 0);
    
    return @{
        @"callbacks": callbacks,
        @"config": ConfigValue(configuration)
    };
}
