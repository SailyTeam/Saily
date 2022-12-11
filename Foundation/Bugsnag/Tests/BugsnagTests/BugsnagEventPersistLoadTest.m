//
//  BugsnagEventPersistenceTest.m
//  Tests
//
//  Created by Jamie Lynch on 11/05/2020.
//  Copyright © 2020 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BugsnagEvent+Private.h"
#import "BugsnagAppWithState.h"
#import "BugsnagUser.h"
#import "BugsnagDeviceWithState+Private.h"
#import "BugsnagError.h"
#import "BugsnagStackframe.h"
#import "BugsnagBreadcrumb.h"
#import "BugsnagHandledState.h"
#import "Bugsnag.h"
#import "BugsnagError.h"
#import "BugsnagSession+Private.h"
#import "BugsnagStackframe.h"
#import "BugsnagThread.h"

@interface BugsnagEventPersistLoadTest : XCTestCase
@property NSDictionary *eventData;
@end

/**
 * Verifies that a BugsnagEvent can load information persisted from a handled error.
 *
 * Handled errors store information in the user section of the KSCrashReport. The
 * stored information matches the JSON schema of an Error Reporting API payload.
 */
@implementation BugsnagEventPersistLoadTest

- (void)setUp {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:@"report" ofType:@"json"];
    NSString *contents = [NSString stringWithContentsOfFile:path
                                                   encoding:NSUTF8StringEncoding
                                                      error:nil];
    NSData *contentData = [contents dataUsingEncoding:NSUTF8StringEncoding];
    self.eventData = [NSJSONSerialization JSONObjectWithData:contentData
                                                     options:0
                                                       error:nil];
}

/**
 * Constructs JSON data used to build a BugsnagEvent from a KSCrashReport
 * @param overrides the overrides that would be persisted in the user section of the report
 * @return a representation of the persisted JSON
 */
- (BugsnagEvent *)generateEventWithOverrides:(NSDictionary *)overrides {
    NSMutableDictionary *event = [self.eventData mutableCopy];
    if (overrides != nil) {
        event[@"user"] = [event[@"user"] mutableCopy];
        event[@"user"][@"event"] = overrides;
    }
    return [[BugsnagEvent alloc] initWithKSReport:event];
}

- (void)testNilDict {
    BugsnagEvent *event = [self generateEventWithOverrides:nil];
    XCTAssertNotNil(event);
}

- (void)testEmptyDict {
    BugsnagEvent *event = [self generateEventWithOverrides:@{}];
    XCTAssertNotNil(event);
}

- (void)testContextOverride {
    BugsnagEvent *event = [self generateEventWithOverrides:@{
            @"context": @"Making network request"
    }];
    XCTAssertEqualObjects(@"Making network request", event.context);
}

- (void)testApiKeyOverride {
    BugsnagEvent *event = [self generateEventWithOverrides:@{
            @"apiKey": @"f0ab0192837465afbecd0192837465af"
    }];
    XCTAssertEqualObjects(@"f0ab0192837465afbecd0192837465af", event.apiKey);
}

- (void)testGroupingHashOverride {
    BugsnagEvent *event = [self generateEventWithOverrides:@{
            @"groupingHash": @"509adf9c"
    }];
    XCTAssertEqualObjects(@"509adf9c", event.groupingHash);
}

- (void)testUserOverride {
    BugsnagEvent *event = [self generateEventWithOverrides:@{
            @"user": @{
                    @"id": @"958",
                    @"email": @"ishmael@yahoo.com",
                    @"name": @"Ishmael"
            }
    }];
    XCTAssertEqualObjects(@"958", event.user.id);
    XCTAssertEqualObjects(@"ishmael@yahoo.com", event.user.email);
    XCTAssertEqualObjects(@"Ishmael", event.user.name);
}

- (void)testAppFieldsOverride {
    BugsnagEvent *event = [self generateEventWithOverrides:@{
            @"app": @{
                    @"duration": @5092,
                    @"durationInForeground": @4293,
                    @"inForeground": @NO,
                    @"bundleVersion": @"5.69",
                    @"codeBundleId": @"293.4",
                    @"dsymUUIDs": @[@"f0ab09ee"],
                    @"id": @"uk.co.bugsnag",
                    @"releaseStage": @"beta",
                    @"type": @"custom",
                    @"version": @"2.3.4"
            }
    }];
    BugsnagAppWithState *app = event.app;
    XCTAssertEqual(@5092, app.duration);
    XCTAssertEqual(@4293, app.durationInForeground);
    XCTAssertFalse(app.inForeground);
    XCTAssertEqualObjects(@"5.69", app.bundleVersion);
    XCTAssertEqualObjects(@"293.4", app.codeBundleId);
    XCTAssertEqualObjects(@"f0ab09ee", app.dsymUuid);
    XCTAssertEqualObjects(@"uk.co.bugsnag", app.id);
    XCTAssertEqualObjects(@"beta", app.releaseStage);
    XCTAssertEqualObjects(@"custom", app.type);
    XCTAssertEqualObjects(@"2.3.4", app.version);
}

