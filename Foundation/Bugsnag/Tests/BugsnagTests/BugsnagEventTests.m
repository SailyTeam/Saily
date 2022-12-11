//
//  BugsnagEventTests.m
//  Bugsnag
//
//  Created by Simon Maynard on 12/1/14.
//
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#import "BSG_RFC3339DateTool.h"
#import "Bugsnag.h"
#import "BugsnagBreadcrumb+Private.h"
#import "BugsnagClient+Private.h"
#import "BugsnagEvent+Private.h"
#import "BugsnagHandledState.h"
#import "BugsnagMetadata+Private.h"
#import "BugsnagSession.h"
#import "BugsnagSession+Private.h"
#import "BugsnagStackframe+Private.h"
#import "BugsnagTestConstants.h"
#import "BugsnagTestsDummyClass.h"

@interface BugsnagEventTests : XCTestCase
@end

@implementation BugsnagEventTests

- (BugsnagEvent *)generateEvent:(BugsnagHandledState *)handledState {
    return [[BugsnagEvent alloc] initWithApp:nil
                                      device:nil
                                handledState:handledState
                                        user:nil
                                    metadata:nil
                                 breadcrumbs:@[]
                                      errors:@[]
                                     threads:@[]
                                     session:nil];
}

- (void)testEnabledReleaseStagesSendsFromConfig {
    BugsnagEvent *event = [self generateEvent:nil];
    event.enabledReleaseStages = @[@"foo"];
    event.releaseStage = @"foo";
    XCTAssertTrue([event shouldBeSent]);
}

- (void)testEnabledReleaseStagesSkipsSendFromConfig {
    BugsnagEvent *event = [self generateEvent:nil];
    event.enabledReleaseStages = @[ @"foo", @"bar" ];
    event.releaseStage = @"not foo or bar";
    XCTAssertFalse([event shouldBeSent]);
}

- (void)testSessionJson {
    NSDate *now = [NSDate date];
    BugsnagApp *app;
    BugsnagDevice *device;
    BugsnagSession *bugsnagSession = [[BugsnagSession alloc] initWithId:@"123"
                                                              startedAt:now
                                                                   user:nil
                                                                    app:app
                                                                 device:device];
    bugsnagSession.handledCount = 2;
    bugsnagSession.unhandledCount = 1;

    BugsnagEvent *event = [self generateEvent:nil];
    event.session = bugsnagSession;
    NSDictionary *json = [event toJsonWithRedactedKeys:nil];
    XCTAssertNotNil(json);

    NSDictionary *session = json[@"session"];
    XCTAssertNotNil(session);
    XCTAssertEqualObjects(@"123", session[@"id"]);
    XCTAssertEqualObjects([BSG_RFC3339DateTool stringFromDate:now],
                          session[@"startedAt"]);

    NSDictionary *events = session[@"events"];
    XCTAssertNotNil(events);
    XCTAssertEqualObjects(@2, events[@"handled"]);
    XCTAssertEqualObjects(@1, events[@"unhandled"]);
}

- (void)testDefaultErrorMessageNilForEmptyThreads {
    BugsnagEvent *event = [[BugsnagEvent alloc] initWithKSReport:@{
        @"threads" : @[]
    }];
    NSDictionary *payload = [event toJsonWithRedactedKeys:nil];
    XCTAssertEqualObjects(@"Exception",
                          payload[@"exceptions"][0][@"errorClass"]);
    XCTAssertEqualObjects(@"", payload[@"exceptions"][0][@"message"]);
    XCTAssertEqualObjects(event.errors[0].errorClass,
                          payload[@"exceptions"][0][@"errorClass"]);
    XCTAssertEqualObjects(event.errors[0].errorMessage,
                          payload[@"exceptions"][0][@"message"]);
}

- (void)testEmptyReport {
    BugsnagEvent *event = [[BugsnagEvent alloc] initWithKSReport:@{}];
    XCTAssertNil(event);
}

- (void)testUnhandledReportDepth {
    // unhandled reports should calculate their own depth
    NSDictionary *dict = @{@"user.depth": @2};
    BugsnagEvent *event = [[BugsnagEvent alloc] initWithKSReport:dict];
    XCTAssertEqual(event.depth, 0);
}

- (void)testHandledReportDepth {
    // handled reports should use the serialised depth
    BugsnagHandledState *state = [BugsnagHandledState handledStateWithSeverityReason:HandledException];
    NSDictionary *dict = @{@"user.depth": @2, @"user.handledState": [state toJson]};
    BugsnagEvent *event = [[BugsnagEvent alloc] initWithKSReport:dict];
    XCTAssertEqual(event.depth, 2);
}

