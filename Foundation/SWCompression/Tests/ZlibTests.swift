// Copyright (c) 2021 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import SWCompression
import XCTest

class ZlibTests: XCTestCase {
    private static let testType: String = "zlib"

    func testZlib() throws {
        let testName = "test"

        let testData = try Constants.data(forTest: testName, withType: ZlibTests.testType)
        let testZlibHeader = try ZlibHeader(archive: testData)

        XCTAssertEqual(testZlibHeader.compressionMethod, .deflate)
        XCTAssertEqual(testZlibHeader.compressionLevel, .defaultAlgorithm)
        XCTAssertEqual(testZlibHeader.windowSize, 32768)
    }

    func testZlibFull() throws {
        let testData = try Constants.data(forTest: "random_file", withType: ZlibTests.testType)
        let decompressedData = try ZlibArchive.unarchive(archive: testData)

        let answerData = try Constants.data(forAnswer: "test9")
        XCTAssertEqual(decompressedData, answerData)
    }

    func testCreateZlib() throws {
        let testData = try Constants.data(forAnswer: "test9")
        let archiveData = ZlibArchive.archive(data: testData)
        let reextractedData = try ZlibArchive.unarchive(archive: archiveData)

        XCTAssertEqual(testData, reextractedData)
    }

    func testZlibEmpty() throws {
        let testData = try Constants.data(forTest: "test_empty", withType: ZlibTests.testType)
        XCTAssertEqual(try ZlibArchive.unarchive(archive: testData), Data())
    }

    func testBadFile_short() {
        XCTAssertThrowsError(try ZlibArchive.unarchive(archive: Data([0x78])))
        XCTAssertThrowsError(try ZlibHeader(archive: Data([0x78])))
    }

    func testBadFile_invalid() throws {
        let testData = try Constants.data(forAnswer: "test6")
        XCTAssertThrowsError(try ZlibArchive.unarchive(archive: testData))
    }
}
