// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import BitByteData
import Foundation

/// Provides functions for compression and decompression for BZip2 algorithm.
public class BZip2: DecompressionAlgorithm {
    /**
     Decompresses `data` using BZip2 algortihm.

     - Parameter data: Data compressed with BZip2.

     - Throws: `BZip2Error` if unexpected byte (bit) sequence was encountered in `data`.
     It may indicate that either data is damaged or it might not be compressed with BZip2 at all.

     - Returns: Decompressed data.
     */
    public static func decompress(data: Data) throws -> Data {
        /// Object with input data which supports convenient work with bit shifts.
        let bitReader = MsbBitReader(data: data)
        return try decompress(bitReader)
    }

    static func decompress(_ bitReader: MsbBitReader) throws -> Data {
        // Valid BZip2 "archive" must contain at least 14 bytes of data.
        guard bitReader.bitsLeft >= 14 * 8
        else { throw BZip2Error.wrongMagic }

        /// An array for storing output data
        var out = Data()

        let magic = bitReader.uint16()
        guard magic == 0x5A42 else { throw BZip2Error.wrongMagic }

        let method = bitReader.byte()
        guard method == 104 else { throw BZip2Error.wrongVersion }

        guard let blockSize = BlockSize(bitReader.byte())
        else { throw BZip2Error.wrongBlockSize }

        var totalCRC: UInt32 = 0
        while true {
            // Using `Int64` because 48 bits may not fit into `Int` on some platforms.
            let blockType = bitReader.uint64(fromBits: 48)

            let blockCRC32 = bitReader.uint32(fromBits: 32)

            if blockType == 0x3141_5926_5359 {
                let blockData = try decode(bitReader, blockSize)
                out.append(blockData)
                guard CheckSums.bzip2crc32(blockData) == blockCRC32
                else { throw BZip2Error.wrongCRC(out) }
                totalCRC = (totalCRC << 1) | (totalCRC >> 31)
                totalCRC ^= blockCRC32
            } else if blockType == 0x1772_4538_5090 {
                guard totalCRC == blockCRC32
                else { throw BZip2Error.wrongCRC(out) }
                break
            } else {
                throw BZip2Error.wrongBlockType
            }
        }

        return out
    }

    private static func decode(_ bitReader: MsbBitReader, _ blockSize: BlockSize) throws -> Data {
        let isRandomized = bitReader.bit()
        guard isRandomized == 0
        else { throw BZip2Error.randomizedBlock }

        let pointer = bitReader.int(fromBits: 24)

        // Decoding which symbols are used in Huffman tables.
        // The "list" of all possible 256 symbols is split into 16 blocks.
        // If no symbols from a block are in use, then the block is not present.
        // First, we decode which blocks are present.
        let usedBlocksBitMap = UInt16(bitReader.int(fromBits: 16))
        var blockMask = 1 << 15 as UInt16
        var usedSymbols = [UInt8]()
        // Two additional symbols are RUNA and RUNB.
        var usedSymbolsCount = 2
        while blockMask > 0 {
            if usedBlocksBitMap & blockMask > 0 {
                // Each block, if present, is a set of 16 bits which, if set, represent that the corresponding symbols
                // are in use by Huffman tables.
                let usedSymbolsBitMask = UInt16(bitReader.int(fromBits: 16))
                var symbolMask = 1 << 15 as UInt16
                while symbolMask > 0 {
                    if usedSymbolsBitMask & symbolMask > 0 {
                        usedSymbolsCount += 1
                        usedSymbols.append(UInt8(blockMask.leadingZeroBitCount * 16 + symbolMask.leadingZeroBitCount))
                    }
                    symbolMask >>= 1
                }
            }
            blockMask >>= 1
        }

        let huffmanGroups = bitReader.int(fromBits: 3)
        guard huffmanGroups >= 2, huffmanGroups <= 6
        else { throw BZip2Error.wrongHuffmanGroups }

        func computeSelectors() throws -> [Int] {
            let selectorsUsed = bitReader.int(fromBits: 15)

            var mtf = Array(0 ..< huffmanGroups)
            var selectorsList = [Int]()

            for _ in 0 ..< selectorsUsed {
                var c = 0
                while bitReader.bit() > 0 {
                    c += 1
                    guard c < huffmanGroups
                    else { throw BZip2Error.wrongSelector }
                }
                if c >= 0 {
                    let el = mtf.remove(at: c)
                    mtf.insert(el, at: 0)
                }
                selectorsList.append(mtf[0])
            }

            return selectorsList
        }

        let selectors = try computeSelectors()

        func computeTables() throws -> [DecodingTree] {
            var tables = [DecodingTree]()
            for _ in 0 ..< huffmanGroups {
                var length = bitReader.int(fromBits: 5)
                var lengths = [CodeLength]()
                for i in 0 ..< usedSymbolsCount {
                    guard length >= 0, length <= 20
                    else { throw BZip2Error.wrongHuffmanCodeLength }
                    while bitReader.bit() > 0 {
                        length -= (bitReader.bit().toInt() * 2 - 1)
                    }
                    if length > 0 {
                        lengths.append(CodeLength(symbol: i, codeLength: length))
                    }
                }
                let codes = Code.huffmanCodes(from: lengths)
                let table = DecodingTree(codes: codes.codes, maxBits: codes.maxBits, bitReader)
                tables.append(table)
            }

            return tables
        }

        let tables = try computeTables()

        var selectorPointer = 0
        var decoded = 0
        var runLength = 0
        var repeatPower = 0
        var buffer: [UInt8] = []
        var currentTable: DecodingTree?

        while true {
            decoded -= 1
            if decoded <= 0 {
                decoded = 50
                if selectorPointer == selectors.count {
                    throw BZip2Error.wrongSelector
                } else if selectorPointer < selectors.count {
                    currentTable = tables[selectors[selectorPointer]]
                    selectorPointer += 1
                }
            }

            guard let symbol = currentTable?.findNextSymbol(), symbol != -1
            else { throw BZip2Error.symbolNotFound }

            if symbol == 0 || symbol == 1 { // RUNA and RUNB symbols.
                if runLength == 0 {
                    repeatPower = 1
                }
                runLength += repeatPower << symbol
                repeatPower <<= 1
                continue
            } else if runLength > 0 {
                for _ in 0 ..< runLength {
                    buffer.append(usedSymbols[0])
                }
                runLength = 0
            }
            if symbol == usedSymbolsCount - 1 { // End of stream symbol.
                break
            } else { // Move to front inverse.
                let element = usedSymbols.remove(at: symbol - 1)
                usedSymbols.insert(element, at: 0)
                buffer.append(element)
            }
        }

        let nt = BurrowsWheeler.reverse(bytes: buffer, pointer)

        // Run Length Decoding
        var i = 0
        var out = [UInt8]()
        out.reserveCapacity(blockSize.sizeInKilobytes * 1000)
        while i < nt.count {
            if i < nt.count - 4, nt[i] == nt[i + 1], nt[i] == nt[i + 2], nt[i] == nt[i + 3] {
                // While the reference implementation of BZip2 doesn't produce such output, the "specification"
                // technically allows run lengths greater than 255. To allow this we have to convert to Int.
                let runLength = nt[i + 4].toInt() + 4
                for _ in 0 ..< runLength {
                    out.append(nt[i])
                }
                i += 5
            } else {
                out.append(nt[i])
                i += 1
            }
        }

        return Data(out)
    }
}