- (void)testUnhandledReportSeverity {
    // unhandled reports should calculate their own severity
    NSDictionary *dict = @{@"user.state.crash.severity": @"info"};
    BugsnagEvent *event = [[BugsnagEvent alloc] initWithKSReport:dict];
    XCTAssertEqual(event.severity, BSGSeverityError);
}

- (void)testHandledReportSeverity {
    // handled reports should use the serialised depth
    BugsnagHandledState *state = [BugsnagHandledState handledStateWithSeverityReason:HandledException];
    NSDictionary *dict = @{@"user.handledState": [state toJson]};
    BugsnagEvent *event = [[BugsnagEvent alloc] initWithKSReport:dict];
    XCTAssertEqual(event.severity, BSGSeverityWarning);
}

- (void)testHandledReportMetaData {
    BugsnagHandledState *state = [BugsnagHandledState handledStateWithSeverityReason:HandledException];
    BugsnagMetadata *metadata = [BugsnagMetadata new];
    [metadata addMetadata:@"Bar" withKey:@"Foo" toSection:@"Custom"];
    NSDictionary *dict = @{@"user.handledState": [state toJson], @"user.metaData": [metadata toDictionary]};

    BugsnagEvent *event = [[BugsnagEvent alloc] initWithKSReport:dict];
    [event clearMetadataFromSection:@"device"];
    XCTAssertNotNil(event.metadata);
    XCTAssertEqual([[event.metadata toDictionary] count], 1);
    XCTAssertEqualObjects([event.metadata getMetadataFromSection:@"Custom" withKey:@"Foo"], @"Bar");
}

- (void)testUnhandledReportMetaData {
    BugsnagMetadata *metadata = [BugsnagMetadata new];
    [metadata addMetadata:@"Bar" withKey:@"Foo" toSection:@"Custom"];
    NSDictionary *dict = @{@"user.metaData": [metadata toDictionary]};

    BugsnagEvent *event = [[BugsnagEvent alloc] initWithKSReport:dict];
    [event clearMetadataFromSection:@"device"];
    XCTAssertNotNil(event.metadata);
    XCTAssertEqual([[event.metadata toDictionary] count], 1);
    XCTAssertEqualObjects([event.metadata getMetadataFromSection:@"Custom" withKey:@"Foo"], @"Bar");
}

- (void)testAppVersionOverride {
    BugsnagEvent *overrideReport = [[BugsnagEvent alloc] initWithKSReport:@{
            @"system" : @{
                    @"CFBundleShortVersionString": @"1.1",
            },
            @"user": @{
                    @"config": @{
                            @"appVersion": @"1.2.3"
                    }
            }
    }];
    NSDictionary *dictionary = [overrideReport toJsonWithRedactedKeys:nil];
    XCTAssertEqualObjects(@"1.2.3", dictionary[@"app"][@"version"]);
}

- (void)testBundleVersionOverride {
    BugsnagEvent *overrideReport = [[BugsnagEvent alloc] initWithKSReport:@{
            @"system" : @{
                    @"CFBundleVersion": @"1.1",
            },
            @"user": @{
                    @"config": @{
                            @"bundleVersion": @"1.2.3"
                    }
            }
    }];
    NSDictionary *dictionary = [overrideReport toJsonWithRedactedKeys:nil];
    XCTAssertEqualObjects(@"1.2.3", dictionary[@"app"][@"bundleVersion"]);
}

- (void)testReportAddAttr {
    BugsnagEvent *event = [[BugsnagEvent alloc] initWithKSReport:@{@"user.metaData": @{@"user": @{@"id": @"user id"}}}];
    [event addMetadata:@"user" withKey:@"foo" toSection:@"bar"];
}

- (void)testReportAddMetadata {
    BugsnagEvent *event = [[BugsnagEvent alloc] initWithKSReport:@{@"user.metaData": @{@"user": @{@"id": @"user id"}}}];
    [event addMetadata:@{@"foo": @"bar"} toSection:@"user"];
}


/**
 * Test that BugsnagEvent has an apiKey value and supports non-persistent
 * per-event changes to apiKey.
 */
