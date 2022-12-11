//
//  BugsnagEvent+Private.h
//  Bugsnag
//
//  Created by Nick Dowell on 23/11/2020.
//  Copyright © 2020 Bugsnag Inc. All rights reserved.
//

#import "BSGDefines.h"
#import "BSGFeatureFlagStore.h"
#import "BugsnagInternals.h"

NS_ASSUME_NONNULL_BEGIN

BSG_OBJC_DIRECT_MEMBERS
@interface BugsnagEvent ()

@property (copy, nonatomic) NSString *codeBundleId;

/// User-provided exception metadata.
@property (readwrite, copy, nullable, nonatomic) NSDictionary *customException;

/// Number of frames to discard at the top of the generated stacktrace. Stacktraces from raised exceptions are unaffected.
@property (nonatomic) NSUInteger depth;

/// A unique hash identifying this device for the application or vendor.
@property (readwrite, copy, nullable, nonatomic) NSString *deviceAppHash;

/// The release stages used to notify at the time this report is captured.
@property (readwrite, copy, nullable, nonatomic) NSArray *enabledReleaseStages;

/// The event state (whether the error is handled/unhandled.)
@property (readwrite, nonatomic) BugsnagHandledState *handledState;

@property (strong, nullable, nonatomic) BugsnagMetadata *metadata;

/// The release stage of the application
@property (readwrite, copy, nullable, nonatomic) NSString *releaseStage;

@property (copy, nullable, nonatomic) BugsnagSession *session;

/// An array of string representations of BSGErrorType describing the types of stackframe / stacktrace in this error.
@property (readonly, nonatomic) NSArray<NSString *> *stacktraceTypes;

/// Usage telemetry info, from BSGTelemetryCreateUsage(), or nil if BSGTelemetryUsage is not enabled.
@property (readwrite, nullable, nonatomic) NSDictionary *usage;

@property (readwrite, nonnull, nonatomic) BugsnagUser *user;

- (instancetype)initWithKSReport:(NSDictionary *)KSReport;

- (instancetype)initWithUserData:(NSDictionary *)event;

/// Whether this report should be sent, based on release stage information cached at crash time and within the application currently.
- (BOOL)shouldBeSent;

- (void)trimBreadcrumbs:(NSUInteger)bytesToRemove;

- (void)truncateStrings:(NSUInteger)maxLength;

- (void)notifyUnhandledOverridden;

@end

NS_ASSUME_NONNULL_END
