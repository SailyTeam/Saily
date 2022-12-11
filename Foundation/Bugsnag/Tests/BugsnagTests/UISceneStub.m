//
//  UISceneStub.m
//  BugsnagTests
//
//  Created by Nick Dowell on 12/08/2021.
//  Copyright © 2021 Bugsnag Inc. All rights reserved.
//

#import "UISceneStub.h"

#if (defined(__IPHONE_13_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0) || \
    (defined(__TVOS_13_0) && __TV_OS_VERSION_MAX_ALLOWED >= __TVOS_13_0)

@interface UISceneStub ()

@property (nonatomic) NSString *configurationName;
@property (weak, nonatomic) Class delegateClass;
@property (nonatomic) UISceneSessionRole role;
@property (nonatomic) Class sceneClass;
@property (nonatomic) NSString *title;

@end

@implementation UISceneStub

- (instancetype)initWithConfiguration:(NSString *)configuration
                        delegateClass:(Class)delegateClass
                                 role:(UISceneSessionRole)role
                           sceneClass:(Class)sceneClass
                                title:(NSString *)title {
    if ((self = [super init])) {
        _configurationName = configuration;
        _delegateClass = delegateClass;
        _role = role;
        _sceneClass = sceneClass;
        _title = title;
    }
    return self;
}

- (id)session {
    return self;
}

- (id)configuration {
    return self;
}

- (NSString *)name {
    return self.configurationName;
}

- (BOOL)isKindOfClass:(Class)aClass {
    return [NSStringFromClass(aClass) isEqualToString:@"UIScene"] || [super isKindOfClass:aClass];
}

@end

#endif
