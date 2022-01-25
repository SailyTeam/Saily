// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import BitByteData
import Foundation

struct ZipCentralDirectoryEntry {
    let versionMadeBy: UInt16
    let versionNeeded: UInt16
    let generalPurposeBitFlags: UInt16
    let compressionMethod: UInt16
    let lastModFileTime: UInt16
    let lastModFileDate: UInt16
    let crc32: UInt32
    private(set) var compSize: UInt64
    private(set) var uncompSize: UInt64

    let fileName: String
    let fileComment: String

    private(set) var diskNumberStart: UInt32

    let internalFileAttributes: UInt16
    let externalFileAttributes: UInt32

    private(set) var localHeaderOffset: UInt64

    // 0x5455 extra field.
    private(set) var extendedTimestampExtraField: ExtendedTimestampExtraField?

    /// 0x000a extra field.
    private(set) var ntfsExtraField: NtfsExtraField?

    // 0x7855 extra field doesn't have any information in Central Directory.

    /// 0x7875 extra field.
    private(set) var infoZipNewUnixExtraField: InfoZipNewUnixExtraField?

    let customExtraFields: [ZipExtraField]

    let nextEntryOffset: Int

    init(_ byteReader: LittleEndianByteReader) throws {
        // Check signature.
        guard byteReader.uint32() == 0x0201_4B50
        else { throw ZipError.wrongSignature }

        versionMadeBy = byteReader.uint16()
        versionNeeded = byteReader.uint16()

        generalPurposeBitFlags = byteReader.uint16()
        let useUtf8 = generalPurposeBitFlags & 0x800 != 0

        compressionMethod = byteReader.uint16()

        lastModFileTime = byteReader.uint16()
        lastModFileDate = byteReader.uint16()

        crc32 = byteReader.uint32()

        compSize = byteReader.uint64(fromBytes: 4)
        uncompSize = byteReader.uint64(fromBytes: 4)

        let fileNameLength = byteReader.int(fromBytes: 2)
        let extraFieldLength = byteReader.int(fromBytes: 2)
        let fileCommentLength = byteReader.int(fromBytes: 2)

        diskNumberStart = byteReader.uint32(fromBytes: 2)

        internalFileAttributes = byteReader.uint16()
        externalFileAttributes = byteReader.uint32()

        localHeaderOffset = byteReader.uint64(fromBytes: 4)

        guard let fileName = byteReader.zipString(fileNameLength, useUtf8)
        else { throw ZipError.wrongTextField }
        self.fileName = fileName

        let extraFieldStart = byteReader.offset
        var customExtraFields = [ZipExtraField]()
        while byteReader.offset - extraFieldStart < extraFieldLength {
            // There are a lot of possible extra fields.
            let headerID = byteReader.uint16()
            let size = byteReader.int(fromBytes: 2)
            switch headerID {
            case 0x0001: // Zip64
                // Zip64 extra field is a special case, because it requires knowledge about central directory fields.
                if uncompSize == 0xFFFF_FFFF {
                    uncompSize = byteReader.uint64()
                }
                if compSize == 0xFFFF_FFFF {
                    compSize = byteReader.uint64()
                }
                if localHeaderOffset == 0xFFFF_FFFF {
                    localHeaderOffset = byteReader.uint64()
                }
                if diskNumberStart == 0xFFFF {
                    diskNumberStart = byteReader.uint32()
                }
            case 0x5455: // Extended Timestamp
                extendedTimestampExtraField = ExtendedTimestampExtraField(byteReader, size,
                                                                          location: .centralDirectory)
            case 0x000A: // NTFS Extra Fields
                ntfsExtraField = NtfsExtraField(byteReader, size, location: .centralDirectory)
            case 0x7855: // Info-ZIP Unix Extra Field
                // If there is any data for Info-ZIP Unix extra field in central directory (`size != 0`), skip it.
                // However, according to definition of this extra field it shouldn't have any data in CD.
                byteReader.offset += size
            case 0x7875: // Info-ZIP New Unix Extra Field
                infoZipNewUnixExtraField = InfoZipNewUnixExtraField(byteReader, size, location: .centralDirectory)
            default:
                let customFieldOffset = byteReader.offset
                if let customExtraFieldType = ZipContainer.customExtraFields[headerID],
                   customExtraFieldType.id == headerID,
                   let customExtraField = customExtraFieldType.init(byteReader, size, location: .centralDirectory),
                   customExtraField.id == headerID
                {
                    precondition(customExtraField.location == .centralDirectory,
                                 "Custom field in Central Directory with ID=\(headerID) of type=\(customExtraFieldType)"
                                     + " changed location.")
                    precondition(customExtraField.size == size,
                                 "Custom field in Central Directory with ID=\(headerID) of type=\(customExtraFieldType)"
                                     + " changed size.")
                    guard byteReader.offset == customFieldOffset + size
                    else { fatalError("Custom field in Central Directory with ID=\(headerID) of" +
                            "type=\(customExtraFieldType) failed to read exactly \(size) bytes.") }
                    customExtraFields.append(customExtraField)
                } else {
                    byteReader.offset = customFieldOffset + size
                }
            }
        }
        self.customExtraFields = customExtraFields

        guard let fileComment = byteReader.zipString(fileCommentLength, useUtf8)
        else { throw ZipError.wrongTextField }
        self.fileComment = fileComment

        nextEntryOffset = byteReader.offset
    }
}
