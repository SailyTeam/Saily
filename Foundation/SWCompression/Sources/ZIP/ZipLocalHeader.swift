// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import BitByteData
import Foundation

struct ZipLocalHeader {
    let versionNeeded: UInt16
    let generalPurposeBitFlags: UInt16
    let compressionMethod: UInt16
    let lastModFileTime: UInt16
    let lastModFileDate: UInt16

    let crc32: UInt32
    private(set) var compSize: UInt64
    private(set) var uncompSize: UInt64

    private(set) var zip64FieldsArePresent: Bool = false

    let fileName: String

    /// 0x5455 extra field.
    private(set) var extendedTimestampExtraField: ExtendedTimestampExtraField?

    /// 0x000a extra field.
    private(set) var ntfsExtraField: NtfsExtraField?

    /// 0x7855 extra field.
    private(set) var infoZipUnixExtraField: InfoZipUnixExtraField?

    /// 0x7875 extra field.
    private(set) var infoZipNewUnixExtraField: InfoZipNewUnixExtraField?

    let customExtraFields: [ZipExtraField]

    let dataOffset: Int

    init(_ byteReader: LittleEndianByteReader) throws {
        // Check signature.
        guard byteReader.uint32() == 0x0403_4B50
        else { throw ZipError.wrongSignature }

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
                // Zip64 extra field is a special case, because it requires knowledge about local header fields,
                // in particular, uncompressed and compressed sizes.
                // In the local header both uncompressed size and compressed size fields are required.
                uncompSize = byteReader.uint64()
                compSize = byteReader.uint64()
                zip64FieldsArePresent = true
            case 0x5455: // Extended Timestamp
                extendedTimestampExtraField = ExtendedTimestampExtraField(byteReader, size, location: .localHeader)
            case 0x000A: // NTFS Extra Fields
                ntfsExtraField = NtfsExtraField(byteReader, size, location: .localHeader)
            case 0x7855: // Info-ZIP Unix Extra Field
                infoZipUnixExtraField = InfoZipUnixExtraField(byteReader, size, location: .localHeader)
            case 0x7875: // Info-ZIP New Unix Extra Field
                infoZipNewUnixExtraField = InfoZipNewUnixExtraField(byteReader, size, location: .localHeader)
            default:
                let customFieldOffset = byteReader.offset
                if let customExtraFieldType = ZipContainer.customExtraFields[headerID],
                   customExtraFieldType.id == headerID,
                   let customExtraField = customExtraFieldType.init(byteReader, size, location: .localHeader),
                   customExtraField.id == headerID
                {
                    precondition(customExtraField.location == .localHeader,
                                 "Custom field in Local Header with ID=\(headerID) of type=\(customExtraFieldType)"
                                     + " changed location.")
                    precondition(customExtraField.size == size,
                                 "Custom field in Local Header with ID=\(headerID) of type=\(customExtraFieldType)"
                                     + " changed size.")
                    guard byteReader.offset == customFieldOffset + size
                    else { fatalError("Custom field in Local Header with ID=\(headerID) of" +
                            "type=\(customExtraFieldType) failed to read exactly \(size) bytes.") }
                    customExtraFields.append(customExtraField)
                } else {
                    byteReader.offset = customFieldOffset + size
                }
            }
        }
        self.customExtraFields = customExtraFields

        dataOffset = byteReader.offset
    }

    func validate(with cdEntry: ZipCentralDirectoryEntry, _ currentDiskNumber: UInt32) throws {
        // Check Local Header for unsupported features.
        guard versionNeeded & 0xFF <= 63
        else { throw ZipError.wrongVersion }
        guard generalPurposeBitFlags & 0x2000 == 0,
              generalPurposeBitFlags & 0x40 == 0,
              generalPurposeBitFlags & 0x01 == 0
        else { throw ZipError.encryptionNotSupported }
        guard generalPurposeBitFlags & 0x20 == 0
        else { throw ZipError.patchingNotSupported }

        // Check Central Directory record for unsupported features.
        guard cdEntry.versionNeeded & 0xFF <= 63
        else { throw ZipError.wrongVersion }
        guard cdEntry.diskNumberStart == currentDiskNumber
        else { throw ZipError.multiVolumesNotSupported }

        // Check if Local Header is consistent with Central Directory record.
        guard generalPurposeBitFlags == cdEntry.generalPurposeBitFlags,
              compressionMethod == cdEntry.compressionMethod,
              lastModFileTime == cdEntry.lastModFileTime,
              lastModFileDate == cdEntry.lastModFileDate
        else { throw ZipError.wrongLocalHeader }
    }
}