- (void)testApiKey {
    BugsnagConfiguration *config = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    BugsnagClient *client = [[BugsnagClient alloc] initWithConfiguration:config];
    [client start];

    NSException *ex = [[NSException alloc] initWithName:@"myName" reason:@"myReason1" userInfo:nil];

    // Check that the event is passed the apiKey
    [client notify:ex block:^BOOL(BugsnagEvent * _Nonnull event) {
        XCTAssertEqualObjects(event.apiKey, DUMMY_APIKEY_32CHAR_1);
        return true;
    }];

    // Check that we can change it
    [client notify:ex block:^BOOL(BugsnagEvent * _Nonnull event) {
        XCTAssertEqualObjects(event.apiKey, DUMMY_APIKEY_32CHAR_1);
        event.apiKey = DUMMY_APIKEY_32CHAR_2;
        XCTAssertEqual(event.apiKey, DUMMY_APIKEY_32CHAR_2);
        XCTAssertEqualObjects(client.configuration.apiKey, DUMMY_APIKEY_32CHAR_1);
        return true;
    }];

    // Check that the global configuration is unaffected
    [client notify:ex block:^BOOL(BugsnagEvent * _Nonnull event) {
        XCTAssertEqualObjects(event.apiKey, DUMMY_APIKEY_32CHAR_1);
        event.apiKey = DUMMY_APIKEY_32CHAR_1;
        XCTAssertEqual(event.apiKey, DUMMY_APIKEY_32CHAR_1);
        XCTAssertEqualObjects(client.configuration.apiKey, DUMMY_APIKEY_32CHAR_1);
        event.apiKey = DUMMY_APIKEY_32CHAR_3;
        XCTAssertEqual(event.apiKey, DUMMY_APIKEY_32CHAR_3);
        return true;
    }];

    // Check that previous local and global values are not persisted erroneously
    client.configuration.apiKey = DUMMY_APIKEY_32CHAR_4;
    [client notify:ex block:^BOOL(BugsnagEvent * _Nonnull event) {
        XCTAssertEqual(event.apiKey, DUMMY_APIKEY_32CHAR_4);
        event.apiKey = DUMMY_APIKEY_32CHAR_1;
        XCTAssertEqual(event.apiKey, DUMMY_APIKEY_32CHAR_1);
        XCTAssertEqual(client.configuration.apiKey, DUMMY_APIKEY_32CHAR_4);
        event.apiKey = DUMMY_APIKEY_32CHAR_2;
        XCTAssertEqual(event.apiKey, DUMMY_APIKEY_32CHAR_2);
        return true;
    }];

    // Check that validation is performed and that invalid API keys can't be set
    client.configuration.apiKey = DUMMY_APIKEY_32CHAR_1;
    [client notify:ex block:^BOOL(BugsnagEvent * _Nonnull event) {
        event.apiKey = DUMMY_APIKEY_16CHAR;
        XCTAssertEqual(event.apiKey, DUMMY_APIKEY_32CHAR_1);
        return true;
    }];
}

- (void)testStacktraceTypes {
    BugsnagEvent *event = [[BugsnagEvent alloc] init];
    XCTAssertEqualObjects(event.stacktraceTypes, @[]);
    
    BugsnagError *error = [[BugsnagError alloc] init];
    event.errors = @[error];
    error.type = BSGErrorTypeCocoa;
    XCTAssertEqualObjects(event.stacktraceTypes, @[@"cocoa"]);
    
    error.type = BSGErrorTypeReactNativeJs;
    XCTAssertEqualObjects(event.stacktraceTypes, @[@"reactnativejs"]);
    
    NSArray *(^ sorted)(NSArray *) = ^(NSArray *array) { return [array sortedArrayUsingSelector:@selector(compare:)]; };
    
    error.stacktrace = @[
        [BugsnagStackframe frameFromJson:@{}],
        [BugsnagStackframe frameFromJson:@{@"type": @"cocoa"}],
        [BugsnagStackframe frameFromJson:@{@"type": @"reactnativejs"}],
    ];
    XCTAssertEqualObjects(sorted(event.stacktraceTypes), (@[@"cocoa", @"reactnativejs"]));
    
    event.errors = @[[[BugsnagError alloc] init]];
    
    BugsnagThread *thread1 = [[BugsnagThread alloc] init];
    thread1.stacktrace = @[
        [BugsnagStackframe frameFromJson:@{@"type": @"c"}],
        [BugsnagStackframe frameFromJson:@{@"type": @"java"}],
    ];
    thread1.type = BSGThreadTypeCocoa;
    event.threads = @[thread1];
    XCTAssertEqualObjects(sorted(event.stacktraceTypes), (@[@"c", @"cocoa", @"java"]));

    BugsnagThread *thread2 = [[BugsnagThread alloc] init];
    thread2.stacktrace = @[
        [BugsnagStackframe frameFromJson:@{@"type": @"csharp"}],
        [BugsnagStackframe frameFromJson:@{@"type": @"android"}],
    ];
    event.threads = @[thread1, thread2];
    XCTAssertEqualObjects(sorted(event.stacktraceTypes), (@[@"android", @"c", @"cocoa", @"csharp", @"java"]));
}

