// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import SWCompression
import XCTest

class LzmaTests: XCTestCase {
    private static let testType: String = "lzma"

    func perform(test testName: String) throws {
        let testData = try Constants.data(forTest: testName, withType: LzmaTests.testType)
        let decompressedData = try LZMA.decompress(data: testData)

        let answerData = try Constants.data(forAnswer: "test8")
        XCTAssertEqual(decompressedData, answerData)
    }

    func testLzma8() throws {
        try perform(test: "test8")
    }

    func testLzma9() throws {
        try perform(test: "test9")
    }

    func testLzma10() throws {
        try perform(test: "test10")
    }

    func testLzma11() throws {
        try perform(test: "test11")
    }

    func testLzmaEmpty() throws {
        let testData = try Constants.data(forTest: "test_empty", withType: LzmaTests.testType)
        XCTAssertEqual(try LZMA.decompress(data: testData), Data())
    }

    func testBadFile_short() {
        // Not enough data for LZMA properties.
        XCTAssertThrowsError(try LZMA.decompress(data: Data([0, 1, 2, 3])))
        // Not enough data to initialize range decoder.
        XCTAssertThrowsError(try LZMA.decompress(data: Data([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14])))
    }

    func testBadFile_invalid() throws {
        let testData = try Constants.data(forAnswer: "test7")
        XCTAssertThrowsError(try LZMA.decompress(data: testData))
    }

    func testEmptyData() throws {
        XCTAssertThrowsError(try LZMA.decompress(data: Data()))
        XCTAssertThrowsError(try LZMA2.decompress(data: Data()))
    }
}
