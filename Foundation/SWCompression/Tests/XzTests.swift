// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import SWCompression
import XCTest

class XZTests: XCTestCase {
    private static let testType: String = "xz"

    func perform(test testName: String) throws {
        let testData = try Constants.data(forTest: testName, withType: XZTests.testType)
        let decompressedData = try XZArchive.unarchive(archive: testData)

        let answerData = try Constants.data(forAnswer: testName)
        XCTAssertEqual(decompressedData, answerData)
    }

    func testXz1() throws {
        try perform(test: "test1")
    }

    func testXz2() throws {
        try perform(test: "test2")
    }

    func testXz3() throws {
        try perform(test: "test3")
    }

    func testXz4() throws {
        // This test contains padding!
        try perform(test: "test4")
    }

    func testXz5() throws {
        try perform(test: "test5")
    }

    func testXz6() throws {
        try perform(test: "test6")
    }

    func testXz7() throws {
        try perform(test: "test7")
    }

    func testXz8() throws {
        try perform(test: "test8")
    }

    func testXz9() throws {
        try perform(test: "test9")
    }

    func testMultiStreamNoPadding() throws {
        // Doesn't contain any padding.
        let testData = try Constants.data(forTest: "test_multi", withType: XZTests.testType)
        let splitDecompressedData = try XZArchive.splitUnarchive(archive: testData)
        XCTAssertEqual(splitDecompressedData.count, 4)

        var answerData = Data()
        for i in 1 ... 4 {
            let currentAnswerData = try Constants.data(forAnswer: "test\(i)")
            answerData.append(currentAnswerData)
            XCTAssertEqual(splitDecompressedData[i - 1], currentAnswerData)
        }

        let decompressedData = try XZArchive.unarchive(archive: testData)
        XCTAssertEqual(decompressedData, answerData)
    }

    func testMultiStreamComplexPadding() throws {
        // After first stream - no padding.
        // After second - 4 bytes of padding.
        // Third - 8 bytes.
        // At the end - 4 bytes.
        let testData = try Constants.data(forTest: "test_multi_pad", withType: XZTests.testType)
        let splitDecompressedData = try XZArchive.splitUnarchive(archive: testData)
        XCTAssertEqual(splitDecompressedData.count, 4)

        var answerData = Data()
        for i in 1 ... 4 {
            let currentAnswerData = try Constants.data(forAnswer: "test\(i)")

            answerData.append(currentAnswerData)
            XCTAssertEqual(splitDecompressedData[i - 1], currentAnswerData)
        }

        let decompressedData = try XZArchive.unarchive(archive: testData)
        XCTAssertEqual(decompressedData, answerData)
    }

    func testDeltaFilter() throws {
        let testData = try Constants.data(forTest: "test_delta_filter", withType: XZTests.testType)
        let decompressedData = try XZArchive.unarchive(archive: testData)

        let answerData = try Constants.data(forAnswer: "test4")
        XCTAssertEqual(decompressedData, answerData)
    }

    func testSha256Check() throws {
        let testData = try Constants.data(forTest: "test_sha256", withType: XZTests.testType)
        let decompressedData = try XZArchive.unarchive(archive: testData)

        let answerData = try Constants.data(forAnswer: "test4")
        XCTAssertEqual(decompressedData, answerData)
    }

    func testBadFile_short() {
        XCTAssertThrowsError(try XZArchive.unarchive(archive: Data([0, 1, 2])))
        XCTAssertThrowsError(try XZArchive.splitUnarchive(archive: Data([0, 1, 2])))
    }

    func testBadFile_invalid() throws {
        let testData = try Constants.data(forAnswer: "test6")
        XCTAssertThrowsError(try XZArchive.unarchive(archive: testData))
    }

    func testChecksumMismatch() throws {
        // Here we test that an error for checksum mismatch is thrown correctly and its associated value contains
        // expected data. We do this by programmatically adjusting the input: we change one of the bytes for the checkum,
        // which makes it incorrect.
        var testData = try Constants.data(forTest: "test1", withType: XZTests.testType)
        // Here we modify the stored value of crc64.
        testData[46] &+= 1
        var thrownError: Error?
        XCTAssertThrowsError(try XZArchive.unarchive(archive: testData)) { thrownError = $0 }
        XCTAssertTrue(thrownError is XZError, "Unexpected error type: \(type(of: thrownError))")
        if case let .some(.wrongCheck(decompressedData)) = thrownError as? XZError {
            XCTAssertEqual(decompressedData.count, 1)
            let answerData = try Constants.data(forAnswer: "test1")
            XCTAssertEqual(decompressedData.first, answerData)
        } else {
            XCTFail("Unexpected error: \(String(describing: thrownError))")
        }
    }

    func testMultiStreamChecksumMismatch() throws {
        // Here we test that an error for checksum mismatch is thrown correctly and its associated value contains
        // expected data. We do this by programmatically adjusting the input: we change one of the bytes for the checkum,
        // which makes it incorrect.
        var testData = try Constants.data(forTest: "test_multi", withType: XZTests.testType)
        // Here we modify the stored value of crc64.
        testData[2346] &+= 1
        var thrownError: Error?
        XCTAssertThrowsError(try XZArchive.splitUnarchive(archive: testData)) { thrownError = $0 }
        XCTAssertTrue(thrownError is XZError, "Unexpected error type: \(type(of: thrownError))")
        if case let .some(.wrongCheck(decompressedData)) = thrownError as? XZError {
            XCTAssertEqual(decompressedData.count, 2)
            var answerData = [try Constants.data(forAnswer: "test1")]
            answerData.append(try Constants.data(forAnswer: "test2"))
            XCTAssertEqual(decompressedData, answerData)
        } else {
            XCTFail("Unexpected error: \(String(describing: thrownError))")
        }
    }
}
