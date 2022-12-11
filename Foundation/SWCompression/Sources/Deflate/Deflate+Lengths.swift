// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation

// Deflate specific functions for generation of HuffmanLength arrays from different inputs.
extension Deflate {
    /// - Note: Skips zero codeLengths.
    static func lengths(from orderedCodeLengths: [Int]) -> [CodeLength] {
        var lengths = [CodeLength]()
        for (i, codeLength) in orderedCodeLengths.enumerated() where codeLength > 0 {
            lengths.append(CodeLength(symbol: i, codeLength: codeLength))
        }
        return lengths
    }
}