- (void)testDeviceFieldsOverride {
    BugsnagEvent *event = [self generateEventWithOverrides:@{
            @"device": @{
                    @"freeDisk": @920234094,
                    @"freeMemory": @5092340923,
                    @"totalMemory": @92092340923,
                    @"orientation": @"landscape",
                    @"time": @"2020-05-11T15:36:09Z",
                    @"jailbroken": @NO,
                    @"id": @"f0a9b99",
                    @"locale": @"yue",
                    @"manufacturer": @"Foxconn",
                    @"model": @"Custom iPhone",
                    @"modelNumber": @"Custom iPhone 7",
                    @"osName": @"Lunix",
                    @"osVersion": @"15.923",
                    @"runtimeVersions": @{
                            @"fiddleBorkVersion": @"2.3"
                    }
            }
    }];
    
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZ";
    formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];

    BugsnagDeviceWithState *device = event.device;
    XCTAssertEqualObjects(@920234094, device.freeDisk);
    XCTAssertEqualObjects(@5092340923, device.freeMemory);
    XCTAssertEqualObjects(@92092340923, device.totalMemory);
    XCTAssertEqualObjects(@"landscape", device.orientation);
    XCTAssertFalse(device.jailbroken);
    NSString *date = [formatter stringFromDate:device.time];
    XCTAssertEqualObjects(@"2020-05-11T15:36:09+0000", date);

    XCTAssertEqualObjects(@"f0a9b99", device.id);
    XCTAssertEqualObjects(@"yue", device.locale);
    XCTAssertEqualObjects(@"Foxconn", device.manufacturer);
    XCTAssertEqualObjects(@"Custom iPhone", device.model);
    XCTAssertEqualObjects(@"Custom iPhone 7", device.modelNumber);
    XCTAssertEqualObjects(@"Lunix", device.osName);
    XCTAssertEqualObjects(@"15.923", device.osVersion);
    XCTAssertEqualObjects(@{
            @"fiddleBorkVersion": @"2.3"
    }, device.runtimeVersions);
}

- (void)testErrorsOverride {
    BugsnagEvent *event = [self generateEventWithOverrides:@{
            @"exceptions": @[@{
                    @"errorClass": @"InvalidNetworkError",
                    @"message": @"No network connection",
                    @"type": @"reactnativejs",
                    @"stacktrace": @[
                            @{
                                    @"machoFile": @"/Users/foo/Bugsnag.h",
                                    @"method": @"-[BugsnagClient notify:handledState:block:]",
                                    @"machoUUID": @"B6D80CB5-A772-3D2F-B5A1-A3A137B8B58F",
                                    @"frameAddress": @"0x10b5756bf",
                                    @"symbolAddress": @"0x10b574fa0",
                                    @"machoLoadAddress": @"0x10b54b000",
                                    @"machoVMAddress": @"0x102340922",
                                    @"isPC": @YES,
                                    @"isLR": @YES
                            }
                    ]
            }]
    }];
    BugsnagError *error = event.errors[0];
    XCTAssertNotNil(error);
    XCTAssertEqual(1, [event.errors count]);
    XCTAssertEqualObjects(@"InvalidNetworkError", error.errorClass);
    XCTAssertEqualObjects(@"No network connection", error.errorMessage);
    XCTAssertEqual(BSGErrorTypeReactNativeJs, error.type);

    BugsnagStackframe *frame = error.stacktrace[0];
    XCTAssertNotNil(frame);
    XCTAssertEqual(1, [error.stacktrace count]);
    XCTAssertEqualObjects(@"-[BugsnagClient notify:handledState:block:]", frame.method);
    XCTAssertEqualObjects(@"/Users/foo/Bugsnag.h", frame.machoFile);
    XCTAssertEqualObjects(@"B6D80CB5-A772-3D2F-B5A1-A3A137B8B58F", frame.machoUuid);
    XCTAssertEqualObjects(@0x102340922, frame.machoVmAddress);
    XCTAssertEqualObjects(@0x10b574fa0, frame.symbolAddress);
    XCTAssertEqualObjects(@0x10b54b000, frame.machoLoadAddress);
    XCTAssertEqualObjects(@0x10b5756bf, frame.frameAddress);
    XCTAssertTrue(frame.isPc);
    XCTAssertTrue(frame.isLr);
}

- (void)testMetadataOverride {
    BugsnagEvent *event = [self generateEventWithOverrides:@{
            @"metaData": @{
                    @"custom": @{
                            @"foo": @"bar"
                    }
            }
    }];
    XCTAssertEqualObjects(@"bar", [event getMetadataFromSection:@"custom" withKey:@"foo"]);
}

