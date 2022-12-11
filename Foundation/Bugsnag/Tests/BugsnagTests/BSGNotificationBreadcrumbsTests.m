//
//  BSGNotificationBreadcrumbsTests.m
//  Bugsnag
//
//  Created by Nick Dowell on 10/12/2020.
//  Copyright © 2020 Bugsnag Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <Bugsnag/Bugsnag.h>

#import "BSGNotificationBreadcrumbs.h"
#import "BugsnagBreadcrumb+Private.h"
#import "BSGDefines.h"

#if TARGET_OS_IOS || TARGET_OS_TV
#import "UISceneStub.h"
#endif


@interface BSGNotificationBreadcrumbsTests : XCTestCase <BSGBreadcrumbSink>

@property NSNotificationCenter *notificationCenter;
@property id notificationObject;
@property NSDictionary *notificationUserInfo;

@property BSGNotificationBreadcrumbs *notificationBreadcrumbs;
@property (nonatomic) BugsnagBreadcrumb *breadcrumb;

@end


#pragma mark Mock Objects

@interface BSGMockObject: NSObject
@property(readwrite, strong) NSString *descriptionString;
@end

@implementation BSGMockObject
- (NSString *)description {return self.descriptionString;}
@end


@interface BSGMockScene: BSGMockObject
@property(readwrite, strong) NSString *title;
@property(readwrite, strong) NSString *subtitle;
@end

@implementation BSGMockScene
@end


@interface BSGMockViewController: BSGMockObject
@property(readwrite, strong) NSString *title;
@end

@implementation BSGMockViewController
@end

#if BSG_HAVE_WINDOW

#if TARGET_OS_OSX
@interface BSGMockWindow: NSWindow
#else
@interface BSGMockWindow: UIWindow
#endif
@property(readwrite, strong) NSString *mockDescription;
@property(readwrite, strong) NSString *mockTitle;
@property(readwrite, strong) NSString *mockRepresentedURLString;
@property(readwrite, strong) BSGMockScene *mockScene;
@property(readwrite, strong) BSGMockViewController *mockViewController;
@end

@implementation BSGMockWindow
- (NSString *)description {return self.mockDescription;}
#if TARGET_OS_OSX
- (NSViewController *)contentViewController {return (NSViewController *)self.mockViewController;}
- (NSString *)title {return self.mockTitle;}
- (NSURL *)representedURL {return [NSURL URLWithString:self.mockRepresentedURLString];}
#else
#if !TARGET_OS_TV && (defined(__IPHONE_13_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0)
- (UIScene *)windowScene  {return (UIScene *)self.mockScene;}
#endif
- (UIViewController *)rootViewController {return (UIViewController *)self.mockViewController;}
#endif
@end

#endif


#if TARGET_OS_IOS
@interface MockDevice : NSObject
@property UIDeviceOrientation orientation;
@end

@implementation MockDevice
@end
#endif


@interface MockProcessInfo : NSObject
@property NSProcessInfoThermalState thermalState API_AVAILABLE(ios(11.0), tvos(11.0));
@end

@implementation MockProcessInfo
@end


#pragma mark -

@implementation BSGNotificationBreadcrumbsTests

#pragma mark Setup

- (void)setUp {
    self.breadcrumb = nil;
    BugsnagConfiguration *configuration = [[BugsnagConfiguration alloc] initWithApiKey:@"0192837465afbecd0192837465afbecd"];
    self.notificationBreadcrumbs = [[BSGNotificationBreadcrumbs alloc] initWithConfiguration:configuration breadcrumbSink:self];
    self.notificationBreadcrumbs.notificationCenter = [[NSNotificationCenter alloc] init];
    self.notificationBreadcrumbs.workspaceNotificationCenter = [[NSNotificationCenter alloc] init];
    self.notificationCenter = self.notificationBreadcrumbs.notificationCenter; 
    self.notificationObject = nil;
    self.notificationUserInfo = nil;
    [self.notificationBreadcrumbs start];
}

- (BugsnagBreadcrumb *)breadcrumbForNotificationWithName:(NSString *)name {
    self.breadcrumb = nil;
    [self.notificationCenter postNotification:
     [NSNotification notificationWithName:name object:self.notificationObject userInfo:self.notificationUserInfo]];
    return self.breadcrumb;
}

#pragma mark BSGBreadcrumbSink

