// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation

infix operator >>>

@inline(__always)
private func >>> (num: UInt32, count: Int) -> UInt32 {
    // This implementation assumes without checking that `count` is in the 1...31 range.
    (num >> count) | (num << (32 - count))
}

enum Sha256 {
    private static let k: [UInt32] =
        [0x428A_2F98, 0x7137_4491, 0xB5C0_FBCF, 0xE9B5_DBA5, 0x3956_C25B, 0x59F1_11F1, 0x923F_82A4, 0xAB1C_5ED5, 0xD807_AA98,
         0x1283_5B01, 0x2431_85BE, 0x550C_7DC3, 0x72BE_5D74, 0x80DE_B1FE, 0x9BDC_06A7, 0xC19B_F174, 0xE49B_69C1, 0xEFBE_4786,
         0x0FC1_9DC6, 0x240C_A1CC, 0x2DE9_2C6F, 0x4A74_84AA, 0x5CB0_A9DC, 0x76F9_88DA, 0x983E_5152, 0xA831_C66D, 0xB003_27C8,
         0xBF59_7FC7, 0xC6E0_0BF3, 0xD5A7_9147, 0x06CA_6351, 0x1429_2967, 0x27B7_0A85, 0x2E1B_2138, 0x4D2C_6DFC, 0x5338_0D13,
         0x650A_7354, 0x766A_0ABB, 0x81C2_C92E, 0x9272_2C85, 0xA2BF_E8A1, 0xA81A_664B, 0xC24B_8B70, 0xC76C_51A3, 0xD192_E819,
         0xD699_0624, 0xF40E_3585, 0x106A_A070, 0x19A4_C116, 0x1E37_6C08, 0x2748_774C, 0x34B0_BCB5, 0x391C_0CB3, 0x4ED8_AA4A,
         0x5B9C_CA4F, 0x682E_6FF3, 0x748F_82EE, 0x78A5_636F, 0x84C8_7814, 0x8CC7_0208, 0x90BE_FFFA, 0xA450_6CEB, 0xBEF9_A3F7,
         0xC671_78F2]

    static func hash(data: Data) -> [UInt8] {
        var h0 = 0x6A09_E667 as UInt32
        var h1 = 0xBB67_AE85 as UInt32
        var h2 = 0x3C6E_F372 as UInt32
        var h3 = 0xA54F_F53A as UInt32
        var h4 = 0x510E_527F as UInt32
        var h5 = 0x9B05_688C as UInt32
        var h6 = 0x1F83_D9AB as UInt32
        var h7 = 0x5BE0_CD19 as UInt32

        // Padding
        var bytes = data.withUnsafeBytes { $0.map { $0 } }

        let originalLength = bytes.count
        var newLength = originalLength * 8 + 1
        while newLength % 512 != 448 {
            newLength += 1
        }
        newLength /= 8

        bytes.append(0x80)
        for _ in 0 ..< (newLength - originalLength - 1) {
            bytes.append(0x00)
        }

        // Length
        let bitsLength = UInt64(truncatingIfNeeded: originalLength * 8)
        for i: UInt64 in 0 ..< 8 {
            bytes.append(UInt8(truncatingIfNeeded: (bitsLength & 0xFF << ((7 - i) * 8)) >> ((7 - i) * 8)))
        }

        for i in stride(from: 0, to: bytes.count, by: 64) {
            var w = Array(repeating: 0 as UInt32, count: 64)

            for j in 0 ..< 16 {
                var word = 0 as UInt32
                for k: UInt32 in 0 ..< 4 {
                    word += UInt32(truncatingIfNeeded: bytes[i + j * 4 + k.toInt()]) << ((3 - k) * 8)
                }
                w[j] = word
            }

            for i in 16 ..< 64 {
                let s0 = (w[i - 15] >>> 7) ^ (w[i - 15] >>> 18) ^ (w[i - 15] >> 3)
                let s1 = (w[i - 2] >>> 17) ^ (w[i - 2] >>> 19) ^ (w[i - 2] >> 10)
                w[i] = w[i - 16] &+ s0 &+ w[i - 7] &+ s1
            }

            var a = h0
            var b = h1
            var c = h2
            var d = h3
            var e = h4
            var f = h5
            var g = h6
            var h = h7

            for i in 0 ..< 64 {
                let s1 = (e >>> 6) ^ (e >>> 11) ^ (e >>> 25)
                let ch = (e & f) ^ ((~e) & g)
                let temp1 = h &+ s1 &+ ch &+ k[i] &+ w[i]
                let s0 = (a >>> 2) ^ (a >>> 13) ^ (a >>> 22)
                let maj = (a & b) ^ (a & c) ^ (b & c)
                let temp2 = s0 &+ maj

                h = g
                g = f
                f = e
                e = d &+ temp1
                d = c
                c = b
                b = a
                a = temp1 &+ temp2
            }

            h0 = h0 &+ a
            h1 = h1 &+ b
            h2 = h2 &+ c
            h3 = h3 &+ d
            h4 = h4 &+ e
            h5 = h5 &+ f
            h6 = h6 &+ g
            h7 = h7 &+ h
        }

        var result = [UInt8]()
        result.reserveCapacity(32)

        for i: UInt32 in 0 ..< 4 {
            result.append(UInt8(truncatingIfNeeded: (h0 & 0xFF << ((3 - i) * 8)) >> ((3 - i) * 8)))
        }
        for i: UInt32 in 0 ..< 4 {
            result.append(UInt8(truncatingIfNeeded: (h1 & 0xFF << ((3 - i) * 8)) >> ((3 - i) * 8)))
        }
        for i: UInt32 in 0 ..< 4 {
            result.append(UInt8(truncatingIfNeeded: (h2 & 0xFF << ((3 - i) * 8)) >> ((3 - i) * 8)))
        }
        for i: UInt32 in 0 ..< 4 {
            result.append(UInt8(truncatingIfNeeded: (h3 & 0xFF << ((3 - i) * 8)) >> ((3 - i) * 8)))
        }
        for i: UInt32 in 0 ..< 4 {
            result.append(UInt8(truncatingIfNeeded: (h4 & 0xFF << ((3 - i) * 8)) >> ((3 - i) * 8)))
        }
        for i: UInt32 in 0 ..< 4 {
            result.append(UInt8(truncatingIfNeeded: (h5 & 0xFF << ((3 - i) * 8)) >> ((3 - i) * 8)))
        }
        for i: UInt32 in 0 ..< 4 {
            result.append(UInt8(truncatingIfNeeded: (h6 & 0xFF << ((3 - i) * 8)) >> ((3 - i) * 8)))
        }
        for i: UInt32 in 0 ..< 4 {
            result.append(UInt8(truncatingIfNeeded: (h7 & 0xFF << ((3 - i) * 8)) >> ((3 - i) * 8)))
        }

        return result
    }
}
