// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import BitByteData
import XCTest

class LittleEndianByteReaderBenchmarks: XCTestCase {
    func testByte() {
        measure {
            let reader = LittleEndianByteReader(data: Data(count: 10_485_760)) // 10 MB

            for _ in 0 ..< 5_000_000 {
                _ = reader.byte()
            }
        }
    }

    func testBytes() {
        measure {
            let reader = LittleEndianByteReader(data: Data(count: 10_485_760)) // 10 MB

            for _ in 0 ..< 500_000 {
                _ = reader.bytes(count: 20)
            }
        }
    }

    func testIntFromBytes() {
        measure {
            let reader = LittleEndianByteReader(data: Data(count: 10_485_760)) // 10 MB

            for _ in 0 ..< 1_000_000 {
                _ = reader.int(fromBytes: 7)
            }
        }
    }

    func testUint16() {
        measure {
            let reader = LittleEndianByteReader(data: Data(count: 10_485_760)) // 10 MB

            for _ in 0 ..< 1_000_000 {
                _ = reader.uint16()
            }
        }
    }

    func testUint16_FB() { // For comparison with no-argument version.
        measure {
            let reader = LittleEndianByteReader(data: Data(count: 10_485_760)) // 10 MB

            for _ in 0 ..< 1_000_000 {
                _ = reader.uint16(fromBytes: 2)
            }
        }
    }

    func testUint16FromBytes() {
        measure {
            let reader = LittleEndianByteReader(data: Data(count: 10_485_760)) // 10 MB

            for _ in 0 ..< 1_000_000 {
                _ = reader.uint16(fromBytes: 1)
            }
        }
    }

    func testUint32() {
        measure {
            let reader = LittleEndianByteReader(data: Data(count: 10_485_760)) // 10 MB

            for _ in 0 ..< 1_000_000 {
                _ = reader.uint32()
            }
        }
    }

    func testUint32_FB() { // For comparison with no-argument version.
        measure {
            let reader = LittleEndianByteReader(data: Data(count: 10_485_760)) // 10 MB

            for _ in 0 ..< 1_000_000 {
                _ = reader.uint32(fromBytes: 4)
            }
        }
    }

    func testUint32FromBytes() {
        measure {
            let reader = LittleEndianByteReader(data: Data(count: 10_485_760)) // 10 MB

            for _ in 0 ..< 1_000_000 {
                _ = reader.uint32(fromBytes: 3)
            }
        }
    }

    func testUint64() {
        measure {
            let reader = LittleEndianByteReader(data: Data(count: 10_485_760)) // 10 MB

            for _ in 0 ..< 1_000_000 {
                _ = reader.uint64()
            }
        }
    }

    func testUint64_FB() { // For comparison with no-argument version.
        measure {
            let reader = LittleEndianByteReader(data: Data(count: 10_485_760)) // 10 MB

            for _ in 0 ..< 1_000_000 {
                _ = reader.uint64(fromBytes: 8)
            }
        }
    }

    func testUint64FromBytes() {
        measure {
            let reader = LittleEndianByteReader(data: Data(count: 10_485_760)) // 10 MB

            for _ in 0 ..< 1_000_000 {
                _ = reader.uint64(fromBytes: 7)
            }
        }
    }
}
