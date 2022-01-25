// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import BitByteData
import Foundation

/**
 The purpose of this struct is to accompany `ZipEntryInfo` instances while processing a `ZipContainer` and to store
 information which is necessary for reading entry's data later.
 */
struct ZipEntryInfoHelper {
    let entryInfo: ZipEntryInfo

    let hasDataDescriptor: Bool
    let zip64FieldsArePresent: Bool
    let nextCdEntryOffset: Int
    let dataOffset: Int
    let compSize: UInt64
    let uncompSize: UInt64

    init(_ byteReader: LittleEndianByteReader, _ currentDiskNumber: UInt32) throws {
        // Read Central Directory entry.
        let cdEntry = try ZipCentralDirectoryEntry(byteReader)

        // Move to the location of Local Header.
        byteReader.offset = cdEntry.localHeaderOffset.toInt()
        // Read Local Header.
        let localHeader = try ZipLocalHeader(byteReader)
        try localHeader.validate(with: cdEntry, currentDiskNumber)

        // If file has data descriptor, then some properties are only present in CD entry.
        hasDataDescriptor = localHeader.generalPurposeBitFlags & 0x08 != 0

        entryInfo = ZipEntryInfo(byteReader, cdEntry, localHeader, hasDataDescriptor)

        // Save some properties from CD entry and Local Header.
        zip64FieldsArePresent = localHeader.zip64FieldsArePresent
        nextCdEntryOffset = cdEntry.nextEntryOffset
        dataOffset = localHeader.dataOffset
        compSize = hasDataDescriptor ? cdEntry.compSize : localHeader.compSize
        uncompSize = hasDataDescriptor ? cdEntry.uncompSize : localHeader.uncompSize
    }
}
