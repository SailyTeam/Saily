// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import BitByteData
import Foundation

extension MsbBitReader {
    /// Abbreviation for "sevenZipMultiByteDecode".
    func szMbd() -> Int {
        align()
        let firstByte = byte().toInt()
        var mask = 0x80
        var value = 0
        for i in 0 ..< 8 {
            if firstByte & mask == 0 {
                value |= ((firstByte & (mask &- 1)) << (8 * i))
                break
            }
            value |= byte().toInt() << (8 * i)
            mask >>= 1
        }
        return value
    }

    func defBits(count: Int) -> [UInt8] {
        align()
        let allDefined = byte()
        let definedBits: [UInt8]
        if allDefined == 0 {
            definedBits = bits(count: count)
        } else {
            definedBits = Array(repeating: 1, count: count)
        }
        return definedBits
    }
}
