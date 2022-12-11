//
//  BSGAppKitTests.m
//  Bugsnag-macOSTests
//
//  Created by Nick Dowell on 13/04/2021.
//  Copyright © 2021 Bugsnag Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface BSGAppKitTests : XCTestCase

@end

@implementation BSGAppKitTests

- (void)testNotificationNames {
    // The notifier uses hard-coded notification names so that it can avoid linking to AppKit.
    // These tests ensure that the hard-coded names in BSGAppKit.h match the SDK.
    #define ASSERT_NOTIFICATION_NAME(name) XCTAssertEqualObjects(name, @#name)
    ASSERT_NOTIFICATION_NAME(NSApplicationDidBecomeActiveNotification);
    ASSERT_NOTIFICATION_NAME(NSApplicationDidFinishLaunchingNotification);
    ASSERT_NOTIFICATION_NAME(NSApplicationDidHideNotification);
    ASSERT_NOTIFICATION_NAME(NSApplicationDidResignActiveNotification);
    ASSERT_NOTIFICATION_NAME(NSApplicationDidUnhideNotification);
    ASSERT_NOTIFICATION_NAME(NSApplicationWillBecomeActiveNotification);
    ASSERT_NOTIFICATION_NAME(NSApplicationWillTerminateNotification);
    ASSERT_NOTIFICATION_NAME(NSControlTextDidBeginEditingNotification);
    ASSERT_NOTIFICATION_NAME(NSControlTextDidEndEditingNotification);
    ASSERT_NOTIFICATION_NAME(NSMenuWillSendActionNotification);
    ASSERT_NOTIFICATION_NAME(NSTableViewSelectionDidChangeNotification);
    ASSERT_NOTIFICATION_NAME(NSUndoManagerDidRedoChangeNotification);
    ASSERT_NOTIFICATION_NAME(NSUndoManagerDidUndoChangeNotification);
    ASSERT_NOTIFICATION_NAME(NSWindowDidBecomeKeyNotification);
    ASSERT_NOTIFICATION_NAME(NSWindowDidEnterFullScreenNotification);
    ASSERT_NOTIFICATION_NAME(NSWindowDidExitFullScreenNotification);
    ASSERT_NOTIFICATION_NAME(NSWindowWillCloseNotification);
    ASSERT_NOTIFICATION_NAME(NSWindowWillMiniaturizeNotification);
    ASSERT_NOTIFICATION_NAME(NSWorkspaceScreensDidSleepNotification);
    ASSERT_NOTIFICATION_NAME(NSWorkspaceScreensDidWakeNotification);
}

@end
