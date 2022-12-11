// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import SWCompression
import XCTest

class LZ4CompressionTests: XCTestCase {
    func answerTest(_ testName: String) throws {
        let answerData = try Constants.data(forAnswer: testName)
        let compressedData = LZ4.compress(data: answerData)
        let redecompressedData = try LZ4.decompress(data: compressedData)
        XCTAssertEqual(redecompressedData, answerData)
        if answerData.count > 0 { // Compression ratio is always bad for empty file.
            let compressionRatio = Double(answerData.count) / Double(compressedData.count)
            print(String(format: "LZ4.\(testName).compressionRatio = %.3f", compressionRatio))
        }
    }

    func stringTest(_ string: String) throws {
        let answerData = Data(string.utf8)
        let compressedData = LZ4.compress(data: answerData)
        let redecompressedData = try LZ4.decompress(data: compressedData)
        XCTAssertEqual(redecompressedData, answerData)
    }

    func testLZ4CompressStrings() throws {
        try stringTest("ban")
        try stringTest("banana")
        try stringTest("abaaba")
        try stringTest("abracadabra")
        try stringTest("cabbage")
        try stringTest("baabaabac")
        try stringTest("AAAAAAABBBBCCCD")
        try stringTest("AAAAAAA")
        try stringTest("qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890")
    }

    func testLZ4CompressBytes() throws {
        var bytes = ""
        for i: UInt8 in 0 ... 255 {
            bytes += String(format: "%c", i)
        }
        try stringTest(bytes)
    }

    func testWithAnswer1LZ4Compress() throws {
        try answerTest("test1")
    }

    func testWithAnswer2LZ4Compress() throws {
        try answerTest("test2")
    }

    func testWithAnswer3LZ4Compress() throws {
        try answerTest("test3")
    }

    func testWithAnswer4LZ4Compress() throws {
        try answerTest("test4")
    }

    func testWithAnswer5LZ4Compress() throws {
        try answerTest("test5")
    }

    func testWithAnswer6LZ4Compress() throws {
        try answerTest("test6")
    }

    func testWithAnswer7LZ4Compress() throws {
        try answerTest("test7")
    }

    func testWithAnswer8LZ4Compress() throws {
        try answerTest("test8")
    }

    func testWithAnswer9LZ4Compress() throws {
        try answerTest("test9")
    }

    func testWithRandomOptions() throws {
        for i in 1 ... 9 {
            let independentBlocks = Bool.random()
            let blockChecksums = Bool.random()
            let contentChecksum = Bool.random()
            let contentSize = Bool.random()
            let blockSize = Int.random(in: 1024 ... 4 * 1024 * 1024)

            let answerData = try Constants.data(forAnswer: "test\(i)")
            let compressedData = LZ4.compress(data: answerData, independentBlocks: independentBlocks,
                                              blockChecksums: blockChecksums, contentChecksum: contentChecksum,
                                              contentSize: contentSize, blockSize: blockSize)
            do {
                let redecompressedData = try LZ4.decompress(data: compressedData)
                XCTAssertEqual(redecompressedData, answerData, "Test #\(i) failed (result mismatch) with the following " +
                    "options: independent blocks = \(independentBlocks), block checksums = \(blockChecksums), " +
                    "content checksum = \(contentChecksum), content size = \(contentSize), " +
                    "block size = \(blockSize) bytes")
            } catch {
                XCTFail("Test #\(i) failed (DataError.\(error) caught) with the following options: " +
                    "independent blocks = \(independentBlocks), block checksums = \(blockChecksums), " +
                    "content checksum = \(contentChecksum), content size = \(contentSize), " +
                    "block size = \(blockSize) bytes")
            }
        }
    }

