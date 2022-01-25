// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import BitByteData
import Foundation

/// Provides functions for work with TAR containers.
public class TarContainer: Container {
    /**
     Represents the "format" of a TAR container: a minimal set of extensions to basic TAR format required to
     successfully read a particular container.
     */
    public enum Format {
        /// Pre POSIX format (aka "basic TAR format").
        case prePosix
        /// "UStar" format introduced by POSIX IEEE P1003.1 standard.
        case ustar
        /// "UStar"-like format with GNU extensions (e.g. special container entries for long file and link names).
        case gnu
        /// "PAX" format introduced by POSIX.1-2001 standard, a set of extensions to "UStar" format.
        case pax
    }

    /**
     Processes TAR container and returns its "format": a minimal set of extensions to basic TAR format required to
     successfully read this container.

     - Parameter container: TAR container's data.

     - Throws: `TarError`, which may indicate that either container is damaged or it might not be TAR container at all.

     - SeeAlso: `TarContainer.Format`
     */
    public static func formatOf(container data: Data) throws -> Format {
        var parser = TarParser(data)
        var ustarEncountered = false

        parsingLoop: while true {
            let result = try parser.next()
            switch result {
            case let .specialEntry(specialEntryType):
                if specialEntryType == .globalExtendedHeader || specialEntryType == .localExtendedHeader {
                    return .pax
                } else if specialEntryType == .longName || specialEntryType == .longLinkName {
                    return .gnu
                }
            case let .entryInfo(_, _, headerFormat):
                switch headerFormat {
                case .pax:
                    fatalError("Unexpected format of basic header: pax")
                case .gnu:
                    return .gnu
                case .ustar:
                    ustarEncountered = true
                case .prePosix:
                    break
                }
            case .truncated:
                // We don't have an error with a more suitable name.
                throw TarError.tooSmallFileIsPassed
            case .finished:
                fallthrough
            case .eofMarker:
                break parsingLoop
            }
        }

        return ustarEncountered ? .ustar : .prePosix
    }

    /**
     Creates a new TAR container with `entries` as its content and generates its `Data`.

     - Parameter entries: TAR entries to store in the container.

     - SeeAlso: `TarEntryInfo` properties documenation to see how their values are connected with the specific TAR
     format used during container creation.
     */
    public static func create(from entries: [TarEntry]) -> Data {
        create(from: entries, force: .pax)
    }

    /**
     Creates a new TAR container with `entries` as its content and generates its `Data` using the specified `format`.

     This function forces the usage of the `format`, meaning that certain properties of the `entries` may be missing
     from the resulting container data if the chosen format does not support corresponding features. For example,
     relatively long names (and linknames) will be truncated if the `.ustar` or `.prePosix` format is specified.

     It is highly recommended to use the `TarContainer.create(from:)` function (or use the `.pax` format) to ensure the
     best representation of the `entries` in the output. Other (non-PAX) formats should only be used if you have a
     specific need for them and you understand limitations of those formats.

     - Parameter entries: TAR entries to store in the container.
     - Parameter force: Force the usage of the specified format.

     - SeeAlso: `TarEntryInfo` properties documenation to see how their values are connected with the specific TAR
     format used during container creation.
     */
    public static func create(from entries: [TarEntry], force format: TarContainer.Format) -> Data {
        // The general strategy is as follows. For each entry we:
        //  1. Create special entries if required by the entry's info and if supported by the format.
        //  2. For each special entry we create a TarHeader.
        //  3. For each TarHeader we generate binary data, and then append it with the content of the special entry to
        //     the output.
        //  4. Perform the previous two steps for the entry itself.
        // Every time we append something to the output we also make sure that the data is padded to 512 byte-long blocks.

        // In theory if the counters are big enough, the names of the special entries can become long enough to cause
        // problems (truncation, etc.). In practice, the largest possible counter (UInt.max) is 20 symbols long, which
        // when combined with the longest used special entry name can never cause any problems, since it is still
        // shorter then 99 symbols available in the "name" field of the TAR header.
        // However, if in the distant future Int.max becomes large enough to cause any issues (e.g. 128-bit and higher
        // integers), the following check will catch it.
        assert(String(UInt.max).count < 100 - 19) // "SWC_LocalPaxHeader_".count == 19
        // We also use &+ when incrementing counters to prevent integer overflow crashes: we rather deal with the special
        // entries having repeating names, then crash the program.
        var longNameCounter = 0 as UInt
        var longLinkNameCounter = 0 as UInt
        var localPaxHeaderCounter = 0 as UInt

        var out = Data()
        for entry in entries {
            if format == .gnu {
                if entry.info.name.utf8.count > 100 {
                    let nameData = Data(entry.info.name.utf8)
                    let longNameHeader = TarHeader(specialName: "SWC_LongName_\(longNameCounter)",
                                                   specialType: .longName, size: nameData.count,
                                                   uid: entry.info.ownerID, gid: entry.info.groupID)
                    out.append(longNameHeader.generateContainerData(.gnu))
                    assert(out.count % 512 == 0)
                    out.appendAsTarBlock(nameData)
                    longNameCounter &+= 1
                }

                if entry.info.linkName.utf8.count > 100 {
                    let linkNameData = Data(entry.info.linkName.utf8)
                    let longLinkNameHeader = TarHeader(specialName: "SWC_LongLinkName_\(longLinkNameCounter)",
                                                       specialType: .longLinkName, size: linkNameData.count,
                                                       uid: entry.info.ownerID, gid: entry.info.groupID)
                    out.append(longLinkNameHeader.generateContainerData(.gnu))
                    assert(out.count % 512 == 0)
                    out.appendAsTarBlock(linkNameData)
                    longLinkNameCounter &+= 1
                }
            } else if format == .pax {
                let extHeader = TarExtendedHeader(entry.info)
                let extHeaderData = extHeader.generateContainerData()
                if !extHeaderData.isEmpty {
                    let extHeaderHeader = TarHeader(specialName: "SWC_LocalPaxHeader_\(localPaxHeaderCounter)",
                                                    specialType: .localExtendedHeader, size: extHeaderData.count,
                                                    uid: entry.info.ownerID, gid: entry.info.groupID)
                    out.append(extHeaderHeader.generateContainerData(.pax))
                    assert(out.count % 512 == 0)
                    out.appendAsTarBlock(extHeaderData)
                    localPaxHeaderCounter &+= 1
                }
            }

            let header = TarHeader(entry.info)
            out.append(header.generateContainerData(format))
            assert(out.count % 512 == 0)
            if let data = entry.data {
                out.appendAsTarBlock(data)
            }
        }
        // Two 512-byte blocks consisting of zeros as an EOF marker.
        out.append(Data(count: 1024))
        return out
    }

