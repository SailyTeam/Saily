//
//  UIKitTests.m
//  Bugsnag-iOSTests
//
//  Created by Nick Dowell on 16/11/2020.
//  Copyright © 2020 Bugsnag Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

@interface UIKitTests : XCTestCase

@end

@implementation UIKitTests

- (void)testNotificationNames {
    // The notifier uses hard-coded notification names so that it can avoid linking
    // to UIKit. These tests ensure that the hard-coded names match the SDK.
    #define ASSERT_NOTIFICATION_NAME(name) XCTAssertEqualObjects(name, @#name)
    ASSERT_NOTIFICATION_NAME(UIApplicationDidBecomeActiveNotification);
    ASSERT_NOTIFICATION_NAME(UIApplicationDidEnterBackgroundNotification);
    ASSERT_NOTIFICATION_NAME(UIApplicationDidReceiveMemoryWarningNotification);
    ASSERT_NOTIFICATION_NAME(UIApplicationUserDidTakeScreenshotNotification);
    ASSERT_NOTIFICATION_NAME(UIApplicationWillEnterForegroundNotification);
    ASSERT_NOTIFICATION_NAME(UIApplicationWillResignActiveNotification);
    ASSERT_NOTIFICATION_NAME(UIApplicationWillTerminateNotification);
    ASSERT_NOTIFICATION_NAME(UIDeviceBatteryLevelDidChangeNotification);
    ASSERT_NOTIFICATION_NAME(UIDeviceBatteryStateDidChangeNotification);
    ASSERT_NOTIFICATION_NAME(UIDeviceOrientationDidChangeNotification);
    ASSERT_NOTIFICATION_NAME(UIKeyboardDidHideNotification);
    ASSERT_NOTIFICATION_NAME(UIKeyboardDidShowNotification);
    ASSERT_NOTIFICATION_NAME(UIMenuControllerDidHideMenuNotification);
    ASSERT_NOTIFICATION_NAME(UIMenuControllerDidShowMenuNotification);
    ASSERT_NOTIFICATION_NAME(UIScreenBrightnessDidChangeNotification);
    ASSERT_NOTIFICATION_NAME(UITableViewSelectionDidChangeNotification);
    ASSERT_NOTIFICATION_NAME(UITextFieldTextDidBeginEditingNotification);
    ASSERT_NOTIFICATION_NAME(UITextFieldTextDidEndEditingNotification);
    ASSERT_NOTIFICATION_NAME(UITextViewTextDidBeginEditingNotification);
    ASSERT_NOTIFICATION_NAME(UITextViewTextDidEndEditingNotification);
    ASSERT_NOTIFICATION_NAME(UIWindowDidBecomeHiddenNotification);
    ASSERT_NOTIFICATION_NAME(UIWindowDidBecomeKeyNotification);
    ASSERT_NOTIFICATION_NAME(UIWindowDidBecomeVisibleNotification);
    ASSERT_NOTIFICATION_NAME(UIWindowDidResignKeyNotification);

#if (defined(__IPHONE_13_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0) || \
    (defined(__TVOS_13_0) && __TV_OS_VERSION_MAX_ALLOWED >= __TVOS_13_0)
    if (@available(iOS 13.0, tvOS 13.0, *)) {
        ASSERT_NOTIFICATION_NAME(UISceneWillConnectNotification);
        ASSERT_NOTIFICATION_NAME(UISceneDidDisconnectNotification);
        ASSERT_NOTIFICATION_NAME(UISceneDidActivateNotification);
        ASSERT_NOTIFICATION_NAME(UISceneWillDeactivateNotification);
        ASSERT_NOTIFICATION_NAME(UISceneWillEnterForegroundNotification);
        ASSERT_NOTIFICATION_NAME(UISceneDidEnterBackgroundNotification);
    }
#endif
}

@end
