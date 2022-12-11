//
//  BugsnagBreadcrumbs.h
//  Bugsnag
//
//  Created by Jamie Lynch on 26/03/2020.
//  Copyright © 2020 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BSGDefines.h"

@class BugsnagBreadcrumb;
@class BugsnagConfiguration;
typedef struct BSG_KSCrashReportWriter BSG_KSCrashReportWriter;

NS_ASSUME_NONNULL_BEGIN

BSG_OBJC_DIRECT_MEMBERS
@interface BugsnagBreadcrumbs : NSObject

- (instancetype)initWithConfiguration:(BugsnagConfiguration *)config;

/**
 * Returns an array of new objects representing the breadcrumbs stored in memory.
 */
@property (readonly, nonatomic) NSArray<BugsnagBreadcrumb *> *breadcrumbs;

/**
 * Store a new breadcrumb.
 */
- (void)addBreadcrumb:(BugsnagBreadcrumb *)breadcrumb;

/**
 * Store a new serialized breadcrumb.
 *
 * This method is not intended to be used from other classes, it is exposed to facilitate unit testing.
 */
- (void)addBreadcrumbWithData:(NSData *)data writeToDisk:(BOOL)writeToDisk;

- (NSArray<BugsnagBreadcrumb *> *)breadcrumbsBeforeDate:(NSDate *)date;

/**
 * The breadcrumb stored on disk.
 */
- (NSArray<BugsnagBreadcrumb *> *)cachedBreadcrumbs;

/**
 * Removes breadcrumbs from disk.
 */
- (void)removeAllBreadcrumbs;

@end

NS_ASSUME_NONNULL_END

#pragma mark -

/**
 * Inserts the current breadcrumbs into a crash report.
 *
 * This function is async-signal-safe, but requires that any threads that could be adding
 * breadcrumbs are suspended.
 */
void BugsnagBreadcrumbsWriteCrashReport(const BSG_KSCrashReportWriter * _Nonnull writer);
