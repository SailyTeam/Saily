// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import BitByteData
import Foundation

private struct CodingIndex {
    let treeCode: Int
    let bitSize: Int
}

final class EncodingTree {
    private let bitWriter: BitWriter

    private let codingIndices: [CodingIndex]

    init(codes: [Code], _ bitWriter: BitWriter, reverseCodes: Bool = false) {
        self.bitWriter = bitWriter

        var codingIndices = Array(repeating: CodingIndex(treeCode: -1, bitSize: -1), count: codes.count)

        for code in codes {
            // Codes have already been reversed.
            // TODO: This assumption may be only correct for Huffman codes.
            let treeCode = reverseCodes ? code.code : code.code.reversed(bits: code.bits)
            codingIndices[code.symbol] = CodingIndex(treeCode: treeCode, bitSize: code.bits)
        }
        self.codingIndices = codingIndices
    }

    func code(symbol: Int) {
        guard symbol < codingIndices.count
        else { fatalError("Symbol is not found.") }

        let codingIndex = codingIndices[symbol]

        guard codingIndex.treeCode > -1
        else { fatalError("Symbol is not found.") }

        bitWriter.write(number: codingIndex.treeCode, bitsCount: codingIndex.bitSize)
    }

    func bitSize(for stats: [Int]) -> Int {
        var totalSize = 0
        for (symbol, count) in stats.enumerated() where count > 0 {
            guard symbol < self.codingIndices.count
            else { fatalError("Symbol is not found.") }
            let codingIndex = self.codingIndices[symbol]
            guard codingIndex.treeCode > -1
            else { fatalError("Symbol is not found.") }

            totalSize += count * codingIndex.bitSize
        }
        return totalSize
    }
}
