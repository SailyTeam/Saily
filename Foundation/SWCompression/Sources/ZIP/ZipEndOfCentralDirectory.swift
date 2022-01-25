// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import BitByteData
import Foundation

struct ZipEndOfCentralDirectory {
    /// Number of the current disk.
    private(set) var currentDiskNumber: UInt32

    private(set) var cdEntries: UInt64
    private(set) var cdOffset: UInt64

    // There are two fields in the EndOfCD that aren't currently used anywhere except in the initalizer.
    //    /// Number of the disk with the start of CD.
    //    private var cdDiskNumber: UInt32
    //    private var cdSize: UInt64

    init(_ byteReader: LittleEndianByteReader) throws {
        /// Indicates if Zip64 records should be present.
        var zip64RecordExists = false

        currentDiskNumber = byteReader.uint32(fromBytes: 2)
        var cdDiskNumber = byteReader.uint32(fromBytes: 2)
        guard currentDiskNumber == cdDiskNumber
        else { throw ZipError.multiVolumesNotSupported }

        /// Number of CD entries on the current disk.
        var cdEntriesCurrentDisk = byteReader.uint64(fromBytes: 2)
        /// Total number of CD entries.
        cdEntries = byteReader.uint64(fromBytes: 2)
        guard cdEntries == cdEntriesCurrentDisk
        else { throw ZipError.multiVolumesNotSupported }

        /// Size of Central Directory.
        var cdSize = byteReader.uint64(fromBytes: 4)
        /// Offset to the start of Central Directory.
        cdOffset = byteReader.uint64(fromBytes: 4)

        // There is also a .ZIP file comment, but we don't need it.
        // Here's how it can be processed:
        // let zipCommentLength = byteReader.int(fromBytes: 2)
        // let zipComment = String(data: Data(byteReader.bytes(count: zipCommentLength)),
        //                         encoding: .utf8)

        // Check if zip64 records are present.
        if currentDiskNumber == 0xFFFF || cdDiskNumber == 0xFFFF ||
            cdEntriesCurrentDisk == 0xFFFF || cdEntries == 0xFFFF ||
            cdSize == 0xFFFF_FFFF || cdOffset == 0xFFFF_FFFF
        {
            zip64RecordExists = true
        }

        if zip64RecordExists { // We need to find Zip64 end of CD locator.
            // Back to start of end of CD record.
            byteReader.offset -= 20
            // Zip64 locator takes exactly 20 bytes.
            byteReader.offset -= 20

            // Check signature.
            guard byteReader.uint32() == 0x0706_4B50
            else { throw ZipError.wrongSignature }

            let zip64CDStartDisk = byteReader.uint32()
            guard currentDiskNumber == zip64CDStartDisk
            else { throw ZipError.multiVolumesNotSupported }

            let zip64CDEndOffset = byteReader.int(fromBytes: 8)
            let totalDisks = byteReader.uint32()
            guard totalDisks == 1
            else { throw ZipError.multiVolumesNotSupported }

            // Now we need to move to Zip64 End of CD.
            byteReader.offset = zip64CDEndOffset

            // Check signature.
            guard byteReader.uint32() == 0x0606_4B50
            else { throw ZipError.wrongSignature }

            // Following 8 bytes are size of end of zip64 CD, but we don't need it.
            _ = byteReader.uint64()

            // Next two bytes are version of compressor, but we don't need it.
            _ = byteReader.uint16()
            let versionNeeded = byteReader.uint16()
            guard versionNeeded & 0xFF <= 63
            else { throw ZipError.wrongVersion }

            // Update values read from basic End of CD with the ones from Zip64 End of CD.
            currentDiskNumber = byteReader.uint32()
            cdDiskNumber = byteReader.uint32()
            guard currentDiskNumber == cdDiskNumber
            else { throw ZipError.multiVolumesNotSupported }

            cdEntriesCurrentDisk = byteReader.uint64()
            cdEntries = byteReader.uint64()
            guard cdEntries == cdEntriesCurrentDisk
            else { throw ZipError.multiVolumesNotSupported }

            cdSize = byteReader.uint64()
            cdOffset = byteReader.uint64()

            // Then, there might be 'zip64 extensible data sector' with 'special purpose data'.
            // But we don't need them currently, so let's skip them.

            // To find the size of these data:
            // let specialPurposeDataSize = zip64EndCDSize - 56
        }
    }
}
