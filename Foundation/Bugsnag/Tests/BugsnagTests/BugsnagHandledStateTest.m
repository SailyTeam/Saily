//
//  BugsnagHandledStateTest.m
//  Bugsnag
//
//  Created by Jamie Lynch on 21/09/2017.
//  Copyright © 2017 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Bugsnag/Bugsnag.h>
#import "BugsnagHandledState.h"

@interface BugsnagHandledStateTest : XCTestCase

@end

@implementation BugsnagHandledStateTest

- (void)testUnhandledException {
    BugsnagHandledState *state =
    [BugsnagHandledState handledStateWithSeverityReason:UnhandledException];
    XCTAssertNotNil(state);
    XCTAssertTrue(state.unhandled);
    XCTAssertEqual(BSGSeverityError, state.currentSeverity);
    XCTAssertNil(state.attrValue);
    XCTAssertNil(state.attrKey);
}

- (void)testLogMessage {
    BugsnagHandledState *state =
    [BugsnagHandledState handledStateWithSeverityReason:LogMessage
                                               severity:BSGSeverityInfo
                                              attrValue:@"info"];
    XCTAssertNotNil(state);
    XCTAssertFalse(state.unhandled);
    XCTAssertEqual(BSGSeverityInfo, state.currentSeverity);
    XCTAssertEqualObjects(@"info", state.attrValue);
    XCTAssertEqualObjects(@"level", state.attrKey);
}

- (void)testHandledException {
    BugsnagHandledState *state =
    [BugsnagHandledState handledStateWithSeverityReason:HandledException];
    XCTAssertNotNil(state);
    XCTAssertFalse(state.unhandled);
    XCTAssertEqual(BSGSeverityWarning, state.currentSeverity);
    XCTAssertNil(state.attrValue);
    XCTAssertNil(state.attrKey);
}

- (void)testUserSpecified {
    BugsnagHandledState *state = [BugsnagHandledState
                                  handledStateWithSeverityReason:UserSpecifiedSeverity
                                  severity:BSGSeverityInfo
                                  attrValue:nil];
    XCTAssertNotNil(state);
    XCTAssertFalse(state.unhandled);
    XCTAssertEqual(BSGSeverityInfo, state.currentSeverity);
    XCTAssertNil(state.attrValue);
    XCTAssertNil(state.attrKey);
}

- (void)testCallbackSpecified {
    BugsnagHandledState *state =
    [BugsnagHandledState handledStateWithSeverityReason:HandledException];
    XCTAssertEqual(HandledException, state.calculateSeverityReasonType);
    
    state.currentSeverity = BSGSeverityInfo;
    XCTAssertEqual(UserCallbackSetSeverity, state.calculateSeverityReasonType);
    XCTAssertNil(state.attrValue);
    XCTAssertNil(state.attrKey);
}

- (void)testHandledError {
    BugsnagHandledState *state =
    [BugsnagHandledState handledStateWithSeverityReason:HandledError
                                               severity:BSGSeverityWarning
                                              attrValue:@"Test"];
    XCTAssertNotNil(state);
    XCTAssertFalse(state.unhandled);
    XCTAssertEqual(BSGSeverityWarning, state.currentSeverity);
    XCTAssertNil(state.attrValue);
}

- (void)testSignal {
    BugsnagHandledState *state =
    [BugsnagHandledState handledStateWithSeverityReason:Signal
                                               severity:BSGSeverityError
                                              attrValue:@"Test"];
    XCTAssertNotNil(state);
    XCTAssertTrue(state.unhandled);
    XCTAssertEqual(BSGSeverityError, state.currentSeverity);
    XCTAssertEqualObjects(@"Test", state.attrValue);
}

- (void)testPromiseRejection {
    BugsnagHandledState *state =
    [BugsnagHandledState handledStateWithSeverityReason:PromiseRejection];
    XCTAssertNotNil(state);
    XCTAssertTrue(state.unhandled);
    XCTAssertEqual(BSGSeverityError, state.currentSeverity);
    XCTAssertNil(state.attrValue);
}

@end
