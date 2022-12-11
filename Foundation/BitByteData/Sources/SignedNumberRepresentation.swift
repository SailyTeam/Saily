// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

/// Represents a method to encode signed integers in a binary format.
public enum SignedNumberRepresentation {
    /// Signed magnitude representation.
    case signMagnitude
    /// One's complement representation of negative integers.
    case oneComplementNegatives
    /// Two's complement representation of negative integers.
    case twoComplementNegatives
    /// Biased representation with a custom `bias`.
    case biased(bias: Int)
    /// Base (radix) -2 representation.
    case radixNegativeTwo

    // Generally speaking, there is a natural limit of the maximum and minimum values that Swift's Int type can hold.
    // So when the bitsCount matches the bit width of the Int type we need to be careful.

    /**
     Returns a minimum signed integer that is possible to represent in a binary format within `bitsCount` bits using the
     current representation.

     - Precondition: Parameter `bitsCount` must be greater than zero.
     - Precondition: For the `SignedNumberRepresentation.biased` representation, the `bias` must be non-negative.
     */
    public func minRepresentableNumber(bitsCount: Int) -> Int {
        precondition(bitsCount > 0)

        switch self {
        case .signMagnitude:
            fallthrough
        case .oneComplementNegatives:
            return bitsCount >= Int.bitWidth ? Int.min : -(1 << (bitsCount - 1) - 1)
        case .twoComplementNegatives:
            // Technically, we don't need to be extremely careful in the 2's-complement case, since it is the
            // representation used internally by Swift, however, in practice, we still get arithmetic overflow
            // in the bitsCount == Int.bitWidth case, if we use the formula, so we check for this case specifically.
            return bitsCount >= Int.bitWidth ? Int.min : -(1 << (bitsCount - 1))
        case let .biased(bias):
            precondition(bias >= 0)
            return -bias
        case .radixNegativeTwo:
            // Minimum corresponds to all of the odd bits being set.
            var result = 0
            var mult = 2
            for i in stride(from: 1, to: bitsCount, by: 2) {
                result -= mult
                let (newMult, overflow) = mult.multipliedReportingOverflow(by: 4)
                if overflow {
                    // This means that we reached the Int.min limit.
                    // Since, the last, 63rd, bit is an odd bit, Int.min is encodable within 64 bits using RN2.
                    // So if the loop would continue in the absence of the overflow, which would result in even smaller
                    // values, we need to return Int.min as the correct answer.
                    if i + 2 < bitsCount {
                        result = Int.min
                    }
                    break
                }
                mult = newMult
            }
            return result
        }
    }

    /**
     Returns a maximum signed integer that is possible to represent in a binary format within `bitsCount` bits using the
     current representation.

     - Precondition: Parameter `bitsCount` must be greater than zero.
     - Precondition: For the `SignedNumberRepresentation.biased` representation, the `bias` must be non-negative.
     */
    public func maxRepresentableNumber(bitsCount: Int) -> Int {
        precondition(bitsCount > 0)

        switch self {
        case .signMagnitude:
            fallthrough
        case .oneComplementNegatives:
            fallthrough
        case .twoComplementNegatives:
            return bitsCount >= Int.bitWidth ? Int.max : 1 << (bitsCount - 1) - 1
        case let .biased(bias):
            precondition(bias >= 0)
            return bitsCount >= Int.bitWidth ? Int.max - bias : (1 << bitsCount) - 1 - bias
        case .radixNegativeTwo:
            // Maximum corresponds to all of the even bits being set.
            var result = 0
            var mult = 1
            for _ in stride(from: 0, to: bitsCount, by: 2) {
                result += mult
                let (newMult, overflow) = mult.multipliedReportingOverflow(by: 4)
                if overflow {
                    // This means that we reached the Int.max limit.
                    // Since, the last, 63rd, bit is an odd bit, we cannot encode Int.max within 64 bits using RN2,
                    // so the correct answer is always "all even bits set".
                    break
                }
                mult = newMult
            }
            return result
        }
    }
}