- (void)leaveBreadcrumbWithMessage:(NSString *)message metadata:(NSDictionary *)metadata andType:(BSGBreadcrumbType)type {
    self.breadcrumb = [BugsnagBreadcrumb new];
    self.breadcrumb.message = message;
    self.breadcrumb.metadata = metadata;
    self.breadcrumb.type = type;
}

#define TEST(__NAME__, __TYPE__, __MESSAGE__, __METADATA__) do { \
    BugsnagBreadcrumb *breadcrumb = [self breadcrumbForNotificationWithName:__NAME__]; \
    XCTAssert([NSJSONSerialization isValidJSONObject:breadcrumb.metadata]); \
    if (breadcrumb) { \
        XCTAssertEqual(breadcrumb.type, __TYPE__); \
        XCTAssertEqualObjects(breadcrumb.message, __MESSAGE__); \
        XCTAssertEqualObjects(breadcrumb.metadata, __METADATA__); \
    } \
} while (0)

#pragma mark Tests

- (void)testNSUndoManagerNotifications {
    TEST(NSUndoManagerDidRedoChangeNotification, BSGBreadcrumbTypeState, @"Redo Operation", @{});
    TEST(NSUndoManagerDidUndoChangeNotification, BSGBreadcrumbTypeState, @"Undo Operation", @{});
}

- (void)testNSProcessInfoThermalStateThermalStateNotifications {
    if (@available(iOS 13.0, tvOS 13.0, watchOS 4.0, *)) {
        MockProcessInfo *processInfo = [[MockProcessInfo alloc] init];
        self.notificationObject = processInfo;
        
        // Set initial state
        processInfo.thermalState = NSProcessInfoThermalStateNominal;
        [self breadcrumbForNotificationWithName:NSProcessInfoThermalStateDidChangeNotification];
        
        processInfo.thermalState = NSProcessInfoThermalStateCritical;
        TEST(NSProcessInfoThermalStateDidChangeNotification, BSGBreadcrumbTypeState,
             @"Thermal State Changed", (@{@"from": @"nominal", @"to": @"critical"}));
        
        processInfo.thermalState = NSProcessInfoThermalStateCritical;
        XCTAssertNil([self breadcrumbForNotificationWithName:NSProcessInfoThermalStateDidChangeNotification],
                     @"No breadcrumb should be left if state did not change");
    }
}

#pragma mark iOS Tests

#if TARGET_OS_IOS

- (void)testUIApplicationNotifications {
    TEST(UIApplicationDidEnterBackgroundNotification, BSGBreadcrumbTypeState, @"App Did Enter Background", @{});
    TEST(UIApplicationDidReceiveMemoryWarningNotification, BSGBreadcrumbTypeState, @"Memory Warning", @{});
    TEST(UIApplicationUserDidTakeScreenshotNotification, BSGBreadcrumbTypeState, @"Took Screenshot", @{});
    TEST(UIApplicationWillEnterForegroundNotification, BSGBreadcrumbTypeState, @"App Will Enter Foreground", @{});
    TEST(UIApplicationWillTerminateNotification, BSGBreadcrumbTypeState, @"App Will Terminate", @{});
}
 
- (void)testUIDeviceOrientationNotifications {
    MockDevice *device = [[MockDevice alloc] init];
    self.notificationObject = device;
    
    // Set initial state
    device.orientation = UIDeviceOrientationPortrait;
    [self breadcrumbForNotificationWithName:UIDeviceOrientationDidChangeNotification];
    
    device.orientation = UIDeviceOrientationLandscapeLeft;
    TEST(UIDeviceOrientationDidChangeNotification, BSGBreadcrumbTypeState,
         @"Orientation Changed", (@{@"from": @"portrait", @"to": @"landscapeleft"}));
    
    device.orientation = UIDeviceOrientationUnknown;
    XCTAssertNil([self breadcrumbForNotificationWithName:UIDeviceOrientationDidChangeNotification],
                 @"UIDeviceOrientationUnknown should be ignored");
    
    device.orientation = UIDeviceOrientationLandscapeLeft;
    XCTAssertNil([self breadcrumbForNotificationWithName:UIDeviceOrientationDidChangeNotification],
                 @"No breadcrumb should be left if orientation did not change");
}

- (void)testUIKeyboardNotifications {
    TEST(UIKeyboardDidHideNotification, BSGBreadcrumbTypeState, @"Keyboard Became Hidden", @{});
    TEST(UIKeyboardDidShowNotification, BSGBreadcrumbTypeState, @"Keyboard Became Visible", @{});
}

