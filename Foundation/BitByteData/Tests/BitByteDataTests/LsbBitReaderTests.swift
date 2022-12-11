// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import BitByteData
import XCTest

class LsbBitReaderTests: XCTestCase {
    func testAdvance() {
        let reader = LsbBitReader(data: TestHelper.bitData)
        reader.advance(by: 0)
        XCTAssertEqual(reader.bit(), 0)
        reader.advance()
        XCTAssertEqual(reader.bit(), 0)
        reader.advance()
        reader.advance()
        XCTAssertEqual(reader.bit(), 0)
        reader.advance(by: 4)
        XCTAssertEqual(reader.bit(), 1)
        XCTAssertFalse(reader.isAligned)
    }

    func testBit() {
        let reader = LsbBitReader(data: TestHelper.bitData)
        XCTAssertEqual(reader.bit(), 0)
        XCTAssertEqual(reader.bit(), 1)
        XCTAssertEqual(reader.bit(), 0)
        XCTAssertEqual(reader.bit(), 1)
        XCTAssertEqual(reader.bit(), 1)
        XCTAssertEqual(reader.bit(), 0)
        XCTAssertEqual(reader.bit(), 1)
        XCTAssertEqual(reader.bit(), 0)
        XCTAssertEqual(reader.bit(), 0)
        XCTAssertEqual(reader.bit(), 1)
        XCTAssertEqual(reader.bit(), 1)
        XCTAssertFalse(reader.isAligned)
    }

    func testBits() {
        let reader = LsbBitReader(data: TestHelper.bitData)
        XCTAssertEqual(reader.bits(count: 0), [])
        var bits = reader.bits(count: 3)
        XCTAssertEqual(bits, [0, 1, 0])
        bits = reader.bits(count: 8)
        XCTAssertEqual(bits, [1, 1, 0, 1, 0, 0, 1, 1])
        XCTAssertFalse(reader.isAligned)
    }

    func testIntFromBits() {
        let reader: LsbBitReader
        if MemoryLayout<Int>.size == 8 {
            reader = LsbBitReader(data: Data([127, 160, 15, 128,
                                              0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F,
                                              0, 0, 0, 0, 0, 0, 0, 0x80]))
        } else if MemoryLayout<Int>.size == 4 {
            reader = LsbBitReader(data: Data([127, 160, 15, 128, 133, 200, 15,
                                              0xFF, 0xFF, 0xFF, 0x7F, 0, 0, 0, 0x80]))
        } else {
            XCTFail("Unsupported Int bit width.")
            return
        }
        XCTAssertEqual(reader.int(fromBits: 0), 0)
        XCTAssertEqual(reader.int(fromBits: 8), 127)
        XCTAssertEqual(reader.int(fromBits: 3), 0)
        XCTAssertEqual(reader.int(fromBits: 4), 4)
        XCTAssertFalse(reader.isAligned)
        XCTAssertEqual(reader.int(fromBits: 5), 31)
        XCTAssertEqual(reader.int(fromBits: 12), 2048)
        XCTAssertTrue(reader.isAligned)
        XCTAssertEqual(reader.int(fromBits: Int.bitWidth), Int.max)
        XCTAssertEqual(reader.int(fromBits: Int.bitWidth), Int.min)
    }

