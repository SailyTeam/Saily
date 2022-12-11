// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import SWCompression
import XCTest

class TarReaderTests: XCTestCase {
    private static let testType: String = "tar"

    func testBadFile_invalid() throws {
        // This is potentially a misleading test, since there is no way to guarantee that a file is not a TAR container.
        // We use randomly generated data, since the 0-filled data is processed as an empty container.
        let testHandle = try Constants.handle(forTest: "test7", withType: "answer")
        var reader = TarReader(fileHandle: testHandle)
        XCTAssertThrowsError(try reader.read())
        try testHandle.closeCompat()
    }

    func test() throws {
        let testHandle = try Constants.handle(forTest: "test", withType: TarReaderTests.testType)
        var reader = TarReader(fileHandle: testHandle)
        var isFinished = false
        var entriesCount = 0
        while !isFinished {
            isFinished = try reader.process { (entry: TarEntry?) -> Bool in
                if entry == nil {
                    return true
                }
                XCTAssertEqual(entry!.info.name, "test5.answer")
                XCTAssertEqual(entry!.info.size, 0)
                XCTAssertEqual(entry!.info.type, .regular)
                XCTAssertEqual(entry!.info.ownerID, 501)
                XCTAssertEqual(entry!.info.groupID, 20)
                XCTAssertEqual(entry!.info.ownerUserName, "timofeysolomko")
                XCTAssertEqual(entry!.info.ownerGroupName, "staff")
                XCTAssertEqual(entry!.info.permissions, Permissions(rawValue: 420))
                XCTAssertNil(entry!.info.comment)
                XCTAssertEqual(entry!.data, Data())
                entriesCount += 1
                return false
            }
        }
        XCTAssertEqual(entriesCount, 1)

        try testHandle.closeCompat()
    }

    func testPax() throws {
        let testHandle = try Constants.handle(forTest: "full_test", withType: TarReaderTests.testType)
        var reader = TarReader(fileHandle: testHandle)
        var isFinished = false
        var entriesCount = 0
        while !isFinished {
            isFinished = try reader.process { (entry: TarEntry?) -> Bool in
                if entry == nil {
                    return true
                }
                let name = entry!.info.name.components(separatedBy: ".")[0]
                let answerData = try Constants.data(forAnswer: name)
                XCTAssertEqual(entry!.data, answerData)
                XCTAssertEqual(entry!.info.type, .regular)
                XCTAssertEqual(entry!.info.ownerUserName, "tsolomko")
                XCTAssertEqual(entry!.info.ownerGroupName, "tsolomko")
                XCTAssertEqual(entry!.info.ownerID, 1001)
                XCTAssertEqual(entry!.info.groupID, 1001)
                XCTAssertEqual(entry!.info.permissions, Permissions(rawValue: 436))
                XCTAssertNil(entry!.info.comment)
                // Checking times' values is a bit difficult since they are extremely precise.
                XCTAssertNotNil(entry!.info.modificationTime)
                XCTAssertNotNil(entry!.info.accessTime)
                XCTAssertNotNil(entry!.info.creationTime)
                entriesCount += 1
                return false
            }
        }
        XCTAssertEqual(entriesCount, 5)
        try testHandle.closeCompat()
    }

    func testFormats() throws {
        let formatTestNames = ["test_gnu", "test_oldgnu", "test_pax", "test_ustar", "test_v7"]
        let answerData = try Constants.data(forAnswer: "test1")

        for testName in formatTestNames {
            let testHandle = try Constants.handle(forTest: testName, withType: TarReaderTests.testType)
            var reader = TarReader(fileHandle: testHandle)
            var isFinished = false
            var entriesCount = 0
            while !isFinished {
                isFinished = try reader.process { (entry: TarEntry?) -> Bool in
                    if entry == nil {
                        return true
                    }
                    XCTAssertEqual(entry!.info.name, "test1.answer")
                    XCTAssertEqual(entry!.info.size, 14)
                    XCTAssertEqual(entry!.info.type, .regular)
                    XCTAssertEqual(entry!.data, answerData)
                    entriesCount += 1
                    return false
                }
            }
            XCTAssertEqual(entriesCount, 1)
            try testHandle.closeCompat()
        }
    }

    func testLongNames() throws {
        let formatTestNames = ["long_test_gnu", "long_test_oldgnu", "long_test_pax"]
        for testName in formatTestNames {
            let testHandle = try Constants.handle(forTest: testName, withType: TarReaderTests.testType)
            var reader = TarReader(fileHandle: testHandle)
            var isFinished = false
            var entriesCount = 0
            while !isFinished {
                isFinished = try reader.process { (entry: TarEntry?) -> Bool in
                    if entry == nil {
                        return true
                    }
                    entriesCount += 1
                    return false
                }
            }
            XCTAssertEqual(entriesCount, 6)
            try testHandle.closeCompat()
        }
    }

