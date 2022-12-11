//
//  BugsnagFeatureFlag.m
//  Bugsnag
//
//  Created by Nick Dowell on 11/11/2021.
//  Copyright © 2021 Bugsnag Inc. All rights reserved.
//

#import "BugsnagFeatureFlag.h"

@implementation BugsnagFeatureFlag

+ (instancetype)flagWithName:(NSString *)name {
    return [[BugsnagFeatureFlag alloc] initWithName:name variant:nil];
}

+ (instancetype)flagWithName:(NSString *)name variant:(nullable NSString *)variant {
    return [[BugsnagFeatureFlag alloc] initWithName:name variant:variant];
}

- (instancetype)initWithName:(NSString *)name variant:(nullable NSString *)variant {
    if ((self = [super init])) {
        _name = [name copy];
        _variant = [variant copy];
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if (object == nil) {
        return NO;
    }

    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[BugsnagFeatureFlag class]]) {
        return NO;
    }

    BugsnagFeatureFlag *obj = (BugsnagFeatureFlag *)object;

    // Ignore the variant when checking for equality. We only care if the name matches
    // when checking for duplicates.
    return [obj.name isEqualToString:self.name];
}

@end
