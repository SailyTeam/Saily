// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import SWCompression
import XCTest

class BZip2CompressionTests: XCTestCase {
    func answerTest(_ testName: String) throws {
        let answerData = try Constants.data(forAnswer: testName)
        let compressedData = BZip2.compress(data: answerData)
        let redecompressedData = try BZip2.decompress(data: compressedData)
        XCTAssertEqual(redecompressedData, answerData)
        if answerData.count > 0 { // Compression ratio is always bad for empty file.
            let compressionRatio = Double(answerData.count) / Double(compressedData.count)
            print(String(format: "BZip2.\(testName).compressionRatio = %.3f", compressionRatio))
        }
    }

    func stringTest(_ string: String) throws {
        let answerData = Data(string.utf8)

        let compressedData = BZip2.compress(data: answerData)

        let redecompressedData = try BZip2.decompress(data: compressedData)
        XCTAssertEqual(redecompressedData, answerData)
    }

    func testBZip2CompressStrings() throws {
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

    func testBZip2CompressBytes() throws {
        var bytes = ""
        for i: UInt8 in 0 ... 255 {
            bytes += String(format: "%c", i)
        }
        try stringTest(bytes)
    }

    func testWithAnswer1BZip2Compress() throws {
        try answerTest("test1")
    }

    func testWithAnswer2BZip2Compress() throws {
        try answerTest("test2")
    }

    func testWithAnswer3BZip2Compress() throws {
        try answerTest("test3")
    }

    func testWithAnswer4BZip2Compress() throws {
        try answerTest("test4")
    }

    func testWithAnswer5BZip2Compress() throws {
        try answerTest("test5")
    }

    func testWithAnswer6BZip2Compress() throws {
        try answerTest("test6")
    }

//    func testWithAnswer7BZip2Compress() throws {
//        try answerTest("test7")
//    }

    func testWithAnswer8BZip2Compress() throws {
        try answerTest("test8")
    }

    func testWithAnswer9BZip2Compress() throws {
        try answerTest("test9")
    }
}
