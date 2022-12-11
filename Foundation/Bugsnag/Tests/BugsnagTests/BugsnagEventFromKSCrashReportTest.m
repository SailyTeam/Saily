//
//  CreateCrashReportTests.m
//  Tests
//
//  Created by Paul Zabelin on 6/6/19.
//  Copyright © 2019 Bugsnag. All rights reserved.
//

@import XCTest;

#import "Bugsnag+Private.h"
#import "BugsnagEvent+Private.h"

@interface BugsnagEventFromKSCrashReportTest : XCTestCase
@property BugsnagEvent *event;
@end

@implementation BugsnagEventFromKSCrashReportTest

- (void)setUp {
    [super setUp];
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:@"report" ofType:@"json"];
    NSString *contents = [NSString stringWithContentsOfFile:path
                                                   encoding:NSUTF8StringEncoding
                                                      error:nil];
    NSDictionary *dictionary = [NSJSONSerialization
                                JSONObjectWithData:[contents dataUsingEncoding:NSUTF8StringEncoding]
                                options:0
                                error:nil];
    // required due to BugsnagEvent using global singleton
    Bugsnag.client.configuration.bundleVersion = @"3";
    self.event = [[BugsnagEvent alloc] initWithKSReport:dictionary];
}

- (void)tearDown {
    [super tearDown];
    self.event = nil;
}

- (void)testReportDepth {
    XCTAssertEqual(7, self.event.depth);
}

- (void)testReadReleaseStage {
    XCTAssertEqualObjects(self.event.app.releaseStage, @"production");
}

- (void)testReadEnabledReleaseStages {
    XCTAssertEqualObjects(self.event.enabledReleaseStages,
                          (@[ @"production", @"development" ]));
}

- (void)testReadEnabledReleaseStagesSends {
    XCTAssertTrue([self.event shouldBeSent]);
}

- (void)testAddMetadataAddsNewTab {
    NSDictionary *metadata = @{@"color" : @"blue", @"beverage" : @"tea"};
    [self.event addMetadata:metadata toSection:@"user prefs"];
    NSDictionary *prefs = [self.event getMetadataFromSection:@"user prefs"];
    XCTAssertEqual(@"blue", prefs[@"color"]);
    XCTAssertEqual(@"tea", prefs[@"beverage"]);
    XCTAssert([prefs count] == 2);
}

- (void)testAddMetadataMergesExistingTab {
    NSDictionary *oldMetadata = @{@"color" : @"red", @"food" : @"carrots"};
    [self.event addMetadata:oldMetadata toSection:@"user prefs"];
    NSDictionary *metadata = @{@"color" : @"blue", @"beverage" : @"tea"};
    [self.event addMetadata:metadata toSection:@"user prefs"];
    NSDictionary *prefs = [self.event getMetadataFromSection:@"user prefs"];
    XCTAssertEqual(@"blue", prefs[@"color"]);
    XCTAssertEqual(@"tea", prefs[@"beverage"]);
    XCTAssertEqual(@"carrots", prefs[@"food"]);
    XCTAssert([prefs count] == 3);
}

- (void)testAddMetadataAddsNewSection {
    [self.event addMetadata:@"blue"
                    withKey:@"color"
                  toSection:@"prefs"];
    NSDictionary *prefs = [self.event getMetadataFromSection:@"prefs"];
    XCTAssertEqual(@"blue", prefs[@"color"]);
}

- (void)testAddMetadataOverridesExistingValue {
    [self.event addMetadata:@"red"
                    withKey:@"color"
                  toSection:@"prefs"];
    [self.event addMetadata:@"blue"
                    withKey:@"color"
                  toSection:@"prefs"];
    NSDictionary *prefs = [self.event getMetadataFromSection:@"prefs"];
    XCTAssertEqual(@"blue", prefs[@"color"]);
}

- (void)testAddMetadataRemovesValue {
    [self.event addMetadata:@"prefs"
                    withKey:@"color"
                  toSection:@"red"];
    [self.event addMetadata:nil
                    withKey:@"color"
                  toSection:@"prefs"];
    NSDictionary *prefs = [self.event getMetadataFromSection:@"prefs"];
    XCTAssertNil(prefs[@"color"]);
}

- (void)testAppVersion {
    NSDictionary *dictionary = [self.event toJsonWithRedactedKeys:nil];
    XCTAssertEqualObjects(dictionary[@"app"][@"version"], @"1.0");
    XCTAssertEqualObjects(dictionary[@"app"][@"bundleVersion"], @"1");
}

- (void)testThreadsPopulated {
    XCTAssertEqual(9, [self.event.threads count]);
    BugsnagThread *thread = self.event.threads[0];
    XCTAssertEqualObjects(@"0", thread.id);
}

@end
