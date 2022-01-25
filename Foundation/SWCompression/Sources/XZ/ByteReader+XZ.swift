// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import BitByteData
import Foundation

extension LittleEndianByteReader {
    func multiByteDecode() throws -> Int {
        var i = 1
        var result = byte().toInt()
        if result <= 127 {
            return result
        }
        result &= 0x7F
        while true {
            let byte = byte()
            if i >= 9 || byte == 0x00 {
                throw XZError.multiByteIntegerError
            }
            result += (byte.toInt() & 0x7F) << (7 * i)
            i += 1

            if byte & 0x80 == 0 {
                break
            }
        }
        return result
    }
}
