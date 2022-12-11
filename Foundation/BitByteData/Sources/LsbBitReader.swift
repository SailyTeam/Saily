// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation

/**
 A type that contains functions for reading `Data` bit-by-bit using "LSB0" bit numbering scheme and byte-by-byte in the
 Little Endian order.
 */
public final class LsbBitReader: BitReader {
    private var bitMask: UInt8 = 1
    private var currentByte: UInt8

    /// Size of the `data` (in bytes).
    public let size: Int

    /// Data which is being read.
    public let data: Data

    /**
     Offset to a byte in the `data` which will be read next.

     - Precondition: The reader must be aligned when accessing the setter of `offset`.
     */
    public var offset: Int {
        willSet {
            precondition(bitMask == 1, "BitReader is not aligned.")
        }
        didSet {
            if !isFinished {
                currentByte = data[offset]
            }
        }
    }

    /// True, if a bit pointer is aligned to a byte boundary.
    public var isAligned: Bool {
        bitMask == 1
    }

    /// Amount of bits left to read.
    public var bitsLeft: Int {
        let bytesLeft = data.endIndex - offset
        return bytesLeft * 8 - bitMask.trailingZeroBitCount
    }

    /// Amount of bits that were already read.
    public var bitsRead: Int {
        let bytesRead = offset - data.startIndex
        return bytesRead * 8 + bitMask.trailingZeroBitCount
    }

    /// Creates an instance for reading bits (and bytes) from the `data`.
    public init(data: Data) {
        size = data.count
        self.data = data
        offset = data.startIndex
        currentByte = data.first ?? 0
    }

    /**
     Converts a `ByteReader` instance into a `LsbBitReader`, enabling bit reading capabilities. The current `offset`
     value of the `byteReader` is preserved.
     */
    public convenience init(_ byteReader: ByteReader) {
        self.init(data: byteReader.data)
        offset = byteReader.offset
        currentByte = byteReader.isFinished ? 0 : byteReader.data[byteReader.offset]
    }

    // MARK: Bit reading methods

    /**
     Advances a bit pointer by the specified amount of bits (the default value is 1).

     - Warning: This function doesn't check if there is any data left. It is advised to use `isFinished` after calling
     this method to check if the end was reached.
     */
    public func advance(by count: Int = 1) {
        for _ in 0 ..< count {
            if bitMask == 128 {
                bitMask = 1
                offset += 1
            } else {
                bitMask <<= 1
            }
        }
    }

    /**
     Reads a bit and returns it, advancing by one bit position.

     - Precondition: There must be enough data left.
     */
    public func bit() -> UInt8 {
        precondition(bitsLeft >= 1)
        let bit: UInt8 = currentByte & bitMask > 0 ? 1 : 0

        if bitMask == 128 {
            bitMask = 1
            offset += 1
        } else {
            bitMask <<= 1
        }

        return bit
    }

    /**
     Reads `count` bits and returns them as a `[UInt8]` array, advancing by `count` bit positions.

     - Precondition: Parameter `count` must non-negative
     - Precondition: There must be enough data left.
     */
    public func bits(count: Int) -> [UInt8] {
        precondition(count >= 0)
        precondition(bitsLeft >= count)

        var array = [UInt8]()
        array.reserveCapacity(count)
        for _ in 0 ..< count {
            array.append(bit())
        }

        return array
    }

    /**
     Reads `fromBits` bits, treating them as a binary `represenation` of a signed integer, and returns the result as a
     `Int` number, advancing by `fromBits` bit positions.

     If the `representation` doesn't match the representation that was used to produce the data then the result may be
     incorrect.

     The default value of `representation` is `SignedNumberRepresentation.twoComplementNegatives`.

     - Precondition: Parameter `fromBits` must be in the `0...Int.bitWidth` range.
     - Precondition: There must be enough data left.
     */
    public func signedInt(fromBits count: Int, representation: SignedNumberRepresentation = .twoComplementNegatives) -> Int {
        precondition(0 ... Int.bitWidth ~= count)
        precondition(bitsLeft >= count)

        guard count > 0
        else { return 0 }

        var result = 0
        switch representation {
        case .signMagnitude:
            result = int(fromBits: count - 1)
            result = bit() > 0 ? -result : result
        case .oneComplementNegatives:
            result = int(fromBits: count - 1)
            if bit() > 0 {
                // First, we convert to 2's-complement, and then we proceed as in the 2's-complement case.
                result &+= 1
                result &-= 1 << (count - 1)
            }
        case .twoComplementNegatives:
            result = int(fromBits: count - 1)
            result &-= bit() > 0 ? (1 << (count - 1)) : 0
        case let .biased(bias):
            result = int(fromBits: count)
            result &-= bias
        case .radixNegativeTwo:
            var mult = 1
            var sign = 1
            for _ in 0 ..< count {
                result &+= Int(truncatingIfNeeded: bit()) * sign * mult
                mult <<= 1
                sign *= -1
            }
        }

        return result
    }

    /**
     Reads `fromBits` bits and returns them as a `UInt8` number, advancing by `fromBits` bit positions.

     - Precondition: Parameter `fromBits` must be in the `0...8` range.
     - Precondition: There must be enough data left.
     */
    public func byte(fromBits count: Int) -> UInt8 {
        precondition(0 ... 8 ~= count)
        precondition(bitsLeft >= count)

        var result = 0 as UInt8
        for i in 0 ..< count {
            let bit: UInt8 = currentByte & bitMask > 0 ? 1 : 0
            result += (1 << i) * bit

            if bitMask == 128 {
                bitMask = 1
                offset += 1
            } else {
                bitMask <<= 1
            }
        }

        return result
    }

