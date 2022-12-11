// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import BitByteData
import XCTest

class MsbBitWriterTests: XCTestCase {
    func testWriteBit() {
        let writer = MsbBitWriter()
        writer.write(bit: 0)
        writer.write(bit: 1)
        writer.write(bit: 0)
        writer.write(bit: 1)
        writer.write(bit: 1)
        writer.align()
        XCTAssertEqual(writer.data, Data([88]))
    }

    func testWriteBitsArray() {
        let writer = MsbBitWriter()
        writer.write(bits: [1, 1, 0, 0, 1, 0, 1, 0, 0, 1, 1])
        writer.align()
        XCTAssertEqual(writer.data, Data([202, 96]))
    }

    func testWriteNumber() {
        let writer = MsbBitWriter()
        writer.write(number: 255, bitsCount: 8)
        XCTAssertEqual(writer.data, Data([255]))
        writer.write(number: 6, bitsCount: 3)
        XCTAssertEqual(writer.data, Data([255]))
        writer.write(number: 103, bitsCount: 7)
        XCTAssertEqual(writer.data, Data([255, 217]))
        writer.align()
        XCTAssertEqual(writer.data, Data([255, 217, 192]))
        writer.write(number: -123, bitsCount: 8)
        XCTAssertEqual(writer.data, Data([255, 217, 192, 133]))
        writer.write(number: -56, bitsCount: 12)
        XCTAssertEqual(writer.data, Data([255, 217, 192, 133, 252]))
        writer.align()
        XCTAssertEqual(writer.data, Data([255, 217, 192, 133, 252, 128]))
        writer.write(number: Int.max, bitsCount: Int.bitWidth)
        writer.write(number: Int.min, bitsCount: Int.bitWidth)
        if Int.bitWidth == 64 {
            XCTAssertEqual(writer.data, Data([255, 217, 192, 133, 252, 128,
                                              0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
                                              0x80, 0, 0, 0, 0, 0, 0, 0]))
        } else if Int.bitWidth == 32 {
            XCTAssertEqual(writer.data, Data([255, 217, 192, 133, 252, 128, 0x7F, 0xFF, 0xFF, 0xFF, 0x80, 0, 0, 0]))
        }
    }

    func testWriteSignedNumber_SM() {
        let repr = SignedNumberRepresentation.signMagnitude
        let writer = MsbBitWriter()
        writer.write(signedNumber: 127, bitsCount: 8, representation: repr)
        XCTAssertEqual(writer.data, Data([127]))
        writer.write(signedNumber: 6, bitsCount: 4, representation: repr)
        XCTAssertEqual(writer.data, Data([127]))
        writer.write(signedNumber: 56, bitsCount: 7, representation: repr)
        XCTAssertEqual(writer.data, Data([127, 103]))
        writer.align()
        XCTAssertEqual(writer.data, Data([127, 103, 0]))
        writer.write(signedNumber: -123, bitsCount: 8, representation: repr)
        XCTAssertEqual(writer.data, Data([127, 103, 0, 251]))
        writer.write(signedNumber: -56, bitsCount: 12, representation: repr)
        XCTAssertEqual(writer.data, Data([127, 103, 0, 251, 131]))
        writer.align()
        XCTAssertEqual(writer.data, Data([127, 103, 0, 251, 131, 128]))
        writer.write(signedNumber: Int.max, bitsCount: Int.bitWidth, representation: repr)
        writer.write(signedNumber: Int.min + 1, bitsCount: Int.bitWidth, representation: repr)
        if Int.bitWidth == 64 {
            XCTAssertEqual(writer.data, Data([127, 103, 0, 251, 131, 128,
                                              0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
                                              0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]))
        } else if Int.bitWidth == 32 {
            XCTAssertEqual(writer.data, Data([127, 103, 0, 251, 131, 128, 0xFF, 0xFF, 0xFF, 0xFE, 0xFF, 0xFF, 0xFF, 0xFF]))
        }
    }

    func testWriteSignedNumber_1C() {
        let repr = SignedNumberRepresentation.oneComplementNegatives
        let writer = MsbBitWriter()
        writer.write(signedNumber: 127, bitsCount: 8, representation: repr)
        XCTAssertEqual(writer.data, Data([127]))
        writer.write(signedNumber: 6, bitsCount: 4, representation: repr)
        XCTAssertEqual(writer.data, Data([127]))
        writer.write(signedNumber: 56, bitsCount: 7, representation: repr)
        XCTAssertEqual(writer.data, Data([127, 103]))
        writer.align()
        XCTAssertEqual(writer.data, Data([127, 103, 0]))
        writer.write(signedNumber: -123, bitsCount: 8, representation: repr)
        XCTAssertEqual(writer.data, Data([127, 103, 0, 132]))
        writer.write(signedNumber: -56, bitsCount: 12, representation: repr)
        XCTAssertEqual(writer.data, Data([127, 103, 0, 132, 252]))
        writer.align()
        XCTAssertEqual(writer.data, Data([127, 103, 0, 132, 252, 112]))
        writer.write(signedNumber: Int.max, bitsCount: Int.bitWidth, representation: repr)
        writer.write(signedNumber: Int.min + 1, bitsCount: Int.bitWidth, representation: repr)
        if Int.bitWidth == 64 {
            XCTAssertEqual(writer.data, Data([127, 103, 0, 132, 252, 112,
                                              0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
                                              0x80, 0, 0, 0, 0, 0, 0, 0]))
        } else if Int.bitWidth == 32 {
            XCTAssertEqual(writer.data, Data([127, 103, 0, 132, 252, 112, 0x7F, 0xFF, 0xFF, 0xFF, 0x80, 0, 0, 0]))
        }
    }

