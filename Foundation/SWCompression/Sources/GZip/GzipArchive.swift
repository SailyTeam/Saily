// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import BitByteData
import Foundation

/// Provides unarchive and archive functions for GZip archives.
public class GzipArchive: Archive {
    /// Represents the member of a multi-member GZip archive.
    public struct Member {
        /// GZip header of a member.
        public let header: GzipHeader

        /// Unarchived data from a member.
        public let data: Data

        let crcError: Bool
    }

    /**
     Unarchives GZip archive.

     - Note: This function is specification compliant.

     - Parameter archive: Data archived with GZip.

     - Throws: `DeflateError` or `GzipError` depending on the type of the problem.
     It may indicate that either archive is damaged or it might not be archived with GZip
     or compressed with Deflate at all.

     - Returns: Unarchived data.
     */
    public static func unarchive(archive data: Data) throws -> Data {
        /// Object with input data which supports convenient work with bit shifts.
        let bitReader = LsbBitReader(data: data)

        let member = try processMember(bitReader)

        guard !member.crcError
        else { throw GzipError.wrongCRC([member]) }

        return member.data
    }

    /**
     Unarchives multi-member GZip archive.
     Multi-member GZip archives are essentially several GZip archives following each other in a single file.

     - Parameter archive: GZip archive with one or more members.

     - Throws: `DeflateError` or `GzipError` depending on the type of the problem.
     It may indicate that one of the members of archive is damaged or
     it might not be archived with GZip or compressed with Deflate at all.

     - Returns: Unarchived data.
     */
    public static func multiUnarchive(archive data: Data) throws -> [Member] {
        /// Object with input data which supports convenient work with bit shifts.
        let bitReader = LsbBitReader(data: data)

        var result = [Member]()
        while !bitReader.isFinished {
            let member = try processMember(bitReader)

            result.append(member)

            guard !member.crcError
            else { throw GzipError.wrongCRC(result) }
        }

        return result
    }

    private static func processMember(_ bitReader: LsbBitReader) throws -> Member {
        // Valid GZip archive must contain at least 20 bytes of data (10 for the header, 2 for an empty Deflate block,
        // and 8 for checksums). In addition, since GZip format is "byte-oriented" we should ensure that members are
        // byte-aligned.
        guard bitReader.isAligned, bitReader.bytesLeft >= 20
        else { throw GzipError.wrongMagic }

        let header = try GzipHeader(bitReader)

        let memberData = try Deflate.decompress(bitReader)
        bitReader.align()

        guard bitReader.bytesLeft >= 8
        else { throw GzipError.wrongMagic }
        let crc32 = bitReader.uint32()
        let isize = bitReader.uint64(fromBytes: 4)
        guard UInt64(truncatingIfNeeded: memberData.count) % (UInt64(truncatingIfNeeded: 1) << 32) == isize
        else { throw GzipError.wrongISize }

        return Member(header: header, data: memberData,
                      crcError: CheckSums.crc32(memberData) != crc32)
    }

