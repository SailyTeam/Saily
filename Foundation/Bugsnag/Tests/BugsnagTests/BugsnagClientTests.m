//
//  BugsnagClientTests.m
//  Tests
//
//  Created by Robin Macharg on 18/03/2020.
//  Copyright © 2020 Bugsnag. All rights reserved.
//

#import "BSGInternalErrorReporter.h"
#import "BSGKeys.h"
#import "BSGRunContext.h"
#import "Bugsnag+Private.h"
#import "BugsnagBreadcrumb+Private.h"
#import "BugsnagBreadcrumbs.h"
#import "BugsnagClient+Private.h"
#import "BugsnagConfiguration+Private.h"
#import "BugsnagSystemState.h"
#import "BugsnagTestConstants.h"
#import "BugsnagUser.h"

#import <objc/runtime.h>
#import <XCTest/XCTest.h>

/**
 * Tests for BugsnagClient.
 *
 * BugsnagClient is an expensive object and not suitable for unit testing because it depends on and alters global
 * state like the file system and default notification center. Furthermore, instances never get deallocated - so
 * clients instantiated by previous test cases can alter the results of a client instantiated in a later test
 * case due to the shared global state.
 *
 * For these reasons, test cases should only be added here as a matter of last resort.
 */
@interface BugsnagClientTests : XCTestCase
@end

NSString *BSGFormatSeverity(BSGSeverity severity);

@implementation BugsnagClientTests

/**
 * A boilerplate helper method to setup Bugsnag
 */
-(BugsnagClient *)setUpBugsnagWillCallNotify:(bool)willNotify {
    BugsnagConfiguration *configuration = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    if (willNotify) {
        [configuration addOnSendErrorBlock:^BOOL(BugsnagEvent *_Nonnull event) {
            return false;
        }];
    }
    return [[BugsnagClient alloc] initWithConfiguration:configuration];
}

/**
 * Handled events leave a breadcrumb when notify() is called.  Test that values are inserted
 * correctly.
 */
- (void)testAutomaticNotifyBreadcrumbData {

    BugsnagClient *client = [self setUpBugsnagWillCallNotify:false];

    NSException *ex = [[NSException alloc] initWithName:@"myName" reason:@"myReason1" userInfo:nil];

    __block NSString *eventErrorClass;
    __block NSString *eventErrorMessage;
    __block BOOL eventUnhandled;
    __block NSString *eventSeverity;

    // Check that the event is passed the apiKey
    [client notify:ex block:^BOOL(BugsnagEvent * _Nonnull event) {
        XCTAssertEqualObjects(event.apiKey, DUMMY_APIKEY_32CHAR_1);

        // Grab the values that end up in the event for later comparison
        eventErrorClass = event.errors[0].errorClass;
        eventErrorMessage = event.errors[0].errorMessage;
        eventUnhandled = [event valueForKeyPath:@"handledState.unhandled"] ? YES : NO;
        eventSeverity = BSGFormatSeverity([event severity]);
        return true;
    }];

    // Check that we can change it
    [client notify:ex];

    NSDictionary *breadcrumb = [client.breadcrumbs.lastObject objectValue];
    NSDictionary *metadata = [breadcrumb valueForKey:@"metaData"];

    XCTAssertEqualObjects([breadcrumb valueForKey:@"type"], @"error");
    XCTAssertEqualObjects([breadcrumb valueForKey:@"name"], eventErrorClass);
    XCTAssertEqualObjects([metadata valueForKey:@"errorClass"], eventErrorClass);
    XCTAssertEqualObjects([metadata valueForKey:@"name"], eventErrorMessage);
    XCTAssertEqual((bool)[metadata valueForKey:@"unhandled"], eventUnhandled);
    XCTAssertEqualObjects([metadata valueForKey:@"severity"], eventSeverity);
}

/**
 * Test that Client inherits metadata from Configuration on init()
 */
