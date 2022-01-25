// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation

/// Used to decode symbols that need several bits for storing.
struct LZMABitTreeDecoder {
    var probs: [Int]
    let numBits: Int

    init(numBits: Int) {
        probs = Array(repeating: LZMAConstants.probInitValue,
                      count: 1 << numBits)
        self.numBits = numBits
    }

    mutating func decode(with rangeDecoder: inout LZMARangeDecoder) -> Int {
        var m = 1
        for _ in 0 ..< numBits {
            m = (m << 1) + rangeDecoder.decode(bitWithProb: &probs[m])
        }
        return m - (1 << numBits)
    }

    mutating func reverseDecode(with rangeDecoder: inout LZMARangeDecoder) -> Int {
        LZMABitTreeDecoder.bitTreeReverseDecode(probs: &probs,
                                                startIndex: 0,
                                                bits: numBits, &rangeDecoder)
    }

    static func bitTreeReverseDecode(probs: inout [Int], startIndex: Int, bits: Int,
                                     _ rangeDecoder: inout LZMARangeDecoder) -> Int
    {
        var m = 1
        var symbol = 0
        for i in 0 ..< bits {
            let bit = rangeDecoder.decode(bitWithProb: &probs[startIndex + m])
            m <<= 1
            m += bit
            symbol |= bit << i
        }
        return symbol
    }
}
