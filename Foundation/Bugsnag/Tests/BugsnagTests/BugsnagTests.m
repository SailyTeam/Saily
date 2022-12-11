//
//  BugsnagTests.m
//  Tests
//
//  Created by Robin Macharg on 04/02/2020.
//  Copyright © 2020 Bugsnag. All rights reserved.
//
// Unit tests of global Bugsnag behaviour

#import <XCTest/XCTest.h>

#import "Bugsnag.h"
#import "BugsnagClient+Private.h"
#import "BugsnagConfiguration+Private.h"
#import "BugsnagEvent+Private.h"
#import "BugsnagTestConstants.h"
#import "BugsnagNotifier.h"

// MARK: - BugsnagTests

@interface BugsnagTests : XCTestCase
@end

@implementation BugsnagTests

/**
 * Test that global metadata is added correctly, applied to each event, and
 * deleted appropriately.
 */
- (void)testBugsnagMetadataAddition {

	__block XCTestExpectation *expectation = [self expectationWithDescription:@"Localized metadata changes"];

    BugsnagConfiguration *config = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    BugsnagClient *client = [[BugsnagClient alloc] initWithConfiguration:config];
    [client start];
    [client addMetadata:@"aValue1" withKey:@"aKey1" toSection:@"mySection1"];
    
    // We should see our added metadata in every request.  Let's try a couple:
    
    NSException *exception1 = [[NSException alloc] initWithName:@"exception1" reason:@"reason1" userInfo:nil];
    NSException *exception2 = [[NSException alloc] initWithName:@"exception2" reason:@"reason2" userInfo:nil];

    [client notify:exception1 block:^BOOL(BugsnagEvent * _Nonnull event) {
        XCTAssertEqualObjects([event getMetadataFromSection:@"mySection1" withKey:@"aKey1"], @"aValue1");
        XCTAssertEqual(event.errors[0].errorClass, @"exception1");
        XCTAssertEqual(event.errors[0].errorMessage, @"reason1");
        XCTAssertNil([event getMetadataFromSection:@"mySection2"]);
        
        // Add some additional metadata once we're sure it's not already there
        [client addMetadata:@"aValue2" withKey:@"aKey2" toSection:@"mySection2"];
    }];
    
    [client notify:exception2 block:^BOOL(BugsnagEvent * _Nonnull event) {
        XCTAssertEqualObjects([event getMetadataFromSection:@"mySection1" withKey:@"aKey1"], @"aValue1");
        XCTAssertEqualObjects([event getMetadataFromSection:@"mySection2" withKey:@"aKey2"], @"aValue2");
        XCTAssertEqual(event.errors[0].errorClass, @"exception2");
        XCTAssertEqual(event.errors[0].errorMessage, @"reason2");
    }];

    // Check nil value causes deletions
    
    [client addMetadata:nil withKey:@"aKey1" toSection:@"mySection1"];
    [client addMetadata:nil withKey:@"aKey2" toSection:@"mySection2"];
    
    [client notify:exception1 block:^BOOL(BugsnagEvent * _Nonnull event) {
        XCTAssertNil([event getMetadataFromSection:@"mySection1" withKey:@"aKey1"]);
        XCTAssertNil([event getMetadataFromSection:@"mySection2" withKey:@"aKey2"]);
    }];
    
    // Check that event-level metadata alteration doesn't affect configuration-level metadata
    
    // This goes to Client
    [client addMetadata:@"aValue1" withKey:@"aKey1" toSection:@"mySection1"];
    [client notify:exception1 block:^BOOL(BugsnagEvent * _Nonnull event) {
        // event should have a copy of Client metadata
        
        XCTAssertEqualObjects([client getMetadataFromSection:@"mySection1" withKey:@"aKey1"],
                              [event.metadata getMetadataFromSection:@"mySection1" withKey:@"aKey1"]);

        [event addMetadata:@{@"myNewKey" : @"myNewValue"}
                 toSection:@"myNewSection"];

        XCTAssertNil([client getMetadataFromSection:@"myNewSection" withKey:@"myNewKey"]);
        
        
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:0.1 handler:^(NSError * _Nullable error) {
        // Check old values still exist
        XCTAssertNil([[client.configuration getMetadataFromSection: @"mySection1"] valueForKey:@"aKey1"]);
        
        // Check "new" values don't exist
        XCTAssertNil([[client.configuration getMetadataFromSection:@"myNewSection"] valueForKey:@"myNewKey"]);
        XCTAssertNil([client.configuration getMetadataFromSection:@"myNewSection"]);
        expectation = nil;
    }];
}

/**
 * Test that the global Bugsnag metadata retrieval performs as expected:
 * return a section when there is one, or nil otherwise.
 */
- (void)testGetMetadata {
    BugsnagConfiguration *config = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    BugsnagClient *client = [[BugsnagClient alloc] initWithConfiguration:config];
    [client start];
    
    XCTAssertNil([client getMetadataFromSection:@"dummySection"]);
    [client addMetadata:@"aValue1" withKey:@"aKey1" toSection:@"dummySection"];
    NSMutableDictionary *section = [[client getMetadataFromSection:@"dummySection"] mutableCopy];
    XCTAssertNotNil(section);
    XCTAssertEqual(section[@"aKey1"], @"aValue1");
    XCTAssertNil([client getMetadataFromSection:@"anotherSection"]);
    
    XCTAssertTrue([[client getMetadataFromSection:@"dummySection" withKey:@"aKey1"] isEqualToString:@"aValue1"]);
    XCTAssertNil([client getMetadataFromSection:@"noSection" withKey:@"notaKey1"]);
}

/**
 * Test that pausing the session performs as expected.
 * NOTE: For now this test is inadequate.  Some form of dependency injection
 *       or mocking is required to isolate and test the session pausing semantics.
 */
-(void)testBugsnagPauseSession {
    BugsnagConfiguration *configuration = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    [configuration addOnSendErrorBlock:^BOOL(BugsnagEvent *_Nonnull event) {
        return false;
    }];

    BugsnagClient *client = [[BugsnagClient alloc] initWithConfiguration:configuration];
    [client start];

    // For now only test that the method exists
    [client pauseSession];
}

/**
 * Test that the BugsnagConfiguration-mirroring Bugsnag.context is mutable
 */
- (void)testMutableContext {
    // Allow for checks inside blocks that may (potentially) be run asynchronously
    __block XCTestExpectation *expectation1 = [self expectationWithDescription:@"Localized metadata changes"];
    
    BugsnagConfiguration *configuration = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    [configuration setContext:@"firstContext"];
    [configuration addOnSendErrorBlock:^BOOL(BugsnagEvent *_Nonnull event) {
        return false;
    }];

    BugsnagClient *client = [[BugsnagClient alloc] initWithConfiguration:configuration];
    [client start];

    NSException *exception1 = [[NSException alloc] initWithName:@"exception1" reason:@"reason1" userInfo:nil];

    // Check that the context is set going in to the test and that we can change it
    [client notify:exception1 block:^BOOL(BugsnagEvent * _Nonnull event) {
        XCTAssertEqual(client.configuration.context, @"firstContext");
        
        // Change the global context
        [client setContext:@"secondContext"];
        
        // Check that it's made it into the configuration (from the point of view of the block)
        // and that setting it here doesn't affect the event's value.
        XCTAssertEqual(client.configuration.context, @"secondContext");
        XCTAssertEqual([event context], @"firstContext");
        
        [expectation1 fulfill];
        return true;
    }];

    // Test that the context (changed inside the notify block) remains changed
    // And that the event picks up this value.
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError * _Nullable error) {
        XCTAssertEqual(client.configuration.context, @"secondContext");
        
        [client notify:exception1 block:^BOOL(BugsnagEvent * _Nonnull report) {
            XCTAssertEqual(client.configuration.context, @"secondContext");
            XCTAssertEqual([report context], @"secondContext");
            return true;
        }];
    }];
}