// MARK: - JSON serialization tests

- (void)testJsonToEventToJson {
    NSString *directory = [[[[NSBundle bundleForClass:[self class]] resourcePath]
                            stringByAppendingPathComponent:@"Data"]
                           stringByAppendingPathComponent:@"BugsnagEvents"];
    
    NSArray<NSString *> *entries = [NSFileManager.defaultManager contentsOfDirectoryAtPath:directory error:nil];
    
    for (NSString *filename in entries) {
        if (![filename.pathExtension isEqual:@"json"] || [filename hasSuffix:@"."]) {
            continue;
        }
        
        NSString *file = [directory stringByAppendingPathComponent:filename];
        NSData *data = [NSData dataWithContentsOfFile:file];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        
        BugsnagEvent *event = [[BugsnagEvent alloc] initWithJson:json];
        XCTAssertNotNil(event);
        
        NSDictionary *toJson = [event toJsonWithRedactedKeys:nil];
        XCTAssertEqualObjects(json, toJson, @"Input and output JSON do not match");
    }
}

- (void)testTrimBreadcrumbs {
    BugsnagEvent *event = [BugsnagEvent new];
    
    BugsnagBreadcrumb * (^ MakeBreadcrumb)() = ^(BSGBreadcrumbType type, NSString *message, NSDictionary *metadata) {
        BugsnagBreadcrumb *breadcrumb = [BugsnagBreadcrumb new];
        breadcrumb.type = type;
        breadcrumb.message = message;
        breadcrumb.metadata = metadata;
        return breadcrumb;
    };
    
    event.breadcrumbs = @[
        MakeBreadcrumb(BSGBreadcrumbTypeState, @"Test started", @{}), // 91 bytes
        MakeBreadcrumb(BSGBreadcrumbTypeLog, @"Some log message", @{@"some": @"metadata"}), // 110 bytes
        MakeBreadcrumb(BSGBreadcrumbTypeManual, @"The final breadcrumb", @{@"key": @"untouched"})];
    
    event.usage = @{@"sentinel": @42}; // Enable gathering telemetry
    
    [event trimBreadcrumbs:100];
    
    XCTAssertEqual(event.breadcrumbs.count, 2);
    
    XCTAssertEqual       (event.breadcrumbs[0].type, BSGBreadcrumbTypeLog);
    XCTAssertEqualObjects(event.breadcrumbs[0].message, @"Removed, along with 1 older breadcrumb, to reduce payload size");
    XCTAssertEqualObjects(event.breadcrumbs[0].metadata, @{});
    
    XCTAssertEqual       (event.breadcrumbs[1].type, BSGBreadcrumbTypeManual);
    XCTAssertEqualObjects(event.breadcrumbs[1].message, @"The final breadcrumb");
    XCTAssertEqualObjects(event.breadcrumbs[1].metadata, @{@"key": @"untouched"});
    
    XCTAssertEqualObjects(event.usage, (@{@"system": @{@"breadcrumbBytesRemoved": @(91 + 110), @"breadcrumbsRemoved": @2}, @"sentinel": @42}));
}

- (void)testTrimSingleBreadcrumbs {
    BugsnagEvent *event = [BugsnagEvent new];
    
    BugsnagBreadcrumb *breadcrumb = [BugsnagBreadcrumb new]; 
    breadcrumb.message = @""
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor i"
    "ncididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostru"
    "d exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aut"
    "e irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat n"
    "ulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui"
    " officia deserunt mollit anim id est laborum.";
    breadcrumb.metadata = @{@"something": @"👍🏾🔥"};
    breadcrumb.type = BSGBreadcrumbTypeError;
    event.breadcrumbs = @[breadcrumb];
    
    NSUInteger byteCount = [NSJSONSerialization dataWithJSONObject:[breadcrumb objectValue] options:0 error:NULL].length; 
    
    event.usage = @{}; // Enable gathering telemetry
    
    [event trimBreadcrumbs:100];
    
    XCTAssertEqual       (event.breadcrumbs[0].type, BSGBreadcrumbTypeError);
    XCTAssertEqualObjects(event.breadcrumbs[0].message, @"Removed to reduce payload size");
    XCTAssertEqualObjects(event.breadcrumbs[0].metadata, @{});
    XCTAssertEqualObjects(event.usage, (@{@"system": @{@"breadcrumbBytesRemoved": @(byteCount), @"breadcrumbsRemoved": @1}}));
}

