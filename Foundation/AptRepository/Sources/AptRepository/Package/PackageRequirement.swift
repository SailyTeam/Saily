//
//  Project Chromatic
//  Chromatic
//
//  Created by Lakr Aream on 2020/4/18.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import AptPackageVersion
import Foundation

public struct PackageRequirement: Codable {
    /// present a requirement group
    /// **TYPE** -> depends, preDepends, conflicts, replaces, breaks...
    public struct PackageRequirementGroup: Codable {
        // MARK: - Group Type

        public enum RequirementType: String, CaseIterable, Codable {
            case depends
            case conflicts
            case replaces
            case breaks
            case provides
            // let apt to handle pre-depends, we treat it the same as depends
        }

        public let type: RequirementType

        // MARK: - Items

        public struct Requirement: Codable {
            // chose one to match
            public struct RequirementElement: Codable {
                public enum VersionType: String, CaseIterable, Codable {
                    case bigger
                    case biggerOrEqual
                    case equal
                    case smaller
                    case smallerOrEqual
                    case noneSpecific
                }

                public let original: String
                public let representPackage: String
                public let versionValue: String
                public let versionType: VersionType

                init?(value: String) {
                    original = value.trimmingCharacters(in: .whitespacesAndNewlines)
                    let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
                    if value.count < 1 { return nil }
                    if value.contains("("), value.contains(")") {
                        let split = value
                            .components(separatedBy: "(")
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        guard split.count == 2 else { return nil }
                        let packageName = split[0]
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        var versionControl = split[1]
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .trimmingCharacters(in: .init(charactersIn: ")"))
                        var control = ""
                        while
                            versionControl.hasPrefix(">")
                            || versionControl.hasPrefix("=")
                            || versionControl.hasPrefix("<")
                        {
                            control += String(versionControl.removeFirst())
                        }
                        control = control
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        versionControl = versionControl
                            .trimmingCharacters(in: .whitespacesAndNewlines)

                        representPackage = packageName
                        versionValue = versionControl
                        switch control {
                        case ">=": versionType = .biggerOrEqual
                        case ">", ">>": versionType = .bigger
                        case "=", "==": versionType = .equal
                        case "<", "<<": versionType = .smaller
                        case "<=": versionType = .smallerOrEqual
                        default: versionType = .noneSpecific
                        }
                        return
                    }
                    representPackage = value
                    versionValue = ""
                    versionType = .noneSpecific
                }

                public func doesThisVersionMatchesRequirement(version: String) -> Bool {
                    if versionType == .noneSpecific { return true }
                    let compare = Package.compareVersion(versionValue, b: version)
                    if compare == .invalidParameter {
                        return false
                    }
                    switch versionType {
                    case .bigger: return compare == .aIsSmallerThenB
                    case .biggerOrEqual: return (compare == .aIsSmallerThenB || compare == .aIsEqualToB)
                    case .equal: return compare == .aIsEqualToB
                    case .smaller: return compare == .aIsBiggerThenB
                    case .smallerOrEqual: return (compare == .aIsBiggerThenB || compare == .aIsEqualToB)
                    case .noneSpecific: return true
                    }
                }

                public func biggestVersionMatchRequirement(list: [String]) -> String? {
                    let sorted = list
                        .sorted { AptPackageVersion.compareA($0, andB: $1) > 0 }
                    for item in sorted {
                        if doesThisVersionMatchesRequirement(version: item) {
                            return item
                        }
                    }
                    return nil
                }
            }

            public let elements: [RequirementElement]
            public let original: String

            // solve: xulrunner (>= 1.9~) | xulrunner-1.9
            init?(value: String) {
                original = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if value.contains("|") {
                    let elements = value
                        .components(separatedBy: "|")
                        .map { RequirementElement(value: $0) }
                        .compactMap { $0 }
                    self.elements = elements
                } else {
                    let elements = [RequirementElement(value: value)]
                        .compactMap { $0 }
                    self.elements = elements
                }
                if elements.count == 0 { return nil }
            }
        }

        public let requirements: [Requirement]
        public let original: String

        // solves: aaa | bbb (>= 1.1) | ccc, ddd (<=888), eee, fff, ggg(=99)
        init?(value: String, type: RequirementType) {
            self.type = type
            original = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if value.contains(",") {
                let requirements = value
                    .components(separatedBy: ",")
                    .map { Requirement(value: $0) }
                self.requirements = requirements.compactMap { $0 }
            } else {
                let requirements = [Requirement(value: value)]
                self.requirements = requirements.compactMap { $0 }
            }
            if requirements.count == 0 { return nil }
        }
    } // PackageRequirementGroup
    // the whole requirement for a package
    public let group: [PackageRequirementGroup]

    /// create requirement group of the package, nil if metadata not found
    /// - Parameters:
    ///   - package: object
    ///   - version: version to load, otherwise newest
    public init?(with package: Package, onVersion version: String? = nil) {
        guard let version = version ?? package.latestVersion else {
            return nil
        }
        guard let meta = package.payload[version] else {
            return nil
        }
        var result = [PackageRequirementGroup]()
        if let value = meta["depends"] {
            if let group = PackageRequirementGroup(value: value, type: .depends) {
                result.append(group)
            }
        }
        if let value = meta["pre-depends"] {
            if let group = PackageRequirementGroup(value: value, type: .depends) {
                result.append(group)
            }
        }
        if let value = meta["conflicts"] {
            if let group = PackageRequirementGroup(value: value, type: .conflicts) {
                result.append(group)
            }
        }
        if let value = meta["replaces"] {
            if let group = PackageRequirementGroup(value: value, type: .replaces) {
                result.append(group)
            }
        }
        if let value = meta["breaks"] {
            if let group = PackageRequirementGroup(value: value, type: .breaks) {
                result.append(group)
            }
        }
        if let value = meta["provides"] {
            if let group = PackageRequirementGroup(value: value, type: .provides) {
                result.append(group)
            }
        }
        if result.count == 0 { return nil }
        group = result
    }
}