    func testWinContainer() throws {
        let testHandle = try Constants.handle(forTest: "test_win", withType: TarReaderTests.testType)
        var reader = TarReader(fileHandle: testHandle)
        try reader.process { (entry: TarEntry?) in
            XCTAssertNotNil(entry)
            XCTAssertEqual(entry!.info.name, "dir/")
            XCTAssertEqual(entry!.info.type, .directory)
            XCTAssertEqual(entry!.info.size, 0)
            XCTAssertEqual(entry!.info.ownerUserName, "")
            XCTAssertEqual(entry!.info.ownerGroupName, "")
            XCTAssertEqual(entry!.info.ownerID, 0)
            XCTAssertEqual(entry!.info.groupID, 0)
            XCTAssertEqual(entry!.info.permissions, Permissions(rawValue: 511))
            XCTAssertNil(entry!.info.comment)
            XCTAssertEqual(entry!.data, nil)
        }
        try reader.process { (entry: TarEntry?) in
            XCTAssertNotNil(entry)
            XCTAssertEqual(entry!.info.name, "text_win.txt")
            XCTAssertEqual(entry!.info.type, .regular)
            XCTAssertEqual(entry!.info.size, 15)
            XCTAssertEqual(entry!.info.ownerUserName, "")
            XCTAssertEqual(entry!.info.ownerGroupName, "")
            XCTAssertEqual(entry!.info.ownerID, 0)
            XCTAssertEqual(entry!.info.groupID, 0)
            XCTAssertEqual(entry!.info.permissions, Permissions(rawValue: 511))
            XCTAssertNil(entry!.info.comment)
            XCTAssertEqual(entry!.data, "Hello, Windows!".data(using: .utf8))
        }
        try testHandle.closeCompat()
    }

    func testEmptyFile() throws {
        let testHandle = try Constants.handle(forTest: "test_empty_file", withType: TarReaderTests.testType)
        var reader = TarReader(fileHandle: testHandle)
        try reader.process { (entry: TarEntry?) in
            XCTAssertNotNil(entry)
            XCTAssertEqual(entry!.info.name, "empty_file")
            XCTAssertEqual(entry!.info.type, .regular)
            XCTAssertEqual(entry!.info.size, 0)
            XCTAssertEqual(entry!.info.ownerID, 501)
            XCTAssertEqual(entry!.info.groupID, 20)
            XCTAssertEqual(entry!.info.ownerUserName, "timofeysolomko")
            XCTAssertEqual(entry!.info.ownerGroupName, "staff")
            XCTAssertEqual(entry!.info.permissions, Permissions(rawValue: 420))
            XCTAssertNil(entry!.info.comment)
            XCTAssertEqual(entry!.data, Data())
        }
        try testHandle.closeCompat()
    }

    func testEmptyDirectory() throws {
        let testHandle = try Constants.handle(forTest: "test_empty_dir", withType: TarReaderTests.testType)
        var reader = TarReader(fileHandle: testHandle)
        try reader.process { (entry: TarEntry?) in
            XCTAssertNotNil(entry)
            XCTAssertEqual(entry!.info.name, "empty_dir/")
            XCTAssertEqual(entry!.info.type, .directory)
            XCTAssertEqual(entry!.info.size, 0)
            XCTAssertEqual(entry!.info.ownerID, 501)
            XCTAssertEqual(entry!.info.groupID, 20)
            XCTAssertEqual(entry!.info.ownerUserName, "timofeysolomko")
            XCTAssertEqual(entry!.info.ownerGroupName, "staff")
            XCTAssertEqual(entry!.info.permissions, Permissions(rawValue: 493))
            XCTAssertNil(entry!.info.comment)
            XCTAssertNil(entry!.data)
        }
        try testHandle.closeCompat()
    }

    func testOnlyDirectoryHeader() throws {
        // This tests the correct handling of the situation when there is nothing in the container but one basic header,
        // even no EOF marker (two blocks of zeros).
        let testHandle = try Constants.handle(forTest: "test_only_dir_header", withType: TarReaderTests.testType)
        var reader = TarReader(fileHandle: testHandle)
        try reader.process { (entry: TarEntry?) in
            XCTAssertNotNil(entry)
            XCTAssertEqual(entry!.info.name, "empty_dir/")
            XCTAssertEqual(entry!.info.type, .directory)
            XCTAssertEqual(entry!.info.size, 0)
            XCTAssertEqual(entry!.info.ownerID, 501)
            XCTAssertEqual(entry!.info.groupID, 20)
            XCTAssertEqual(entry!.info.ownerUserName, "timofeysolomko")
            XCTAssertEqual(entry!.info.ownerGroupName, "staff")
            XCTAssertEqual(entry!.info.permissions, Permissions(rawValue: 493))
            XCTAssertNil(entry!.info.comment)
            XCTAssertNil(entry!.data)
        }
        try testHandle.closeCompat()
    }