    /**
     Reads `fromBits` bits and returns them as a `UInt16` number, advancing by `fromBits` bit positions.

     - Precondition: Parameter `fromBits` must be in the `0...16` range.
     - Precondition: There must be enough data left.
     */
    public func uint16(fromBits count: Int) -> UInt16 {
        precondition(0 ... 16 ~= count)
        precondition(bitsLeft >= count)

        var result = 0 as UInt16
        for i in 0 ..< count {
            let bit: UInt16 = currentByte & bitMask > 0 ? 1 : 0
            result += (1 << i) * bit

            if bitMask == 128 {
                bitMask = 1
                offset += 1
            } else {
                bitMask <<= 1
            }
        }

        return result
    }

    /**
     Reads `fromBits` bits and returns them as a `UInt32` number, advancing by `fromBits` bit positions.

     - Precondition: Parameter `fromBits` must be in the `0...32` range.
     - Precondition: There must be enough data left.
     */
    public func uint32(fromBits count: Int) -> UInt32 {
        precondition(0 ... 32 ~= count)
        precondition(bitsLeft >= count)

        var result = 0 as UInt32
        for i in 0 ..< count {
            let bit: UInt32 = currentByte & bitMask > 0 ? 1 : 0
            result += (1 << i) * bit

            if bitMask == 128 {
                bitMask = 1
                offset += 1
            } else {
                bitMask <<= 1
            }
        }

        return result
    }

    /**
     Reads `fromBits` bits and returns them as a `UInt64` number, advancing by `fromBits` bit positions.

     - Precondition: Parameter `fromBits` must be from `0...64` range.
     - Precondition: There must be enough data left.
     */
    public func uint64(fromBits count: Int) -> UInt64 {
        precondition(0 ... 64 ~= count)
        precondition(bitsLeft >= count)

        var result = 0 as UInt64
        for i in 0 ..< count {
            let bit: UInt64 = currentByte & bitMask > 0 ? 1 : 0
            result += (1 << i) * bit

            if bitMask == 128 {
                bitMask = 1
                offset += 1
            } else {
                bitMask <<= 1
            }
        }

        return result
    }

    /**
     Aligns a bit pointer to a byte boundary, i.e. moves the bit pointer to the first bit of the next byte. If the
     reader is already aligned, then does nothing.

     - Warning: This function doesn't check if there is any data left. It is advised to use `isFinished` after calling
     this method to check if the end was reached.
     */
    public func align() {
        if bitMask != 1 {
            bitMask = 1
            offset += 1
        }
    }

    // MARK: Byte reading methods

    /**
     Reads a byte and returns it, advancing by one byte position.

     - Precondition: The reader must be aligned.
     - Precondition: There must be enough bytes left.
     */
    public func byte() -> UInt8 {
        defer { offset += 1 }
        return data[offset]
    }

    /**
     Reads `count` bytes and returns them as a `[UInt8]` array, advancing by `count` byte positions.

     - Precondition: The reader must be aligned.
     - Precondition: Parameter `count` must be non-negative.
     - Precondition: There must be enough bytes left.
     */
    public func bytes(count: Int) -> [UInt8] {
        defer { offset += count }
        return data[offset ..< offset + count].toByteArray()
    }

    /**
     Reads 8 bytes and returns them as a `UInt64` number, advancing by 8 byte positions.

     - Precondition: The reader must be aligned.
     - Precondition: There must be enough bytes left.
     */
    public func uint64() -> UInt64 {
        defer { offset += 8 }
        return data[offset ..< offset + 8].toU64()
    }

    /**
     Reads `fromBytes` bytes and returns them as a `UInt64` number, advancing by `fromBytes` byte positions.

     - Note: If it is known that the `fromBytes` is exactly 8 then consider using the `uint64()` function (without an
     argument), since it may provide better performance.
     - Precondition: The reader must be aligned.
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
     Reads 4 bytes and returns them as a `UInt32` number, advancing by 4 byte positions.

     - Precondition: The reader must be aligned.
     - Precondition: There must be enough bytes left.
     */
    public func uint32() -> UInt32 {
        defer { offset += 4 }
        return data[offset ..< offset + 4].toU32()
    }

    /**
     Reads `fromBytes` bytes and returns them as a `UInt32` number, advancing by `fromBytes` byte positions.

     - Note: If it is known that the `fromBytes` is exactly 4 then consider using the `uint32()` function (without an
     argument), since it may provide better performance.
     - Precondition: The reader must be aligned.
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
     Reads 2 bytes and returns them as a `UInt16` number, advancing by 2 byte positions.

     - Precondition: The reader must be aligned.
     - Precondition: There must be enough data left.
     */
    public func uint16() -> UInt16 {
        defer { offset += 2 }
        return data[offset ..< offset + 2].toU16()
    }

    /**
     Reads `fromBytes` bytes and returns them as a `UInt16` number, advancing by `fromBytes` byte positions.

     - Note: If it is known that the `fromBytes` is exactly 2 then consider using the `uint16()` function (without an
     argument), since it may provide better performance.
     - Precondition: The reader must be aligned.
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