    func testSignedIntFromBits_SM() {
        let repr = SignedNumberRepresentation.signMagnitude
        let reader: LsbBitReader
        if MemoryLayout<Int>.size == 8 {
            reader = LsbBitReader(data: Data([127, 160, 15, 128, 251, 56, 8,
                                              0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F,
                                              0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]))
        } else if MemoryLayout<Int>.size == 4 {
            reader = LsbBitReader(data: Data([127, 160, 15, 128, 251, 56, 8,
                                              0xFF, 0xFF, 0xFF, 0x7F, 0xFF, 0xFF, 0xFF, 0xFF]))
        } else {
            XCTFail("Unsupported Int bit width.")
            return
        }
        XCTAssertEqual(reader.signedInt(fromBits: 0, representation: repr), 0)
        XCTAssertEqual(reader.signedInt(fromBits: 8, representation: repr), 127)
        XCTAssertEqual(reader.signedInt(fromBits: 3, representation: repr), 0)
        XCTAssertEqual(reader.signedInt(fromBits: 4, representation: repr), 4)
        XCTAssertFalse(reader.isAligned)
        XCTAssertEqual(reader.signedInt(fromBits: 5, representation: repr), -15)
        XCTAssertEqual(reader.signedInt(fromBits: 12, representation: repr), 0)
        XCTAssertTrue(reader.isAligned)
        XCTAssertEqual(reader.signedInt(fromBits: 8, representation: repr), -123)
        XCTAssertEqual(reader.signedInt(fromBits: 12, representation: repr), -56)
        reader.align()
        XCTAssertEqual(reader.signedInt(fromBits: Int.bitWidth, representation: repr), Int.max)
        XCTAssertEqual(reader.signedInt(fromBits: Int.bitWidth, representation: repr), Int.min + 1)
    }

    func testSignedIntFromBits_1C() {
        let repr = SignedNumberRepresentation.oneComplementNegatives
        let reader: LsbBitReader
        if MemoryLayout<Int>.size == 8 {
            reader = LsbBitReader(data: Data([127, 160, 15, 128, 132, 199, 15,
                                              0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F,
                                              0, 0, 0, 0, 0, 0, 0, 0x80]))
        } else if MemoryLayout<Int>.size == 4 {
            reader = LsbBitReader(data: Data([127, 160, 15, 128, 132, 199, 15, 0xFF, 0xFF, 0xFF, 0x7F, 0, 0, 0, 0x80]))
        } else {
            XCTFail("Unsupported Int bit width.")
            return
        }
        XCTAssertEqual(reader.signedInt(fromBits: 0, representation: repr), 0)
        XCTAssertEqual(reader.signedInt(fromBits: 8, representation: repr), 127)
        XCTAssertEqual(reader.signedInt(fromBits: 3, representation: repr), 0)
        XCTAssertEqual(reader.signedInt(fromBits: 4, representation: repr), 4)
        XCTAssertFalse(reader.isAligned)
        XCTAssertEqual(reader.signedInt(fromBits: 5, representation: repr), 0)
        XCTAssertEqual(reader.signedInt(fromBits: 12, representation: repr), -2047)
        XCTAssertTrue(reader.isAligned)
        XCTAssertEqual(reader.signedInt(fromBits: 8, representation: repr), -123)
        XCTAssertEqual(reader.signedInt(fromBits: 12, representation: repr), -56)
        reader.align()
        XCTAssertEqual(reader.signedInt(fromBits: Int.bitWidth, representation: repr), Int.max)
        XCTAssertEqual(reader.signedInt(fromBits: Int.bitWidth, representation: repr), Int.min + 1)
    }

    func testSignedIntFromBits_2C() {
        let repr = SignedNumberRepresentation.twoComplementNegatives
        let reader: LsbBitReader
        if MemoryLayout<Int>.size == 8 {
            reader = LsbBitReader(data: Data([127, 160, 15, 128, 133, 200, 15,
                                              0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F,
                                              0, 0, 0, 0, 0, 0, 0, 0x80]))
        } else if MemoryLayout<Int>.size == 4 {
            reader = LsbBitReader(data: Data([127, 160, 15, 128, 133, 200, 15, 0xFF, 0xFF, 0xFF, 0x7F, 0, 0, 0, 0x80]))
        } else {
            XCTFail("Unsupported Int bit width.")
            return
        }
        XCTAssertEqual(reader.signedInt(fromBits: 0, representation: repr), 0)
        XCTAssertEqual(reader.signedInt(fromBits: 8, representation: repr), 127)
        XCTAssertEqual(reader.signedInt(fromBits: 3, representation: repr), 0)
        XCTAssertEqual(reader.signedInt(fromBits: 4, representation: repr), 4)
        XCTAssertFalse(reader.isAligned)
        XCTAssertEqual(reader.signedInt(fromBits: 5, representation: repr), -1)
        XCTAssertEqual(reader.signedInt(fromBits: 12, representation: repr), -2048)
        XCTAssertTrue(reader.isAligned)
        XCTAssertEqual(reader.signedInt(fromBits: 8, representation: repr), -123)
        XCTAssertEqual(reader.signedInt(fromBits: 12, representation: repr), -56)
        reader.align()
        XCTAssertEqual(reader.signedInt(fromBits: Int.bitWidth, representation: repr), Int.max)
        XCTAssertEqual(reader.signedInt(fromBits: Int.bitWidth, representation: repr), Int.min)
    }

