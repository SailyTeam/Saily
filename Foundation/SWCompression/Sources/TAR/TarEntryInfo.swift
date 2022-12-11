// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation

/// Provides access to information about an entry from the TAR container.
public struct TarEntryInfo: ContainerEntryInfo {
    // MARK: ContainerEntryInfo

    /**
     Entry's name.

     Depending on the particular format of the container, different container's structures are used
     to set this property, in the following preference order:
     1. Local PAX extended header "path" property.
     2. Global PAX extended header "path" property.
     3. GNU format type "L" (LongName) entry.
     4. Default TAR header.

     - Note: When a new TAR container is created, if `name` cannot be encoded with ASCII or its ASCII byte-representation
     is longer than 100 bytes then a PAX extended header will be created to represent this value correctly, unless other
     format is forced.
     - Note: When creating new TAR container, `name` is always encoded with UTF-8 in the basic TAR header.
     */
    public var name: String

    /**
      Entry's data size.

      - Note: This property cannot be directly modified. Instead it is updated automatically to be equal to its parent's
      `entry.data.count`.
      - Note: When a new TAR container is created, if `size` is bigger than 8589934591 then a PAX extended header will be
      created to represent this value correctly, unless other format is forced. In addition, base-256 encoding will be
      used to encode this value in the basic TAR header.
     */
    public internal(set) var size: Int?

    public let type: ContainerEntryType

    /**
     Entry's last access time (only available for PAX format; `nil` otherwise).

     - Note: When a new TAR container is created, if `accessTime` is not `nil` then a PAX extended header will be created
     to store this property, unless other format is forced.
     */
    public var accessTime: Date?

    /**
     Entry's creation time (only available for PAX format; `nil` otherwise).

     - Note: When a new TAR container is created, if `creationTime` is not `nil` then a PAX extended header will be
     created to store this property, unless other format is forced.
     */
    public var creationTime: Date?

    /**
     Entry's last modification time.

     - Note: When a new TAR container is created, if `modificationTime` is bigger than 8589934591 then a PAX extended
     header will be created to represent this value correctly, unless other format is forced. In addition, base-256
     encoding will be used to encode this value in the basic TAR header.
     */
    public var modificationTime: Date?

    public var permissions: Permissions?

    // MARK: TAR specific

    /// Entry's compression method. Always `.copy` for the entries of TAR containers.
    public let compressionMethod = CompressionMethod.copy

    /**
     ID of entry's owner.

     - Note: When a new TAR container is created, if `ownerID` is bigger than 2097151 then a PAX extended header will be
     created to represent this value correctly, unless other format is forced. In addition, base-256 encoding will be
     used to encode this value in the basic TAR header.
     */
    public var ownerID: Int?

    /**
     ID of the group of entry's owner.

     - Note: When a new TAR container is created, if `groupID` is bigger than 2097151 then a PAX extended header will be
     created to represent this value correctly, unless other format is forced. In addition, base-256 encoding will be
     used to encode this value in the basic TAR header.
     */
    public var groupID: Int?

    /**
     User name of entry's owner.

     - Note: When a new TAR container is created, if `ownerUserName` cannot be encoded with ASCII or its ASCII
     byte-representation is longer than 32 bytes then a PAX extended header will be created to represent this value
     correctly, unless other format is forced.
     - Note: When creating new TAR container, `ownerUserName` is always encoded with UTF-8 in the ustar header.
     */
    public var ownerUserName: String?

    /**
     Name of the group of entry's owner.

     - Note: When new TAR container is created, if `ownerGroupName` cannot be encoded with ASCII or its ASCII
     byte-representation is longer than 32 bytes then a PAX extended header will be created to represent this value
     correctly, unless other format is forced.
     - Note: When creating new TAR container, `ownerGroupName` is always encoded with UTF-8 in the ustar header.
     */
    public var ownerGroupName: String?

    /**
     Device major number (used when entry is either block or character special file).

     - Note: When new TAR container is created, if `deviceMajorNumber` is bigger than 2097151 then base-256 encoding
     will be used to encode this value in ustar header.
     */
    public var deviceMajorNumber: Int?

    /**
     Device minor number (used when entry is either block or character special file).

     - Note: When new TAR container is created, if `deviceMajorNumber` is bigger than 2097151 then base-256 encoding
     will be used to encode this value in ustar header.
     */
    public var deviceMinorNumber: Int?

