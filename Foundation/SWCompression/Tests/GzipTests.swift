// Copyright (c) 2021 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import SWCompression
import XCTest

class GzipTests: XCTestCase {
    private static let testType: String = "gz"

    func header(test testName: String, mtime: Int) throws {
        let testData = try Constants.data(forTest: testName, withType: GzipTests.testType)
        let testGzipHeader = try GzipHeader(archive: testData)

        XCTAssertEqual(testGzipHeader.compressionMethod, .deflate)
        XCTAssertEqual(testGzipHeader.modificationTime, Date(timeIntervalSince1970: TimeInterval(mtime)))
        XCTAssertEqual(testGzipHeader.osType, .unix)
        XCTAssertEqual(testGzipHeader.fileName, "\(testName).answer")
        XCTAssertEqual(testGzipHeader.comment, nil)
    }

    func unarchive(test testName: String) throws {
        let testData = try Constants.data(forTest: testName, withType: GzipTests.testType)
        let decompressedData = try GzipArchive.unarchive(archive: testData)

        let answerData = try Constants.data(forAnswer: testName)
        XCTAssertEqual(decompressedData, answerData)
    }

    func archive(test testName: String) throws {
        let answerData = try Constants.data(forAnswer: testName)

        // Options for archiving.
        let mtimeDate = Date(timeIntervalSinceNow: 0.0)
        let mtime = mtimeDate.timeIntervalSince1970.rounded(.towardZero)

        // Test GZip archiving.
        let archiveData = try GzipArchive.archive(data: answerData, comment: "some file comment",
                                                  fileName: testName + ".answer",
                                                  writeHeaderCRC: true,
                                                  isTextFile: true,
                                                  osType: .macintosh,
                                                  modificationTime: mtimeDate)

        // Test output GZip header.
        let testGzipHeader = try GzipHeader(archive: archiveData)

        XCTAssertEqual(testGzipHeader.compressionMethod, .deflate)
        XCTAssertEqual(testGzipHeader.modificationTime?.timeIntervalSince1970, mtime)
        XCTAssertEqual(testGzipHeader.osType, .macintosh)
        XCTAssertEqual(testGzipHeader.fileName, "\(testName).answer")
        XCTAssertEqual(testGzipHeader.comment, "some file comment")
        XCTAssertTrue(testGzipHeader.isTextFile)

        // Test output GZip archive content.
        let decompressedData = try GzipArchive.unarchive(archive: archiveData)

        XCTAssertEqual(decompressedData, answerData)
    }

    func testGzip1() throws {
        try header(test: "test1", mtime: 1_482_698_300)
        try unarchive(test: "test1")
    }

    func testGzip2() throws {
        try header(test: "test2", mtime: 1_482_698_300)
        try unarchive(test: "test2")
    }

    func testGzip3() throws {
        try header(test: "test3", mtime: 1_482_698_301)
        try unarchive(test: "test3")
    }

    func testGzip4() throws {
        try header(test: "test4", mtime: 1_482_698_301)
        try unarchive(test: "test4")
    }

    func testGzip5() throws {
        try header(test: "test5", mtime: 1_482_698_242)
        try unarchive(test: "test5")
    }

    func testGzip6() throws {
        try header(test: "test6", mtime: 1_511_554_495)
        try unarchive(test: "test6")
    }

    func testGzip7() throws {
        try header(test: "test7", mtime: 1_511_554_611)
        try unarchive(test: "test7")
    }

    func testGzip8() throws {
        try header(test: "test8", mtime: 1_483_040_005)
        try unarchive(test: "test8")
    }

    func testGzip9() throws {
        try header(test: "test9", mtime: 1_483_040_005)
        try unarchive(test: "test9")
    }

    func testGzipArchive4() throws {
        try archive(test: "test4")
    }

    func testMultiUnarchive() throws {
        let testData = try Constants.data(forTest: "test_multi", withType: GzipTests.testType)
        let members = try GzipArchive.multiUnarchive(archive: testData)

        XCTAssertEqual(members.count, 4)

        for i in 1 ... 4 {
            let header = members[i - 1].header
            XCTAssertEqual(header.fileName, "test\(i).answer")
            let data = members[i - 1].data

            let answerData = try Constants.data(forAnswer: "test\(i)")
            XCTAssertEqual(data, answerData)
        }
    }

    func testMultiUnarchiveRedundant() throws {
        let testData = try Constants.data(forTest: "test1", withType: GzipTests.testType)
        let members = try GzipArchive.multiUnarchive(archive: testData)

        XCTAssertEqual(members.count, 1)

        let header = members[0].header
        XCTAssertEqual(header.fileName, "test1.answer")
        let data = members[0].data

        let answerData = try Constants.data(forAnswer: "test1")
        XCTAssertEqual(data, answerData)
    }

    func testBadFile_short() {
        XCTAssertThrowsError(try GzipArchive.unarchive(archive: Data([0])))
        XCTAssertThrowsError(try GzipArchive.multiUnarchive(archive: Data([0])))
        XCTAssertThrowsError(try GzipHeader(archive: Data([0])))
    }

    func testBadFile_invalid() throws {
        let testData = try Constants.data(forAnswer: "test6")
        XCTAssertThrowsError(try GzipArchive.unarchive(archive: testData))
        XCTAssertThrowsError(try GzipArchive.multiUnarchive(archive: testData))
    }
}
