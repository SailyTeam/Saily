//
//  Bugsnag.m
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

#import "Bugsnag.h"

#import "BSGStorageMigratorV0V1.h"
#import "Bugsnag+Private.h"
#import "BugsnagBreadcrumbs.h"
#import "BugsnagClient+Private.h"
#import "BugsnagInternals.h"
#import "BugsnagLogger.h"

static BugsnagClient *bsg_g_bugsnag_client = NULL;

BSG_OBJC_DIRECT_MEMBERS
@implementation Bugsnag

+ (BugsnagClient *_Nonnull)start {
    BugsnagConfiguration *configuration = [BugsnagConfiguration loadConfig];
    return [self startWithConfiguration:configuration];
}

+ (BugsnagClient *_Nonnull)startWithApiKey:(NSString *_Nonnull)apiKey {
    BugsnagConfiguration *configuration = [BugsnagConfiguration loadConfig];
    configuration.apiKey = apiKey;
    return [self startWithConfiguration:configuration];
}

+ (BugsnagClient *_Nonnull)startWithConfiguration:(BugsnagConfiguration *_Nonnull)configuration {
    @synchronized(self) {
        if (bsg_g_bugsnag_client == nil) {
            [BSGStorageMigratorV0V1 migrate];
            bsg_g_bugsnag_client = [[BugsnagClient alloc] initWithConfiguration:configuration];
            [bsg_g_bugsnag_client start];
        } else {
            bsg_log_warn(@"Multiple Bugsnag.start calls detected. Ignoring.");
        }
        return bsg_g_bugsnag_client;
    }
}

/**
 * Purge the global client so that it will be regenerated on the next call to start.
 * This is only used by the unit tests.
 */
+ (void)purge {
    bsg_g_bugsnag_client = nil;
}

+ (BugsnagClient *)client {
    return bsg_g_bugsnag_client;
}

+ (BOOL)appDidCrashLastLaunch {
    if ([self bugsnagStarted]) {
        return [self.client appDidCrashLastLaunch];
    }
    return NO;
}

+ (BugsnagLastRunInfo *)lastRunInfo {
    if ([self bugsnagStarted]) {
        return self.client.lastRunInfo;
    }
    return nil;
}

+ (void)markLaunchCompleted {
    if ([self bugsnagStarted]) {
        [self.client markLaunchCompleted];
    }
}

+ (void)notify:(NSException *)exception {
    if ([self bugsnagStarted]) {
        [self.client notify:exception];
    }
}

+ (void)notify:(NSException *)exception block:(BugsnagOnErrorBlock)block {
    if ([self bugsnagStarted]) {
        [self.client notify:exception block:block];
    }
}

+ (void)notifyError:(NSError *)error {
    if ([self bugsnagStarted]) {
        [self.client notifyError:error];
    }
}

+ (void)notifyError:(NSError *)error block:(BugsnagOnErrorBlock)block {
    if ([self bugsnagStarted]) {
        [self.client notifyError:error block:block];
    }
}

+ (BOOL)bugsnagStarted {
    if (!self.client.started) {
        bsg_log_err(@"Ensure you have started Bugsnag with startWithApiKey: "
                    @"before calling any other Bugsnag functions.");

        return NO;
    }
    return YES;
}

+ (void)leaveBreadcrumbWithMessage:(NSString *)message {
    if ([self bugsnagStarted]) {
        [self.client leaveBreadcrumbWithMessage:message];
    }
}

+ (void)leaveBreadcrumbForNotificationName:
    (NSString *_Nonnull)notificationName {
    if ([self bugsnagStarted]) {
        [self.client leaveBreadcrumbForNotificationName:notificationName];
    }
}

+ (void)leaveBreadcrumbWithMessage:(NSString *_Nonnull)message
                          metadata:(NSDictionary *_Nullable)metadata
                           andType:(BSGBreadcrumbType)type
{
    if ([self bugsnagStarted]) {
        [self.client leaveBreadcrumbWithMessage:message
                                       metadata:metadata
                                        andType:type];
    }
}

+ (void)leaveNetworkRequestBreadcrumbForTask:(NSURLSessionTask *)task
                                     metrics:(NSURLSessionTaskMetrics *)metrics {
    if ([self bugsnagStarted]) {
        [self.client leaveNetworkRequestBreadcrumbForTask:task metrics:metrics];
    }
}

+ (NSArray<BugsnagBreadcrumb *> *_Nonnull)breadcrumbs {
    if ([self bugsnagStarted]) {
        return self.client.breadcrumbs;
    } else {
        return @[];
    }
}

+ (void)startSession {
    if ([self bugsnagStarted]) {
        [self.client startSession];
    }
}

+ (void)pauseSession {
    if ([self bugsnagStarted]) {
        [self.client pauseSession];
    }
}

+ (BOOL)resumeSession {
    if ([self bugsnagStarted]) {
        return [self.client resumeSession];
    } else {
        return false;
    }
}

// =============================================================================
// MARK: - <BugsnagFeatureFlagStore>
// =============================================================================