    func testSignedIntFromBits_Biased_E127() {
        let repr = SignedNumberRepresentation.biased(bias: 127)
        let reader: LsbBitReader
        if MemoryLayout<Int>.size == 8 {
            reader = LsbBitReader(data: Data([253, 133, 183, 127, 4, 71, 0, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F]))
        } else if MemoryLayout<Int>.size == 4 {
            reader = LsbBitReader(data: Data([253, 133, 183, 127, 4, 71, 0, 0xFF, 0xFF, 0xFF, 0x7F]))
        } else {
            XCTFail("Unsupported Int bit width.")
            return
        }
        XCTAssertEqual(reader.signedInt(fromBits: 0, representation: repr), 0)
        XCTAssertEqual(reader.signedInt(fromBits: 8, representation: repr), 126)
        XCTAssertEqual(reader.signedInt(fromBits: 8, representation: repr), 6)
        XCTAssertEqual(reader.signedInt(fromBits: 8, representation: repr), 56)
        XCTAssertEqual(reader.signedInt(fromBits: 8, representation: repr), 0)
        XCTAssertEqual(reader.signedInt(fromBits: 8, representation: repr), -123)
        XCTAssertEqual(reader.signedInt(fromBits: 12, representation: repr), -56)
        XCTAssertFalse(reader.isAligned)
        reader.align()
        XCTAssertEqual(reader.signedInt(fromBits: Int.bitWidth, representation: repr), Int.max - 127)
    }

    func testSignedIntFromBits_Biased_E3() {
        let repr = SignedNumberRepresentation.biased(bias: 3)
        let reader: LsbBitReader
        if MemoryLayout<Int>.size == 8 {
            reader = LsbBitReader(data: Data([240, 129, 9, 176, 3, 3, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F]))
        } else if MemoryLayout<Int>.size == 4 {
            reader = LsbBitReader(data: Data([240, 129, 9, 176, 3, 3, 0xFF, 0xFF, 0xFF, 0x7F]))
        } else {
            XCTFail("Unsupported Int bit width.")
            return
        }
        XCTAssertEqual(reader.signedInt(fromBits: 0, representation: repr), 0)
        XCTAssertEqual(reader.signedInt(fromBits: 4, representation: repr), -3)
        XCTAssertFalse(reader.isAligned)
        XCTAssertEqual(reader.signedInt(fromBits: 4, representation: repr), 12)
        XCTAssertTrue(reader.isAligned)
        XCTAssertEqual(reader.signedInt(fromBits: 8, representation: repr), 126)
        XCTAssertEqual(reader.signedInt(fromBits: 12, representation: repr), 6)
        XCTAssertFalse(reader.isAligned)
        XCTAssertEqual(reader.signedInt(fromBits: 6, representation: repr), 56)
        XCTAssertFalse(reader.isAligned)
        reader.align()
        XCTAssertTrue(reader.isAligned)
        XCTAssertEqual(reader.signedInt(fromBits: 8, representation: repr), 0)
        XCTAssertEqual(reader.signedInt(fromBits: Int.bitWidth, representation: repr), Int.max - 3)
    }