- (void)testTruncateStrings {
    BugsnagEvent *event = [BugsnagEvent new];
    
    BugsnagBreadcrumb * (^ MakeBreadcrumb)() = ^(NSString *message) {
        BugsnagBreadcrumb *breadcrumb = [BugsnagBreadcrumb new];
        breadcrumb.message = message;
        breadcrumb.metadata = @{@"string": message};
        return breadcrumb;
    };
    
    event.breadcrumbs = @[
        MakeBreadcrumb(@"Lorem ipsum dolor si"
        "t amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."),
        
        MakeBreadcrumb(@"Lorem ipsum is place"
        "holder text commonly used in the graphic, print, and publishing industries for previewing layouts and visual mockups."),
        
        MakeBreadcrumb(@"20 characters string")];
    
    event.metadata = [[BugsnagMetadata alloc] initWithDictionary:@{}];
    [event addMetadata:@"From its medieval or"
     "igins to the digital era, learn everything there is to know about the ubiquitous lorem ipsum passage."
               withKey:@"name" toSection:@"test"];
    
    event.usage = @{}; // Enable gathering telemetry
    
    [event truncateStrings:20];
    
    XCTAssertEqualObjects([event.usage valueForKeyPath:@"system.stringsTruncated"], @5);
    
    XCTAssertEqualObjects([event.usage valueForKeyPath:@"system.stringCharsTruncated"], @(103 + 103 + 117 + 117 + 101));
    
    XCTAssertEqualObjects(event.breadcrumbs[0].message, @"Lorem ipsum dolor si"
                          "\n***103 CHARS TRUNCATED***");
    
    XCTAssertEqualObjects(event.breadcrumbs[0].metadata[@"string"], @"Lorem ipsum dolor si"
                          "\n***103 CHARS TRUNCATED***");
    
    XCTAssertEqualObjects(event.breadcrumbs[1].message, @"Lorem ipsum is place"
                          "\n***117 CHARS TRUNCATED***");
    
    XCTAssertEqualObjects(event.breadcrumbs[1].metadata[@"string"], @"Lorem ipsum is place"
                          "\n***117 CHARS TRUNCATED***");
    
    XCTAssertEqualObjects(event.breadcrumbs[2].message, @"20 characters string");
    
    XCTAssertEqualObjects(event.breadcrumbs[2].metadata[@"string"], @"20 characters string");
    
    XCTAssertEqualObjects([event getMetadataFromSection:@"test" withKey:@"name"], @"From its medieval or"
                          "\n***101 CHARS TRUNCATED***");
}

// MARK: - Feature flags interface

- (void)testFeatureFlags {
    BugsnagEvent *event = [[BugsnagEvent alloc] initWithKSReport:@{
        @"user.metaData": @{
                @"user": @{@"id": @"user id"}
        }}];
    
    XCTAssertEqualObjects([event toJsonWithRedactedKeys:nil][@"featureFlags"], @[]);
    
    [event addFeatureFlagWithName:@"color" variant:@"red"];
    
    XCTAssertEqualObjects([event toJsonWithRedactedKeys:nil][@"featureFlags"],
                          (@[@{@"featureFlag": @"color", @"variant": @"red"}]));
    
    [event addFeatureFlagWithName:@"color" variant:@"green"];
    
    XCTAssertEqualObjects([event toJsonWithRedactedKeys:nil][@"featureFlags"],
                          (@[@{@"featureFlag": @"color", @"variant": @"green"}]));
    
    [event addFeatureFlagWithName:@"color"];
    
    XCTAssertEqualObjects([event toJsonWithRedactedKeys:nil][@"featureFlags"],
                          (@[@{@"featureFlag": @"color"}]));
    
    [event clearFeatureFlags];
    
    XCTAssertEqualObjects([event toJsonWithRedactedKeys:nil][@"featureFlags"], @[]);
}

// MARK: - Metadata interface

- (void)testAddMetadataSectionKeyValue {
    BugsnagEvent *event = [[BugsnagEvent alloc] initWithKSReport:@{
        @"user.metaData": @{
                @"user": @{@"id": @"user id"}
        }}];
    [event addMetadata:@{@"foo": @"bar"} toSection:@"section"];

    // Known
    XCTAssertEqual([event getMetadataFromSection:@"section" withKey:@"foo"], @"bar");
    XCTAssertNotNil([event getMetadataFromSection:@"section"]);
    XCTAssertEqual([[event getMetadataFromSection:@"section"] count], 1);
    [event addMetadata:@{@"baz": @"bam"} toSection:@"section"];
    XCTAssertEqual([[event getMetadataFromSection:@"section"] count], 2);
    XCTAssertEqual([event getMetadataFromSection:@"section" withKey:@"baz"], @"bam");
    // check type
    NSDictionary *v = [event getMetadataFromSection:@"section"];
    XCTAssertTrue([((NSString *)[v valueForKey:@"foo"]) isEqualToString:@"bar"]);

    // Unknown
    XCTAssertNil([event getMetadataFromSection:@"section" withKey:@"bob"]);
    XCTAssertNil([event getMetadataFromSection:@"anotherSection" withKey:@"baz"]);
    XCTAssertNil([event getMetadataFromSection:@"dummySection"]);
}

