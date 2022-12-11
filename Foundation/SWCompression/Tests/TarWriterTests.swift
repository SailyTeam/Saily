// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import SWCompression
import XCTest

class TarWriterTests: XCTestCase {
    private static let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("TestSWCompression-" + UUID().uuidString, isDirectory: true)

    override class func setUp() {
        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            fatalError("TarWriterTests.setUp(): unable to create temporary directory: \(error)")
        }
    }

    override class func tearDown() {
        do {
            try FileManager.default.removeItem(at: tempDir)
        } catch {
            fatalError("TarWriterTests.tearDown(): unable to remove temporary directory: \(error)")
        }
    }

    private static func generateContainerData(_ entries: [TarEntry], format: TarContainer.Format = .pax) throws -> Data {
        let tempFileUrl = tempDir.appendingPathComponent(UUID().uuidString, isDirectory: false)
        try "".write(to: tempFileUrl, atomically: true, encoding: .utf8)
        let handle = try FileHandle(forWritingTo: tempFileUrl)
        var writer = TarWriter(fileHandle: handle, force: format)
        for entry in entries {
            try writer.append(entry)
        }
        try writer.finalize()
        try handle.closeCompat()
        return try Data(contentsOf: tempFileUrl)
    }

    func test1() throws {
        var info = TarEntryInfo(name: "file.txt", type: .regular)
        info.ownerUserName = "timofeysolomko"
        info.ownerGroupName = "staff"
        info.ownerID = 501
        info.groupID = 20
        info.permissions = Permissions(rawValue: 420)
        // We have to convert time interval to int, since tar can't store fractional timestamps, so we lose in accuracy.
        let intTimeInterval = Int(Date().timeIntervalSince1970)
        let date = Date(timeIntervalSince1970: Double(intTimeInterval))
        info.modificationTime = date
        info.creationTime = date
        info.accessTime = date
        info.comment = "comment"
        let data = Data("Hello, World!\n".utf8)
        let entry = TarEntry(info: info, data: data)

        let containerData = try TarWriterTests.generateContainerData([entry])
        XCTAssertEqual(try TarContainer.formatOf(container: containerData), .pax)
        let newEntries = try TarContainer.open(container: containerData)

        XCTAssertEqual(newEntries.count, 1)
        XCTAssertEqual(newEntries[0].info.name, "file.txt")
        XCTAssertEqual(newEntries[0].info.type, .regular)
        XCTAssertEqual(newEntries[0].info.size, 14)
        XCTAssertEqual(newEntries[0].info.ownerUserName, "timofeysolomko")
        XCTAssertEqual(newEntries[0].info.ownerGroupName, "staff")
        XCTAssertEqual(newEntries[0].info.ownerID, 501)
        XCTAssertEqual(newEntries[0].info.groupID, 20)
        XCTAssertEqual(newEntries[0].info.permissions, Permissions(rawValue: 420))
        XCTAssertEqual(newEntries[0].info.modificationTime, date)
        XCTAssertEqual(newEntries[0].info.creationTime, date)
        XCTAssertEqual(newEntries[0].info.accessTime, date)
        XCTAssertEqual(newEntries[0].info.comment, "comment")
        XCTAssertEqual(newEntries[0].data, data)
    }

    func test2() throws {
        let dict = [
            "SWCompression/Tests/TAR": "value",
            "key": "valuevaluevaluevaluevaluevaluevaluevaluevaluevaluevaluevaluevaluevaluevaluevaluevaluevalue22",
        ]

        var info = TarEntryInfo(name: "symbolic-link", type: .symbolicLink)
        info.accessTime = Date(timeIntervalSince1970: 1)
        info.creationTime = Date(timeIntervalSince1970: 2)
        info.modificationTime = Date(timeIntervalSince1970: 0)
        info.permissions = Permissions(rawValue: 420)
        info.permissions?.insert(.executeOwner)
        info.ownerID = 250
        info.groupID = 250
        info.ownerUserName = "testUserName"
        info.ownerGroupName = "testGroupName"
        info.deviceMajorNumber = 1
        info.deviceMinorNumber = 2
        info.charset = "UTF-8"
        info.comment = "some comment..."
        info.linkName = "file"
        info.unknownExtendedHeaderRecords = dict
        let entry = TarEntry(info: info, data: Data())

        let containerData = try TarWriterTests.generateContainerData([entry])
        XCTAssertEqual(try TarContainer.formatOf(container: containerData), .pax)
        let newInfo = try TarContainer.open(container: containerData)[0].info

        XCTAssertEqual(newInfo.name, "symbolic-link")
        XCTAssertEqual(newInfo.type, .symbolicLink)
        XCTAssertEqual(newInfo.permissions?.rawValue, 484)
        XCTAssertEqual(newInfo.ownerID, 250)
        XCTAssertEqual(newInfo.groupID, 250)
        XCTAssertEqual(newInfo.size, 0)
        XCTAssertEqual(newInfo.modificationTime?.timeIntervalSince1970, 0)
        XCTAssertEqual(newInfo.linkName, "file")
        XCTAssertEqual(newInfo.ownerUserName, "testUserName")
        XCTAssertEqual(newInfo.ownerGroupName, "testGroupName")
        XCTAssertEqual(newInfo.deviceMajorNumber, 1)
        XCTAssertEqual(newInfo.deviceMinorNumber, 2)
        XCTAssertEqual(newInfo.accessTime?.timeIntervalSince1970, 1)
        XCTAssertEqual(newInfo.creationTime?.timeIntervalSince1970, 2)
        XCTAssertEqual(newInfo.charset, "UTF-8")
        XCTAssertEqual(newInfo.comment, "some comment...")
        XCTAssertEqual(newInfo.unknownExtendedHeaderRecords, dict)
    }

    func testLongName() throws {
        var info = TarEntryInfo(name: "", type: .regular)
        info.name = "path/to/"
        info.name.append(String(repeating: "readme/", count: 15))
        info.name.append("readme.txt")
        let entry = TarEntry(info: info, data: Data())

        let containerData = try TarWriterTests.generateContainerData([entry])
        XCTAssertEqual(try TarContainer.formatOf(container: containerData), .pax)
        let newInfo = try TarContainer.open(container: containerData)[0].info

        // This name should fit into ustar format using "prefix" field
        XCTAssertEqual(newInfo.name, info.name)
    }

    func testVeryLongName() throws {
        var info = TarEntryInfo(name: "", type: .regular)
        info.name = "path/to/"
        info.name.append(String(repeating: "readme/", count: 25))
        info.name.append("readme.txt")
        let entry = TarEntry(info: info, data: Data())

        let containerData = try TarWriterTests.generateContainerData([entry])
        XCTAssertEqual(try TarContainer.formatOf(container: containerData), .pax)
        let newInfo = try TarContainer.open(container: containerData)[0].info

        XCTAssertEqual(newInfo.name, info.name)
    }

    func testLongDirectoryName() throws {
        // Tests what happens to the filename's trailing slash when "prefix" field is used.
        var info = TarEntryInfo(name: "", type: .regular)
        info.name = "path/to/"
        info.name.append(String(repeating: "readme/", count: 15))
        let entry = TarEntry(info: info, data: Data())

        let containerData = try TarWriterTests.generateContainerData([entry])
        XCTAssertEqual(try TarContainer.formatOf(container: containerData), .pax)
        let newInfo = try TarContainer.open(container: containerData)[0].info

        XCTAssertEqual(newInfo.name, info.name)
    }

    func testUnicode() throws {
        let date = Date(timeIntervalSince1970: 1_300_000)
        var info = TarEntryInfo(name: "ссылка", type: .symbolicLink)
        info.accessTime = date
        info.creationTime = date
        info.modificationTime = date
        info.permissions = Permissions(rawValue: 420)
        info.ownerID = 501
        info.groupID = 20
        info.ownerUserName = "timofeysolomko"
        info.ownerGroupName = "staff"
        info.deviceMajorNumber = 1
        info.deviceMinorNumber = 2
        info.comment = "комментарий"
        info.linkName = "путь/к/файлу"
        let entry = TarEntry(info: info, data: Data())

        let containerData = try TarWriterTests.generateContainerData([entry])
        XCTAssertEqual(try TarContainer.formatOf(container: containerData), .pax)
        let newInfo = try TarContainer.open(container: containerData)[0].info

        XCTAssertEqual(newInfo.name, "ссылка")
        XCTAssertEqual(newInfo.type, .symbolicLink)
        XCTAssertEqual(newInfo.permissions?.rawValue, 420)
        XCTAssertEqual(newInfo.ownerID, 501)
        XCTAssertEqual(newInfo.groupID, 20)
        XCTAssertEqual(newInfo.size, 0)
        XCTAssertEqual(newInfo.modificationTime?.timeIntervalSince1970, 1_300_000)
        XCTAssertEqual(newInfo.linkName, "путь/к/файлу")
        XCTAssertEqual(newInfo.ownerUserName, "timofeysolomko")
        XCTAssertEqual(newInfo.ownerGroupName, "staff")
        XCTAssertEqual(newInfo.accessTime?.timeIntervalSince1970, 1_300_000)
        XCTAssertEqual(newInfo.creationTime?.timeIntervalSince1970, 1_300_000)
        XCTAssertEqual(newInfo.comment, "комментарий")
    }

    func testUstar() throws {
        // This set of settings should result in the container which uses only ustar TAR format features.
        let date = Date(timeIntervalSince1970: 1_300_000)
        var info = TarEntryInfo(name: "file.txt", type: .regular)
        info.permissions = Permissions(rawValue: 420)
        info.ownerID = 501
        info.groupID = 20
        info.modificationTime = date
        let entry = TarEntry(info: info, data: Data())

        let containerData = try TarWriterTests.generateContainerData([entry], format: .ustar)
        XCTAssertEqual(try TarContainer.formatOf(container: containerData), .ustar)
        let newInfo = try TarContainer.open(container: containerData)[0].info

        XCTAssertEqual(newInfo.name, "file.txt")
        XCTAssertEqual(newInfo.type, .regular)
        XCTAssertEqual(newInfo.permissions?.rawValue, 420)
        XCTAssertEqual(newInfo.ownerID, 501)
        XCTAssertEqual(newInfo.groupID, 20)
        XCTAssertEqual(newInfo.size, 0)
        XCTAssertEqual(newInfo.modificationTime?.timeIntervalSince1970, 1_300_000)
        XCTAssertEqual(newInfo.linkName, "")
        XCTAssertEqual(newInfo.ownerUserName, "")
        XCTAssertEqual(newInfo.ownerGroupName, "")
        XCTAssertNil(newInfo.accessTime)
        XCTAssertNil(newInfo.creationTime)
        XCTAssertNil(newInfo.comment)
    }

    func testNegativeMtime() throws {
        let date = Date(timeIntervalSince1970: -1_300_000)
        var info = TarEntryInfo(name: "file.txt", type: .regular)
        info.modificationTime = date
        let entry = TarEntry(info: info, data: Data())

        let containerData = try TarWriterTests.generateContainerData([entry])
        XCTAssertEqual(try TarContainer.formatOf(container: containerData), .pax)
        let newInfo = try TarContainer.open(container: containerData)[0].info

        XCTAssertEqual(newInfo.name, "file.txt")
        XCTAssertEqual(newInfo.type, .regular)
        XCTAssertEqual(newInfo.size, 0)
        XCTAssertEqual(newInfo.modificationTime?.timeIntervalSince1970, -1_300_000)
        XCTAssertEqual(newInfo.linkName, "")
        XCTAssertEqual(newInfo.ownerUserName, "")
        XCTAssertEqual(newInfo.ownerGroupName, "")
        XCTAssertNil(newInfo.permissions)
        XCTAssertNil(newInfo.ownerID)
        XCTAssertNil(newInfo.groupID)
        XCTAssertNil(newInfo.accessTime)
        XCTAssertNil(newInfo.creationTime)
        XCTAssertNil(newInfo.comment)
    }

    func testBigUid() throws {
        // Int.max tests that base-256 encoding of integer fields works in the edge case.
        for uid in [(1 << 32) - 1, Int.max] {
            var info = TarEntryInfo(name: "file.txt", type: .regular)
            info.ownerID = uid
            let entry = TarEntry(info: info, data: Data())

            let containerData = try TarWriterTests.generateContainerData([entry])
            XCTAssertEqual(try TarContainer.formatOf(container: containerData), .pax)
            let newInfo = try TarContainer.open(container: containerData)[0].info

            XCTAssertEqual(newInfo.name, "file.txt")
            XCTAssertEqual(newInfo.type, .regular)
            XCTAssertEqual(newInfo.size, 0)
            XCTAssertEqual(newInfo.ownerID, uid)
            XCTAssertEqual(newInfo.linkName, "")
            XCTAssertEqual(newInfo.ownerUserName, "")
            XCTAssertEqual(newInfo.ownerGroupName, "")
            XCTAssertNil(newInfo.permissions)
            XCTAssertNil(newInfo.groupID)
            XCTAssertNil(newInfo.accessTime)
            XCTAssertNil(newInfo.creationTime)
            XCTAssertNil(newInfo.modificationTime)
            XCTAssertNil(newInfo.comment)
        }
    }

    func testGnuLongName() throws {
        var info = TarEntryInfo(name: "", type: .regular)
        info.name = "path/to/"
        info.name.append(String(repeating: "name/", count: 25))
        info.name.append("name.txt")
        let entry = TarEntry(info: info, data: Data())

        let containerData = try TarWriterTests.generateContainerData([entry], format: .gnu)
        XCTAssertEqual(try TarContainer.formatOf(container: containerData), .gnu)
        let newInfo = try TarContainer.open(container: containerData)[0].info

        XCTAssertEqual(newInfo.name, info.name)
    }

    func testGnuLongLinkName() throws {
        var info = TarEntryInfo(name: "", type: .symbolicLink)
        info.name = "link"
        info.linkName = "path/to/"
        info.linkName.append(String(repeating: "name/", count: 25))
        info.linkName.append("name.txt")
        let entry = TarEntry(info: info, data: Data())

        let containerData = try TarWriterTests.generateContainerData([entry], format: .gnu)
        XCTAssertEqual(try TarContainer.formatOf(container: containerData), .gnu)
        let newInfo = try TarContainer.open(container: containerData)[0].info

        XCTAssertEqual(newInfo.name, info.name)
    }

    func testGnuBothLongNames() throws {
        var info = TarEntryInfo(name: "", type: .symbolicLink)
        info.name = "path/to/"
        info.name.append(String(repeating: "name/", count: 25))
        info.name.append("name.txt")
        info.linkName = "path/to/"
        info.linkName.append(String(repeating: "link/", count: 25))
        info.linkName.append("link.txt")
        let entry = TarEntry(info: info, data: Data())

        let containerData = try TarWriterTests.generateContainerData([entry], format: .gnu)
        XCTAssertEqual(try TarContainer.formatOf(container: containerData), .gnu)
        let newInfo = try TarContainer.open(container: containerData)[0].info

        XCTAssertEqual(newInfo.name, info.name)
    }

    func testGnuTimes() throws {
        var info = TarEntryInfo(name: "dir", type: .directory)
        info.ownerUserName = "tsolomko"
        info.ownerGroupName = "staff"
        info.ownerID = 501
        info.groupID = 20
        info.permissions = Permissions(rawValue: 420)
        // We have to convert time interval to int, since tar can't store fractional timestamps, so we lose in accuracy.
        let intTimeInterval = Int(Date().timeIntervalSince1970)
        let date = Date(timeIntervalSince1970: Double(intTimeInterval))
        info.modificationTime = date
        info.creationTime = date
        info.accessTime = date
        let entry = TarEntry(info: info, data: Data())

        let containerData = try TarWriterTests.generateContainerData([entry], format: .gnu)
        XCTAssertEqual(try TarContainer.formatOf(container: containerData), .gnu)
        let newEntries = try TarContainer.open(container: containerData)

        XCTAssertEqual(newEntries.count, 1)
        XCTAssertEqual(newEntries[0].info.name, "dir")
        XCTAssertEqual(newEntries[0].info.type, .directory)
        XCTAssertEqual(newEntries[0].info.size, 0)
        XCTAssertEqual(newEntries[0].info.ownerUserName, "tsolomko")
        XCTAssertEqual(newEntries[0].info.ownerGroupName, "staff")
        XCTAssertEqual(newEntries[0].info.ownerID, 501)
        XCTAssertEqual(newEntries[0].info.groupID, 20)
        XCTAssertEqual(newEntries[0].info.permissions, Permissions(rawValue: 420))
        XCTAssertEqual(newEntries[0].info.modificationTime, date)
        XCTAssertEqual(newEntries[0].info.creationTime, date)
        XCTAssertEqual(newEntries[0].info.accessTime, date)
        XCTAssertNil(newEntries[0].info.comment)
    }
}
