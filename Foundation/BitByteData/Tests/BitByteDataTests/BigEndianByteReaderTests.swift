// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import BitByteData
import XCTest

class BigEndianByteReaderTests: XCTestCase {
    func testByte() {
        let randomByte = UInt8.random(in: 0 ... UInt8.max)
        let reader = BigEndianByteReader(data: Data([randomByte, UInt8.min, UInt8.max]))

        XCTAssertEqual(reader.byte(), randomByte)
        XCTAssertFalse(reader.isFinished)
        XCTAssertEqual(reader.byte(), UInt8.min)
        XCTAssertEqual(reader.byte(), UInt8.max)
        XCTAssertTrue(reader.isFinished)
    }

    func testIsFinished() {
        let reader = BigEndianByteReader(data: TestHelper.byteData)
        XCTAssertFalse(reader.isFinished)
        reader.offset = 9
        XCTAssertTrue(reader.isFinished)
    }

    func testBytesLeft() {
        let reader = BigEndianByteReader(data: TestHelper.byteData)
        XCTAssertEqual(reader.bytesLeft, 9)
        _ = reader.uint16()
        XCTAssertEqual(reader.bytesLeft, 7)
        reader.offset = reader.data.endIndex
        XCTAssertEqual(reader.bytesLeft, 0)
    }

    func testBytesRead() {
        let reader = BigEndianByteReader(data: TestHelper.byteData)
        XCTAssertEqual(reader.bytesRead, 0)
        _ = reader.uint16()
        XCTAssertEqual(reader.bytesRead, 2)
        reader.offset = reader.data.endIndex
        XCTAssertEqual(reader.bytesRead, 9)
    }

    func testBytes() {
        let count = Int.random(in: 4 ... 16)
        let bytes = TestHelper.randomBytes(count: count)
        let reader = BigEndianByteReader(data: Data(bytes))
        XCTAssertEqual(reader.bytes(count: 0), [])
        XCTAssertEqual(reader.bytes(count: count), bytes)
    }

    func testIntFromBytes() {
        var reader = BigEndianByteReader(data: TestHelper.byteData)
        XCTAssertEqual(reader.int(fromBytes: 0), 0)
        XCTAssertEqual(reader.int(fromBytes: 3), 258)
        XCTAssertEqual(reader.int(fromBytes: 2), 772)
        XCTAssertEqual(reader.int(fromBytes: 4), 84_281_096)
        XCTAssertTrue(reader.isFinished)
        if MemoryLayout<Int>.size == 8 {
            reader = BigEndianByteReader(data: Data([0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
                                                     0x80, 0, 0, 0, 0, 0, 0, 0]))
        } else if MemoryLayout<Int>.size == 4 {
            reader = BigEndianByteReader(data: Data([0x7F, 0xFF, 0xFF, 0xFF, 0x80, 0, 0, 0]))
        } else {
            XCTFail("Unsupported Int bit width.")
            return
        }
        XCTAssertEqual(reader.int(fromBytes: MemoryLayout<Int>.size), Int.max)
        XCTAssertEqual(reader.int(fromBytes: MemoryLayout<Int>.size), Int.min)
    }

    func testUint64() {
        var reader = BigEndianByteReader(data: TestHelper.byteData)
        XCTAssertEqual(reader.uint64(), 0x0001_0203_0405_0607)
        reader = BigEndianByteReader(data: Data(Array(repeating: 0xFF, count: 8)))
        XCTAssertEqual(reader.uint64(), UInt64.max)
        reader = BigEndianByteReader(data: Data(Array(repeating: 0, count: 8)))
        XCTAssertEqual(reader.uint64(), UInt64.min)
    }

    func testUint64FromBytes() {
        var reader = BigEndianByteReader(data: TestHelper.byteData)
        XCTAssertEqual(reader.uint64(fromBytes: 0), 0)
        XCTAssertEqual(reader.uint64(fromBytes: 3), 258)
        XCTAssertFalse(reader.isFinished)
        reader = BigEndianByteReader(data: TestHelper.byteData)
        XCTAssertEqual(reader.uint64(fromBytes: 8), 0x0001_0203_0405_0607)
        XCTAssertFalse(reader.isFinished)
        reader = BigEndianByteReader(data: Data(Array(repeating: 0xFF, count: 8)))
        XCTAssertEqual(reader.uint64(fromBytes: 8), UInt64.max)
        reader = BigEndianByteReader(data: Data(Array(repeating: 0, count: 8)))
        XCTAssertEqual(reader.uint64(fromBytes: 8), UInt64.min)
    }

    func testUint32() {
        var reader = BigEndianByteReader(data: TestHelper.byteData)
        XCTAssertEqual(reader.uint32(), 0x0001_0203)
        reader = BigEndianByteReader(data: Data(Array(repeating: 0xFF, count: 4)))
        XCTAssertEqual(reader.uint32(), UInt32.max)
        reader = BigEndianByteReader(data: Data(Array(repeating: 0, count: 4)))
        XCTAssertEqual(reader.uint32(), UInt32.min)
    }

    func testUint32FromBytes() {
        var reader = BigEndianByteReader(data: TestHelper.byteData)
        XCTAssertEqual(reader.uint32(fromBytes: 0), 0)
        XCTAssertEqual(reader.uint32(fromBytes: 3), 258)
        XCTAssertFalse(reader.isFinished)
        reader = BigEndianByteReader(data: TestHelper.byteData)
        XCTAssertEqual(reader.uint32(fromBytes: 4), 0x0001_0203)
        XCTAssertFalse(reader.isFinished)
        reader = BigEndianByteReader(data: Data(Array(repeating: 0xFF, count: 4)))
        XCTAssertEqual(reader.uint32(fromBytes: 4), UInt32.max)
        reader = BigEndianByteReader(data: Data(Array(repeating: 0, count: 4)))
        XCTAssertEqual(reader.uint32(fromBytes: 4), UInt32.min)
    }

    func testUint16() {
        var reader = BigEndianByteReader(data: TestHelper.byteData)
        XCTAssertEqual(reader.uint16(), 0x0001)
        reader = BigEndianByteReader(data: Data(Array(repeating: 0xFF, count: 2)))
        XCTAssertEqual(reader.uint16(), UInt16.max)
        reader = BigEndianByteReader(data: Data(Array(repeating: 0, count: 2)))
        XCTAssertEqual(reader.uint16(), UInt16.min)
    }

    func testUint16FromBytes() {
        var reader = BigEndianByteReader(data: TestHelper.byteData)
        XCTAssertEqual(reader.uint16(fromBytes: 0), 0)
        XCTAssertEqual(reader.uint16(fromBytes: 2), 1)
        XCTAssertFalse(reader.isFinished)
        reader = BigEndianByteReader(data: Data(Array(repeating: 0xFF, count: 2)))
        XCTAssertEqual(reader.uint16(fromBytes: 2), UInt16.max)
        reader = BigEndianByteReader(data: Data(Array(repeating: 0, count: 2)))
        XCTAssertEqual(reader.uint16(fromBytes: 2), UInt16.min)
    }

    func testNonZeroStartIndex() {
        let reader = BigEndianByteReader(data: TestHelper.byteData[1...])
        XCTAssertEqual(reader.offset, 1)
        XCTAssertEqual(reader.uint16(), 0x0102)
        XCTAssertEqual(reader.offset, 3)
        XCTAssertEqual(reader.uint32(), 0x0304_0506)
        XCTAssertEqual(reader.offset, 7)
        XCTAssertEqual(reader.byte(), 0x07)
        XCTAssertEqual(reader.bytes(count: 1), [0x08])
    }
}