- (void)testUIMenuNotifications {
    TEST(UIMenuControllerDidHideMenuNotification, BSGBreadcrumbTypeState, @"Did Hide Menu", @{});
    TEST(UIMenuControllerDidShowMenuNotification, BSGBreadcrumbTypeState, @"Did Show Menu", @{});
}

- (void)testUITextFieldNotifications {
    TEST(UITextFieldTextDidBeginEditingNotification, BSGBreadcrumbTypeUser, @"Began Editing Text", @{});
    TEST(UITextFieldTextDidEndEditingNotification, BSGBreadcrumbTypeUser, @"Stopped Editing Text", @{});
}

- (void)testUITextViewNotifications {
    TEST(UITextViewTextDidBeginEditingNotification, BSGBreadcrumbTypeUser, @"Began Editing Text", @{});
    TEST(UITextViewTextDidEndEditingNotification, BSGBreadcrumbTypeUser, @"Stopped Editing Text", @{});
}

- (void)testUIWindowNotificationsNoData {
    BSGMockWindow *window = [[BSGMockWindow alloc]  init];
    window.mockScene = [[BSGMockScene alloc]  init];
    window.mockViewController = [[BSGMockViewController alloc] init];
    self.notificationObject = window;

    NSMutableDictionary *metadata = [[NSMutableDictionary alloc] init];

    TEST(UIWindowDidBecomeHiddenNotification, BSGBreadcrumbTypeState, @"Window Became Hidden", metadata);
    TEST(UIWindowDidBecomeVisibleNotification, BSGBreadcrumbTypeState, @"Window Became Visible", metadata);
}

- (void)testUIWindowNotificationsWithData {
    BSGMockWindow *window = [[BSGMockWindow alloc]  init];
    window.mockScene = [[BSGMockScene alloc]  init];
    window.mockViewController = [[BSGMockViewController alloc] init];
    self.notificationObject = window;

    window.mockDescription = @"Window Description";
    window.mockTitle = @"Window Title";
    window.mockRepresentedURLString = @"https://bugsnag.com";
    window.mockScene.title = @"Scene Title";
    window.mockScene.subtitle = @"Scene Subtitle";
    window.mockViewController.title = @"ViewController Title";
    window.mockViewController.descriptionString = @"ViewController Description";

    NSMutableDictionary *metadata = [[NSMutableDictionary alloc] init];
    metadata[@"description"] = @"Window Description";
    metadata[@"viewController"] = @"ViewController Description";
    metadata[@"viewControllerTitle"] = @"ViewController Title";
    if (@available(iOS 13.0, *)) {
        metadata[@"sceneTitle"] = @"Scene Title";
    }
    if (@available(iOS 15.0, *)) {
        metadata[@"sceneSubtitle"] = @"Scene Subtitle";
    }

    TEST(UIWindowDidBecomeHiddenNotification, BSGBreadcrumbTypeState, @"Window Became Hidden", metadata);
    TEST(UIWindowDidBecomeVisibleNotification, BSGBreadcrumbTypeState, @"Window Became Visible", metadata);
}

#endif

#pragma mark iOS & tvOS Tests

#if TARGET_OS_IOS || TARGET_OS_TV

#if (defined(__IPHONE_13_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0) || \
    (defined(__TVOS_13_0) && __TV_OS_VERSION_MAX_ALLOWED >= __TVOS_13_0)

- (void)testUISceneNotifications {
    if (@available(iOS 13.0, tvOS 13.0, *)) {
        self.notificationObject = [[UISceneStub alloc] initWithConfiguration:@"Default Configuration"
                                                               delegateClass:[BSGNotificationBreadcrumbsTests class]
                                                                        role:UIWindowSceneSessionRoleApplication
                                                                  sceneClass:[UISceneStub class]
                                                                       title:@"Home"];
        
        TEST(UISceneWillConnectNotification, BSGBreadcrumbTypeState, @"Scene Will Connect",
             (@{@"configuration": @"Default Configuration",
                @"delegateClass": @"BSGNotificationBreadcrumbsTests",
                @"role": @"UIWindowSceneSessionRoleApplication",
                @"sceneClass": @"UISceneStub",
                @"title": @"Home"}));
        
        self.notificationObject = nil;
        TEST(UISceneDidDisconnectNotification, BSGBreadcrumbTypeState, @"Scene Disconnected", @{});
        TEST(UISceneDidActivateNotification, BSGBreadcrumbTypeState, @"Scene Activated", @{});
        TEST(UISceneWillDeactivateNotification, BSGBreadcrumbTypeState, @"Scene Will Deactivate", @{});
        TEST(UISceneWillEnterForegroundNotification, BSGBreadcrumbTypeState, @"Scene Will Enter Foreground", @{});
        TEST(UISceneDidEnterBackgroundNotification, BSGBreadcrumbTypeState, @"Scene Entered Background", @{});
    }
}