    /**
     Archives `data` into GZip archive, using various specified options.
     Data will be also compressed with Deflate algorithm.
     It will be also specified in archive's header that the compressor used the slowest Deflate algorithm.

     - Note: This function is specification compliant.

     - Parameter data: Data to compress and archive.
     - Parameter comment: Additional comment, which will be stored as a separate field in archive.
     - Parameter fileName: Name of the file which will be archived.
     - Parameter writeHeaderCRC: Set to true, if you want to store consistency check for archive's header.
     - Parameter isTextFile: Set to true, if the file which will be archived is text file or ASCII-file.
     - Parameter osType: Type of the system on which this archive will be created.
     - Parameter modificationTime: Last time the file was modified.
     - Parameter extraFields: Any extra fields. Note that no extra field is allowed to have second byte of the extra
     field (subfield) ID equal to zero. In addition, the length of a field's binary content must be less than
     `UInt16.max`, while the total sum of the binary content length of all extra fields plus 4 for each field must also
     not exceed `UInt16.max`. See GZip format specification for more details.

     - Throws: `GzipError.cannotEncodeISOLatin1` if a file name or a comment cannot be encoded with ISO-Latin-1 encoding
     or if the total sum of the binary content length of all extra fields plus 4 for each field exceeds `UInt16.max`.

     - Returns: Resulting archive's data.
     */
    public static func archive(data: Data, comment: String? = nil, fileName: String? = nil,
                               writeHeaderCRC: Bool = false, isTextFile: Bool = false,
                               osType: FileSystemType? = nil, modificationTime: Date? = nil,
                               extraFields: [GzipHeader.ExtraField] = []) throws -> Data
    {
        var flags: UInt8 = 0

        var commentData = Data()
        if var comment = comment {
            flags |= 1 << 4
            if comment.last != "\u{00}" {
                comment.append("\u{00}")
            }
            if let data = comment.data(using: .isoLatin1) {
                commentData = data
            } else {
                throw GzipError.cannotEncodeISOLatin1
            }
        }

        var fileNameData = Data()
        if var fileName = fileName {
            flags |= 1 << 3
            if fileName.last != "\u{00}" {
                fileName.append("\u{00}")
            }
            if let data = fileName.data(using: .isoLatin1) {
                fileNameData = data
            } else {
                throw GzipError.cannotEncodeISOLatin1
            }
        }

        if !extraFields.isEmpty {
            flags |= 1 << 2
        }

        if writeHeaderCRC {
            flags |= 1 << 1
        }

        if isTextFile {
            flags |= 1 << 0
        }

        let os = osType?.osTypeByte ?? 255

        var mtimeBytes: [UInt8] = [0, 0, 0, 0]
        if let modificationTime = modificationTime {
            let timeInterval = Int(modificationTime.timeIntervalSince1970)
            for i in 0 ..< 4 {
                mtimeBytes[i] = UInt8(truncatingIfNeeded: (timeInterval & (0xFF << (i * 8))) >> (i * 8))
            }
        }

        var headerBytes: [UInt8] = [
            0x1F, 0x8B, // 'magic' bytes.
            8, // Compression method (DEFLATE).
            flags,
        ]
        for i in 0 ..< 4 {
            headerBytes.append(mtimeBytes[i])
        }
        headerBytes.append(2) // Extra flags; 2 means that DEFLATE used slowest algorithm.
        headerBytes.append(os)

        if !extraFields.isEmpty {
            let xlen = extraFields.reduce(0) { $0 + 4 + $1.bytes.count }
            guard xlen <= UInt16.max
            else { throw GzipError.cannotEncodeISOLatin1 }
            headerBytes.append((xlen & 0xFF).toUInt8())
            headerBytes.append(((xlen >> 8) & 0xFF).toUInt8())

            for extraField in extraFields {
                headerBytes.append(extraField.si1)
                headerBytes.append(extraField.si2)

                let len = extraField.bytes.count
                headerBytes.append((len & 0xFF).toUInt8())
                headerBytes.append(((len >> 8) & 0xFF).toUInt8())

                for byte in extraField.bytes {
                    headerBytes.append(byte)
                }
            }
        }

        var outData = Data(headerBytes)

        outData.append(fileNameData)
        outData.append(commentData)

        if writeHeaderCRC {
            let headerCRC = CheckSums.crc32(outData)
            for i: UInt32 in 0 ..< 2 {
                outData.append(UInt8(truncatingIfNeeded: (headerCRC & (0xFF << (i * 8))) >> (i * 8)))
            }
        }

        outData.append(Deflate.compress(data: data))

        let crc32 = CheckSums.crc32(data)
        var crcBytes = [UInt8]()
        for i: UInt32 in 0 ..< 4 {
            crcBytes.append(UInt8(truncatingIfNeeded: (crc32 & (0xFF << (i * 8))) >> (i * 8)))
        }
        outData.append(Data(crcBytes))

        let isize = UInt64(data.count) % UInt64(1) << 32
        var isizeBytes = [UInt8]()
        for i: UInt64 in 0 ..< 4 {
            isizeBytes.append(UInt8(truncatingIfNeeded: (isize & (0xFF << (i * 8))) >> (i * 8)))
        }
        outData.append(Data(isizeBytes))

        return outData
    }
}