    /**
     Processes TAR container and returns an array of `TarEntry` with information and data for all entries.

     - Important: The order of entries is defined by TAR container and, particularly, by the creator of a given TAR
     container. It is likely that directories will be encountered earlier than files stored in those directories, but no
     particular order is guaranteed.

     - Parameter container: TAR container's data.

     - Throws: `TarError`, which may indicate that either container is damaged or it might not be TAR container at all.

     - Returns: Array of `TarEntry`.
     */
    public static func open(container data: Data) throws -> [TarEntry] {
        var parser = TarParser(data)
        var entries = [TarEntry]()

        parsingLoop: while true {
            let result = try parser.next()
            switch result {
            case .specialEntry:
                continue parsingLoop
            case let .entryInfo(info, blockStartIndex, _):
                if info.type == .directory {
                    var entry = TarEntry(info: info, data: nil)
                    entry.info.size = 0
                    entries.append(entry)
                } else {
                    let dataStartIndex = blockStartIndex + 512
                    let dataEndIndex = dataStartIndex + info.size!
                    // Verify that data is not truncated.
                    // The data.startIndex inequality is strict since by this point at least one header (i.e. 512 bytes)
                    // has been processed. The data.endIndex inequality is strict since there can be a 1024 bytes-long EOF
                    // marker block which isn't included into any entry.
                    guard dataStartIndex > data.startIndex, dataEndIndex < data.endIndex
                    else { throw TarError.tooSmallFileIsPassed }
                    let entryData = data.subdata(in: dataStartIndex ..< dataEndIndex)
                    entries.append(TarEntry(info: info, data: entryData))
                }
            case .truncated:
                // We don't have an error with a more suitable name.
                throw TarError.tooSmallFileIsPassed
            case .finished:
                fallthrough
            case .eofMarker:
                break parsingLoop
            }
        }

        return entries
    }

    /**
     Processes TAR container and returns an array of `TarEntryInfo` with information about entries in this container.

     - Important: The order of entries is defined by TAR container and, particularly, by the creator of a given TAR
     container. It is likely that directories will be encountered earlier than files stored in those directories, but no
     particular order is guaranteed.

     - Parameter container: TAR container's data.

     - Throws: `TarError`, which may indicate that either container is damaged or it might not be TAR container at all.

     - Returns: Array of `TarEntryInfo`.
     */
    public static func info(container data: Data) throws -> [TarEntryInfo] {
        var parser = TarParser(data)
        var entries = [TarEntryInfo]()

        parsingLoop: while true {
            let result = try parser.next()
            switch result {
            case .specialEntry:
                continue parsingLoop
            case let .entryInfo(info, _, _):
                entries.append(info)
            case .truncated:
                // We don't have an error with a more suitable name.
                throw TarError.tooSmallFileIsPassed
            case .finished:
                fallthrough
            case .eofMarker:
                break parsingLoop
            }
        }

        return entries
    }
}
