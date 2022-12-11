//
//  UIApplicationStub.m
//  Bugsnag
//
//  Created by Nick Dowell on 06/12/2021.
//  Copyright © 2021 Bugsnag Inc. All rights reserved.
//

#import "UIApplicationStub.h"

#import <objc/runtime.h>


@implementation UIApplicationStub

- (BOOL)isKindOfClass:(Class)aClass {
    return aClass == [UIApplication class] || [super isKindOfClass:aClass];
}

@end


@implementation XCTestCase (UIApplicationStub)

- (void)setUpUIApplicationStub {
    Method method = class_getClassMethod([UIApplication class], @selector(sharedApplication));
    NSParameterAssert(method != NULL);
    
    void *originalImplementation = method_setImplementation(method, imp_implementationWithBlock(^(){
        return [[UIApplicationStub alloc] init];
    }));
    
    [self addTeardownBlock:^{
        method_setImplementation(method, originalImplementation);
    }];
}

@end