- (void) testClientConfigurationHaveSeparateMetadata {
    BugsnagConfiguration *configuration = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    [configuration addMetadata:@{@"exampleKey" : @"exampleValue"} toSection:@"exampleSection"];

    BugsnagClient *client = [[BugsnagClient alloc] initWithConfiguration:configuration];
    [client start];

    // We expect that the client metadata is the same as the configuration's to start with
    XCTAssertEqualObjects([client getMetadataFromSection:@"exampleSection" withKey:@"exampleKey"],
                          [configuration getMetadataFromSection:@"exampleSection" withKey:@"exampleKey"]);
    XCTAssertNil([client getMetadataFromSection:@"aSection" withKey:@"foo"]);
    [client addMetadata:@{@"foo" : @"bar"} withKey:@"aDict" toSection:@"aSection"];
    XCTAssertNotNil([client getMetadataFromSection:@"aSection" withKey:@"aDict"]);

    // Updates to Configuration should not affect Client
    [configuration addMetadata:@{@"exampleKey2" : @"exampleValue2"} toSection:@"exampleSection2"];
    XCTAssertNil([client getMetadataFromSection:@"exampleSection2" withKey:@"exampleKey2"]);

    // Updates to Client should not affect Configuration
    [client addMetadata:@{@"exampleKey3" : @"exampleValue3"} toSection:@"exampleSection3"];
    XCTAssertNil([configuration getMetadataFromSection:@"exampleSection3" withKey:@"exampleKey3"]);
}

- (void)testMissingApiKey {
    BugsnagConfiguration *configuration = [[BugsnagConfiguration alloc] initWithApiKey:@""];
    BugsnagClient *client = [[BugsnagClient alloc] initWithConfiguration:configuration];
    XCTAssertThrowsSpecificNamed([client start], NSException, NSInvalidArgumentException,
                                 @"An empty apiKey should cause [BugsnagClient start] to throw an exception.");
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    configuration.apiKey = nil;
#pragma clang diagnostic pop
    XCTAssertThrowsSpecificNamed([client start], NSException, NSInvalidArgumentException,
                                 @"A missing apiKey should cause [BugsnagClient start] to throw an exception.");
}

- (void)testInvalidApiKey {
    BugsnagConfiguration *configuration = [[BugsnagConfiguration alloc] initWithApiKey:@"INVALID-API-KEY"];
    BugsnagClient *client = [[BugsnagClient alloc] initWithConfiguration:configuration];
    XCTAssertNoThrow([client start], @"[BugsnagClient start] should not throw an exception if the apiKey appears to be malformed");
}

/**
 * Test that user info is stored and retreived correctly
 */
- (void) testUserInfoStorageRetrieval {
    BugsnagConfiguration *configuration = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    BugsnagClient *client = [[BugsnagClient alloc] initWithConfiguration:configuration];
    [client start];

    [client setUser:@"Jiminy" withEmail:@"jiminy@bugsnag.com" andName:@"Jiminy Cricket"];

    XCTAssertNil([client.metadata getMetadataFromSection:BSGKeyUser withKey:BSGKeyId], @"Jiminy");
    XCTAssertNil([client.metadata getMetadataFromSection:BSGKeyUser withKey:BSGKeyName], @"Jiminy Cricket");
    XCTAssertNil([client.metadata getMetadataFromSection:BSGKeyUser withKey:BSGKeyEmail], @"jiminy@bugsnag.com");

    XCTAssertEqualObjects([client user].id, @"Jiminy");
    XCTAssertEqualObjects([client user].name, @"Jiminy Cricket");
    XCTAssertEqualObjects([client user].email, @"jiminy@bugsnag.com");

    [client setUser:nil withEmail:nil andName:@"Jiminy Cricket"];

    XCTAssertNil([client user].id);
    XCTAssertEqualObjects([client user].name, @"Jiminy Cricket");
    XCTAssertNil([client user].email);
}

- (void)testMetadataMutability {
    BugsnagConfiguration *configuration = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    BugsnagClient *client = [[BugsnagClient alloc] initWithConfiguration:configuration];
    [client start];

    // Immutable in, mutable out
    [client addMetadata:@{@"foo" : @"bar"} toSection:@"section1"];
    NSObject *metadata1 = [client getMetadataFromSection:@"section1"];
    XCTAssertTrue([metadata1 isKindOfClass:[NSMutableDictionary class]]);

    // Mutable in, mutable out
    [client addMetadata:[@{@"foo" : @"bar"} mutableCopy] toSection:@"section2"];
    NSObject *metadata2 = [client getMetadataFromSection:@"section2"];
    XCTAssertTrue([metadata2 isKindOfClass:[NSMutableDictionary class]]);
}

