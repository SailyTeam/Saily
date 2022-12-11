// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation

/// A type that contains functions for reading `Data` byte-by-byte.
public protocol ByteReader: AnyObject {
    /// Size of the `data` (in bytes).
    var size: Int { get }

    /// Data which is being read.
    var data: Data { get }

    /// Offset to a byte in the `data` which will be read next.
    var offset: Int { get set }

    /// Creates an instance for reading bytes from the `data`.
    init(data: Data)

    /// Reads a byte and returns it, advancing by one position.
    func byte() -> UInt8

    /// Reads `count` bytes and returns them as a `[UInt8]` array, advancing by `count` positions.
    func bytes(count: Int) -> [UInt8]

    /// Reads `fromBytes` bytes and returns them as a `Int` number, advancing by `fromBytes` positions.
    func int(fromBytes count: Int) -> Int

    /// Reads `fromBytes` bytes and returns them as a `UInt64` number, advancing by `fromBytes` positions.
    func uint64(fromBytes count: Int) -> UInt64

    /// Reads `fromBytes` bytes and returns them as a `UInt32` number, advancing by `fromBytes` positions.
    func uint32(fromBytes count: Int) -> UInt32

    /// Reads `fromBytes` bytes and returns them as a `UInt16` number, advancing by `fromBytes` positions.
    func uint16(fromBytes count: Int) -> UInt16
}

public extension ByteReader {
    /// Creates an instance for reading bytes by using the `data` and the `offset` of the specified `BitReader`.
    init(_ bitReader: BitReader) {
        self.init(data: bitReader.data)
        offset = bitReader.offset
    }

    /// Amount of bytes left to read.
    var bytesLeft: Int {
        data.endIndex - offset
    }

    /// Amount of bytes that were already read.
    var bytesRead: Int {
        offset - data.startIndex
    }

    /**
     True, if the `offset` points at any position after the last byte in `data`, which generally means that all data
     has been read.
     */
    var isFinished: Bool {
        data.endIndex <= offset
    }

    /**
     Reads `fromBytes` bytes by either using `uint64(fromBytes:)` or `uint32(fromBytes:)` depending on the platform's
     integer bit width, converts the result to `Int`, and returns it, advancing by `fromBytes` positions.
     */
    func int(fromBytes count: Int) -> Int {
        if MemoryLayout<Int>.size == 8 {
            return Int(truncatingIfNeeded: uint64(fromBytes: count))
        } else if MemoryLayout<Int>.size == 4 {
            return Int(truncatingIfNeeded: uint32(fromBytes: count))
        } else {
            fatalError("Unknown Int bit width")
        }
    }
}
