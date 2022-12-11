// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation

enum TestHelper {
    static let bitData = Data([0x5A, 0xD6, 0x57, 0x14, 0xAB, 0xCC, 0x2D, 0x88, 0xEA, 0x00])

    static let byteData = Data([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08])

    static func randomBytes(count: Int) -> [UInt8] {
        var bytes = [UInt8]()
        bytes.reserveCapacity(count)
        for _ in 0 ..< count {
            bytes.append(UInt8.random(in: 0 ... UInt8.max))
        }
        return bytes
    }
}
