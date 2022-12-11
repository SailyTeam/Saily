// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation
import SWCompression
import SwiftCLI

extension TarEntry {
    static func createEntries(_ inputPath: String, _ verbose: Bool) throws -> [TarEntry] {
        let inputURL = URL(fileURLWithPath: inputPath)
        let fileManager = FileManager.default

        let fileAttributes = try fileManager.attributesOfItem(atPath: inputPath)

        let name = inputURL.relativePath

        let entryType: ContainerEntryType
        if let typeFromAttributes = fileAttributes[.type] as? FileAttributeType {
            switch typeFromAttributes {
            case .typeBlockSpecial:
                entryType = .blockSpecial
            case .typeCharacterSpecial:
                entryType = .characterSpecial
            case .typeDirectory:
                entryType = .directory
            case .typeRegular:
                entryType = .regular
            case .typeSocket:
                entryType = .socket
            case .typeSymbolicLink:
                entryType = .symbolicLink
            case .typeUnknown:
                entryType = .unknown
            default:
                entryType = .unknown
            }
        } else {
            entryType = .unknown
        }

        var info = TarEntryInfo(name: name, type: entryType)
        info.creationTime = fileAttributes[.creationDate] as? Date
        info.groupID = (fileAttributes[.groupOwnerAccountID] as? NSNumber)?.intValue
        info.ownerGroupName = fileAttributes[.groupOwnerAccountName] as? String
        info.modificationTime = fileAttributes[.modificationDate] as? Date
        info.ownerID = (fileAttributes[.ownerAccountID] as? NSNumber)?.intValue
        info.ownerUserName = fileAttributes[.ownerAccountName] as? String
        if let posixPermissions = (fileAttributes[.posixPermissions] as? NSNumber)?.intValue {
            info.permissions = Permissions(rawValue: UInt32(truncatingIfNeeded: posixPermissions))
        }

        var entryData = Data()
        if entryType == .symbolicLink {
            info.linkName = try fileManager.destinationOfSymbolicLink(atPath: inputPath)
        } else if entryType != .directory {
            entryData = try Data(contentsOf: URL(fileURLWithPath: inputPath))
        }

        if verbose {
            var log = ""
            switch entryType {
            case .regular:
                log += "f: "
            case .directory:
                log += "d: "
            case .symbolicLink:
                log += "l:"
            default:
                log += "u: "
            }
            log += name
            if entryType == .symbolicLink {
                log += " -> " + info.linkName
            }
            print(log)
        }

        let entry = TarEntry(info: info, data: entryData)

        var entries = [TarEntry]()
        entries.append(entry)

        if entryType == .directory {
            for subPath in try fileManager.contentsOfDirectory(atPath: inputPath) {
                entries.append(contentsOf: try createEntries(inputURL.appendingPathComponent(subPath).relativePath,
                                                             verbose))
            }
        }

        return entries
    }

    static func generateEntries(_ writer: inout TarWriter, _ inputPath: String, _ verbose: Bool) throws {
        let inputURL = URL(fileURLWithPath: inputPath)
        let fileManager = FileManager.default

        let fileAttributes = try fileManager.attributesOfItem(atPath: inputPath)

        let name = inputURL.relativePath

        let entryType: ContainerEntryType
        if let typeFromAttributes = fileAttributes[.type] as? FileAttributeType {
            switch typeFromAttributes {
            case .typeBlockSpecial:
                entryType = .blockSpecial
            case .typeCharacterSpecial:
                entryType = .characterSpecial
            case .typeDirectory:
                entryType = .directory
            case .typeRegular:
                entryType = .regular
            case .typeSocket:
                entryType = .socket
            case .typeSymbolicLink:
                entryType = .symbolicLink
            case .typeUnknown:
                entryType = .unknown
            default:
                entryType = .unknown
            }
        } else {
            entryType = .unknown
        }

        var info = TarEntryInfo(name: name, type: entryType)
        info.creationTime = fileAttributes[.creationDate] as? Date
        info.groupID = (fileAttributes[.groupOwnerAccountID] as? NSNumber)?.intValue
        info.ownerGroupName = fileAttributes[.groupOwnerAccountName] as? String
        info.modificationTime = fileAttributes[.modificationDate] as? Date
        info.ownerID = (fileAttributes[.ownerAccountID] as? NSNumber)?.intValue
        info.ownerUserName = fileAttributes[.ownerAccountName] as? String
        if let posixPermissions = (fileAttributes[.posixPermissions] as? NSNumber)?.intValue {
            info.permissions = Permissions(rawValue: UInt32(truncatingIfNeeded: posixPermissions))
        }

        try autoreleasepool {
            var entryData = Data()
            if entryType == .symbolicLink {
                info.linkName = try fileManager.destinationOfSymbolicLink(atPath: inputPath)
            } else if entryType != .directory {
                entryData = try Data(contentsOf: URL(fileURLWithPath: inputPath))
            }
            let entry = TarEntry(info: info, data: entryData)
            try writer.append(entry)
        }

        if verbose {
            var log = ""
            switch entryType {
            case .regular:
                log += "f: "
            case .directory:
                log += "d: "
            case .symbolicLink:
                log += "l:"
            default:
                log += "u: "
            }
            log += name
            if entryType == .symbolicLink {
                log += " -> " + info.linkName
            }
            print(log)
        }

        if entryType == .directory {
            for subPath in try fileManager.contentsOfDirectory(atPath: inputPath) {
                try generateEntries(&writer, inputURL.appendingPathComponent(subPath).relativePath, verbose)
            }
        }
    }
}

#if os(Linux) || os(Windows)
    @discardableResult
    fileprivate func autoreleasepool<T>(_ block: () throws -> T) rethrows -> T {
        try block()
    }
#endif