    func testSignedIntFromBits_Biased_E1023() {
        let repr = SignedNumberRepresentation.biased(bias: 1023)
        let reader: LsbBitReader
        if MemoryLayout<Int>.size == 8 {
            reader = LsbBitReader(data: Data([0, 0, 255, 3, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F]))
        } else if MemoryLayout<Int>.size == 4 {
            reader = LsbBitReader(data: Data([0, 0, 255, 3, 0xFF, 0xFF, 0xFF, 0x7F]))
        } else {
            XCTFail("Unsupported Int bit width.")
            return
        }
        XCTAssertEqual(reader.signedInt(fromBits: 0, representation: repr), 0)
        XCTAssertEqual(reader.signedInt(fromBits: 11, representation: repr), -1023)
        XCTAssertFalse(reader.isAligned)
        reader.align()
        XCTAssertTrue(reader.isAligned)
        XCTAssertEqual(reader.signedInt(fromBits: 11, representation: repr), 0)
        XCTAssertFalse(reader.isAligned)
        reader.align()
        XCTAssertTrue(reader.isAligned)
        XCTAssertEqual(reader.signedInt(fromBits: Int.bitWidth, representation: repr), Int.max - 1023)
    }

    func testSignedIntFromBits_RN2() {
        let repr = SignedNumberRepresentation.radixNegativeTwo
        let reader = LsbBitReader(data: Data([90, 1, 12]))
        XCTAssertEqual(reader.signedInt(fromBits: 0, representation: repr), 0)
        XCTAssertEqual(reader.signedInt(fromBits: 5, representation: repr), 6)
        XCTAssertFalse(reader.isAligned)
        XCTAssertEqual(reader.signedInt(fromBits: 3, representation: repr), -2)
        XCTAssertTrue(reader.isAligned)
        XCTAssertEqual(reader.signedInt(fromBits: 12, representation: repr), -1023)
        XCTAssertFalse(reader.isAligned)
        XCTAssertEqual(reader.signedInt(fromBits: 4, representation: repr), 0)
        XCTAssertTrue(reader.isAligned)
    }

    func testByteFromBits() {
        var reader = LsbBitReader(data: TestHelper.bitData)
        XCTAssertEqual(reader.byte(fromBits: 0), 0)
        var num = reader.byte(fromBits: 3)
        XCTAssertEqual(num, 2)
        num = reader.byte(fromBits: 8)
        XCTAssertEqual(num, 203)
        XCTAssertFalse(reader.isAligned)
        reader.align()
        XCTAssertTrue(reader.isAligned)
        XCTAssertEqual(reader.byte(fromBits: 8), 0x57)
        reader = LsbBitReader(data: Data([UInt8.max, UInt8.min]))
        XCTAssertEqual(reader.byte(fromBits: 8), UInt8.max)
        XCTAssertEqual(reader.byte(fromBits: 8), UInt8.min)
    }

    func testUint16FromBits() {
        var reader = LsbBitReader(data: TestHelper.bitData)
        XCTAssertEqual(reader.uint16(fromBits: 0), 0)
        var num = reader.uint16(fromBits: 3)
        XCTAssertEqual(num, 2)
        num = reader.uint16(fromBits: 8)
        XCTAssertEqual(num, 203)
        XCTAssertFalse(reader.isAligned)
        reader.align()
        XCTAssertTrue(reader.isAligned)
        XCTAssertEqual(reader.uint16(fromBits: 16), 0x1457)
        reader = LsbBitReader(data: Data(Array(repeating: 0xFF, count: 2)))
        XCTAssertEqual(reader.uint16(fromBits: 16), UInt16.max)
        reader = LsbBitReader(data: Data(Array(repeating: 0, count: 2)))
        XCTAssertEqual(reader.uint16(fromBits: 16), UInt16.min)
    }

    func testUint32FromBits() {
        var reader = LsbBitReader(data: TestHelper.bitData)
        XCTAssertEqual(reader.uint32(fromBits: 0), 0)
        var num = reader.uint32(fromBits: 3)
        XCTAssertEqual(num, 2)
        num = reader.uint32(fromBits: 8)
        XCTAssertEqual(num, 203)
        XCTAssertFalse(reader.isAligned)
        reader.align()
        XCTAssertTrue(reader.isAligned)
        XCTAssertEqual(reader.uint32(fromBits: 32), 0xCCAB_1457)
        reader = LsbBitReader(data: Data(Array(repeating: 0xFF, count: 4)))
        XCTAssertEqual(reader.uint32(fromBits: 32), UInt32.max)
        reader = LsbBitReader(data: Data(Array(repeating: 0, count: 4)))
        XCTAssertEqual(reader.uint32(fromBits: 32), UInt32.min)
    }