    func testWriteSignedNumber_2C() {
        let repr = SignedNumberRepresentation.twoComplementNegatives
        let writer = MsbBitWriter()
        writer.write(signedNumber: 127, bitsCount: 8, representation: repr)
        XCTAssertEqual(writer.data, Data([127]))
        writer.write(signedNumber: 6, bitsCount: 4, representation: repr)
        XCTAssertEqual(writer.data, Data([127]))
        writer.write(signedNumber: 56, bitsCount: 7, representation: repr)
        XCTAssertEqual(writer.data, Data([127, 103]))
        writer.align()
        XCTAssertEqual(writer.data, Data([127, 103, 0]))
        writer.write(signedNumber: -123, bitsCount: 8, representation: repr)
        XCTAssertEqual(writer.data, Data([127, 103, 0, 133]))
        writer.write(signedNumber: -56, bitsCount: 12, representation: repr)
        XCTAssertEqual(writer.data, Data([127, 103, 0, 133, 252]))
        writer.align()
        XCTAssertEqual(writer.data, Data([127, 103, 0, 133, 252, 128]))
        writer.write(signedNumber: Int.max, bitsCount: Int.bitWidth, representation: repr)
        writer.write(signedNumber: Int.min, bitsCount: Int.bitWidth, representation: repr)
        if Int.bitWidth == 64 {
            XCTAssertEqual(writer.data, Data([127, 103, 0, 133, 252, 128,
                                              0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
                                              0x80, 0, 0, 0, 0, 0, 0, 0]))
        } else if Int.bitWidth == 32 {
            XCTAssertEqual(writer.data, Data([127, 103, 0, 133, 252, 128, 0x7F, 0xFF, 0xFF, 0xFF, 0x80, 0, 0, 0]))
        }
    }

    func testWriteSignedNumber_Biased_E127() {
        let repr = SignedNumberRepresentation.biased(bias: 127)
        let writer = MsbBitWriter()
        writer.write(signedNumber: 126, bitsCount: 8, representation: repr)
        XCTAssertEqual(writer.data, Data([253]))
        writer.write(signedNumber: 6, bitsCount: 8, representation: repr)
        XCTAssertEqual(writer.data, Data([253, 133]))
        writer.write(signedNumber: 56, bitsCount: 8, representation: repr)
        XCTAssertEqual(writer.data, Data([253, 133, 183]))
        writer.write(signedNumber: 0, bitsCount: 8, representation: repr)
        XCTAssertEqual(writer.data, Data([253, 133, 183, 127]))
        writer.align()
        XCTAssertEqual(writer.data, Data([253, 133, 183, 127]))
        writer.write(signedNumber: -123, bitsCount: 8, representation: repr)
        XCTAssertEqual(writer.data, Data([253, 133, 183, 127, 4]))
        writer.write(signedNumber: -56, bitsCount: 12, representation: repr)
        XCTAssertEqual(writer.data, Data([253, 133, 183, 127, 4, 4]))
        writer.align()
        XCTAssertEqual(writer.data, Data([253, 133, 183, 127, 4, 4, 112]))
        writer.write(signedNumber: Int.max - 127, bitsCount: Int.bitWidth, representation: repr)
        if Int.bitWidth == 64 {
            XCTAssertEqual(writer.data, Data([253, 133, 183, 127, 4, 4, 112, 0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]))
        } else if Int.bitWidth == 32 {
            XCTAssertEqual(writer.data, Data([253, 133, 183, 127, 4, 4, 112, 0x7F, 0xFF, 0xFF, 0xFF]))
        }
    }

