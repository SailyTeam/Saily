// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation

/**
 A type that contains functions for writing `Data` bit-by-bit and byte-by-byte using "LSB 0" bit numbering scheme.
 */
public final class LsbBitWriter: BitWriter {
    /// Data which contains the writer's output (the last byte, that is currently being written, is not included).
    public private(set) var data: Data = .init()

    private var bitMask: UInt8 = 1
    private var currentByte: UInt8 = 0

    /// True, if a bit pointer is aligned to a byte boundary.
    public var isAligned: Bool {
        bitMask == 1
    }

    /// Creates an instance for writing bits and bytes.
    public init() {}

    /**
     Writes a `bit`, advancing by one bit position.

     - Precondition: The `bit` must be either 0 or 1.
     */
    public func write(bit: UInt8) {
        precondition(bit <= 1, "A bit must be either 0 or 1.")

        currentByte += bitMask * bit

        if bitMask == 128 {
            bitMask = 1
            data.append(currentByte)
            currentByte = 0
        } else {
            bitMask <<= 1
        }
    }

    /**
     Writes an unsigned `number`, advancing by `bitsCount` bit positions.

     This method may be useful for writing numbers, that would cause an integer overflow crash if converted to `Int`.

     - Note: The `number` will be truncated if the `bitsCount` is less than the amount of bits required to fully
     represent the value of `number`.
     - Note: Bits of the `number` are processed using the same bit-numbering scheme as of the writer (i.e. "LSB 0").
     - Precondition: Parameter `bitsCount` must be in the `0...UInt.bitWidth` range.
     */
    public func write(unsignedNumber: UInt, bitsCount: Int) {
        precondition(0 ... UInt.bitWidth ~= bitsCount)
        var mask = 1 as UInt
        for _ in 0 ..< bitsCount {
            write(bit: unsignedNumber & mask > 0 ? 1 : 0)
            mask <<= 1
        }
    }

    /**
     Writes a `byte`, advancing by one byte position.

     - Precondition: The writer must be aligned.
     */
    public func append(byte: UInt8) {
        precondition(isAligned, "BitWriter is not aligned.")
        data.append(byte)
    }

    /**
     Aligns a bit pointer to a byte boundary, i.e. moves the bit pointer to the first bit of the next byte, filling all
     skipped bit positions with zeros. If the writer is already aligned, then does nothing.
     */
    public func align() {
        guard bitMask != 1
        else { return }

        data.append(currentByte)
        currentByte = 0
        bitMask = 1
    }
}