-(void)testClearMetadataInSectionWithKey {
    BugsnagConfiguration *config = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    BugsnagClient *client = [[BugsnagClient alloc] initWithConfiguration:config];
    [client start];

    [client addMetadata:@"myValue1" withKey:@"myKey1" toSection:@"section1"];
    [client addMetadata:@"myValue2" withKey:@"myKey2" toSection:@"section1"];
    [client addMetadata:@"myValue3" withKey:@"myKey3" toSection:@"section2"];
    
    XCTAssertEqual([[client getMetadataFromSection:@"section1"] count], 2);
    XCTAssertEqual([[client getMetadataFromSection:@"section2"] count], 1);
    
    [client clearMetadataFromSection:@"section1" withKey:@"myKey1"];
    XCTAssertEqual([[client getMetadataFromSection:@"section1"] count], 1);
    XCTAssertNil([[client getMetadataFromSection:@"section1"] valueForKey:@"myKey1"]);
    XCTAssertEqual([[client getMetadataFromSection:@"section1"] valueForKey:@"myKey2"], @"myValue2");
}

-(void)testClearMetadataInSection {
    BugsnagConfiguration *config = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    BugsnagClient *client = [[BugsnagClient alloc] initWithConfiguration:config];
    [client start];

    [client addMetadata:@"myValue1" withKey:@"myKey1" toSection:@"section1"];
    [client addMetadata:@"myValue2" withKey:@"myKey2" toSection:@"section1"];
    [client addMetadata:@"myValue3" withKey:@"myKey3" toSection:@"section2"];

    // Existing section
    [client clearMetadataFromSection:@"section2"];
    XCTAssertNil([client getMetadataFromSection:@"section2"]);
    XCTAssertEqual([[client getMetadataFromSection:@"section1"] valueForKey:@"myKey1"], @"myValue1");
    
    // nonexistent sections
    [client clearMetadataFromSection:@"section3"];
    
    // Add it back in, but different
    [client addMetadata:@"myValue4" withKey:@"myKey4" toSection:@"section2"];
    XCTAssertEqual([[client getMetadataFromSection:@"section2"] valueForKey:@"myKey4"], @"myValue4");
}