/**
 * Helper for asserting two BugsnagConfiguration objects are equal
 */
- (void)assertEqualConfiguration:(BugsnagConfiguration *)expected withActual:(BugsnagConfiguration *)actual {
    XCTAssertEqualObjects(expected.apiKey, actual.apiKey);
    XCTAssertEqualObjects(expected.appType, actual.appType);
    XCTAssertEqualObjects(expected.appVersion, actual.appVersion);
    XCTAssertEqual(expected.autoDetectErrors, actual.autoDetectErrors);
    XCTAssertEqual(expected.autoTrackSessions, actual.autoTrackSessions);
    XCTAssertEqualObjects(expected.bundleVersion, actual.bundleVersion);
    XCTAssertEqual(expected.context, actual.context);
    XCTAssertEqual(expected.enabledBreadcrumbTypes, actual.enabledBreadcrumbTypes);
    XCTAssertEqual(expected.enabledErrorTypes.cppExceptions, actual.enabledErrorTypes.cppExceptions);
    XCTAssertEqual(expected.enabledErrorTypes.unhandledExceptions, actual.enabledErrorTypes.unhandledExceptions);
    XCTAssertEqual(expected.enabledErrorTypes.unhandledRejections, actual.enabledErrorTypes.unhandledRejections);
    XCTAssertEqual(expected.enabledReleaseStages, actual.enabledReleaseStages);
    XCTAssertEqualObjects(expected.endpoints.notify, actual.endpoints.notify);
    XCTAssertEqualObjects(expected.endpoints.sessions, actual.endpoints.sessions);
    XCTAssertEqual(expected.maxPersistedEvents, actual.maxPersistedEvents);
    XCTAssertEqual(expected.maxPersistedSessions, actual.maxPersistedSessions);
    XCTAssertEqual(expected.maxBreadcrumbs, actual.maxBreadcrumbs);
    XCTAssertEqual(expected.persistUser, actual.persistUser);
    XCTAssertEqual([expected.redactedKeys count], [actual.redactedKeys count]);
    XCTAssertEqualObjects([expected.redactedKeys allObjects][0], [actual.redactedKeys allObjects][0]);
    XCTAssertEqualObjects(expected.releaseStage, actual.releaseStage);
#if !TARGET_OS_WATCH
    XCTAssertEqual(expected.enabledErrorTypes.machExceptions, actual.enabledErrorTypes.machExceptions);
    XCTAssertEqual(expected.enabledErrorTypes.signals, actual.enabledErrorTypes.signals);
    XCTAssertEqual(expected.enabledErrorTypes.ooms, actual.enabledErrorTypes.ooms);
    XCTAssertEqual(expected.sendThreads, actual.sendThreads);
#endif
}

/**
 * After starting Bugsnag, any changes to the supplied Configuration should be ignored
 * Instead it should be changed by mutating the returned Configuration from "[Bugsnag configuration]"
 */
- (void)testChangesToConfigurationAreIgnoredAfterCallingStart {
    BugsnagConfiguration *config = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    // Take a copy of our Configuration object so we can compare with it later
    BugsnagConfiguration *initialConfig = [config copy];

    BugsnagClient *client = [[BugsnagClient alloc] initWithConfiguration:config];
    [client start];

    // Modify some arbitrary properties
    config.persistUser = !config.persistUser;
    config.maxPersistedEvents = config.maxPersistedEvents * 2;
    config.maxPersistedSessions = config.maxPersistedSessions * 2;
    config.maxBreadcrumbs = config.maxBreadcrumbs * 2;
    config.appVersion = @"99.99.99";

    // Ensure the changes haven't been reflected in our copy
    XCTAssertNotEqual(initialConfig.persistUser, config.persistUser);
    XCTAssertNotEqual(initialConfig.maxPersistedEvents, config.maxPersistedEvents);
    XCTAssertNotEqual(initialConfig.maxPersistedSessions, config.maxPersistedSessions);
    XCTAssertNotEqual(initialConfig.maxBreadcrumbs, config.maxBreadcrumbs);
    XCTAssertNotEqualObjects(initialConfig.appVersion, config.appVersion);

    BugsnagConfiguration *configAfter = client.configuration;

    [self assertEqualConfiguration:initialConfig withActual:configAfter];
}

