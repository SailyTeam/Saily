// Copyright (c) 2022 Timofey Solomko
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
        XCTAssertTrue(testGzipHeader.extraFields.isEmpty)
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

        // Random extra field.
        let si1 = UInt8.random(in: 0 ... 255)
        let si2 = UInt8.random(in: 1 ... 255) // 0 is a reserved value here.
        let len = UInt16.random(in: 0 ... (UInt16.max - 4))
        var extraFieldBytes = [UInt8]()
        for _ in 0 ..< len {
            extraFieldBytes.append(UInt8.random(in: 0 ... 255))
        }
        let extraField = GzipHeader.ExtraField(si1, si2, extraFieldBytes)

        // Test GZip archiving.
        let archiveData = try GzipArchive.archive(data: answerData, comment: "some file comment",
                                                  fileName: testName + ".answer", writeHeaderCRC: true,
                                                  isTextFile: true, osType: .macintosh, modificationTime: mtimeDate,
                                                  extraFields: [extraField])

        // Test output GZip header.
        let testGzipHeader = try GzipHeader(archive: archiveData)

        XCTAssertEqual(testGzipHeader.compressionMethod, .deflate)
        XCTAssertEqual(testGzipHeader.modificationTime?.timeIntervalSince1970, mtime)
        XCTAssertEqual(testGzipHeader.osType, .macintosh)
        XCTAssertEqual(testGzipHeader.fileName, "\(testName).answer")
        XCTAssertEqual(testGzipHeader.comment, "some file comment")
        XCTAssertTrue(testGzipHeader.isTextFile)
        XCTAssertEqual(testGzipHeader.extraFields.count, 1)
        XCTAssertEqual(testGzipHeader.extraFields.first?.si1, si1)
        XCTAssertEqual(testGzipHeader.extraFields.first?.si2, si2)
        XCTAssertEqual(testGzipHeader.extraFields.first?.bytes, extraFieldBytes)

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

    func testGzip4ExtraField() throws {
        let testData = try Constants.data(forTest: "test4_extra_field", withType: GzipTests.testType)
        let testGzipHeader = try GzipHeader(archive: testData)

        XCTAssertEqual(testGzipHeader.compressionMethod, .deflate)
        XCTAssertEqual(testGzipHeader.modificationTime?.timeIntervalSince1970, 1_665_760_462)
        XCTAssertEqual(testGzipHeader.osType, .macintosh)
        XCTAssertEqual(testGzipHeader.fileName, "test4.answer")
        XCTAssertEqual(testGzipHeader.comment, "some file comment")
        XCTAssertTrue(testGzipHeader.isTextFile)
        XCTAssertEqual(testGzipHeader.extraFields.count, 1)
        XCTAssertEqual(testGzipHeader.extraFields.first?.si1, 0x54)
        XCTAssertEqual(testGzipHeader.extraFields.first?.si2, 0x53)
        XCTAssertEqual(testGzipHeader.extraFields.first?.bytes, [0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99,
                                                                 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF, 0x11, 0x22, 0x33,
                                                                 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xAA, 0xBB, 0xCC,
                                                                 0xDD, 0xEE, 0xFF])
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

    func testEmptyData() throws {
        XCTAssertThrowsError(try GzipArchive.unarchive(archive: Data()))
    }

    func testChecksumMismatch() throws {
        // Here we test that an error for checksum mismatch is thrown correctly and its associated value contains
        // expected data. We do this by programmatically adjusting the input: we change one of the bytes for the checkum,
        // which makes it incorrect.
        var testData = try Constants.data(forTest: "test1", withType: GzipTests.testType)
        // Here we modify the stored value of crc32.
        testData[41] &+= 1
        var thrownError: Error?
        XCTAssertThrowsError(try GzipArchive.unarchive(archive: testData)) { thrownError = $0 }
        XCTAssertTrue(thrownError is GzipError, "Unexpected error type: \(type(of: thrownError))")
        if case let .some(.wrongCRC(members)) = thrownError as? GzipError {
            XCTAssertEqual(members.count, 1)
            let answerData = try Constants.data(forAnswer: "test1")
            XCTAssertEqual(members.first?.data, answerData)
        } else {
            XCTFail("Unexpected error: \(String(describing: thrownError))")
        }
    }

    func testMultiUnarchiveChecksumMismatch() throws {
        // Here we test that an error for checksum mismatch is thrown correctly and its associated value contains
        // expected data. We do this by programmatically adjusting the input: we change one of the bytes for the checkum,
        // which makes it incorrect.
        var testData = try Constants.data(forTest: "test_multi", withType: GzipTests.testType)
        // Here we modify the stored value of crc32.
        testData[2289] &+= 1
        var thrownError: Error?
        XCTAssertThrowsError(try GzipArchive.multiUnarchive(archive: testData)) { thrownError = $0 }
        XCTAssertTrue(thrownError is GzipError, "Unexpected error type: \(type(of: thrownError))")
        if case let .some(.wrongCRC(members)) = thrownError as? GzipError {
            XCTAssertEqual(members.count, 2)
            var answerData = try Constants.data(forAnswer: "test1")
            XCTAssertEqual(members[0].data, answerData)
            answerData = try Constants.data(forAnswer: "test2")
            XCTAssertEqual(members[1].data, answerData)
        } else {
            XCTFail("Unexpected error: \(String(describing: thrownError))")
        }
    }

    func testMinimal() throws {
        // In this test we test several things:
        // - that the archive consisting only of the minimal header is successfully processed,
        // - that the mtime field with the value 0 correctly results in a `GzipHeader.modificationTime == nil`,
        // - that the `GzipArchive.multiUnarchive(archive:)` works on a single member archive.
        let testData = try Constants.data(forTest: "minimal", withType: GzipTests.testType)
        let members = try GzipArchive.multiUnarchive(archive: testData)
        XCTAssertEqual(members.count, 1)
        if let member = members.first {
            XCTAssertEqual(member.header.compressionMethod, .deflate)
            XCTAssertNil(member.header.modificationTime)
            XCTAssertEqual(member.header.osType, .unix)
            XCTAssertNil(member.header.fileName)
            XCTAssertNil(member.header.comment)
            XCTAssertFalse(member.header.isTextFile)
            XCTAssertEqual(member.data, Data())
        }
    }

    func testGzipTruncation() throws {
        // In this test we check the handling of truncation inside the optional elements (name, comment, "extra field",
        // crc) of a GZip header, as well as in the "checksum" information of the archive (last 8 bytes). The sample
        // file used is "test4_extra_field" since it contains a header which utilizes all format features.
        let testData = try Constants.data(forTest: "test4_extra_field", withType: GzipTests.testType)

        // We test all possible truncation points since there are very few of them.
        // The header takes first 79 bytes.
        for truncationIndex in 1 ..< 79 {
            var thrownError: Error?
            XCTAssertThrowsError(try GzipArchive.unarchive(archive: testData[..<truncationIndex]),
                                 "testGzipTruncation.header: no error thrown, truncationIndex=\(truncationIndex)") { thrownError = $0 }
            if let error = thrownError {
                XCTAssertTrue(error is GzipError, "testGzipTruncation.header: unexpected error type: \(type(of: thrownError)), " +
                    "truncationIndex=\(truncationIndex)")
            }
        }

        // The checksum information takes the last 8 bytes of the archive. Again, we test truncations in all of them.
        for truncationIndex in 2 ..< 9 {
            var thrownError: Error?
            XCTAssertThrowsError(try GzipArchive.unarchive(archive: testData[...(testData.count - truncationIndex)]),
                                 "testGzipTruncation.footer: no error thrown, truncationIndex=\(truncationIndex)") { thrownError = $0 }
            if let error = thrownError {
                XCTAssertTrue(error is GzipError, "testGzipTruncation.footer: unexpected error type: \(type(of: thrownError)), " +
                    "truncationIndex=\(truncationIndex)")
            }
        }
    }

    func testDeflateTruncation() throws {
        // In this test we check that there is no crash when dealing with the truncation in the middle of the Deflate
        // compressed data. The idea is to take three different types of Deflate blocks (uncompressed, static Huffman,
        // and dynamic Huffman), truncate the input data manually at a random point inside it, and then test if an
        // appropriate error is thrown. To make test a bit more sophisticated we generate a number of random truncations
        // for each tested file.

        // This test file contains uncompressed Deflate block.
        var testData = try Constants.data(forTest: "test9", withType: GzipTests.testType)
        for _ in 0 ..< 100 {
            let truncationIndex = Int.random(in: 23 ..< testData.count - 8)
            var thrownError: Error?
            XCTAssertThrowsError(try GzipArchive.unarchive(archive: testData[..<truncationIndex]),
                                 "No error thrown, test9, truncationIndex=\(truncationIndex)") { thrownError = $0 }
            if let error = thrownError {
                XCTAssertTrue(error is DeflateError, "Unexpected error type: \(type(of: thrownError)), " +
                    "test9, truncationIndex=\(truncationIndex)")
            }
        }

        // This test file contains static Huffman Deflate block.
        testData = try Constants.data(forTest: "test8", withType: GzipTests.testType)
        for _ in 0 ..< 10 {
            let truncationIndex = Int.random(in: 23 ..< testData.count - 8)
            var thrownError: Error?
            XCTAssertThrowsError(try GzipArchive.unarchive(archive: testData[..<truncationIndex]),
                                 "No error thrown, test8, truncationIndex=\(truncationIndex)") { thrownError = $0 }
            if let error = thrownError {
                XCTAssertTrue(error is DeflateError, "Unexpected error type: \(type(of: thrownError)), " +
                    "test8, truncationIndex=\(truncationIndex)")
            }
        }

        // This test file contains dynamic Huffman Deflate block.
        testData = try Constants.data(forTest: "test6", withType: GzipTests.testType)
        for _ in 0 ..< 10 {
            let truncationIndex = Int.random(in: 23 ..< testData.count - 8)
            var thrownError: Error?
            XCTAssertThrowsError(try GzipArchive.unarchive(archive: testData[..<truncationIndex]),
                                 "No error thrown, test6, truncationIndex=\(truncationIndex)") { thrownError = $0 }
            if let error = thrownError {
                XCTAssertTrue(error is DeflateError, "Unexpected error type: \(type(of: thrownError)), " +
                    "test6, truncationIndex=\(truncationIndex)")
            }
        }
    }
}
