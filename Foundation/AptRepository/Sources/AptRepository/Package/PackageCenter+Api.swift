//
//  Project Chromatic
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/14.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import Dog
import Foundation

public extension PackageCenter {
    /// reload local installed package status
    func realodLocalPackages() {
        reloadLocalInstall()
    }

    /// grab every package identity, useful for search
    /// - Returns: identities
    func obtainAllPackageIdentity() -> [String] {
        accessLock.lock()
        let fetch = summary.keys
        accessLock.unlock()
        return [String](fetch)
    }

    /// grab a summary of a package
    /// - Parameter identity: identity of the package
    /// - Returns: summary of them
    func obtainPackageSummary(with identity: String) -> [URL: Package] {
        accessLock.lock()
        let copy = summary[identity, default: [:]]
        accessLock.unlock()
        return copy
    }

    /// grab available authors
    /// - Returns: list of author name
    func obtainAuthorList() -> [String] {
        accessLock.lock()
        let copy = authers.keys
        accessLock.unlock()
        return [String](copy)
    }

    /// obtain packages written by author
    /// - Parameter author: author name
    /// - Returns: packages
    func obtainPackage(by author: String) -> [Package] {
        accessLock.lock()
        let read = authers[author, default: []]
        let result = read
            .map { summary[$0] }
            .compactMap { $0 }
            .flatMap { $0 }
            .map(\.value)
        accessLock.unlock()
        return result
    }

    /// grab package written by author
    /// - Parameter author: author name
    /// - Returns: package identities
    func obtainAvailablePackageList(writtenBy author: String) -> [String] {
        accessLock.lock()
        let copy = authers[author, default: []]
        accessLock.unlock()
        return [String](copy)
    }

    /// returns installed packages
    /// - Returns: array of packages
    func obtainInstalledPackageList() -> [Package] {
        accessLock.lock()
        let read = localInstalled
            .values
        accessLock.unlock()
        return [Package](read)
    }

    /// returns author names, email trimmed
    /// - Parameter object: package
    /// - Returns: authors
    func obtainAuthor(of object: Package) -> [String] {
        var result = [String]()

        func cleanEmails(str: String) -> String {
            if str.contains("<"),
               str.contains("@"),
               str.contains(">")
            {
                return str
                    .components(separatedBy: "<")
                    .first?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    ?? ""
            }
            return str
        }

        if let text = object.latestMetadata?["author"] {
            result = text
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .map { cleanEmails(str: $0) }
        }
        return result
    }

    /// returns installation info with package identity
    /// - Parameter identity: id
    /// - Returns: any result if installed, otherwise not installed
    func obtainPackageInstallationInfo(with identity: String) -> InstallationInfo? {
        accessLock.lock()
        let currentLookup = localInstalled[identity]
        accessLock.unlock()
        guard let lookup = currentLookup,
              let version = lookup.latestVersion
        else {
            return nil
        }
        return .init(status: .installed,
                     identity: identity,
                     version: version,
                     representObject: lookup)
    }

    /// obtain update for package at current version
    /// - Parameters:
    ///   - identity: identity in string
    ///   - current: current version
    /// - Returns: available updates
    func obtainUpdateForPackage(with identity: String, version current: String) -> [Package] {
        if blockedUpdateTable.contains(identity) {
            return []
        }
        accessLock.lock()
        let fetch = summary[identity, default: [:]]
        accessLock.unlock()
        var result = [Package]()
        for item in fetch.values {
            if let version = item.latestVersion {
                let compare = Package.compareVersion(version, b: current)
                if compare == .aIsBiggerThenB {
                    result.append(item)
                }
            }
        }
        return result
    }

    /// search with virtual package identity that provided by package in return value
    /// - Parameter withIdentity: package identity
    /// - Returns: package that provides this virtual package
    func obtainVirtualPackageReference(withIdentity: String) -> [String] {
        accessLock.lock()
        let read = virtual[withIdentity]
        accessLock.unlock()
        return [String](read ?? [])
    }

    /// search for record table, get the last modification time if available
    /// - Parameters:
    ///   - identity: package identity
    ///   - table: the table to search for, either installed or repo table
    /// - Returns: date for last modification, nil if not modified or found
    func obtainLastModification(for identity: String, and table: RecordTable) -> Date? {
        accessLock.lock()
        var date: Date?
        switch table {
        case .install:
            date = installationTrace[identity]?.lastModification
        case .repo:
            date = tableTrace[identity]?.lastModification
        }
        accessLock.unlock()
        return date
    }

    /// obtain recent update list recorded inside repo
    /// - Returns: list of them, unsorted
    func obtainRecentUpdatedList() -> [Date: [(String, URL?)]] {
        accessLock.lock()
        let fetch = tableTrace
        accessLock.unlock()
        var result = [Date: [(String, URL?)]]()
        for (key, value) in fetch {
            if let date = value.lastModification {
                var read = result[date, default: []]
                read.append((key, value.repo))
                result[date] = read
            }
        }
        return result
    }
}