    func testDictionary() throws {
        let answerData = try Constants.data(forTest: "SWCompressionSourceCode", withType: "tar")
        let dictData = try Constants.data(forTest: "lz4_dict", withType: "")

        var compressedData = LZ4.compress(data: answerData, independentBlocks: true, blockChecksums: Bool.random(),
                                          contentChecksum: Bool.random(), contentSize: Bool.random(),
                                          blockSize: 256 * 1024, dictionary: dictData, dictionaryID: nil)
        var redecompressedData = try LZ4.decompress(data: compressedData, dictionary: dictData)
        XCTAssertEqual(redecompressedData, answerData)
        var compressionRatio = Double(answerData.count) / Double(compressedData.count)
        print(String(format: "LZ4.dict.compressionRatio = %.3f", compressionRatio))

        compressedData = LZ4.compress(data: answerData, independentBlocks: false, blockChecksums: Bool.random(),
                                      contentChecksum: Bool.random(), contentSize: Bool.random(),
                                      blockSize: 256 * 1024, dictionary: dictData, dictionaryID: nil)
        redecompressedData = try LZ4.decompress(data: compressedData, dictionary: dictData)
        XCTAssertEqual(redecompressedData, answerData)
        compressionRatio = Double(answerData.count) / Double(compressedData.count)
        print(String(format: "LZ4.dict_BD.compressionRatio = %.3f", compressionRatio))

        compressedData = LZ4.compress(data: answerData, independentBlocks: true, blockChecksums: Bool.random(),
                                      contentChecksum: Bool.random(), contentSize: Bool.random(),
                                      blockSize: 256 * 1024, dictionary: dictData, dictionaryID: 20000)
        redecompressedData = try LZ4.decompress(data: compressedData, dictionary: dictData, dictionaryID: 20000)
        XCTAssertEqual(redecompressedData, answerData)
        // If the wrong dictionary ID is specified the decompression should fail.
        XCTAssertThrowsError(try LZ4.decompress(data: compressedData, dictionary: dictData, dictionaryID: 12345))
    }

    func testSmallDictionary() throws {
        let answerData = try Constants.data(forTest: "SWCompressionSourceCode", withType: "tar")
        let dictData = try Constants.data(forTest: "lz4_small_dict", withType: "")

        var compressedData = LZ4.compress(data: answerData, independentBlocks: true, blockChecksums: Bool.random(),
                                          contentChecksum: Bool.random(), contentSize: Bool.random(),
                                          blockSize: 256 * 1024, dictionary: dictData, dictionaryID: nil)
        var redecompressedData = try LZ4.decompress(data: compressedData, dictionary: dictData)
        XCTAssertEqual(redecompressedData, answerData)
        var compressionRatio = Double(answerData.count) / Double(compressedData.count)
        print(String(format: "LZ4.small_dict.compressionRatio = %.3f", compressionRatio))

        compressedData = LZ4.compress(data: answerData, independentBlocks: false, blockChecksums: Bool.random(),
                                      contentChecksum: Bool.random(), contentSize: Bool.random(),
                                      blockSize: 256 * 1024, dictionary: dictData, dictionaryID: nil)
        redecompressedData = try LZ4.decompress(data: compressedData, dictionary: dictData)
        XCTAssertEqual(redecompressedData, answerData)
        compressionRatio = Double(answerData.count) / Double(compressedData.count)
        print(String(format: "LZ4.small_dict_BD.compressionRatio = %.3f", compressionRatio))
    }

    func testTrickySequence() throws {
        // This test helped us find an issue with implementation (match index was wrongly used as cyclical index).
        // The last 10 bytes (0x01 - 0x00) are only here to allow creation of a sequence with a match.
        let answerData = Data([0x61, 0x6C, 0x20, 0x2D, 0x43, 0x20, 0x2D, 0x43, 0x20, 0x2D, 0x2D, 0x01, 0x02, 0x03, 0x04,
                               0x05, 0x06, 0x07, 0x08, 0x09, 0x00])
        let compressedData = LZ4.compress(data: answerData, independentBlocks: false, blockChecksums: true,
                                          contentChecksum: true, contentSize: true)
        let redecompressedData = try LZ4.decompress(data: compressedData)
        XCTAssertEqual(redecompressedData, answerData)
    }
}