/**
 * Test that removing an onSession block via the Bugsnag object works as expected
 */
- (void)testRemoveOnSessionBlock {
    
    __block int called = 0; // A counter

    __block XCTestExpectation *expectation1 = [self expectationWithDescription:@"Remove On Session Block 1"];
    __block XCTestExpectation *expectation2 = [self expectationWithDescription:@"Remove On Session Block 2"];
    expectation2.inverted = YES;
    
    BugsnagConfiguration *configuration = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    configuration.autoTrackSessions = NO;

    // non-sending bugsnag
    [configuration addOnSendErrorBlock:^BOOL(BugsnagEvent *_Nonnull event) {
        return false;
    }];

    BugsnagOnSessionBlock sessionBlock = ^BOOL(BugsnagSession * _Nonnull sessionPayload) {
        switch (called) {
        case 0:
            [expectation1 fulfill];
            break;
        case 1:
            [expectation2 fulfill];
            break;
        }
        return true;
    };

    BugsnagOnSessionRef callback = [configuration addOnSessionBlock:sessionBlock];

    BugsnagClient *client = [[BugsnagClient alloc] initWithConfiguration:configuration];
    [client start];
    [client startSession];
    [self waitForExpectations:@[expectation1] timeout:1.0];
    
    [client pauseSession];
    called++;
    [client removeOnSession:callback];
    [client startSession];
    [self waitForExpectations:@[expectation2] timeout:1.0];
}

/**
 * Test that we can add an onSession block, and that it's called correctly when a session starts
 */
- (void)testAddOnSessionBlock {
    
    __block int called = 0; // A counter

    __block XCTestExpectation *expectation1 = [self expectationWithDescription:@"Remove On Session Block 2X"];
    __block XCTestExpectation *expectation2 = [self expectationWithDescription:@"Remove On Session Block 3X"];
    expectation2.inverted = YES;
    
    BugsnagConfiguration *configuration = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    configuration.autoTrackSessions = NO;
    
    // non-sending bugsnag
    [configuration addOnSendErrorBlock:^BOOL(BugsnagEvent *_Nonnull event) {
        return false;
    }];

    BugsnagOnSessionBlock sessionBlock = ^BOOL(BugsnagSession * _Nonnull sessionPayload) {
        switch (called) {
        case 0:
            [expectation1 fulfill];
            break;
        case 1:
            [expectation2 fulfill];
            break;
        }
        return true;
    };

    // NOTE: Due to test conditions the state of the Bugsnag/client class is indeterminate.
    //       We *should* be able to test that pre-start() calls to add/removeOnSessionBlock()
    //       do nothing, but actually we can't guarantee this.  For now we don't test this.

    BugsnagClient *client = [[BugsnagClient alloc] initWithConfiguration:configuration];
    [client start];
    [client pauseSession];

    BugsnagOnSessionRef callback = [client addOnSessionBlock:sessionBlock];
    [client startSession];
    [self waitForExpectations:@[expectation1] timeout:1.0];

    [client pauseSession];
    called++;

    [client removeOnSession:callback];
    [client startSession];
    // This expectation should also NOT be met
    [self waitForExpectations:@[expectation2] timeout:1.0];
}

- (void)testMetadataMutability {
    BugsnagConfiguration *config = [[BugsnagConfiguration alloc] initWithApiKey:DUMMY_APIKEY_32CHAR_1];
    BugsnagClient *client = [[BugsnagClient alloc] initWithConfiguration:config];
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

@end
