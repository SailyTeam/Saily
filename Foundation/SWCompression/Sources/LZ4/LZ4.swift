// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import BitByteData
import Foundation

/// Provides functions for compression and decompression for LZ4 algorithm.
public enum LZ4: DecompressionAlgorithm {
    // Notes about implementation and performance.
    // -------------------------------------------
    // 1. Whenever feasible we try to use [UInt8] instead of Data instances. The reason for this is that most functions
    //    of Data are much slower than their Array counterparts. In particular, this concerns append(_:) function and
    //    various subscripts. At the moment, we only use [UInt8] as the type of the output of the process(block:_:)
    //    function, but in the future we should consider changing outputs of other internal functions to [UInt8] as well
    //    in order to achieve better performance.
    //
    // 2. This implementation has been programmed extremely defensively. This means, that it checks constantly that
    //    every access to the input data will be within bounds. However, in some cases it may be unnecessary, so in the
    //    future if we are able to prove that certain operations can never be out of bounds (based on algorithm logic),
    //    we should remove corresponding checks to increase performance (or perhaps retain them only as assertions,
    //    which are eliminated in Release mode).
    //
    // 3. Compared to the implementations of other algorithms, this implementation features significantly reduced usage
    //    of types from BitByteData, such as LittleEndianByteReader. The reason for this is that currently they are a
    //    big source of sloweness, due to the effect of exclusivity checks on the property access of classes. Because
    //    of this we try to avoid accessing the properties of the LittleEndianByteReader whenever possible.
    //    For example, in the process(block:_:) function we compute the remaining bytes directly by using data.endIndex
    //    and reader.offset instead of relying on the reader.bytesLeft computed property.

    /**
     Decompresses `data` using LZ4 algortihm.

     Use `LZ4.decompress(data:dictionary:dictionaryID:)` instead, if the data was compressed with an external dictionary.
     Otherwise, the decompression will result in an error or incorrect output.

     - Parameter data: Data compressed with LZ4. If `data` represents several concatenated LZ4 frames, only the first
     frame will be processed; use `LZ4.multiDecompress(data:dictionary:dictionaryID:)` instead to decompress all the
     frames.

     - Throws: `DataError.corrupted` or `DataError.truncated` if the data is corrupted or truncated.
     `DataError.checksumMismatch` is thrown with uncompressed data as its associated value if the computed checksum of
     the uncompressed data does not match the stored checksum. `DataError.unsupportedFeature` is thrown when the value
     of a field inside the frame, such as uncompressed data size, is incompatible with the maximum integer size of the
     current platform.
     */
    public static func decompress(data: Data) throws -> Data {
        try LZ4.decompress(data: data, dictionary: nil)
    }

    /**
     Decompresses `data` using LZ4 algortihm and provided external dictionary.

     - Parameter data: Data compressed with LZ4. If `data` represents several concatenated LZ4 frames, only the first
     frame will be processed; use `LZ4.multiDecompress(data:dictionary:dictionaryID:)` instead to decompress all the
     frames.

     - Parameter dictionary: External dictionary which will be used during decompression. Providing incorrect dictionary
     (not the one that was used for compression), no dictionary at all (if one was used for compression), or providing a
     dictionary when no dictionary was used for compression will result in an error or incorrect output.

     - Parameter dictionaryID: Optional dictionary ID, which must match the one stored in the frame. If no dictionary
     ID is present in the frame, then this argument is ignored.

     - Throws: `DataError.corrupted` or `DataError.truncated` if the data is corrupted or truncated.
     `DataError.checksumMismatch` is thrown with uncompressed data as its associated value if the computed checksum of
     the uncompressed data does not match the stored checksum. `DataError.unsupportedFeature` is thrown when the value
     of a field inside the frame, such as uncompressed data size, is incompatible with the maximum integer size of the
     current platform.
     */
    public static func decompress(data: Data, dictionary: Data?, dictionaryID: UInt32? = nil) throws -> Data {
        // Valid LZ4 frame must contain at least a magic number (4 bytes).
        guard data.count >= 4
        else { throw DataError.truncated }

        // Magic number.
        let magic = data[data.startIndex ..< data.startIndex + 4].withUnsafeBytes { $0.bindMemory(to: UInt32.self)[0] }
        switch magic {
        case 0x184D_2204:
            return try LZ4.process(frame: data[(data.startIndex + 4)...], dictionary, dictionaryID).0
        case 0x184D_2A50 ... 0x184D_2A5F:
            let frameSize = try process(skippableFrame: data[(data.startIndex + 4)...])
            return try LZ4.decompress(data: data[(data.startIndex + 4 + frameSize)...])
        case 0x184C_2102:
            return try LZ4.process(legacyFrame: data[(data.startIndex + 4)...]).0
        default:
            throw DataError.corrupted
        }
    }