- (void)testStartingBugsnagTwiceLogsAWarningAndIgnoresNewConfiguration {
    [Bugsnag startWithApiKey:DUMMY_APIKEY_32CHAR_1];
    BugsnagConfiguration *initialConfig = Bugsnag.client.configuration;

    // Create a new Configuration object and modify some arbitrary properties
    // These updates should all be ignored as Bugsnag has been started already
    BugsnagConfiguration *updatedConfig = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_2];
    updatedConfig.persistUser = !initialConfig.persistUser;
    updatedConfig.maxBreadcrumbs = initialConfig.maxBreadcrumbs * 2;
    updatedConfig.maxPersistedEvents = initialConfig.maxPersistedEvents * 2;
    updatedConfig.maxPersistedSessions = initialConfig.maxPersistedSessions * 2;
    updatedConfig.appVersion = @"99.99.99";

    [Bugsnag startWithConfiguration:updatedConfig];

    BugsnagConfiguration *configAfter = Bugsnag.client.configuration;

    [self assertEqualConfiguration:initialConfig withActual:configAfter];
}

/**
 * Verifies that a large breadcrumb is not dropped (historically there was a 4kB limit)
 */
- (void)testLargeBreadcrumbSize {
    BugsnagConfiguration *configuration = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    configuration.enabledBreadcrumbTypes = BSGEnabledBreadcrumbTypeNone;
    BugsnagClient *client = [[BugsnagClient alloc] initWithConfiguration:configuration];
    [client start];

    XCTAssertEqual(client.breadcrumbs.count, 0);

    // small breadcrumb can be left without issue
    [client leaveBreadcrumbWithMessage:@"Hello World"];
    XCTAssertEqual(client.breadcrumbs.count, 1);

    // large breadcrumb is also left without issue
    __block NSUInteger crumbSize = 0;
    __block BugsnagBreadcrumb *crumb;

    [client addOnBreadcrumbBlock:^BOOL(BugsnagBreadcrumb *breadcrumb) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:[breadcrumb objectValue] options:0 error:nil];
        crumbSize = data.length;
        crumb = breadcrumb;
        return true;
    }];

    NSDictionary *largeMetadata = [self generateLargeMetadata];
    [client leaveBreadcrumbWithMessage:@"Hello World"
                              metadata:largeMetadata
                               andType:BSGBreadcrumbTypeManual];
    XCTAssertTrue(crumbSize > 4096); // previous 4kb limit
    XCTAssertEqual(client.breadcrumbs.count, 2);
    XCTAssertNotNil(crumb);
    XCTAssertEqualObjects(@"Hello World", crumb.message);
    XCTAssertEqualObjects(largeMetadata, crumb.metadata);
}

- (void)testMetadataInvalidKey {
    BugsnagConfiguration *configuration = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    configuration.enabledBreadcrumbTypes = BSGEnabledBreadcrumbTypeNone;
    BugsnagClient *client = [[BugsnagClient alloc] initWithConfiguration:configuration];
    [client start];

    id badMetadata = @{
        @"test": @"string key is fine",
        @85 : @"numeric key would break JSON"
    };

    [client notifyError:[NSError errorWithDomain:@"test" code:0 userInfo:badMetadata]];
}

- (NSDictionary *)generateLargeMetadata {
    NSMutableDictionary *dict = [NSMutableDictionary new];

    for (int k = 0; k < 10000; ++k) {
        NSString *key = [NSString stringWithFormat:@"%d", k];
        NSString *value = [NSString stringWithFormat:@"Some metadata value here %d", k];
        dict[key] = value;
    }
    return dict;
}

@end