    /**
     Name of the character set used to encode entry's data (only available for PAX format; `nil` otherwise).

     - Note: When new TAR container is created, if `charset` is not `nil` then a PAX extended header will be created to
     store this property, unless other format is forced.
     */
    public var charset: String?

    /**
     Entry's comment (only available for PAX format; `nil` otherwise).

     - Note: When new TAR container is created, if `comment` is not `nil` then a PAX extended header will be created to
     store this property, unless other format is forced.
     */
    public var comment: String?

    /**
     Path to a linked file for symbolic link entry.

     Depending on the particular format of the container, different container's structures are used
     to set this property, in the following preference order:
     1. Local PAX extended header "linkpath" property.
     2. Global PAX extended header "linkpath" property.
     3. GNU format type "K" (LongLink) entry.
     4. Default TAR header.

     - Note: When new TAR container is created, if `linkName` cannot be encoded with ASCII or its ASCII
     byte-representation is longer than 100 bytes then a PAX extended header will be created to represent this value
     correctly, unless other format is forced.
     - Note: When creating new TAR container, `linkName` is always encoded with UTF-8 in basic TAR header.
     */
    public var linkName: String

    /**
     All custom (unknown) records from global and local PAX extended headers. `nil`, if there were no headers.

     - Note: When new TAR container is created, if `unknownExtendedHeaderRecords` is not `nil` then a *local* PAX
     extended header will be created to store this property, unless other format is forced.
     */
    public var unknownExtendedHeaderRecords: [String: String]?

    /**
     Initializes the entry's info with its name and type.

     - Note: Entry's type cannot be modified after initialization.

     - Parameter name: Entry's name.
     - Parameter type: Entry's type.
     */
    public init(name: String, type: ContainerEntryType) {
        self.name = name
        self.type = type
        linkName = ""
    }

    init(_ header: TarHeader, _ global: TarExtendedHeader?, _ local: TarExtendedHeader?,
         _ longName: String?, _ longLinkName: String?)
    {
        permissions = header.permissions
        ownerID = (local?.uid ?? global?.uid) ?? header.uid
        groupID = (local?.gid ?? global?.gid) ?? header.gid
        size = (local?.size ?? global?.size) ?? header.size
        if let paxMtime = local?.mtime ?? global?.mtime {
            modificationTime = Date(timeIntervalSince1970: paxMtime)
        } else {
            modificationTime = header.mtime
        }

        // File type
        guard case let .normal(entryType) = header.type
        else { fatalError("TarEntryInfo.init: unexpected TarHeader.type, \(header.type)") }
        type = entryType

        ownerUserName = (local?.uname ?? global?.uname) ?? header.uname
        ownerGroupName = (local?.gname ?? global?.gname) ?? header.gname
        deviceMajorNumber = header.deviceMajorNumber
        deviceMinorNumber = header.deviceMinorNumber

        // Set `name` and `linkName` to values from PAX or GNU format if possible.
        var name = header.name
        if let prefix = header.prefix, prefix != "" {
            if prefix.last == "/" {
                name = prefix + name
            } else {
                name = prefix + "/" + name
            }
        }
        self.name = ((local?.path ?? global?.path) ?? longName) ?? name
        linkName = ((local?.linkpath ?? global?.linkpath) ?? longLinkName) ?? header.linkName

        // Set additional properties from PAX extended headers.
        if let atime = local?.atime ?? global?.atime {
            accessTime = Date(timeIntervalSince1970: atime)
        } else {
            accessTime = header.atime
        }

        if let ctime = local?.ctime ?? global?.ctime {
            creationTime = Date(timeIntervalSince1970: ctime)
        } else {
            creationTime = header.ctime
        }

        charset = local?.charset ?? global?.charset
        comment = local?.comment ?? global?.comment
        if let localUnknownRecords = local?.unknownRecords {
            if let globalUnknownRecords = global?.unknownRecords {
                unknownExtendedHeaderRecords = globalUnknownRecords.merging(localUnknownRecords) { $1 }
            } else {
                unknownExtendedHeaderRecords = localUnknownRecords
            }
        } else {
            unknownExtendedHeaderRecords = global?.unknownRecords
        }
    }
}
