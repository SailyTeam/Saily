//
//  BSGFeatureFlagStore.h
//  Bugsnag
//
//  Created by Nick Dowell on 11/11/2021.
//  Copyright © 2021 Bugsnag Inc. All rights reserved.
//

#import "BugsnagInternals.h"
#import "BSGDefines.h"

NS_ASSUME_NONNULL_BEGIN

void BSGFeatureFlagStoreAddFeatureFlag(BSGFeatureFlagStore *store, NSString *name, NSString *_Nullable variant);

void BSGFeatureFlagStoreAddFeatureFlags(BSGFeatureFlagStore *store, NSArray<BugsnagFeatureFlag *> *featureFlags);

void BSGFeatureFlagStoreClear(BSGFeatureFlagStore *store, NSString *_Nullable name);

NSArray<NSDictionary *> * BSGFeatureFlagStoreToJSON(BSGFeatureFlagStore *store);

BSGFeatureFlagStore * BSGFeatureFlagStoreFromJSON(id _Nullable json);


BSG_OBJC_DIRECT_MEMBERS
@interface BSGFeatureFlagStore ()

@property(nonatomic,nonnull,readonly) NSArray<BugsnagFeatureFlag *> * allFlags;

+ (nonnull BSGFeatureFlagStore *) fromJSON:(nonnull id)json;

- (NSUInteger) count;

- (void) addFeatureFlag:(nonnull NSString *)name withVariant:(nullable NSString *)variant;

- (void) addFeatureFlags:(nonnull NSArray<BugsnagFeatureFlag *> *)featureFlags;

- (void) clear:(nullable NSString *)name;

- (nonnull NSArray<NSDictionary *> *) toJSON;

@end

NS_ASSUME_NONNULL_END
