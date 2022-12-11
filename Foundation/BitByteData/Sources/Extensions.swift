// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation

extension Data {
    @inlinable @inline(__always)
    func toU16() -> UInt16 {
        withUnsafeBytes { $0.bindMemory(to: UInt16.self)[0] }
    }

    @inlinable @inline(__always)
    func toU32() -> UInt32 {
        withUnsafeBytes { $0.bindMemory(to: UInt32.self)[0] }
    }

    @inlinable @inline(__always)
    func toU64() -> UInt64 {
        withUnsafeBytes { $0.bindMemory(to: UInt64.self)[0] }
    }

    @inlinable @inline(__always)
    func toByteArray() -> [UInt8] {
        withUnsafeBytes { $0.map { $0 } }
    }
}