+ (void)addFeatureFlagWithName:(NSString *)name variant:(nullable NSString *)variant {
    if ([self bugsnagStarted]) {
        [self.client addFeatureFlagWithName:name variant:variant];
    }
}

+ (void)addFeatureFlagWithName:(NSString *)name {
    if ([self bugsnagStarted]) {
        [self.client addFeatureFlagWithName:name];
    }
}

+ (void)addFeatureFlags:(NSArray<BugsnagFeatureFlag *> *)featureFlags {
    if ([self bugsnagStarted]) {
        [self.client addFeatureFlags:featureFlags];
    }
}

+ (void)clearFeatureFlagWithName:(NSString *)name {
    if ([self bugsnagStarted]) {
        [self.client clearFeatureFlagWithName:name];
    }
}

+ (void)clearFeatureFlags {
    if ([self bugsnagStarted]) {
        [self.client clearFeatureFlags];
    }
}

// =============================================================================
// MARK: - <BugsnagClassLevelMetadataStore>
// =============================================================================

/**
 * Add custom data to send to Bugsnag with every exception. If value is nil,
 * delete the current value for attributeName
 *
 * @param metadata The metadata to add
 * @param key The key for the metadata
 * @param section The top-level section to add the keyed metadata to
 */
+ (void)addMetadata:(id _Nullable)metadata
            withKey:(NSString *_Nonnull)key
          toSection:(NSString *_Nonnull)section
{
    if ([self bugsnagStarted]) {
        [self.client addMetadata:metadata
                                  withKey:key
                                toSection:section];
    }
}

+ (void)addMetadata:(id _Nonnull)metadata
          toSection:(NSString *_Nonnull)section
{
    if ([self bugsnagStarted]) {
        [self.client addMetadata:metadata
                       toSection:section];
    }
}

+ (NSMutableDictionary *)getMetadataFromSection:(NSString *)section
{
    if ([self bugsnagStarted]) {
        return [[self.client getMetadataFromSection:section] mutableCopy];
    }
    return nil;
}

+ (id _Nullable )getMetadataFromSection:(NSString *_Nonnull)section
                                withKey:(NSString *_Nonnull)key
{
    if ([self bugsnagStarted]) {
        return [[self.client getMetadataFromSection:section withKey:key] mutableCopy];
    }
    return nil;
}

+ (void)clearMetadataFromSection:(NSString *)section
{
    if ([self bugsnagStarted]) {
        [self.client clearMetadataFromSection:section];
    }
}

+ (void)clearMetadataFromSection:(NSString *_Nonnull)sectionName
                         withKey:(NSString *_Nonnull)key
{
    if ([self bugsnagStarted]) {
        [self.client clearMetadataFromSection:sectionName
                                      withKey:key];
    }
}

// MARK: -

+ (void)setContext:(NSString *_Nullable)context {
    if ([self bugsnagStarted]) {
        [self.client setContext:context];
    }
}

+ (NSString *_Nullable)context {
    if ([self bugsnagStarted]) {
        return self.client.context;
    }
    return nil;
}

+ (BugsnagUser *)user {
    return self.client.user;
}

+ (void)setUser:(NSString *_Nullable)userId
      withEmail:(NSString *_Nullable)email
        andName:(NSString *_Nullable)name {
    if ([self bugsnagStarted]) {
        [self.client setUser:userId withEmail:email andName:name];
    }
}

+ (nonnull BugsnagOnSessionRef)addOnSessionBlock:(nonnull BugsnagOnSessionBlock)block {
    if ([self bugsnagStarted]) {
        return [self.client addOnSessionBlock:block];
    } else {
        // We need to return something from this nonnull method; simulate what would have happened.
        return [block copy];
    }
}

+ (void)removeOnSession:(nonnull BugsnagOnSessionRef)callback {
    if ([self bugsnagStarted]) {
        [self.client removeOnSession:callback];
    }
}

+ (void)removeOnSessionBlock:(BugsnagOnSessionBlock _Nonnull )block
{
    if ([self bugsnagStarted]) {
        [self.client removeOnSessionBlock:block];
    }
}

// =============================================================================
// MARK: - OnBreadcrumb
// =============================================================================

+ (nonnull BugsnagOnBreadcrumbRef)addOnBreadcrumbBlock:(nonnull BugsnagOnBreadcrumbBlock)block {
    if ([self bugsnagStarted]) {
        return [self.client addOnBreadcrumbBlock:block];
    } else {
        // We need to return something from this nonnull method; simulate what would have happened.
        return [block copy];
    }
}

+ (void)removeOnBreadcrumb:(nonnull BugsnagOnBreadcrumbRef)callback {
    if ([self bugsnagStarted]) {
        [self.client removeOnBreadcrumb:callback];
    }
}

+ (void)removeOnBreadcrumbBlock:(BugsnagOnBreadcrumbBlock _Nonnull)block {
    if ([self bugsnagStarted]) {
        [self.client removeOnBreadcrumbBlock:block];
    }
}

@end