#endif

- (void)testUITableViewNotifications {
    TEST(UITableViewSelectionDidChangeNotification, BSGBreadcrumbTypeNavigation, @"TableView Select Change", @{});
}

#endif

#pragma mark tvOS Tests

#if TARGET_OS_TV

- (void)testUIScreenNotifications {
    TEST(UIScreenBrightnessDidChangeNotification, BSGBreadcrumbTypeState, @"Screen Brightness Changed", @{});
}

- (void)testUIWindowNotificationsNoData {
    BSGMockWindow *window = [[BSGMockWindow alloc]  init];
    window.mockScene = [[BSGMockScene alloc]  init];
    window.mockViewController = [[BSGMockViewController alloc] init];
    self.notificationObject = window;

    NSMutableDictionary *metadata = [[NSMutableDictionary alloc] init];

    TEST(UIWindowDidBecomeHiddenNotification, BSGBreadcrumbTypeState, @"Window Became Hidden", metadata);
    TEST(UIWindowDidBecomeKeyNotification, BSGBreadcrumbTypeState, @"Window Became Key", metadata);
    TEST(UIWindowDidBecomeVisibleNotification, BSGBreadcrumbTypeState, @"Window Became Visible", metadata);
    TEST(UIWindowDidResignKeyNotification, BSGBreadcrumbTypeState, @"Window Resigned Key", metadata);
}

- (void)testUIWindowNotificationsWithData {
    BSGMockWindow *window = [[BSGMockWindow alloc]  init];
    window.mockScene = [[BSGMockScene alloc]  init];
    window.mockViewController = [[BSGMockViewController alloc] init];
    self.notificationObject = window;

    window.mockDescription = @"Window Description";
    window.mockTitle = @"Window Title";
    window.mockRepresentedURLString = @"https://bugsnag.com";
    window.mockScene.title = @"Scene Title";
    window.mockScene.subtitle = @"Scene Subtitle";
    window.mockViewController.title = @"ViewController Title";
    window.mockViewController.descriptionString = @"ViewController Description";

    NSMutableDictionary *metadata = [[NSMutableDictionary alloc] init];
    metadata[@"description"] = @"Window Description";
    metadata[@"viewController"] = @"ViewController Description";
    metadata[@"viewControllerTitle"] = @"ViewController Title";

    TEST(UIWindowDidBecomeHiddenNotification, BSGBreadcrumbTypeState, @"Window Became Hidden", metadata);
    TEST(UIWindowDidBecomeKeyNotification, BSGBreadcrumbTypeState, @"Window Became Key", metadata);
    TEST(UIWindowDidBecomeVisibleNotification, BSGBreadcrumbTypeState, @"Window Became Visible", metadata);
    TEST(UIWindowDidResignKeyNotification, BSGBreadcrumbTypeState, @"Window Resigned Key", metadata);
}

#endif

#pragma mark macOS Tests

#if TARGET_OS_OSX

- (void)testNSApplicationNotifications {
    TEST(NSApplicationDidBecomeActiveNotification, BSGBreadcrumbTypeState, @"App Became Active", @{});
    TEST(NSApplicationDidBecomeActiveNotification, BSGBreadcrumbTypeState, @"App Became Active", @{});
    TEST(NSApplicationDidHideNotification, BSGBreadcrumbTypeState, @"App Did Hide", @{});
    TEST(NSApplicationDidResignActiveNotification, BSGBreadcrumbTypeState, @"App Resigned Active", @{});
    TEST(NSApplicationDidUnhideNotification, BSGBreadcrumbTypeState, @"App Did Unhide", @{});
    TEST(NSApplicationWillTerminateNotification, BSGBreadcrumbTypeState, @"App Will Terminate", @{});
}