    func testUint64FromBits() {
        var reader = LsbBitReader(data: TestHelper.bitData)
        XCTAssertEqual(reader.uint64(fromBits: 0), 0)
        var num = reader.uint64(fromBits: 3)
        XCTAssertEqual(num, 2)
        num = reader.uint64(fromBits: 8)
        XCTAssertEqual(num, 203)
        XCTAssertFalse(reader.isAligned)
        reader.align()
        XCTAssertTrue(reader.isAligned)
        XCTAssertEqual(reader.uint64(fromBits: 64), 0x00EA_882D_CCAB_1457)
        reader = LsbBitReader(data: Data(Array(repeating: 0xFF, count: 8)))
        XCTAssertEqual(reader.uint64(fromBits: 64), UInt64.max)
        reader = LsbBitReader(data: Data(Array(repeating: 0, count: 8)))
        XCTAssertEqual(reader.uint64(fromBits: 64), UInt64.min)
    }

    func testIsAligned() {
        let reader = LsbBitReader(data: TestHelper.bitData)
        _ = reader.bits(count: 12)
        XCTAssertFalse(reader.isAligned)
        _ = reader.bits(count: 4)
        XCTAssertTrue(reader.isAligned)
    }

    func testAlign() {
        let reader = LsbBitReader(data: TestHelper.bitData)
        _ = reader.bits(count: 6)
        XCTAssertFalse(reader.isAligned)
        reader.align()
        XCTAssertTrue(reader.isAligned)
        _ = reader.byte()
        reader.align()
        XCTAssertTrue(reader.isAligned)
    }

    func testBytesLeft() {
        let reader = LsbBitReader(data: TestHelper.bitData)
        _ = reader.bits(count: 6)
        XCTAssertEqual(reader.bytesLeft, 10)
        _ = reader.bits(count: 2)
        XCTAssertEqual(reader.bytesLeft, 9)
        _ = reader.byte()
        XCTAssertEqual(reader.bytesLeft, 8)
        reader.offset = reader.data.endIndex - 1
        XCTAssertEqual(reader.bytesLeft, 1)
        _ = reader.bits(count: 2)
        XCTAssertEqual(reader.bytesLeft, 1)
        _ = reader.bits(count: 6)
        XCTAssertEqual(reader.bytesLeft, 0)
    }

    func testBytesRead() {
        let reader = LsbBitReader(data: TestHelper.bitData)
        _ = reader.bits(count: 6)
        XCTAssertEqual(reader.bytesRead, 0)
        _ = reader.bits(count: 2)
        XCTAssertEqual(reader.bytesRead, 1)
        _ = reader.byte()
        XCTAssertEqual(reader.bytesRead, 2)
        reader.offset = reader.data.endIndex - 1
        XCTAssertEqual(reader.bytesRead, 9)
        _ = reader.bits(count: 2)
        XCTAssertEqual(reader.bytesRead, 9)
        _ = reader.bits(count: 6)
        XCTAssertEqual(reader.bytesRead, 10)
    }

    func testBitReaderByte() {
        let reader = LsbBitReader(data: TestHelper.bitData)
        var byte = reader.byte()
        XCTAssertEqual(byte, 0x5A)
        XCTAssertTrue(reader.isAligned)
        XCTAssertFalse(reader.isFinished)
        byte = reader.byte()
        XCTAssertEqual(byte, 0xD6)
        XCTAssertTrue(reader.isAligned)
        XCTAssertFalse(reader.isFinished)
    }

    func testBitReaderBytes() {
        let reader = LsbBitReader(data: TestHelper.bitData)
        XCTAssertEqual(reader.bytes(count: 0), [])
        let bytes = reader.bytes(count: 2)
        XCTAssertEqual(bytes, [0x5A, 0xD6])
        XCTAssertTrue(reader.isAligned)
        XCTAssertFalse(reader.isFinished)
    }

    func testBitReaderIntFromBytes() {
        let reader = LsbBitReader(data: TestHelper.bitData)
        XCTAssertEqual(reader.int(fromBytes: 0), 0)
        XCTAssertEqual(reader.int(fromBytes: 2), 54874)
        XCTAssertTrue(reader.isAligned)
        XCTAssertFalse(reader.isFinished)
    }

