// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation

struct LZMALenDecoder {
    private var choice: Int = LZMAConstants.probInitValue
    private var choice2: Int = LZMAConstants.probInitValue
    private var lowCoder: [LZMABitTreeDecoder] = []
    private var midCoder: [LZMABitTreeDecoder] = []
    private var highCoder: LZMABitTreeDecoder

    init() {
        highCoder = LZMABitTreeDecoder(numBits: 8)
        for _ in 0 ..< (1 << LZMAConstants.numPosBitsMax) {
            lowCoder.append(LZMABitTreeDecoder(numBits: 3))
            midCoder.append(LZMABitTreeDecoder(numBits: 3))
        }
    }

    /// Decodes zero-based match length.
    mutating func decode(with rangeDecoder: inout LZMARangeDecoder, posState: Int) -> Int {
        // There can be one of three options.
        // We need one or two bits to find out which decoding scheme to use.
        // `choice` is used to decode first bit.
        // `choice2` is used to decode second bit.
        // If binary sequence starts with 0 then:
        if rangeDecoder.decode(bitWithProb: &choice) == 0 {
            return lowCoder[posState].decode(with: &rangeDecoder)
        }
        // If binary sequence starts with 1 0 then:
        if rangeDecoder.decode(bitWithProb: &choice2) == 0 {
            return 8 + midCoder[posState].decode(with: &rangeDecoder)
        }
        // If binary sequence starts with 1 1 then:
        return 16 + highCoder.decode(with: &rangeDecoder)
    }
}