    /**
     Decompresses `data`, which may represent several concatenated LZ4 frames, using LZ4 algortihm and provided external
     dictionary.

     - Parameter data: Data compressed with LZ4. If `data` represents several concatenated LZ4 frames, all of them will
     be processed.

     - Parameter dictionary: External dictionary which will be used during decompression of all encountered frames.
     Providing incorrect dictionary (not the one that was used for compression), no dictionary at all (if one was used
     for compression), or providing a dictionary when no dictionary was used for compression will result in an error or
     incorrect output.

     - Parameter dictionaryID: Optional dictionary ID, which must match the one stored in all frames. If no dictionary
     ID is present in a frame, then this argument is ignored for that frame.

     - Throws: `DataError.corrupted` or `DataError.truncated` if the data is corrupted or truncated.
     `DataError.checksumMismatch` is thrown if the computed checksum of the uncompressed data does not match the stored
     checksum. The associated value in this case contains uncompressed data from all the frames up to and including the
     one that caused this error. `DataError.unsupportedFeature` is thrown when the value of a field inside a frame, such
     as uncompressed data size, is incompatible with the maximum integer size of the current platform.

     - Returns: An array with uncompressed data from each processed non-skippable LZ4 frame as its elements.
     */
    public static func multiDecompress(data: Data, dictionary: Data? = nil, dictionaryID: UInt32? = nil) throws -> [Data] {
        var result = [Data]()
        var nextFrameOffset = data.startIndex

        repeat {
            // Magic number.
            // The input must contain at least one valid LZ4 frame, which in turn must contain at least a magic number.
            guard nextFrameOffset + 4 <= data.endIndex
            else { throw DataError.truncated }
            let magic = data[nextFrameOffset ..< nextFrameOffset + 4].withUnsafeBytes { $0.bindMemory(to: UInt32.self)[0] }
            nextFrameOffset += 4
            var out: Data?

            switch magic {
            case 0x184D_2204:
                (out, nextFrameOffset) = try LZ4.process(frame: data[nextFrameOffset...], dictionary, dictionaryID)
            case 0x184D_2A50 ... 0x184D_2A5F:
                nextFrameOffset += try process(skippableFrame: data[nextFrameOffset...])
            case 0x184C_2102:
                (out, nextFrameOffset) = try LZ4.process(legacyFrame: data[nextFrameOffset...])
            default:
                throw DataError.corrupted
            }

            if let out = out {
                result.append(out)
            }
        } while nextFrameOffset < data.endIndex

        return result
    }

    private static func process(skippableFrame data: Data) throws -> Data.Index {
        guard data.count >= 4
        else { throw DataError.truncated }
        let size = data[data.startIndex ..< data.startIndex + 4].withUnsafeBytes { $0.bindMemory(to: UInt32.self)[0] }.toInt()
        guard data.count >= size + 4
        else { throw DataError.truncated }
        return size + 4
    }

    // The functions below return uncompressed data and the offset to the next byte after the processed frame (even if
    // the end of the input data was reached). The offset is needed to make multiDecompress function work.

    private static func process(legacyFrame data: Data) throws -> (Data, Data.Index) {
        let reader = LittleEndianByteReader(data: data)
        var out = Data()
        // The end of a frame is determined by either end-of-file or by encountering a valid frame magic number.
        while !reader.isFinished {
            guard reader.bytesLeft >= 4
            else { throw DataError.truncated }
            let rawBlockSize = reader.uint32()
            if rawBlockSize == 0x184D_2204 || rawBlockSize == 0x184C_2102 || 0x184D_2A50 ... 0x184D_2A5F ~= rawBlockSize {
                reader.offset -= 4
                break
            }
            // Detects overflow issues on 32-bit platforms.
            guard rawBlockSize <= UInt32(truncatingIfNeeded: Int.max)
            else { throw DataError.unsupportedFeature }
            let blockSize = Int(truncatingIfNeeded: rawBlockSize)

            guard reader.bytesLeft >= blockSize
            else { throw DataError.truncated }

            let blockData = data[reader.offset ..< reader.offset + blockSize]
            reader.offset += blockSize

            out.append(Data(try LZ4.process(block: blockData)))
        }
        return (out, reader.offset)
    }