- (void)testBreadcrumbsOverride {
    BugsnagEvent *event = [self generateEventWithOverrides:@{
            @"breadcrumbs": @[
                    @{
                            @"type": @"manual",
                            @"timestamp": @"2020-02-14T16:12:23+001",
                            @"message": @"installed NDK",
                            @"metaData": @{
                            @"custom": @{
                                    @"foo": @"bar"
                            }
                    }
                    }]
    }];
    BugsnagBreadcrumb *breadcrumb = event.breadcrumbs[0];
    XCTAssertNotNil(breadcrumb);
    XCTAssertEqual(1, [event.breadcrumbs count]);
    XCTAssertEqual(BSGBreadcrumbTypeManual, breadcrumb.type);
    XCTAssertEqualObjects(@"installed NDK", breadcrumb.message);
    
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZ";
    formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    NSDate *date = [formatter dateFromString:@"2020-02-14T16:12:23+001"];
    XCTAssertEqualObjects(date, breadcrumb.timestamp);
    XCTAssertEqualObjects(@{
            @"custom": @{
                    @"foo": @"bar"
            }
    }, breadcrumb.metadata);
}

- (void)testSeverityReasonOverride {
    BugsnagEvent *event = [self generateEventWithOverrides:@{
            @"severityReason": @{
                    @"type": @"log",
                    @"attributes": @{
                            @"level": @"info"
                    }
            },
            @"severity": @"info",
            @"unhandled": @YES
    }];
    XCTAssertEqualObjects(@"level", event.handledState.attrKey);
    XCTAssertEqualObjects(@"info", event.handledState.attrValue);
    XCTAssertEqual(LogMessage, event.handledState.severityReasonType);
    XCTAssertEqual(BSGSeverityInfo, event.handledState.originalSeverity);
    XCTAssertEqual(BSGSeverityInfo, event.handledState.currentSeverity);
    XCTAssertTrue(event.unhandled);
}

- (void)testThreadsOverride {
    BugsnagEvent *event = [self generateEventWithOverrides:@{
            @"threads": @[
                    @{
                            @"id": @"13",
                            @"name": @"thread-id-1",
                            @"errorReportingThread": @YES,
                            @"type": @"reactnativejs",
                            @"stacktrace": @[
                            @{
                                    @"machoFile": @"/Users/foo/Bugsnag.h",
                                    @"method": @"-[BugsnagClient notify:handledState:block:]",
                                    @"machoUUID": @"B6D80CB5-A772-3D2F-B5A1-A3A137B8B58F",
                                    @"frameAddress": @"0x10b5756bf",
                                    @"symbolAddress": @"0x10b574fa0",
                                    @"machoLoadAddress": @"0x10b54b000",
                                    @"machoVMAddress": @"0x102340922",
                                    @"isPC": @YES,
                                    @"isLR": @YES
                            }
                    ]}
            ]
    }];
    BugsnagThread *thread = event.threads[0];
    XCTAssertNotNil(thread);
    XCTAssertEqual(1, [event.threads count]);
    XCTAssertEqualObjects(@"13", thread.id);
    XCTAssertEqualObjects(@"thread-id-1", thread.name);
    XCTAssertTrue(thread.errorReportingThread);
    XCTAssertEqual(BSGThreadTypeReactNativeJs, thread.type);

    BugsnagStackframe *frame = thread.stacktrace[0];
    XCTAssertNotNil(frame);
    XCTAssertEqual(1, [thread.stacktrace count]);
    XCTAssertEqualObjects(@"-[BugsnagClient notify:handledState:block:]", frame.method);
    XCTAssertEqualObjects(@"/Users/foo/Bugsnag.h", frame.machoFile);
    XCTAssertEqualObjects(@"B6D80CB5-A772-3D2F-B5A1-A3A137B8B58F", frame.machoUuid);
    XCTAssertEqualObjects(@0x102340922, frame.machoVmAddress);
    XCTAssertEqualObjects(@0x10b574fa0, frame.symbolAddress);
    XCTAssertEqualObjects(@0x10b54b000, frame.machoLoadAddress);
    XCTAssertEqualObjects(@0x10b5756bf, frame.frameAddress);
    XCTAssertTrue(frame.isPc);
    XCTAssertTrue(frame.isLr);
}

- (void)testSessionOverride {
    BugsnagEvent *event = [self generateEventWithOverrides:@{
            @"session": @{
                    @"startedAt": @"2020-05-18T13:13:24Z",
                    @"id": @"123",
                    @"events": @{
                            @"unhandled": @1,
                            @"handled": @2
                    }
            }
    }];
    
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZ";
    formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    NSDate *date = [formatter dateFromString:@"2020-05-18T13:13:24Z"];
    XCTAssertEqualObjects(date, event.session.startedAt);
    XCTAssertEqualObjects(@"123", event.session.id);
    XCTAssertEqual(1, event.session.unhandledCount);
    XCTAssertEqual(2, event.session.handledCount);
}

- (void)testReactNativePromiseRejection {
    NSURL *url = [[NSBundle bundleForClass:[self class]] URLForResource:@"report-react-native-promise-rejection" withExtension:@"json"];
    NSDictionary *userData = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:url] options:0 error:nil];
    XCTAssertEqualObjects([userData valueForKeyPath:@"user.event.exceptions.@count"], @(2));
    BugsnagEvent *event = [[BugsnagEvent alloc] initWithKSReport:userData];
    XCTAssertEqual(event.errors.count, 2);
    XCTAssertEqualObjects([[event toJsonWithRedactedKeys:nil] valueForKeyPath:@"exceptions.@count"], @(2),
                          @"JSON representation of event should have the same number of errors / exceptions");
}

@end
