// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation

/// Provides access to information about an entry from the 7-Zip container.
public struct SevenZipEntryInfo: ContainerEntryInfo {
    // MARK: ContainerEntryInfo

    public let name: String

    public let size: Int?

    public let type: ContainerEntryType

    public let accessTime: Date?

    public let creationTime: Date?

    public let modificationTime: Date?

    public let permissions: Permissions?

    // MARK: 7-Zip specific

    /**
     Entry's "win attributes". 7-Zip internal property.
     May be useful when origin file system's attributes weren't POSIX compatible.
     */
    public let winAttributes: UInt32?

    /// Entry's attributes in DOS format.
    public let dosAttributes: DosAttributes?

    /// True, if entry has a stream (data) inside the container. 7-Zip internal propety.
    public let hasStream: Bool

    /// True, if entry is an empty file. 7-Zip internal property.
    public let isEmpty: Bool

    /**
     True, if entry is an anti-file. Used in differential backups to indicate that file should be deleted.
     7-Zip internal property.
     */
    public let isAnti: Bool

    /// CRC32 of entry's data.
    public let crc: UInt32?

    init(_ file: SevenZipFileInfo.File, _ size: Int? = nil, _ crc: UInt32? = nil) {
        hasStream = !file.isEmptyStream
        isEmpty = file.isEmptyFile
        isAnti = file.isAntiFile

        name = file.name

        accessTime = file.aTime
        creationTime = file.cTime
        modificationTime = file.mTime

        winAttributes = file.winAttributes

        if let attributes = winAttributes {
            permissions = Permissions(rawValue: (0x0FFF_0000 & attributes) >> 16)
            dosAttributes = DosAttributes(rawValue: 0xFF & attributes)
        } else {
            permissions = nil
            dosAttributes = nil
        }

        // Set entry type.
        if let attributes = winAttributes,
           let unixType = ContainerEntryType((0xF000_0000 & attributes) >> 16)
        {
            type = unixType
        } else if let dosAttributes = dosAttributes {
            if dosAttributes.contains(.directory) {
                type = .directory
            } else {
                type = .regular
            }
        } else if file.isEmptyStream, !file.isEmptyFile {
            type = .directory
        } else {
            type = .regular
        }

        self.crc = crc
        self.size = size
    }
}
