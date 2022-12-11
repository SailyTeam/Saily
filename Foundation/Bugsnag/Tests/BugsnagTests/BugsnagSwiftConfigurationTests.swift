//
//  BugsnagSwiftConfigurationTests.swift
//  Tests
//
//  Created by Robin Macharg on 22/01/2020.
//  Copyright © 2020 Bugsnag. All rights reserved.
//

import Bugsnag
import XCTest

class BugsnagSwiftConfigurationTests: XCTestCase {
    /**
     * Objective C trailing-NSError* initializers are translated into throwing
     * Swift methods, allowing us to fail gracefully (at the expense of a more-explicit
     * (read: longer) ObjC invocation).
     */
    func testDesignatedInitializerHasCorrectNS_SWIFT_NAME() {
        let config = BugsnagConfiguration(DUMMY_APIKEY_16CHAR)
        XCTAssertEqual(config.apiKey, DUMMY_APIKEY_16CHAR)
    }

    func testRemoveOnSendError() {
        let config = BugsnagConfiguration(DUMMY_APIKEY_16CHAR)
        let onSendBlocks: NSMutableArray = config.value(forKey: "onSendBlocks") as! NSMutableArray
        XCTAssertEqual(onSendBlocks.count, 0)

        let onSendError = config.addOnSendError { _ in false }
        XCTAssertEqual(onSendBlocks.count, 1)

        config.removeOnSendError(onSendError)
        XCTAssertEqual(onSendBlocks.count, 0)
    }

    func testRemoveOnSendErrorBlockDoesNotWork() {
        let config = BugsnagConfiguration(DUMMY_APIKEY_16CHAR)
        let onSendBlocks: NSMutableArray = config.value(forKey: "onSendBlocks") as! NSMutableArray
        XCTAssertEqual(onSendBlocks.count, 0)

        let onSendErrorBlock: (BugsnagEvent) -> Bool = { _ in false }
        config.addOnSendError(block: onSendErrorBlock)
        XCTAssertEqual(onSendBlocks.count, 1)

        // Intentionally using the deprecated API
        config.removeOnSendError(block: onSendErrorBlock)
        // It's not possible to remove an OnSendError Swift closure because the compiler apparently
        // creates a new NSBlock each time a closure is passed to an Objective-C method.
        XCTAssertEqual(onSendBlocks.count, 1)
    }

    func testRemoveInvalidOnSendErrorDoesNotCrash() {
        let config = BugsnagConfiguration(DUMMY_APIKEY_16CHAR)
        let onSendErrorBlock: (BugsnagEvent) -> Bool = { _ in false }
        config.addOnSendError(block: onSendErrorBlock)

        // This does not compile:
        // config.removeOnSendError(onSendErrorBlock)

        config.removeOnSendError("" as NSString)
    }
}
