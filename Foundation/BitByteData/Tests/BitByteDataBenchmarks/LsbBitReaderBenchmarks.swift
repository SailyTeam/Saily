// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import BitByteData
import XCTest

class LsbBitReaderBenchmarks: XCTestCase {
    func testAdvance() {
        measure {
            let reader = LsbBitReader(data: Data(count: 10_485_760)) // 10 MB

            for _ in 0 ..< 5_000_000 * 8 {
                reader.advance()
            }
        }
    }

    func testAdvanceRealistic() {
        measure {
            let reader = LsbBitReader(data: Data(count: 10_485_760)) // 10 MB

            for _ in 0 ..< 9_300_000 {
                reader.advance(by: 6)
                reader.advance(by: 3)
            }
        }
    }

    func testBit() {
        measure {
            let reader = LsbBitReader(data: Data(count: 10_485_760)) // 10 MB

            for _ in 0 ..< 5_000_000 * 8 {
                _ = reader.bit()
            }
        }
    }

    func testBits() {
        measure {
            let reader = LsbBitReader(data: Data(count: 10_485_760)) // 10 MB

            for _ in 0 ..< 1_000_000 * 8 {
                _ = reader.bits(count: 5)
            }
        }
    }

    func testIntFromBits() {
        measure {
            let reader = LsbBitReader(data: Data(count: 10_485_760)) // 10 MB

            for _ in 0 ..< 1_000_000 * 4 {
                _ = reader.int(fromBits: 10)
            }
        }
    }

    func testSignedInt_SM_pos() {
        var bytes = [UInt8]()
        for _ in 0 ..< 5_242_880 { // 5 MB * 2
            bytes.append(0xD)
            bytes.append(0x37)
        }

        measure {
            let reader = LsbBitReader(data: Data(bytes))

            for _ in 0 ..< 5_000_000 {
                _ = reader.signedInt(fromBits: 16, representation: .signMagnitude)
            }
        }
    }

    func testSignedInt_SM_neg() {
        var bytes = [UInt8]()
        for _ in 0 ..< 5_242_880 { // 5 MB * 2
            bytes.append(0xD)
            bytes.append(0xB7)
        }

        measure {
            let reader = LsbBitReader(data: Data(bytes))

            for _ in 0 ..< 5_000_000 {
                _ = reader.signedInt(fromBits: 16, representation: .signMagnitude)
            }
        }
    }

    func testSignedInt_1C_pos() {
        var bytes = [UInt8]()
        for _ in 0 ..< 5_242_880 { // 5 MB * 2
            bytes.append(0xD)
            bytes.append(0x37)
        }

        measure {
            let reader = LsbBitReader(data: Data(bytes))

            for _ in 0 ..< 5_000_000 {
                _ = reader.signedInt(fromBits: 16, representation: .oneComplementNegatives)
            }
        }
    }

    func testSignedInt_1C_neg() {
        var bytes = [UInt8]()
        for _ in 0 ..< 5_242_880 { // 5 MB * 2
            bytes.append(0xD)
            bytes.append(0xB7)
        }

        measure {
            let reader = LsbBitReader(data: Data(bytes))

            for _ in 0 ..< 5_000_000 {
                _ = reader.signedInt(fromBits: 16, representation: .oneComplementNegatives)
            }
        }
    }

    func testSignedInt_2C_pos() {
        var bytes = [UInt8]()
        for _ in 0 ..< 5_242_880 { // 5 MB * 2
            bytes.append(0xD)
            bytes.append(0x37)
        }

        measure {
            let reader = LsbBitReader(data: Data(bytes))

            for _ in 0 ..< 5_000_000 {
                _ = reader.signedInt(fromBits: 16, representation: .twoComplementNegatives)
            }
        }
    }

    func testSignedInt_2C_neg() {
        var bytes = [UInt8]()
        for _ in 0 ..< 5_242_880 { // 5 MB * 2
            bytes.append(0xD)
            bytes.append(0xB7)
        }

        measure {
            let reader = LsbBitReader(data: Data(bytes))

            for _ in 0 ..< 5_000_000 {
                _ = reader.signedInt(fromBits: 16, representation: .twoComplementNegatives)
            }
        }
    }

    func testSignedInt_E127() {
        var bytes = [UInt8]()
        for _ in 0 ..< 5_242_880 { // 5 MB * 2
            bytes.append(0x6D)
            bytes.append(0xB7)
        }

        measure {
            let reader = LsbBitReader(data: Data(bytes))

            for _ in 0 ..< 5_000_000 {
                _ = reader.signedInt(fromBits: 7, representation: .biased(bias: 127))
            }
        }
    }

    func testSignedInt_RN2() {
        var bytes = [UInt8]()
        for _ in 0 ..< 5_242_880 { // 5 MB * 2
            bytes.append(0x6D)
            bytes.append(0xB7)
        }

        measure {
            let reader = LsbBitReader(data: Data(bytes))

            for _ in 0 ..< 5_000_000 {
                _ = reader.signedInt(fromBits: 13, representation: .radixNegativeTwo)
            }
        }
    }

    func testByteFromBits() {
        measure {
            let reader = LsbBitReader(data: Data(count: 10_485_760)) // 10 MB

            for _ in 0 ..< 1_000_000 * 8 {
                _ = reader.byte(fromBits: 6)
            }
        }
    }

    func testUint16FromBits() {
        measure {
            let reader = LsbBitReader(data: Data(count: 10_485_760)) // 10 MB

            for _ in 0 ..< 1_000_000 * 4 {
                _ = reader.uint16(fromBits: 13)
            }
        }
    }

    func testUint32FromBits() {
        measure {
            let reader = LsbBitReader(data: Data(count: 10_485_760)) // 10 MB

            for _ in 0 ..< 1_000_000 * 3 {
                _ = reader.uint32(fromBits: 23)
            }
        }
    }

    func testUint64FromBits() {
        measure {
            let reader = LsbBitReader(data: Data(count: 10_485_760)) // 10 MB

            for _ in 0 ..< 1_000_000 {
                _ = reader.uint64(fromBits: 52)
            }
        }
    }
}
