// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import SWCompression
import XCTest

class LZ4Tests: XCTestCase {
    private static let testType: String = "lz4"

    // These tests test frames with independent blocks (since they all have only one block). The frames also have
    // additional features enabled, such as content size and block checksums. They also test legacy frame format.

    func perform(test testName: String) throws {
        let testData = try Constants.data(forTest: testName, withType: LZ4Tests.testType)
        let decompressedData = try LZ4.decompress(data: testData)

        let answerData = try Constants.data(forAnswer: testName)
        XCTAssertEqual(decompressedData, answerData)
    }

    private static func perform(legacyTest testName: String) throws {
        let testData = try Constants.data(forTest: testName + "_legacy", withType: LZ4Tests.testType)
        let decompressedData = try LZ4.decompress(data: testData)

        let answerData = try Constants.data(forAnswer: testName)
        XCTAssertEqual(decompressedData, answerData)
    }

    func test1LZ4() throws {
        try perform(test: "test1")
        try LZ4Tests.perform(legacyTest: "test1")
    }

    func test2LZ4() throws {
        try perform(test: "test2")
        try LZ4Tests.perform(legacyTest: "test2")
    }

    func test3LZ4() throws {
        try perform(test: "test3")
        try LZ4Tests.perform(legacyTest: "test3")
    }

    func test4LZ4() throws {
        try perform(test: "test4")
        try LZ4Tests.perform(legacyTest: "test4")
    }

    func test5LZ4() throws {
        try perform(test: "test5")
        try LZ4Tests.perform(legacyTest: "test5")
    }

    func test6LZ4() throws {
        try perform(test: "test6")
        try LZ4Tests.perform(legacyTest: "test6")
    }

    func test7LZ4() throws {
        try perform(test: "test7")
        try LZ4Tests.perform(legacyTest: "test7")
    }

    func test8LZ4() throws {
        try perform(test: "test8")
        try LZ4Tests.perform(legacyTest: "test8")
    }

    func test9LZ4() throws {
        try perform(test: "test9")
        try LZ4Tests.perform(legacyTest: "test9")
    }

    func testDependentBlocks() throws {
        // This test contains dependent blocks (with the size of 64 kB), as well as has additional features enabled,
        // such as content size and block checksums.
        let testData = try Constants.data(forTest: "SWCompressionSourceCode.tar", withType: LZ4Tests.testType)
        let decompressedData = try LZ4.decompress(data: testData)

        let answerData = try Constants.data(forTest: "SWCompressionSourceCode", withType: "tar")
        XCTAssertEqual(decompressedData, answerData)
    }

    func testBadFile_short() {
        LZ4Tests.checkTruncationError(Data([0]))
    }

    func testBadFile_invalid() throws {
        let testData = try Constants.data(forAnswer: "test6")
        var thrownError: Error?
        XCTAssertThrowsError(try LZ4.decompress(data: testData)) { thrownError = $0 }
        XCTAssertTrue(thrownError is DataError, "Unexpected error type: \(type(of: thrownError))")
        XCTAssertEqual(thrownError as? DataError, .corrupted)
    }

    func testEmptyData() {
        LZ4Tests.checkTruncationError(Data())
    }

    private static func checkTruncationError(_ data: Data) {
        var thrownError: Error?
        XCTAssertThrowsError(try LZ4.decompress(data: data)) { thrownError = $0 }
        XCTAssertTrue(thrownError is DataError, "Unexpected error type: \(type(of: thrownError))")
        XCTAssertEqual(thrownError as? DataError, .truncated)
    }

    func testSkippableFrame() throws {
        let testData = try Constants.data(forTest: "test_skippable_frame", withType: LZ4Tests.testType)
        let decompressedData = try LZ4.decompress(data: testData)

        let answerData = try Constants.data(forAnswer: "test4")
        XCTAssertEqual(decompressedData, answerData)
    }

    func testLegacyFrameMultipleBlocks() throws {
        let testData = try Constants.data(forTest: "zeros", withType: LZ4Tests.testType)
        let decompressedData = try LZ4.decompress(data: testData)

        let answerData = Data(count: 18_874_368)
        XCTAssertEqual(decompressedData, answerData)
    }

