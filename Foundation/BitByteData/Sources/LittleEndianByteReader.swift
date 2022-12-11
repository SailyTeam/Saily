// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation

/// A type that contains functions for reading `Data` byte-by-byte in the Little Endian order.
public final class LittleEndianByteReader: ByteReader {
    /// Size of the `data` (in bytes).
    public let size: Int

    /// Data which is being read.
    public let data: Data

    /// Offset to a byte in the `data` which will be read next.
    public var offset: Int

    /// Creates an instance for reading bytes from the `data`.
    public init(data: Data) {
        size = data.count
        self.data = data
        offset = data.startIndex
    }

    /**
     Reads a byte and returns it, advancing by one position.

     - Precondition: There must be enough bytes left.
     */
    public func byte() -> UInt8 {
        defer { offset += 1 }
        return data[offset]
    }

    /**
     Reads `count` bytes and returns them as a `[UInt8]` array, advancing by `count` positions.

     - Precondition: Parameter `count` must be non-negative.
     - Precondition: There must be enough bytes left.
     */
    public func bytes(count: Int) -> [UInt8] {
        precondition(count >= 0)
        defer { offset += count }
        return data[offset ..< offset + count].toByteArray()
    }

    /**
     Reads 8 bytes and returns them as a `UInt64` number, advancing by 8 positions.

     - Precondition: There must be enough bytes left.
     */
    public func uint64() -> UInt64 {
        defer { offset += 8 }
        return data[offset ..< offset + 8].toU64()
    }

    /**
     Reads `fromBytes` bytes and returns them as a `UInt64` number, advancing by `fromBytes` positions.

     - Note: If it is known that the `fromBytes` is exactly 8 then consider using the `uint64()` function (without an
     argument), since it may provide better performance.
     - Precondition: Parameter `fromBytes` must be in the `0...8` range.
     - Precondition: There must be enough bytes left.
     */
    public func uint64(fromBytes count: Int) -> UInt64 {
        precondition(0 ... 8 ~= count)
        var result = 0 as UInt64
        for i in 0 ..< count {
            result += UInt64(truncatingIfNeeded: data[offset]) << (8 * i)
            offset += 1
        }
        return result
    }

    /**
     Reads 4 bytes and returns them as a `UInt32` number, advancing by 4 positions.

     - Precondition: There must be enough bytes left.
     */
    public func uint32() -> UInt32 {
        defer { offset += 4 }
        return data[offset ..< offset + 4].toU32()
    }

    /**
     Reads `fromBytes` bytes and returns them as a `UInt32` number, advancing by `fromBytes` positions.

     - Note: If it is known that the `fromBytes` is exactly 4 then consider using the `uint32()` function (without an
     argument), since it may provide better performance.
     - Precondition: Parameter `fromBytes` must be in the `0...4` range.
     - Precondition: There must be enough bytes left.
     */
    public func uint32(fromBytes count: Int) -> UInt32 {
        precondition(0 ... 4 ~= count)
        var result = 0 as UInt32
        for i in 0 ..< count {
            result += UInt32(truncatingIfNeeded: data[offset]) << (8 * i)
            offset += 1
        }
        return result
    }

    /**
     Reads 2 bytes and returns them as a `UInt16` number, advancing by 2 positions.

     - Precondition: There must be enough bytes left.
     */
    public func uint16() -> UInt16 {
        defer { offset += 2 }
        return data[offset ..< offset + 2].toU16()
    }

    /**
     Reads `fromBytes` bytes and returns them as a `UInt16` number, advancing by `fromBytes` positions.

     - Note: If it is known that the `fromBytes` is exactly 2 then consider using the `uint16()` function (without an
     argument), since it may provide better performance.
     - Precondition: Parameter `fromBytes` must be in the `0...2` range.
     - Precondition: There must be enough bytes left.
     */
    public func uint16(fromBytes count: Int) -> UInt16 {
        precondition(0 ... 2 ~= count)
        var result = 0 as UInt16
        for i in 0 ..< count {
            result += UInt16(truncatingIfNeeded: data[offset]) << (8 * i)
            offset += 1
        }
        return result
    }
}