    private static func process(frame data: Data, _ dictionary: Data?, _ extDictId: UInt32?) throws -> (Data, Data.Index) {
        // Valid LZ4 frame must contain a frame descriptor (at least 3 bytes) and the EndMark (4 bytes), assuming no
        // data blocks.
        guard data.count >= 7
        else { throw DataError.truncated }
        let reader = LittleEndianByteReader(data: data)

        // Frame Descriptor
        let flg = reader.byte()
        // Version number and reserved bit check.
        guard (flg & 0xC0) >> 6 == 1, flg & 0x2 == 0
        else { throw DataError.corrupted }

        /// True, if blocks are independent and thus multi-threaded decoding is possible. Otherwise, blocks must be
        /// decoded in sequence.
        let independentBlocks = (flg & 0x20) >> 5 == 1
        /// True, if each data block is followed by a checksum for compressed data, which can be used to detect data
        /// corruption before decoding.
        let blockChecksumPresent = (flg & 0x10) >> 4 == 1
        /// True, if the size of uncompressed data is present after the flags.
        let contentSizePresent = (flg & 0x8) >> 3 == 1
        /// True, if the checksum for uncompressed data is present after the EndMark.
        let contentChecksumPresent = (flg & 0x4) >> 2 == 1
        /// True, if the dictionary ID field is present after the flags and content size.
        let dictIdPresent = flg & 1 == 1

        let bd = reader.byte()
        let maxBlockSize: Int
        switch bd {
        case 0x40:
            maxBlockSize = 64 * 1024
        case 0x50:
            maxBlockSize = 256 * 1024
        case 0x60:
            maxBlockSize = 1024 * 1024
        case 0x70:
            maxBlockSize = 4 * 1024 * 1024
        default:
            // This case corresponds to the reserved bits check.
            throw DataError.corrupted
        }

        let contentSize: Int?
        if contentSizePresent {
            // At this point valid LZ4 frame must have at least 13 bytes remaining for: content size (8 bytes), header
            // checksum (1 byte), and EndMark (4 bytes), assuming zero data blocks.
            guard reader.bytesLeft >= 13
            else { throw DataError.truncated }
            // Since Data is indexed by the Int type, the maximum size of the uncompressed data that we can decode is
            // Int.max. However, LZ4 supports uncompressed data sizes up to UInt64.max, which is larger, so we check
            // for this possibility.
            let rawContentSize = reader.uint64()
            guard rawContentSize <= UInt64(truncatingIfNeeded: Int.max)
            else { throw DataError.unsupportedFeature }
            contentSize = Int(truncatingIfNeeded: rawContentSize)
        } else {
            contentSize = nil
        }

        let dictId: Int?
        if dictIdPresent {
            // If dictionary ID is present in the frame, then we must have a dictionary to successfully decode it.
            guard dictionary != nil
            else { throw DataError.corrupted }
            // At this point valid LZ4 frame must have at least 9 bytes remaining for: dictionary ID (4 bytes), header
            // checksum (1 byte), and EndMark (4 bytes), assuming zero data blocks.
            guard reader.bytesLeft >= 9
            else { throw DataError.truncated }

            let rawDictID = reader.uint32()
            // Detects overflow issues on 32-bit platforms.
            guard rawDictID <= UInt32(truncatingIfNeeded: Int.max)
            else { throw DataError.unsupportedFeature }
            dictId = Int(truncatingIfNeeded: rawDictID)
        } else {
            dictId = nil
        }

        if let extDictId = extDictId, let dictId = dictId {
            // If dictionary ID is present in the frame, and passed as an argument, then they must be equal.
            guard extDictId == dictId
            else { throw DataError.corrupted }
        }

        let headerData = data[data.startIndex ..< data.startIndex + 2 + (contentSizePresent ? 8 : 0) + (dictIdPresent ? 4 : 0)]
        let headerChecksum = XxHash32.hash(data: headerData)
        guard UInt8(truncatingIfNeeded: (headerChecksum >> 8) & 0xFF) == reader.byte()
        else { throw DataError.corrupted }

        var out = Data()
        while true {
            guard reader.bytesLeft >= 4
            else { throw DataError.truncated }
            // Either the size of the block, or the EndMark.
            let blockMark = reader.uint32()
            // Check for the EndMark.
            if blockMark == 0 {
                break
            }
            // The highest bit indicates if the block is compressed.
            let compressed = blockMark & 0x8000_0000 == 0
            let blockSize = (blockMark & 0x7FFF_FFFF).toInt()
            // Since we don't do manual memory allocation we don't have to constraint the block size. Nevertheless, we
            // follow the reference implementation here and reject blocks with sizes greater than maximum block size.
            guard blockSize <= maxBlockSize
            else { throw DataError.corrupted }

            guard reader.bytesLeft >= blockSize + (blockChecksumPresent ? 4 : 0) + 4
            else { throw DataError.truncated }

            let blockData = data[reader.offset ..< reader.offset + blockSize]
            reader.offset += blockSize
            guard !blockChecksumPresent || XxHash32.hash(data: blockData) == reader.uint32()
            else { throw DataError.corrupted }

            if compressed {
                if independentBlocks {
                    out.append(Data(try LZ4.process(block: blockData, dictionary)))
                } else {
                    if out.isEmpty, let dictionary = dictionary {
                        out.append(Data(try LZ4.process(block: blockData,
                                                        dictionary[max(dictionary.endIndex - 64 * 1024, dictionary.startIndex)...])))
                    } else {
                        out.append(Data(try LZ4.process(block: blockData,
                                                        out[max(out.endIndex - 64 * 1024, out.startIndex)...])))
                    }
                }
            } else {
                out.append(blockData)
            }
        }
        if contentSizePresent {
            guard out.count == contentSize
            else { throw DataError.corrupted }
        }
        if contentChecksumPresent {
            guard reader.bytesLeft >= 4
            else { throw DataError.truncated }
            guard XxHash32.hash(data: out) == reader.uint32()
            else { throw DataError.checksumMismatch([out]) }
        }
        return (out, reader.offset)
    }