/**
 * Invalid data should not be set.  Manually check for coverage of logging code.
 */
- (void)testInvalidSectionData {
    NSException *ex = [[NSException alloc] initWithName:@"myName" reason:@"myReason1" userInfo:nil];
    BugsnagConfiguration *config = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    BugsnagClient *client = [[BugsnagClient alloc] initWithConfiguration:config];
    [client start];

    [client notify:ex block:^BOOL(BugsnagEvent * _Nonnull event) {
        [event clearMetadataFromSection:@"app"];
        [event clearMetadataFromSection:@"user"];
        [event clearMetadataFromSection:@"device"];
        [event clearMetadataFromSection:@"error"];
        NSDictionary *invalidDict = @{};
        NSDictionary *validDict = @{@"myKey" : @"myValue"};
        [event addMetadata:invalidDict toSection:@"mySection"];
        XCTAssertEqual([[event.metadata toDictionary] count], 0);
        [event addMetadata:validDict toSection:@"mySection"];
        XCTAssertEqual([[event.metadata toDictionary] count], 1);
        return true;
    }];
}

- (void)testInvalidKeyValueData {
    NSException *ex = [[NSException alloc] initWithName:@"myName" reason:@"myReason1" userInfo:nil];
    BugsnagConfiguration *config = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    BugsnagClient *client = [[BugsnagClient alloc] initWithConfiguration:config];
    [client start];

    [client notify:ex block:^BOOL(BugsnagEvent * _Nonnull event) {
        [event clearMetadataFromSection:@"app"];
        [event clearMetadataFromSection:@"user"];
        [event clearMetadataFromSection:@"device"];
        [event clearMetadataFromSection:@"error"];
        [event addMetadata:[NSNull null] withKey:@"myKey" toSection:@"mySection"];

        // Invalid value for a non-existant section doesn't cause the section to be created
        XCTAssertEqual([[event.metadata toDictionary] count], 0);
        XCTAssertNil([event.metadata getMetadataFromSection:@"myKey"]);

        [event addMetadata:@"aValue" withKey:@"myKey" toSection:@"mySection"];
        XCTAssertEqual([[event.metadata toDictionary] count], 1);
        XCTAssertNotNil([event.metadata getMetadataFromSection:@"mySection" withKey:@"myKey"]);

        BugsnagTestsDummyClass *dummy = [BugsnagTestsDummyClass new];
        [event addMetadata:dummy withKey:@"myNewKey" toSection:@"mySection"];
        XCTAssertEqual([[event.metadata toDictionary] count], 1);
        XCTAssertNil([event.metadata getMetadataFromSection:@"mySection" withKey:@"myNewKey"]);

        [event addMetadata:@"realValue" withKey:@"myNewKey" toSection:@"mySection"];
        XCTAssertEqual([[event.metadata toDictionary] count], 1);
        XCTAssertNotNil([event.metadata getMetadataFromSection:@"mySection" withKey:@"myNewKey"]);
        return true;
    }];
}

- (void)testClearMetadataSection {
    // Setup
    BugsnagEvent *event = [[BugsnagEvent alloc] initWithKSReport:@{
        @"user.metaData": @{
                @"user": @{@"id": @"user id"}
        }}];
    [event clearMetadataFromSection:@"device"];
    [event addMetadata:@{@"foo": @"bar"} toSection:@"section1"];
    [event addMetadata:@{@"baz": @"bill"} toSection:@"section1"];
    [event addMetadata:@{@"alice": @"bob"} toSection:@"section2"];
    XCTAssertEqual([[event.metadata toDictionary] count], 3);

    // Known
    [event clearMetadataFromSection:@"section1"];
    XCTAssertEqual([[event.metadata toDictionary] count], 2);

    // Unknown
    [event addMetadata:@{@"foo": @"bar"} toSection:@"section1"];
    [event addMetadata:@{@"baz": @"bill"} toSection:@"section1"];
    [event clearMetadataFromSection:@"section3"];
    XCTAssertEqual([[event.metadata toDictionary] count], 3);

    // Empty
    [event addMetadata:@{@"foo": @"bar"} toSection:@"section1"];
    [event addMetadata:@{@"baz": @"bill"} toSection:@"section1"];
    [event clearMetadataFromSection:@"section1"];
    [event clearMetadataFromSection:@"section2"];
    [event clearMetadataFromSection:@"section3"];
    XCTAssertEqual([[event.metadata toDictionary] count], 1);

    [event clearMetadataFromSection:@"user"];
    XCTAssertEqual([[event.metadata toDictionary] count], 0);

    [event clearMetadataFromSection:@"section1"];
    [event clearMetadataFromSection:@"section2"];
    [event clearMetadataFromSection:@"section3"];
    [event clearMetadataFromSection:@"user"];
    XCTAssertEqual([[event.metadata toDictionary] count], 0);
}

