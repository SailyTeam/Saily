// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation

/// A type that contains functions for writing `Data` bit-by-bit and byte-by-byte.
public protocol BitWriter {
    /// Data which contains the writer's output (the last byte, that is currently being written, is not included).
    var data: Data { get }

    /// True, if a bit pointer is aligned to a byte boundary.
    var isAligned: Bool { get }

    /// Creates an instance for writing bits and bytes.
    init()

    /// Writes a `bit`, advancing by one bit position.
    func write(bit: UInt8)

    /// Writes `bits`, advancing by `bits.count` bit positions.
    func write(bits: [UInt8])

    /// Writes a `number` into `bitsCount` amount of bits, advancing by `bitsCount` bit positions.
    func write(number: Int, bitsCount: Int)

    /**
     Writes a signed integer `number` into `bitsCount` amount of bits, advancing by `bitsCount` bit positions, while
     using a `representation` as a method to represent the signed integer in a binary format.
     */
    func write(signedNumber: Int, bitsCount: Int, representation: SignedNumberRepresentation)

    /// Writes an unsigned `number`, advancing by `bitsCount` bit positions.
    func write(unsignedNumber: UInt, bitsCount: Int)

    /// Writes a `byte`, advancing by one byte position.
    func append(byte: UInt8)

    /**
     Aligns a bit pointer to a byte boundary, i.e. moves the bit pointer to the first bit of the next byte, filling all
     skipped bit positions with zeros.
     */
    func align()
}

public extension BitWriter {
    /// Writes `bits`, advancing by `bits.count` bit positions, using the `write(bit:)` function.
    func write(bits: [UInt8]) {
        for bit in bits {
            write(bit: bit)
        }
    }

    /**
     Converts a `number` into an `UInt` integer, and writes it into `bitsCount` amount of bits by using the
     `write(unsignedNumber:bitsCount:)` function, advancing by `bitsCount` bit positions.

     - Note: If the data is supposed to represent a signed integer (i.e. it is important to preserve the sign), it is
     recommended to use the `write(signedNumber:bitsCount:representation:)` function.
     - Precondition: Parameter `bitsCount` must be in the `0...Int.bitWidth` range.
     */
    func write(number: Int, bitsCount: Int) {
        precondition(0 ... Int.bitWidth ~= bitsCount)
        write(unsignedNumber: UInt(bitPattern: number), bitsCount: bitsCount)
    }

    /**
     Writes a signed integer `number` into `bitsCount` amount of bits, advancing by `bitsCount` bit positions, while
     using a `representation` as a method to represent the signed integer in a binary format. This implementation uses
     the `write(unsignedNumber:bitsCount:)` function in the final stage of writing.

     The default value of `representation` is `SignedNumberRepresentation.twoComplementNegatives`.

     For the representations where zero can be represented in two ways (namely, `.signMagnitude` and
     `.oneComplementNegatives`), zero is encoded as +0 (i.e. all bits are set to zero).

     - Precondition: The `signedNumber` must be representable within `bitsCount` bits using the `representation`, i.e.
     it must be in the `representation.minRepresentableNumber...representation.maxRepresentableNumber` range.
     - Precondition: For the `SignedNumberRepresentation.biased` representation, the `bias` must be non-negative.
     - Precondition: Parameter `bitsCount` must be in the `0...Int.bitWidth` range.
     */
    func write(signedNumber: Int, bitsCount: Int, representation: SignedNumberRepresentation = .twoComplementNegatives) {
        precondition(signedNumber >= representation.minRepresentableNumber(bitsCount: bitsCount) &&
            signedNumber <= representation.maxRepresentableNumber(bitsCount: bitsCount),
            "\(signedNumber) cannot be represented by \(representation) using \(bitsCount) bits")
        precondition(0 ... Int.bitWidth ~= bitsCount)

        var magnitude = signedNumber.magnitude
        switch representation {
        case .signMagnitude:
            magnitude += signedNumber < 0 ? (1 << (bitsCount - 1)) : 0
            write(unsignedNumber: magnitude, bitsCount: bitsCount)
        case .oneComplementNegatives:
            if signedNumber < 0 {
                magnitude = ~magnitude
            }
            write(unsignedNumber: magnitude, bitsCount: bitsCount)
        case .twoComplementNegatives:
            if signedNumber < 0 {
                magnitude = ~magnitude &+ 1
            }
            write(unsignedNumber: magnitude, bitsCount: bitsCount)
        case let .biased(bias):
            precondition(bias >= 0, "Bias cannot be less than zero.")
            write(unsignedNumber: UInt(bitPattern: signedNumber &+ bias), bitsCount: bitsCount)
        case .radixNegativeTwo:
            let mask = UInt(truncatingIfNeeded: 0xAAAA_AAAA_AAAA_AAAA as UInt64)
            let unsignedBitPattern = UInt(bitPattern: signedNumber)
            let encoded = (unsignedBitPattern &+ mask) ^ mask
            write(unsignedNumber: encoded, bitsCount: bitsCount)
        }
    }
}