    func testBlockSizes() throws {
        // These tests don't include any checksums (becaused they are too time consuming). Only content sizes are used
        // for verification. We still test both dependent and independent blocks.
        let answerData = Data(count: 5_242_880)

        for blockSize in ["4", "5", "6", "7", "1234"] {
            for dep in ["", "_BD"] {
                let testData = try Constants.data(forTest: "test_B" + blockSize + dep, withType: LZ4Tests.testType)
                let decompressedData = try LZ4.decompress(data: testData)
                XCTAssertEqual(decompressedData, answerData)
            }
        }
    }

    func testDictionary() throws {
        // Unfortunately, LZ4 reference implementation doesn't save dictID inside a frame, even though it is present
        // in the dictionary file. So we test dictID comparison by using the manually constructed file (the last test).
        let answerData = try Constants.data(forTest: "SWCompressionSourceCode", withType: "tar")
        let dictData = try Constants.data(forTest: "lz4_dict", withType: "")

        var testData = try Constants.data(forTest: "test_dict_B5", withType: LZ4Tests.testType)
        var decompressedData = try LZ4.decompress(data: testData, dictionary: dictData)
        XCTAssertEqual(decompressedData, answerData)

        testData = try Constants.data(forTest: "test_dict_B5_BD", withType: LZ4Tests.testType)
        decompressedData = try LZ4.decompress(data: testData, dictionary: dictData)
        XCTAssertEqual(decompressedData, answerData)

        testData = try Constants.data(forTest: "test_dict_B5_dictID", withType: LZ4Tests.testType)
        decompressedData = try LZ4.decompress(data: testData, dictionary: dictData, dictionaryID: 20000)
        XCTAssertEqual(decompressedData, answerData)
    }

    func testSmallDictionary() throws {
        // Here we test decompression with a small dictionary, i.e. smaller than standard "lookback window" of 64 KB.
        let answerData = try Constants.data(forTest: "SWCompressionSourceCode", withType: "tar")
        let dictData = try Constants.data(forTest: "lz4_small_dict", withType: "")

        var testData = try Constants.data(forTest: "test_small_dict_B5", withType: LZ4Tests.testType)
        var decompressedData = try LZ4.decompress(data: testData, dictionary: dictData)
        XCTAssertEqual(decompressedData, answerData)

        testData = try Constants.data(forTest: "test_small_dict_B5_BD", withType: LZ4Tests.testType)
        decompressedData = try LZ4.decompress(data: testData, dictionary: dictData)
        XCTAssertEqual(decompressedData, answerData)
    }

    func testMultiFrameDecompress() throws {
        // The test file contains three frames:
        // - Legacy frame format, compressed test1.answer,
        // - Skippable frame with 1233 bytes of random data,
        // - Normal frame with compressed test4.answer.
        let testData = try Constants.data(forTest: "test_multi_frame", withType: LZ4Tests.testType)
        let result = try LZ4.multiDecompress(data: testData)

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0], try Constants.data(forAnswer: "test1"))
        XCTAssertEqual(result[1], try Constants.data(forAnswer: "test4"))
    }

    func testChecksumMismatch() throws {
        // Here we test that an error for checksum mismatch is thrown correctly and its associated value contains
        // expected data. We do this by programmatically adjusting the input: we change one of the bytes for the checkum,
        // which makes it incorrect.
        var testData = try Constants.data(forTest: "test1", withType: LZ4Tests.testType)
        // The content checksum is the last 4 bytes.
        testData[testData.endIndex - 2] &+= 1
        var thrownError: Error?
        XCTAssertThrowsError(try LZ4.decompress(data: testData)) { thrownError = $0 }
        XCTAssertTrue(thrownError is DataError, "Unexpected error type: \(type(of: thrownError))")
        if case let .some(.checksumMismatch(decompressedData)) = thrownError as? DataError {
            XCTAssertEqual(decompressedData.count, 1)
            let answerData = try Constants.data(forAnswer: "test1")
            XCTAssertEqual(decompressedData.first, answerData)
        } else {
            XCTFail("Unexpected error: \(String(describing: thrownError))")
        }
    }
}
