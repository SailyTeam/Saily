// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import BitByteData
import Foundation

struct LZMARangeDecoder {
    private let byteReader: LittleEndianByteReader

    private var range = 0xFFFF_FFFF as UInt32
    private var code = 0 as UInt32
    private(set) var isCorrupted = false

    var isFinishedOK: Bool {
        code == 0
    }

    init(_ byteReader: LittleEndianByteReader) throws {
        // To initialize range decoder at least 5 bytes are necessary.
        guard byteReader.bytesLeft >= 5
        else { throw LZMAError.rangeDecoderInitError }

        self.byteReader = byteReader

        let byte = self.byteReader.byte()
        for _ in 0 ..< 4 {
            code = (code << 8) | UInt32(self.byteReader.byte())
        }
        guard byte == 0, code != range
        else { throw LZMAError.rangeDecoderInitError }
    }

    init() {
        byteReader = LittleEndianByteReader(data: Data())
    }

    /// `range` property cannot be smaller than `(1 << 24)`. This function keeps it bigger.
    mutating func normalize() {
        if range < LZMAConstants.topValue {
            range <<= 8
            code = (code << 8) | UInt32(byteReader.byte())
        }
    }

    /// Decodes sequence of direct bits (binary symbols with fixed and equal probabilities).
    mutating func decode(directBits: Int) -> Int {
        var res: UInt32 = 0
        var count = directBits
        repeat {
            range >>= 1
            code = code &- range
            let t = 0 &- (code >> 31)
            code = code &+ (range & t)

            if code == range {
                isCorrupted = true
            }

            normalize()

            res <<= 1
            res = res &+ (t &+ 1)
            count -= 1
        } while count > 0
        return res.toInt()
    }

    /// Decodes binary symbol (bit) with predicted (estimated) probability.
    mutating func decode(bitWithProb prob: inout Int) -> Int {
        let bound = (range >> UInt32(LZMAConstants.numBitModelTotalBits)) * UInt32(prob)
        let symbol: Int
        if code < bound {
            prob += ((1 << LZMAConstants.numBitModelTotalBits) - prob) >> LZMAConstants.numMoveBits
            range = bound
            symbol = 0
        } else {
            prob -= prob >> LZMAConstants.numMoveBits
            code -= bound
            range -= bound
            symbol = 1
        }
        normalize()
        return symbol
    }
}
