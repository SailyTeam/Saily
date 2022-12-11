//
//  BugsnagApp+Private.h
//  Bugsnag
//
//  Created by Nick Dowell on 04/12/2020.
//  Copyright © 2020 Bugsnag Inc. All rights reserved.
//

#import <Bugsnag/BugsnagApp.h>

#import "BSGDefines.h"

@class BugsnagConfiguration;

struct BSGRunContext;

NS_ASSUME_NONNULL_BEGIN

@interface BugsnagApp ()

+ (BugsnagApp *)appWithDictionary:(NSDictionary *)event config:(BugsnagConfiguration *)config codeBundleId:(NSString *)codeBundleId;

+ (BugsnagApp *)deserializeFromJson:(nullable NSDictionary *)json;

+ (void)populateFields:(BugsnagApp *)app dictionary:(NSDictionary *)event config:(BugsnagConfiguration *)config codeBundleId:(NSString *)codeBundleId;

- (void)setValuesFromConfiguration:(BugsnagConfiguration *)configuration;

- (NSDictionary *)toDict;

@end

NSDictionary *BSGParseAppMetadata(NSDictionary *event);

NSDictionary *BSGAppMetadataFromRunContext(const struct BSGRunContext *context);

NS_ASSUME_NONNULL_END