- (void)testNSControlNotifications {
    self.notificationObject = ({
        NSControl *control = [[NSControl alloc] init];
        control.accessibilityLabel = @"button1";
        control;
    });
    TEST(NSControlTextDidBeginEditingNotification, BSGBreadcrumbTypeUser, @"Control Text Began Edit", @{@"label": @"button1"});
    TEST(NSControlTextDidEndEditingNotification, BSGBreadcrumbTypeUser, @"Control Text Ended Edit", @{@"label": @"button1"});
}

- (void)testNSMenuNotifications {
    self.notificationUserInfo = @{@"MenuItem": [[NSMenuItem alloc] initWithTitle:@"menuAction:" action:nil keyEquivalent:@""]};
    TEST(NSMenuWillSendActionNotification, BSGBreadcrumbTypeState, @"Menu Will Send Action", @{@"action": @"menuAction:"});
}

- (void)testNSTableViewNotifications {
    self.notificationObject = [[NSTableView alloc] init];
    TEST(NSTableViewSelectionDidChangeNotification, BSGBreadcrumbTypeNavigation, @"TableView Select Change",
         (@{@"selectedColumn": @(-1), @"selectedRow": @(-1)}));
}

- (void)testNSWindowNotificationsNoData {
    BSGMockWindow *window = [[BSGMockWindow alloc]  init];
    window.mockScene = [[BSGMockScene alloc]  init];
    window.mockViewController = [[BSGMockViewController alloc] init];
    self.notificationObject = window;

    NSMutableDictionary *metadata = [[NSMutableDictionary alloc] init];

    TEST(NSWindowDidBecomeKeyNotification, BSGBreadcrumbTypeState, @"Window Became Key", metadata);
    TEST(NSWindowDidEnterFullScreenNotification, BSGBreadcrumbTypeState, @"Window Entered Full Screen", metadata);
    TEST(NSWindowDidExitFullScreenNotification, BSGBreadcrumbTypeState, @"Window Exited Full Screen", metadata);
    TEST(NSWindowWillCloseNotification, BSGBreadcrumbTypeState, @"Window Will Close", metadata);
    TEST(NSWindowWillMiniaturizeNotification, BSGBreadcrumbTypeState, @"Window Will Miniaturize", metadata);
}

- (void)testNSWindowNotificationsWithData {
    BSGMockWindow *window = [[BSGMockWindow alloc]  init];
    window.mockScene = [[BSGMockScene alloc]  init];
    window.mockViewController = [[BSGMockViewController alloc] init];
    self.notificationObject = window;

    window.mockDescription = @"Window Description";
    window.mockTitle = @"Window Title";
    window.mockRepresentedURLString = @"https://bugsnag.com";
    window.mockScene.title = @"Scene Title";
    window.mockScene.subtitle = @"Scene Subtitle";
    window.mockViewController.title = @"ViewController Title";
    window.mockViewController.descriptionString = @"ViewController Description";

    NSMutableDictionary *metadata = [[NSMutableDictionary alloc] init];
    metadata[@"description"] = @"Window Description";
    metadata[@"title"] = @"Window Title";
    metadata[@"viewController"] = @"ViewController Description";
    metadata[@"viewControllerTitle"] = @"ViewController Title";
    metadata[@"representedURL"] = @"https://bugsnag.com";
#if defined(__MAC_11_0) && __MAC_OS_VERSION_MAX_ALLOWED >= __MAC_11_0
    if (@available(macOS 11.0, *)) {
        metadata[@"subtitle"] = @"Window Subtitle";
    }
#endif

    TEST(NSWindowDidBecomeKeyNotification, BSGBreadcrumbTypeState, @"Window Became Key", metadata);
    TEST(NSWindowDidEnterFullScreenNotification, BSGBreadcrumbTypeState, @"Window Entered Full Screen", metadata);
    TEST(NSWindowDidExitFullScreenNotification, BSGBreadcrumbTypeState, @"Window Exited Full Screen", metadata);
    TEST(NSWindowWillCloseNotification, BSGBreadcrumbTypeState, @"Window Will Close", metadata);
    TEST(NSWindowWillMiniaturizeNotification, BSGBreadcrumbTypeState, @"Window Will Miniaturize", metadata);
}

- (void)testNSWorkspaceNotifications {
    self.notificationCenter = self.notificationBreadcrumbs.workspaceNotificationCenter;
    TEST(NSWorkspaceScreensDidSleepNotification, BSGBreadcrumbTypeState, @"Workspace Screen Slept", @{});
    TEST(NSWorkspaceScreensDidWakeNotification, BSGBreadcrumbTypeState, @"Workspace Screen Awoke", @{});
}

#endif

@end
