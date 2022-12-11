// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import BitByteData
import Foundation

/// Represents the header of a GZip archive.
public struct GzipHeader {
    struct Flags: OptionSet {
        let rawValue: UInt8

        init(rawValue: UInt8) {
            self.rawValue = rawValue
        }

        static let ftext = Flags(rawValue: 0x01)
        static let fhcrc = Flags(rawValue: 0x02)
        static let fextra = Flags(rawValue: 0x04)
        static let fname = Flags(rawValue: 0x08)
        static let fcomment = Flags(rawValue: 0x10)
    }

    /// Compression method of archive. Always `.deflate` for GZip archives.
    public var compressionMethod: CompressionMethod

    /**
     The most recent modification time of the original file. If corresponding archive's field is set to 0, which means
     that no time was specified, then this property is `nil`.
     */
    public var modificationTime: Date?

    /// Type of file system on which archivation took place.
    public var osType: FileSystemType

    /// Name of the original file. If archive doesn't contain file's name, then `nil`.
    public var fileName: String?

    /// Comment stored in archive. If archive doesn't contain any comment, then `nil`.
    public var comment: String?

    /// True, if file is likely to be text file or ASCII-file.
    public var isTextFile: Bool

    /**
     Extra fields present in the header.

     - Note: This feature of the GZip format is extremely rarely used, so in vast majority of cases this property
     contains an empty array.
     */
    public var extraFields: [ExtraField]

    /**
     Initializes the structure with the values from the first 'member' of GZip `archive`.

     - Parameter archive: Data archived with GZip.

     - Throws: `GzipError`. It may indicate that either archive is damaged or
     it might not be archived with GZip at all.
     */
    public init(archive data: Data) throws {
        let reader = LsbBitReader(data: data)
        try self.init(reader)
    }

    init(_ reader: LsbBitReader) throws {
        // Valid GZip header must contain at least 10 bytes of data.
        guard reader.bytesLeft >= 10
        else { throw GzipError.wrongMagic }

        // First two bytes should be correct 'magic' bytes
        let magic = reader.uint16()
        guard magic == 0x8B1F
        else { throw GzipError.wrongMagic }
        var headerBytes: [UInt8] = [0x1F, 0x8B]

        // Third byte is a method of compression. Only type 8 (DEFLATE) compression is supported for GZip archives.
        let method = reader.byte()
        guard method == 8
        else { throw GzipError.wrongCompressionMethod }
        headerBytes.append(method)
        compressionMethod = .deflate

        let rawFlags = reader.byte()
        guard rawFlags & 0xE0 == 0
        else { throw GzipError.wrongFlags }
        let flags = Flags(rawValue: rawFlags)
        headerBytes.append(rawFlags)

        var mtime = 0
        for i in 0 ..< 4 {
            let byte = reader.byte()
            mtime |= byte.toInt() << (8 * i)
            headerBytes.append(byte)
        }
        modificationTime = mtime == 0 ? nil : Date(timeIntervalSince1970: TimeInterval(mtime))

        let extraFlags = reader.byte()
        headerBytes.append(extraFlags)

        let rawOsType = reader.byte()
        osType = FileSystemType(rawOsType)
        headerBytes.append(rawOsType)

        isTextFile = flags.contains(.ftext)

        // Some archives may contain extra fields.
        extraFields = [ExtraField]()
        if flags.contains(.fextra) {
            guard reader.bytesLeft >= 2
            else { throw GzipError.wrongMagic }
            var xlen = 0
            for i in 0 ..< 2 {
                let byte = reader.byte()
                xlen |= byte.toInt() << (8 * i)
                headerBytes.append(byte)
            }

            while xlen > 0 {
                // There must be least four bytes of extra fields for SI1, SI2, and 2 bytes of the length parameter
                // filled with zeros (minimal variant).
                guard reader.bytesLeft >= xlen, xlen >= 4
                else { throw GzipError.wrongMagic }

                let si1 = reader.byte()
                headerBytes.append(si1)

                let si2 = reader.byte()
                // IDs with zero in the second byte are reserved.
                guard si2 != 0
                else { throw GzipError.wrongFlags }
                headerBytes.append(si2)

                var len = 0
                for i in 0 ..< 2 {
                    let byte = reader.byte()
                    len |= byte.toInt() << (8 * i)
                    headerBytes.append(byte)
                }
                xlen -= 4

                // Total remaining extra fields length must be larger than the length of the binary content of the
                // current extra field.
                guard xlen >= len
                else { throw GzipError.wrongMagic }
                var extraFieldBytes = [UInt8]()
                for _ in 0 ..< len {
                    let byte = reader.byte()
                    extraFieldBytes.append(byte)
                    headerBytes.append(byte)
                }
                extraFields.append(ExtraField(si1, si2, extraFieldBytes))
                xlen -= len
            }
        }

        // Some archives may contain source file name (this part ends with a zero byte)
        if flags.contains(.fname) {
            var fnameBytes: [UInt8] = []
            while true {
                guard !reader.isFinished
                else { throw GzipError.wrongMagic }
                let byte = reader.byte()
                headerBytes.append(byte)
                guard byte != 0 else { break }
                fnameBytes.append(byte)
            }
            fileName = String(data: Data(fnameBytes), encoding: .isoLatin1)
        } else {
            fileName = nil
        }

        // Some archives may contain comment (this part also ends with zero)
        if flags.contains(.fcomment) {
            var fcommentBytes: [UInt8] = []
            while true {
                guard !reader.isFinished
                else { throw GzipError.wrongMagic }
                let byte = reader.byte()
                headerBytes.append(byte)
                guard byte != 0 else { break }
                fcommentBytes.append(byte)
            }
            comment = String(data: Data(fcommentBytes), encoding: .isoLatin1)
        } else {
            comment = nil
        }

        // Some archives may contain 2-bytes checksum
        if flags.contains(.fhcrc) {
            // It is not an actual CRC-16, it's just two least significant bytes of CRC-32.
            guard reader.bytesLeft >= 2
            else { throw GzipError.wrongMagic }
            let crc16 = reader.uint16()
            guard CheckSums.crc32(headerBytes) & 0xFFFF == crc16
            else { throw GzipError.wrongHeaderCRC }
        }
    }
}
