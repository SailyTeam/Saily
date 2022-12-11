//
//  UIApplicationStub.h
//  Bugsnag
//
//  Created by Nick Dowell on 06/12/2021.
//  Copyright © 2021 Bugsnag Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIApplicationStub : NSObject

@property (nonatomic) UIApplicationState applicationState;

@end

@interface XCTestCase (UIApplicationStub)

- (void)setUpUIApplicationStub;

@end

NS_ASSUME_NONNULL_END
