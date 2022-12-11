// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation

/// A type that contains functions for reading `Data` bit-by-bit and byte-by-byte.
public protocol BitReader: ByteReader {
    /// True, if a bit pointer is aligned to a byte boundary.
    var isAligned: Bool { get }

    /// Amount of bits left to read.
    var bitsLeft: Int { get }

    /// Amount of bits that were already read.
    var bitsRead: Int { get }

    /**
     Converts a `ByteReader` instance into a `BitReader`, enabling bits reading capabilities. The current `offset` value
     of the `byteReader` is preserved.
     */
    init(_ byteReader: ByteReader)

    /// Advances a bit pointer by the amount of bits.
    func advance(by count: Int)

    /// Reads a bit and returns it, advancing by one bit position.
    func bit() -> UInt8

    /// Reads `count` bits and returns them as a `[UInt8]` array, advancing by `count` bit positions.
    func bits(count: Int) -> [UInt8]

    /// Reads `fromBits` bits and returns them as a `Int` number, advancing by `fromBits` bit positions.
    func int(fromBits count: Int) -> Int

    /**
     Reads `fromBits` bits, treating them as a binary `represenation` of a signed integer, and returns the result as a
     `Int` number, advancing by `fromBits` bit positions.
     */
    func signedInt(fromBits count: Int, representation: SignedNumberRepresentation) -> Int

    /// Reads `fromBits` bits and returns them as a `UInt8` number, advancing by `fromBits` bit positions.
    func byte(fromBits count: Int) -> UInt8

    /// Reads `fromBits` bits and returns them as a `UInt16` number, advancing by `fromBits` bit positions.
    func uint16(fromBits count: Int) -> UInt16

    /// Reads `fromBits` bits and returns them as a `UInt32` number, advancing by `fromBits` bit positions.
    func uint32(fromBits count: Int) -> UInt32

    /// Reads `fromBits` bits and returns them as a `UInt64` number, advancing by `fromBits` bit positions.
    func uint64(fromBits count: Int) -> UInt64

    /// Aligns a bit pointer to a byte boundary, i.e. moves the bit pointer to the first bit of the next byte.
    func align()
}

public extension BitReader {
    /**
     Reads `fromBits` bits by either using `uint64(fromBits:)` or `uint32(fromBits:)` depending on the platform's
     integer bit width, converts the result to `Int`, and returns it, advancing by `fromBits` bit positions.

     - Note: If the data is supposed to represent a signed integer, it is recommended to use the
     `signedInt(fromBits:representation:)` function to get a correct result.
     */
    func int(fromBits count: Int) -> Int {
        if MemoryLayout<Int>.size == 8 {
            return Int(truncatingIfNeeded: uint64(fromBits: count))
        } else if MemoryLayout<Int>.size == 4 {
            return Int(truncatingIfNeeded: uint32(fromBits: count))
        } else {
            fatalError("Unknown Int bit width")
        }
    }
}
