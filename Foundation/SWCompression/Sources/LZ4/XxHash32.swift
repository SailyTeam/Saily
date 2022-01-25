// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation

infix operator <<<

@inline(__always)
private func <<< (num: UInt32, count: Int) -> UInt32 {
    // This implementation assumes without checking that `count` is in the 1...31 range.
    (num << count) | (num >> (32 - count))
}

enum XxHash32 {
    private static let prime1: UInt32 = 0x9E37_79B1
    private static let prime2: UInt32 = 0x85EB_CA77
    private static let prime3: UInt32 = 0xC2B2_AE3D
    private static let prime4: UInt32 = 0x27D4_EB2F
    private static let prime5: UInt32 = 0x1656_67B1

    static func hash(data: Data, seed: UInt32 = 0) -> UInt32 {
        if data.count < 16 {
            return hashSmall(data, seed)
        } else {
            return hashBig(data, seed)
        }
    }

    @inline(__always)
    private static func hashSmall(_ data: Data, _ seed: UInt32) -> UInt32 {
        let acc = seed &+ prime5
        return finalize(data, data.startIndex, acc)
    }

    @inline(__always)
    private static func hashBig(_ data: Data, _ seed: UInt32) -> UInt32 {
        var accs = [seed &+ prime1 &+ prime2, seed &+ prime2, seed &+ 0, seed &- prime1]
        var i = data.startIndex
        while data.endIndex - i >= 16 { // Loop over stripes.
            for j in 0 ..< 4 { // Loop over lanes.
                var lane = 0 as UInt32
                for k: UInt32 in 0 ..< 4 {
                    lane &+= UInt32(truncatingIfNeeded: data[i + j * 4 + k.toInt()]) << (k * 8)
                }
                accs[j] &+= lane &* prime2
                accs[j] = accs[j] <<< 13
                accs[j] &*= prime1
            }
            i += 16
        }

        let acc = (accs[0] <<< 1) &+ (accs[1] <<< 7) &+ (accs[2] <<< 12) &+ (accs[3] <<< 18)
        return finalize(data, i, acc)
    }

    private static func finalize(_ data: Data, _ ptr: Int, _ acc: UInt32) -> UInt32 {
        var acc = acc &+ UInt32(truncatingIfNeeded: data.count)
        var i = ptr
        while data.endIndex - i >= 4 {
            var lane = 0 as UInt32
            for k: UInt32 in 0 ..< 4 {
                lane &+= UInt32(truncatingIfNeeded: data[i]) << (k * 8)
                i += 1
            }
            acc &+= lane &* prime3
            acc = (acc <<< 17) &* prime4
        }
        while data.endIndex - i >= 1 {
            let lane = UInt32(truncatingIfNeeded: data[i])
            i += 1
            acc &+= lane &* prime5
            acc = (acc <<< 11) &* prime1
        }
        acc ^= acc >> 15
        acc &*= prime2
        acc ^= acc >> 13
        acc &*= prime3
        acc ^= acc >> 16
        return acc
    }
}
