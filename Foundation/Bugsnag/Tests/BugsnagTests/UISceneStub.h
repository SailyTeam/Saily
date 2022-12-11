//
//  UISceneStub.h
//  BugsnagTests
//
//  Created by Nick Dowell on 12/08/2021.
//  Copyright © 2021 Bugsnag Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#if (defined(__IPHONE_13_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0) || \
    (defined(__TVOS_13_0) && __TV_OS_VERSION_MAX_ALLOWED >= __TVOS_13_0)

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(13.0), tvos(13.0))
@interface UISceneStub : NSObject

- (instancetype)initWithConfiguration:(NSString *)configuration
                        delegateClass:(Class)delegateClass
                                 role:(UISceneSessionRole)role
                           sceneClass:(Class)sceneClass
                                title:(NSString *)title;

@end

NS_ASSUME_NONNULL_END

#endif