    func testEmptyContainer() throws {
        let testHandle = try Constants.handle(forTest: "test_empty_cont", withType: TarReaderTests.testType)
        var reader = TarReader(fileHandle: testHandle)
        XCTAssertNil(try reader.read())
        try testHandle.closeCompat()
    }

    func testBigContainer() throws {
        let testHandle = try Constants.handle(forTest: "SWCompressionSourceCode", withType: TarReaderTests.testType)
        var reader = TarReader(fileHandle: testHandle)
        while try reader.read() != nil {}
        try testHandle.closeCompat()
    }

    func testUnicodeUstar() throws {
        let testHandle = try Constants.handle(forTest: "test_unicode_ustar", withType: TarReaderTests.testType)
        var reader = TarReader(fileHandle: testHandle)
        try reader.process { (entry: TarEntry?) in
            XCTAssertNotNil(entry)
            XCTAssertEqual(entry!.info.name, "текстовый файл.answer")
            XCTAssertEqual(entry!.info.type, .regular)
            XCTAssertEqual(entry!.info.ownerID, 501)
            XCTAssertEqual(entry!.info.groupID, 20)
            XCTAssertEqual(entry!.info.ownerUserName, "timofeysolomko")
            XCTAssertEqual(entry!.info.ownerGroupName, "staff")
            XCTAssertEqual(entry!.info.permissions, Permissions(rawValue: 420))
            XCTAssertNil(entry!.info.comment)
            let answerData = try Constants.data(forAnswer: "текстовый файл")
            XCTAssertEqual(entry!.data, answerData)
        }
        try testHandle.closeCompat()
    }

    func testUnicodePax() throws {
        let testHandle = try Constants.handle(forTest: "test_unicode_pax", withType: TarReaderTests.testType)
        var reader = TarReader(fileHandle: testHandle)
        try reader.process { (entry: TarEntry?) in
            XCTAssertNotNil(entry)
            XCTAssertEqual(entry!.info.name, "текстовый файл.answer")
            XCTAssertEqual(entry!.info.type, .regular)
            XCTAssertEqual(entry!.info.ownerID, 501)
            XCTAssertEqual(entry!.info.groupID, 20)
            XCTAssertEqual(entry!.info.ownerUserName, "timofeysolomko")
            XCTAssertEqual(entry!.info.ownerGroupName, "staff")
            XCTAssertEqual(entry!.info.permissions, Permissions(rawValue: 420))
            XCTAssertNil(entry!.info.comment)
            let answerData = try Constants.data(forAnswer: "текстовый файл")
            XCTAssertEqual(entry!.data, answerData)
        }
        try testHandle.closeCompat()
    }

    func testGnuIncrementalFormat() throws {
        let testHandle = try Constants.handle(forTest: "test_gnu_inc_format", withType: TarReaderTests.testType)
        var reader = TarReader(fileHandle: testHandle)
        var isFinished = false
        var entriesCount = 0
        while !isFinished {
            isFinished = try reader.process { (entry: TarEntry?) -> Bool in
                if entry == nil {
                    return true
                }
                XCTAssertEqual(entry!.info.ownerID, 501)
                XCTAssertEqual(entry!.info.groupID, 20)
                XCTAssertEqual(entry!.info.ownerUserName, "timofeysolomko")
                XCTAssertEqual(entry!.info.ownerGroupName, "staff")
                XCTAssertNotNil(entry!.info.accessTime)
                XCTAssertNotNil(entry!.info.creationTime)
                entriesCount += 1
                return false
            }
        }
        XCTAssertEqual(entriesCount, 3)
        try testHandle.closeCompat()
    }

    // This test is impossible to implement using TarReader since the test file doesn't contain actual entry data.
    // func testBigNumField() throws { }

    func testNegativeMtime() throws {
        let testHandle = try Constants.handle(forTest: "test_negative_mtime", withType: TarReaderTests.testType)
        var reader = TarReader(fileHandle: testHandle)
        try reader.process { (entry: TarEntry?) in
            XCTAssertEqual(entry!.info.name, "file")
            XCTAssertEqual(entry!.info.type, .regular)
            XCTAssertEqual(entry!.info.size, 27)
            XCTAssertEqual(entry!.info.ownerID, 501)
            XCTAssertEqual(entry!.info.groupID, 20)
            XCTAssertEqual(entry!.info.ownerUserName, "timofeysolomko")
            XCTAssertEqual(entry!.info.ownerGroupName, "staff")
            XCTAssertEqual(entry!.info.permissions, Permissions(rawValue: 420))
            XCTAssertEqual(entry!.info.modificationTime, Date(timeIntervalSince1970: -313_006_414))
            XCTAssertNil(entry!.info.comment)
            XCTAssertEqual(entry!.data, "File with negative mtime.\n\n".data(using: .utf8))
        }
        // Test that reading after reaching EOF returns nil.
        XCTAssertNil(try reader.read())
        try testHandle.closeCompat()
    }
}
