// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import SWCompression
import XCTest

class BZip2Tests: XCTestCase {
    private static let testType: String = "bz2"

    func perform(test testName: String) throws {
        let testData = try Constants.data(forTest: testName, withType: BZip2Tests.testType)
        let decompressedData = try BZip2.decompress(data: testData)

        let answerData = try Constants.data(forAnswer: testName)
        XCTAssertEqual(decompressedData, answerData)
    }

    func test1BZip2() throws {
        try perform(test: "test1")
    }

    func test2BZip2() throws {
        try perform(test: "test2")
    }

    func test3BZip2() throws {
        try perform(test: "test3")
    }

    func test4BZip2() throws {
        try perform(test: "test4")
    }

    func test5BZip2() throws {
        try perform(test: "test5")
    }

    func test6BZip2() throws {
        try perform(test: "test6")
    }

    func test7BZip2() throws {
        try perform(test: "test7")
    }

    func test8BZip2() throws {
        try perform(test: "test8")
    }

    func test9BZip2() throws {
        try perform(test: "test9")
    }

    func testNonStandardRunLength() throws {
        try perform(test: "test_nonstandard_runlength")
    }

    func testBadFile_short() {
        XCTAssertThrowsError(try BZip2.decompress(data: Data([0])))
    }

    func testBadFile_invalid() throws {
        let testData = try Constants.data(forAnswer: "test6")
        XCTAssertThrowsError(try BZip2.decompress(data: testData))
    }

    func testBadFile_truncated() throws {
        // This tests that encountering data truncated in the middle of a Huffman symbol correctly throws an error
        // (and doesn't crash).
        let testData = try Constants.data(forTest: "test1", withType: BZip2Tests.testType)[0 ... 40]
        XCTAssertThrowsError(try BZip2.decompress(data: testData))
    }

    func testEmptyData() throws {
        XCTAssertThrowsError(try BZip2.decompress(data: Data()))
    }

    func testChecksumMismatch() throws {
        // Here we test that an error for checksum mismatch is thrown correctly and its associated value contains
        // expected data. We do this by programmatically adjusting the input: we change one of the bytes for the checkum,
        // which makes it incorrect.
        var testData = try Constants.data(forTest: "test1", withType: BZip2Tests.testType)
        // The checksum is the last 4 bytes.
        testData[testData.endIndex - 2] &+= 1
        var thrownError: Error?
        XCTAssertThrowsError(try BZip2.decompress(data: testData)) { thrownError = $0 }
        XCTAssertTrue(thrownError is BZip2Error, "Unexpected error type: \(type(of: thrownError))")
        if case let .some(.wrongCRC(decompressedData)) = thrownError as? BZip2Error {
            let answerData = try Constants.data(forAnswer: "test1")
            XCTAssertEqual(decompressedData, answerData)
        } else {
            XCTFail("Unexpected error: \(String(describing: thrownError))")
        }
    }
}