    func testWriteSignedNumber_Biased_E3() {
        let repr = SignedNumberRepresentation.biased(bias: 3)
        let writer = MsbBitWriter()
        writer.write(signedNumber: -3, bitsCount: 4, representation: repr)
        XCTAssertFalse(writer.isAligned)
        writer.write(signedNumber: 12, bitsCount: 4, representation: repr)
        XCTAssertTrue(writer.isAligned)
        XCTAssertEqual(writer.data, Data([15]))
        writer.write(signedNumber: 126, bitsCount: 8, representation: repr)
        XCTAssertEqual(writer.data, Data([15, 129]))
        writer.write(signedNumber: 6, bitsCount: 12, representation: repr)
        XCTAssertFalse(writer.isAligned)
        XCTAssertEqual(writer.data, Data([15, 129, 0]))
        writer.write(signedNumber: 56, bitsCount: 6, representation: repr)
        XCTAssertFalse(writer.isAligned)
        XCTAssertEqual(writer.data, Data([15, 129, 0, 158]))
        writer.align()
        XCTAssertTrue(writer.isAligned)
        XCTAssertEqual(writer.data, Data([15, 129, 0, 158, 192]))
        writer.write(signedNumber: 0, bitsCount: 8, representation: repr)
        XCTAssertEqual(writer.data, Data([15, 129, 0, 158, 192, 3]))
        writer.write(signedNumber: Int.max - 3, bitsCount: Int.bitWidth, representation: repr)
        if Int.bitWidth == 64 {
            XCTAssertEqual(writer.data, Data([15, 129, 0, 158, 192, 3, 0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]))
        } else if Int.bitWidth == 32 {
            XCTAssertEqual(writer.data, Data([15, 129, 0, 158, 192, 3, 0x7F, 0xFF, 0xFF, 0xFF]))
        }
    }

    func testWriteSignedNumber_Biased_E1023() {
        let repr = SignedNumberRepresentation.biased(bias: 1023)
        let writer = MsbBitWriter()
        writer.write(signedNumber: -1023, bitsCount: 11, representation: repr)
        XCTAssertFalse(writer.isAligned)
        XCTAssertEqual(writer.data, Data([0]))
        writer.align()
        XCTAssertTrue(writer.isAligned)
        XCTAssertEqual(writer.data, Data([0, 0]))
        writer.write(signedNumber: 0, bitsCount: 11, representation: repr)
        XCTAssertFalse(writer.isAligned)
        XCTAssertEqual(writer.data, Data([0, 0, 127]))
        writer.align()
        XCTAssertTrue(writer.isAligned)
        XCTAssertEqual(writer.data, Data([0, 0, 127, 224]))
        writer.write(signedNumber: Int.max - 1023, bitsCount: Int.bitWidth, representation: repr)
        if Int.bitWidth == 64 {
            XCTAssertEqual(writer.data, Data([0, 0, 127, 224, 0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]))
        } else if Int.bitWidth == 32 {
            XCTAssertEqual(writer.data, Data([0, 0, 127, 224, 0x7F, 0xFF, 0xFF, 0xFF]))
        }
    }

    func testWriteSignedNumber_RN2() {
        let repr = SignedNumberRepresentation.radixNegativeTwo
        let writer = MsbBitWriter()
        writer.write(signedNumber: 6, bitsCount: 5, representation: repr)
        writer.write(signedNumber: -2, bitsCount: 3, representation: repr)
        XCTAssertEqual(writer.data, Data([210]))
        writer.write(signedNumber: -1023, bitsCount: 12, representation: repr)
        XCTAssertFalse(writer.isAligned)
        XCTAssertEqual(writer.data, Data([210, 192]))
        writer.write(signedNumber: 0, bitsCount: 4, representation: repr)
        XCTAssertTrue(writer.isAligned)
        XCTAssertEqual(writer.data, Data([210, 192, 16]))
    }

    func testWriteUnsignedNumber() {
        let writer = MsbBitWriter()
        writer.write(unsignedNumber: UInt.max, bitsCount: UInt.bitWidth)
        if UInt.bitWidth == 64 {
            XCTAssertEqual(writer.data, Data([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]))
        } else if UInt.bitWidth == 32 {
            XCTAssertEqual(writer.data, Data([0xFF, 0xFF, 0xFF, 0xFF]))
        }
    }

    func testAppendByte() {
        let writer = MsbBitWriter()
        writer.append(byte: 0xCA)
        XCTAssertEqual(writer.data, Data([0xCA]))
        writer.append(byte: 0xFF)
        XCTAssertEqual(writer.data, Data([0xCA, 0xFF]))
        writer.append(byte: 0)
        XCTAssertEqual(writer.data, Data([0xCA, 0xFF, 0]))
    }

    func testAlign() {
        let writer = MsbBitWriter()
        writer.align()
        XCTAssertEqual(writer.data, Data())
        XCTAssertTrue(writer.isAligned)
    }

    func testIsAligned() {
        let writer = MsbBitWriter()
        writer.write(bits: [0, 1, 0])
        XCTAssertFalse(writer.isAligned)
        writer.write(bits: [0, 1, 0, 1, 0])
        XCTAssertTrue(writer.isAligned)
        writer.write(bit: 0)
        XCTAssertFalse(writer.isAligned)
        writer.align()
        XCTAssertTrue(writer.isAligned)
    }

    func testNamingConsistency() {
        let writer = MsbBitWriter()
        writer.write(signedNumber: 14582, bitsCount: 15)
        writer.align()
        let reader = MsbBitReader(data: writer.data)
        XCTAssertEqual(reader.signedInt(fromBits: 15), 14582)
    }
}