    private static func process(block data: Data, _ dict: Data? = nil) throws -> [UInt8] {
        let reader = LittleEndianByteReader(data: data)
        var out = dict?.withUnsafeBytes { $0.map { $0 } } ?? [UInt8]()
        let outStartIndex = out.endIndex

        // These two variables are used in verifying the end of block restrictions.
        var sequenceCount = 0
        var lastMatchStartIndex = -1

        while true {
            sequenceCount += 1
            guard data.endIndex - reader.offset >= 1
            else { throw DataError.truncated }
            let token = reader.byte()

            var literalCount = (token >> 4).toInt()
            if literalCount == 15 {
                while true {
                    guard data.endIndex - reader.offset >= 1
                    else { throw DataError.truncated }
                    let byte = reader.byte()
                    // There is no size limit on the literal count, so we need to check that it remains within Int range
                    // (similar to content size considerations).
                    let (newLiteralCount, overflow) = literalCount.addingReportingOverflow(byte.toInt())
                    guard !overflow
                    else { throw DataError.unsupportedFeature }
                    literalCount = newLiteralCount
                    if byte != 255 {
                        break
                    }
                }
            }
            guard data.endIndex - reader.offset >= literalCount
            else { throw DataError.truncated }
            out.append(contentsOf: reader.bytes(count: literalCount))

            // The last sequence contains only literals.
            if reader.isFinished {
                // End of block restrictions.
                guard literalCount >= 5 || sequenceCount == 1
                else { throw DataError.corrupted }
                guard out.endIndex - lastMatchStartIndex >= 12 || lastMatchStartIndex == -1
                else { throw DataError.corrupted }
                break
            }

            guard data.endIndex - reader.offset >= 2
            else { throw DataError.truncated }
            let offset = reader.uint16().toInt()
            // The value of 0 is not valid.
            guard offset > 0, offset <= out.endIndex
            else { throw DataError.corrupted }

            var matchLength = 4 + (token & 0xF).toInt()
            if matchLength == 19 {
                while true {
                    guard data.endIndex - reader.offset >= 1
                    else { throw DataError.truncated }
                    let byte = reader.byte()
                    // Again, there is no size limit on the match length, so we need to check that it remains within Int
                    // range.
                    let (newMatchLength, overflow) = matchLength.addingReportingOverflow(byte.toInt())
                    guard !overflow
                    else { throw DataError.unsupportedFeature }
                    matchLength = newMatchLength
                    if byte != 255 {
                        break
                    }
                }
            }

            // We record the start index of the last encountered match to verify it against end-of-block restrictions.
            // Note, that this refers to the bytes that we have found a match for, and not to the bytes that we're
            // matching to.
            lastMatchStartIndex = out.endIndex
            let matchStartIndex = out.endIndex - offset
            for i in 0 ..< matchLength {
                out.append(out[matchStartIndex + i])
            }
        }

        return Array(out[outStartIndex...])
    }
}