- (void)testClearMetadataSectionWithKey {
    // Setup
    BugsnagEvent *event = [[BugsnagEvent alloc] initWithKSReport:@{
        @"user.metaData": @{
                @"user": @{@"id": @"user id"}
        }}];
    [event clearMetadataFromSection:@"device"];
    [event addMetadata:@{@"foo": @"bar"} toSection:@"section1"];
    [event addMetadata:@{@"baz": @"bill"} toSection:@"section1"];
    [event addMetadata:@{@"alice": @"bob"} toSection:@"section2"];
    XCTAssertEqual([[event.metadata toDictionary] count], 3);

    // Remove a key
    XCTAssertEqual([[event getMetadataFromSection:@"section1"] count], 2);
    [event clearMetadataFromSection:@"section1" withKey:@"foo"];
    XCTAssertEqual([[event getMetadataFromSection:@"section1"] count], 1);

    // Remove all keys, check section exists
    [event clearMetadataFromSection:@"section1" withKey:@"baz"];
    XCTAssertNotNil([event getMetadataFromSection:@"section1"]);
    XCTAssertEqual([[event getMetadataFromSection:@"section1"] count], 0);
}

- (void)testClearMetadataSectionWithKeyNonExistentKeys {
    // Setup
    BugsnagEvent *event = [[BugsnagEvent alloc] initWithKSReport:@{
        @"user.metaData": @{
                @"user": @{@"id": @"user id"}
        }}];
    [event clearMetadataFromSection:@"device"];
    [event addMetadata:@{@"foo": @"bar"} toSection:@"section1"];
    [event addMetadata:@{@"baz": @"bill"} toSection:@"section1"];
    [event addMetadata:@{@"alice": @"bob"} toSection:@"section2"];
    XCTAssertEqual([[event.metadata toDictionary] count], 3);

    // Nonexistent key
    [event clearMetadataFromSection:@"section1" withKey:@"flump"];
    XCTAssertEqual([[event getMetadataFromSection:@"section1"] count], 2);
    [event clearMetadataFromSection:@"section1" withKey:@"foo"];
    XCTAssertEqual([[event getMetadataFromSection:@"section1"] count], 1);
    XCTAssertEqual([[event.metadata toDictionary] count], 3);

    // Nonexistent section
    [event clearMetadataFromSection:@"section52" withKey:@"baz"];
    XCTAssertEqual([[event.metadata toDictionary] count], 3);
    XCTAssertEqual([[event getMetadataFromSection:@"section1"] count], 1);
    XCTAssertEqual([[event getMetadataFromSection:@"section2"] count], 1);
}

- (void)testUnhandled {
    BugsnagHandledState *state = [BugsnagHandledState handledStateWithSeverityReason:HandledException];
    BugsnagEvent *event = [self generateEvent:state];
    XCTAssertFalse(event.unhandled);

    state = [BugsnagHandledState handledStateWithSeverityReason:UnhandledException];
    event = [self generateEvent:state];
    XCTAssertTrue(event.unhandled);
}