    func testBitReaderUint16() {
        let reader = LsbBitReader(data: TestHelper.bitData)
        XCTAssertEqual(reader.uint16(fromBytes: 0), 0)
        let num = reader.uint16()
        XCTAssertEqual(num, 54874)
        XCTAssertTrue(reader.isAligned)
        XCTAssertFalse(reader.isFinished)
    }

    func testBitReaderUint32FromBytes() {
        let reader = LsbBitReader(data: TestHelper.bitData)
        XCTAssertEqual(reader.uint32(fromBytes: 0), 0)
        let num = reader.uint32(fromBytes: 3)
        XCTAssertEqual(num, 5_756_506)
        XCTAssertTrue(reader.isAligned)
        XCTAssertFalse(reader.isFinished)
    }

    func testBitReaderNonZeroStartIndex() {
        var reader = LsbBitReader(data: TestHelper.bitData[1...])
        XCTAssertEqual(reader.offset, 1)
        XCTAssertEqual(reader.byte(), 0xD6)
        reader = LsbBitReader(data: TestHelper.bitData[1...])
        XCTAssertEqual(reader.offset, 1)
        XCTAssertEqual(reader.bytes(count: 1), [0xD6])
        reader = LsbBitReader(data: TestHelper.bitData[1...])
        XCTAssertEqual(reader.offset, 1)
        XCTAssertEqual(reader.bit(), 0)
        XCTAssertEqual(reader.bits(count: 3), [1, 1, 0])
        XCTAssertEqual(reader.signedInt(fromBits: 4), -3)
    }

    func testConvertedByteReader() {
        let byteReader = LittleEndianByteReader(data: TestHelper.bitData)
        _ = byteReader.byte()
        var reader = LsbBitReader(byteReader)
        XCTAssertEqual(reader.byte(), 0xD6)
        XCTAssertEqual(reader.bits(count: 4), [1, 1, 1, 0])
        XCTAssertEqual(reader.signedInt(fromBits: 4), 5)
        reader = LsbBitReader(byteReader)
        XCTAssertEqual(reader.bits(count: 4), [0, 1, 1, 0])
        XCTAssertEqual(reader.signedInt(fromBits: 4), -3)
    }

    func testBitsLeft() {
        let reader = LsbBitReader(data: TestHelper.bitData)
        XCTAssertEqual(reader.bitsLeft, 80)
        _ = reader.bits(count: 4)
        XCTAssertEqual(reader.bitsLeft, 76)
        _ = reader.bits(count: 4)
        XCTAssertEqual(reader.bitsLeft, 72)
        _ = reader.bits(count: 2)
        XCTAssertEqual(reader.bitsLeft, 70)
        _ = reader.bits(count: 6)
        XCTAssertEqual(reader.bitsLeft, 64)
        _ = reader.uint64(fromBits: 64)
        XCTAssertEqual(reader.bitsLeft, 0)
    }

    func testBitsRead() {
        let reader = LsbBitReader(data: TestHelper.bitData)
        XCTAssertEqual(reader.bitsRead, 0)
        _ = reader.bits(count: 4)
        XCTAssertEqual(reader.bitsRead, 4)
        _ = reader.bits(count: 4)
        XCTAssertEqual(reader.bitsRead, 8)
        _ = reader.bits(count: 2)
        XCTAssertEqual(reader.bitsRead, 10)
        _ = reader.bits(count: 6)
        XCTAssertEqual(reader.bitsRead, 16)
    }

    func testIsFinished() {
        let reader = LsbBitReader(data: TestHelper.bitData)
        _ = reader.bytes(count: 4)
        XCTAssertFalse(reader.isFinished)
        _ = reader.bytes(count: 5)
        XCTAssertFalse(reader.isFinished)
        _ = reader.bits(count: 5)
        XCTAssertFalse(reader.isFinished)
        XCTAssertTrue(reader.bitsLeft > 0)
        _ = reader.bits(count: 3)
        XCTAssertTrue(reader.isFinished)
        XCTAssertTrue(reader.bitsLeft == 0)
    }
}
