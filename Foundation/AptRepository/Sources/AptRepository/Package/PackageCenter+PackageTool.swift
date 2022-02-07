//
//  Project Chromatic
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/14.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import AptPackageVersion
import Dog
import Foundation

public extension PackageCenter {
    /// obtain avatar url of package
    /// - Parameter package: package
    /// - Returns: url if available
    func avatarUrl(with package: Package) -> URL? {
        if var icon = package.latestMetadata?["icon"] {
            if icon.hasPrefix("file:/") {
                let icon = String(icon.dropFirst("file:/".count))
                return URL(fileURLWithPath: icon)
            } else if icon.hasPrefix("http") {
                return URL(string: icon)
            } else {
                guard let repo = package.repoRef else {
                    return nil
                }
                if icon.hasPrefix("./") {
                    icon.removeFirst(2)
                }
                return repo.appendingPathComponent(icon)
            }
        }
        return nil
    }

    /// obtain name of package
    /// - Parameter package: package
    /// - Returns: name
    func name(of package: Package) -> String {
        if let name = package.latestMetadata?["name"],
           name.count > 0
        {
            return name
        }
        return package.identity
    }

    /// obtain description of package
    /// - Parameter package: package
    /// - Returns: description
    func description(of package: Package) -> String {
        package.latestMetadata?["description"]
            ?? package.latestVersion
            ?? package.identity
    }

    /// obtain depiction of package
    /// - Parameter package: package
    /// - Returns: depiction
    func depiction(of package: Package) -> PackageDepiction {
        guard let targetMeta = package.latestMetadata else {
            return .none
        }

        var candidate: PackageDepiction?
        func lookupNative() {
            var nativeDepictionLookup: String?
            if let lookup = targetMeta["nativedepiction"] {
                nativeDepictionLookup = lookup
            }
            if let lookup = targetMeta["sileodepiction"] {
                nativeDepictionLookup = lookup
            }
            if let read = nativeDepictionLookup,
               let native = URL(string: read)
            {
                candidate = .json(url: native)
            }
        }
        func lookupWeb() {
            if let read = targetMeta["depiction"],
               let url = URL(string: read)
            {
                candidate = .web(url: url)
            }
        }
        func lookupCompleted() -> Bool {
            candidate != nil
        }

        switch preferredDepiction {
        case .automatically:
            lookupNative()
            if !lookupCompleted() { lookupWeb() }
        case .preferredNative:
            lookupNative()
            if !lookupCompleted() { lookupWeb() }
        case .preferredWeb:
            lookupWeb()
            if !lookupCompleted() { lookupNative() }
        case .onlyNative:
            lookupNative()
        case .onlyWeb:
            lookupWeb()
        case .never: break
        }

        return candidate ?? .none
    }

    /// Remove any other version inside a package
    /// - Parameters:
    ///   - package: the package to be trimmed
    ///   - target: target version
    /// - Returns: the trimmed package if version found and validated
    func trim(package: Package, toVersion target: String) -> Package? {
        if !Package.validateVersion(target) { return nil }
        let payload = package.payload
        guard let meta = payload[target] else { return nil }
        let result = Package(identity: package.identity,
                             payload: [target: meta],
                             repoRef: package.repoRef)
        return result
    }

    /// returns a set of packages that contains only one version from parent
    /// - Parameter of: a package
    /// - Returns: sorted from latest to oldest
    func versionTrimmedSingleSubPackages(of package: Package) -> [Package] {
        package
            .payload
            .keys
            .sorted { Package.compareVersion($0, b: $1) == .aIsBiggerThenB }
            .map { trim(package: package, toVersion: $0) }
            .compactMap { $0 }
    }

    /// newest package in array, validated using first one's identity
    /// - Parameter list: list of package
    /// - Returns: newest one, random if multiple exists
    func newestPackage(of list: [Package]) -> Package? {
        guard list.count > 0 else { return nil }
        return list
            // validate
            .filter { $0.identity == list[0].identity }
            // flat extended
            .compactMap { $0 }
            // trim to newest
            .map { PackageCenter.default.trim(package: $0, toVersion: $0.latestVersion ?? "") }
            // delete invalid
            .compactMap { $0 }
            // just in case
            .filter { AptPackageVersion.isVersionVaild($0.latestVersion ?? "") }
            // sort
            .sorted { AptPackageVersion.compareA($0.latestVersion ?? "", andB: $1.latestVersion ?? "") > 0 }
            // get!
            .first
    }
}
