// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation

extension Data {
    @inline(__always)
    mutating func appendAsTarBlock(_ data: Data) {
        append(data)
        let paddingSize = data.count.roundTo512() - data.count
        append(Data(count: paddingSize))
    }

    mutating func append(tarInt value: Int?, maxLength: Int) {
        guard var value = value else {
            // No value; fill field with NULLs.
            append(Data(count: maxLength))
            return
        }

        let maxOctalValue = (1 << (maxLength * 3)) - 1
        guard value > maxOctalValue || value < 0 else {
            // Normal octal encoding.
            append(Data(String(value, radix: 8).utf8).zeroPad(maxLength))
            return
        }

        // Base-256 encoding.
        // As long as we have at least 8 bytes for our value, conversion to base-256 will always succeed, since (64-bit)
        // Int.max neatly fits into 8 bytes of 256-base encoding.
        assert(maxLength >= 8 && Int.bitWidth <= 64)
        var buffer = Array(repeating: 0 as UInt8, count: maxLength)
        for i in stride(from: maxLength - 1, to: 0, by: -1) {
            buffer[i] = UInt8(truncatingIfNeeded: value & 0xFF)
            value >>= 8
        }
        buffer[0] |= 0x80 // Highest bit indicates base-256 encoding.
        append(Data(buffer))
    }

    mutating func append(tarString string: String?, maxLength: Int) {
        guard let string = string else {
            // No value; fill field with NULLs.
            append(Data(count: maxLength))
            return
        }
        append(Data(string.utf8).zeroPad(maxLength))
    }

    /// This should work in the same way as `String.padding(toLength: length, withPad: "\0", startingAt: 0)`.
    @inline(__always)
    private func zeroPad(_ length: Int) -> Data {
        var out = length < count ? prefix(upTo: length) : self
        out.append(Data(count: length - out.count))
        return out
    }
}