- (void)testUnhandledOverride {
    BugsnagConfiguration *config = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    BugsnagClient *client = [[BugsnagClient alloc] initWithConfiguration:config];
    [client start];

    NSException *ex = [[NSException alloc] initWithName:@"myName" reason:@"myReason1" userInfo:nil];
    __block BugsnagEvent *eventRef = nil;

    // No change to unhandled.
    [client notify:ex block:^BOOL(BugsnagEvent * _Nonnull event) {
        eventRef = event;
        return true;
    }];
    XCTAssertEqual(eventRef.unhandled, NO);
    XCTAssertEqual(eventRef.handledState.unhandledOverridden, NO);

    // Change unhandled from NO to YES.
    [client notify:ex block:^BOOL(BugsnagEvent * _Nonnull event) {
        eventRef = event;
        event.unhandled = YES;
        return true;
    }];
    XCTAssertEqual(eventRef.unhandled, YES);
    XCTAssertEqual(eventRef.handledState.unhandledOverridden, YES);

    // Set unhandled to NO, but was already NO.
    [client notify:ex block:^BOOL(BugsnagEvent * _Nonnull event) {
        eventRef = event;
        event.unhandled = NO;
        return true;
    }];
    XCTAssertEqual(eventRef.unhandled, NO);
    XCTAssertEqual(eventRef.handledState.unhandledOverridden, NO);
}

- (void)testMetadataMutability {
    BugsnagEvent *event = [[BugsnagEvent alloc] initWithKSReport:@{@"dummy" : @"value"}];

    // Immutable in, mutable out
    [event addMetadata:@{@"foo" : @"bar"} toSection:@"section1"];
    NSObject *metadata1 = [event getMetadataFromSection:@"section1"];
    XCTAssertTrue([metadata1 isKindOfClass:[NSMutableDictionary class]]);

    // Mutable in, mutable out
    [event addMetadata:[@{@"foo" : @"bar"} mutableCopy] toSection:@"section2"];
    NSObject *metadata2 = [event getMetadataFromSection:@"section2"];
    XCTAssertTrue([metadata2 isKindOfClass:[NSMutableDictionary class]]);
}

/**
 * Legacy unhandled reports stored user in metadata - this should be loaded if present
 */
- (void)testLoadUserFromMetadata {
    BugsnagEvent *event = [[BugsnagEvent alloc] initWithKSReport:@{
            @"user": @{
                    @"metaData": @{
                            @"user": @{
                                    @"id": @"someId",
                                    @"name": @"someName",
                                    @"email": @"someEmail"
                            }
                    }
            }
    }];
    XCTAssertEqualObjects(@"someId", event.user.id);
    XCTAssertEqualObjects(@"someName", event.user.name);
    XCTAssertEqualObjects(@"someEmail", event.user.email);
}

/**
 * Current unhandled reports store user in state - this should be loaded if present
 */
- (void)testLoadUserFromState {
    BugsnagEvent *event = [[BugsnagEvent alloc] initWithKSReport:@{
            @"user": @{
                    @"state": @{
                            @"user": @{
                                    @"id": @"someId",
                                    @"name": @"someName",
                                    @"email": @"someEmail"
                            }
                    }
            }
    }];
    XCTAssertEqualObjects(@"someId", event.user.id);
    XCTAssertEqualObjects(@"someName", event.user.name);
    XCTAssertEqualObjects(@"someEmail", event.user.email);
}

- (void)testLoadNoUser {
    BugsnagEvent *event = [[BugsnagEvent alloc] initWithKSReport:@{@"user": @{}}];
    XCTAssertNil(event.user.id);
    XCTAssertNil(event.user.name);
    XCTAssertNil(event.user.email);
}

- (void)testCodeBundleIdHandled {
    BugsnagEvent *event = [[BugsnagEvent alloc] initWithUserData:@{
            @"user": @{
                    @"event": @{
                            @"app": @{
                                    @"codeBundleId": @"cb-123"
                            }
                    }
            }
    }];
    XCTAssertEqualObjects(@"cb-123", event.app.codeBundleId);
}

- (void)testCodeBundleIdUnhandled {
    BugsnagEvent *event = [[BugsnagEvent alloc] initWithKSReport:@{
            @"user": @{
                    @"state": @{
                            @"app": @{
                                    @"codeBundleId": @"cb-123"
                            }
                    }
            }
    }];
    XCTAssertEqualObjects(@"cb-123", event.app.codeBundleId);
}

- (void)testRuntimeVersionsUnhandled {
    NSDictionary *runtimeVersions = @{
            @"fooVersion": @"5.23",
            @"barVersion": @"7.902.40fc"
    };
    BugsnagEvent *event = [[BugsnagEvent alloc] initWithKSReport:@{
            @"system": @{
                    @"os_version": @"13.2"
            },
            @"user": @{
                    @"state": @{
                            @"device": @{
                                    @"extraRuntimeInfo": runtimeVersions
                            }
                    }
            }
    }];
    NSDictionary *expected = @{
            @"fooVersion": @"5.23",
            @"barVersion": @"7.902.40fc",
            @"osBuild": @"13.2"
    };
    XCTAssertEqualObjects(expected, event.device.runtimeVersions);
}

@end
