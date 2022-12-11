// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import SWCompression
import XCTest

class DeflateCompressionTests: XCTestCase {
    func answerTest(_ testName: String) throws {
        let answerData = try Constants.data(forAnswer: testName)
        let compressedData = Deflate.compress(data: answerData)
        let redecompressedData = try Deflate.decompress(data: compressedData)
        XCTAssertEqual(redecompressedData, answerData)
        if answerData.count > 0 { // Compression ratio is always bad for empty file.
            let compressionRatio = Double(answerData.count) / Double(compressedData.count)
            print(String(format: "Deflate.\(testName).compressionRatio = %.3f", compressionRatio))
        }
    }

    func stringTest(_ string: String) throws {
        let answerData = Data(string.utf8)
        let compressedData = Deflate.compress(data: answerData)
        let redecompressedData = try Deflate.decompress(data: compressedData)
        XCTAssertEqual(redecompressedData, answerData)
    }

    func testDeflateCompressStrings() throws {
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

    func testDeflate1() throws {
        try answerTest("test1")
    }

    func testDeflate2() throws {
        try answerTest("test2")
    }

    func testDeflate3() throws {
        try answerTest("test3")
    }

    func testDeflate4() throws {
        try answerTest("test4")
    }

    func testDeflate5() throws {
        try answerTest("test5")
    }

    func testDeflate6() throws {
        try answerTest("test6")
    }

    func testDeflate7() throws {
        try answerTest("test7")
    }

    func testDeflate8() throws {
        try answerTest("test8")
    }

    func testDeflate9() throws {
        try answerTest("test9")
    }

    func testTrickySequence() throws {
        // This test helped us find an issue with implementation (match index was wrongly used as cyclical index).
        // This test may become useless in the future if the encoder starts preferring creation of an uncompressed block
        // for this input due to changes to the compression logic.
        let answerData = Data([0x2E, 0x20, 0x2E, 0x20, 0x2E, 0x20, 0x20])
        let compressedData = Deflate.compress(data: answerData)
        let redecompressedData = try Deflate.decompress(data: compressedData)
        XCTAssertEqual(redecompressedData, answerData)
    }
}
