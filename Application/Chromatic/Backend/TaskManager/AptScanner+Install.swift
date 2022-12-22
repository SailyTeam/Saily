//
//  AptScanner+Install.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/21.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import Dog
import Foundation

extension TaskManager {
    func searchInstallExtra(installRequest: PackageAction,
                            installContext: [Package],
                            removing: [String],
                            missingPackage: inout [String],
                            breakPackage: inout [String])
        -> [Package]
    {
        struct SearchResult {
            let success: Bool
            let install: [Package]
            let missing: [String]
            let breaks: [String]
        }

        // contains virtual packages
        let originalCopyInstalled = PackageCenter
            .default
            .obtainInstalledPackageList()
        let installedOriginalTable: [String: Package] = {
            var build = [String: Package]()
            originalCopyInstalled.forEach {
                build[$0.identity] = $0
            }
            return build
        }()
        let installedExtendedLookupTable: [String: Package] = {
            var build = [String: Package]()
            originalCopyInstalled.forEach {
                build[$0.identity] = $0
                guard let info = PackageRequirement(with: $0) else { return }
                for item in info.group where item.type == .provides {
                    item.requirements.map(\.elements).flatMap { $0 }.compactMap { $0 }.forEach {
                        if build[$0.representPackage] == nil {
                            build[$0.representPackage] =
                                Package(identity: $0.representPackage,
                                        payload: ["99": [
                                            "package": $0.representPackage,
                                            "version": "99",
                                        ]], repoRef: nil)
                        }
                    }
                }
            }
            return build
        }()

        var requirementCache: [String: PackageRequirement] = [:]
        func lookupRequirementFromCache(_ package: Package) -> PackageRequirement? {
            let key = package.identity
                + (package.repoRef?.absoluteString ?? "")
                + (package.latestVersion ?? "")
            if let value = requirementCache[key] {
                return value
            }
            let val = PackageRequirement(with: package)
            requirementCache[key] = val
            return val
        }

        func resolveMissingItem(context: [Package], install: Package, depth: Int) -> SearchResult {
            if depth > 50 { return returnHook(.init(success: false, install: [], missing: [], breaks: [])) }

            func debugPrint(_ str: String) {
                var str = str
                for _ in 0 ..< depth {
                    str = "||  " + str
                }
                str += "    "
                PackageActionReport.shared.append(str)
                Dog.shared.join(self, str, level: .verbose)
            }
            func returnHook(_ result: SearchResult) -> SearchResult {
                if result.breaks.count > 0 {
                    debugPrint("🔴 \(NSLocalizedString("MISSING_OR_BREAKING", comment: "missing or breaking")) \(result.breaks.joined(separator: ", "))")
                }
                if result.missing.count > 0 {
                    debugPrint("🔴 \(NSLocalizedString("MISSING_OR_BREAKING", comment: "missing or breaking")) \(result.missing.joined(separator: ", "))")
                }
                return result
            }
            // add install candidate
            var currentMissingBuilder = [String]()
            var currentBreakingBuilder = [String]()
            var currentContextBuilder = context
            if currentContextBuilder.map(\.identity).contains(install.identity) {
                // TODO: check if version matched
                return returnHook(.init(success: true, install: context, missing: [], breaks: []))
            }
            debugPrint("adding \(install.identity) to context \(currentContextBuilder.count)")
            currentContextBuilder.append(install)

            // get requirement
            if let newPackageRequirement = lookupRequirementFromCache(install) {
                var dependGroupBuilder = [PackageRequirement.PackageRequirementGroup.Requirement]()
                for eachRequirement in newPackageRequirement.group {
                    autoreleasepool {
                        switch eachRequirement.type {
                        case .breaks, .conflicts:
                            // check if installed or current context contains these items
                            // and TODO: CHECK VERSION
                            // i don't think some body will put
                            // abc | def | kfc, bbb, ccc
                            // in this section................
                            let breakingList = eachRequirement
                                .requirements
                                .map(\.elements)
                                .flatMap { $0 }
                            innerBreakingSearch: for breakingElement in breakingList {
                                if removing.contains(breakingElement.representPackage) {
                                    continue
                                }
                                // check if in an update loop
                                if currentContextBuilder.map(\.identity).contains(breakingElement.representPackage) {
                                    /*
                                     now we need to solve the problem if they are looping the dependency
                                     eg.
                                        chariz-keyring is breaking package procursus-keyring 2020.05.09
                                     while
                                        procursus-keyring is processing update from 2020.05.09 to 2020.05.09-2
                                     */
                                    for installElement in currentContextBuilder
                                        where installElement.identity == breakingElement.representPackage
                                    {
                                        guard let installElementVersion = installElement.latestVersion else {
                                            currentBreakingBuilder.append(installElement.identity)
                                            debugPrint("🔴 \(installElement.identity) is invalid")
                                            continue innerBreakingSearch
                                        }
                                        if breakingElement.doesThisVersionMatchesRequirement(version: installElementVersion) {
                                            currentBreakingBuilder.append(breakingElement.representPackage)
                                            debugPrint("🔴 \(install.identity) is breaking package \(breakingElement.representPackage) \(installElementVersion)")
                                            continue innerBreakingSearch
                                        } else {
                                            continue innerBreakingSearch
                                        }
                                    }
                                    #if DEBUG
                                        // WHAT?
                                        fatalError()
                                    #endif
                                } else {
                                    // not in install loop, check for installed packages
                                    if let installedBreaks = installedOriginalTable[breakingElement.representPackage],
                                       let version = installedBreaks.latestVersion,
                                       breakingElement.doesThisVersionMatchesRequirement(version: version)
                                    {
                                        currentBreakingBuilder.append(installedBreaks.identity)
                                        debugPrint("🔴 \(install.identity) is breaking package \(breakingElement.representPackage) \(version)")
                                        continue innerBreakingSearch
                                    }
                                    for current in currentContextBuilder where current.identity == breakingElement.representPackage {
                                        if let version = current.latestVersion,
                                           breakingElement.doesThisVersionMatchesRequirement(version: version)
                                        {
                                            currentBreakingBuilder.append(current.identity)
                                            debugPrint("🔴 \(install.identity) is breaking package \(current.identity) \(version)")
                                            continue innerBreakingSearch
                                        }
                                    }
                                }
                            }
                        case .depends:
                            // build the dependencies group
                            dependGroupBuilder.append(contentsOf: eachRequirement.requirements)
                        default: break
                        }
                    }
                }
                // if conflicted found by breaks or conflict
                if currentBreakingBuilder.count > 0 || currentMissingBuilder.count > 0 {
                    return returnHook(
                        .init(success: false,
                              install: currentContextBuilder,
                              missing: currentMissingBuilder,
                              breaks: currentBreakingBuilder)
                    )
                }
                // we now have flat mapped depend group
                autoreleasepool {
                    // now let's sort our dependency group, choose the minimal installation solution
                    /*
                      eg:

                      org.coolstar.sileo (>= 2.1) | xyz.willy.zebra (>= 1.1.19) | me.apptapp.installer (>= 5.1) | cydia | openssh-server

                      installed cydia, then sort to
                      cydia | ...
                     */

                    let dependencyGroups = dependGroupBuilder
                        .sorted { elementA, elementB in
                            let context = installContext.map(\.identity)
                            let unknownCountA = elementA
                                .elements
                                .filter { installedExtendedLookupTable[$0.representPackage] == nil }
                                .filter { !context.contains($0.representPackage) }
                                .count
                            let unknownCountB = elementB
                                .elements
                                .filter { installedExtendedLookupTable[$0.representPackage] == nil }
                                .filter { !context.contains($0.representPackage) }
                                .count
                            return unknownCountA < unknownCountB
                        }

                    // after the sort, let's choose one by one

                    // this is a group, eg: aaa, bbb, ccc | ddd, eee, fff
                    group: for eachDependency in dependencyGroups {
                        // this is an element like [ccc | ddd]
                        // one of the element work, we break down the loop
                        debugPrint("resolving depend \(eachDependency.original)")

                        let sortedDependencyGroups = eachDependency.elements
                            .sorted { elementA, elementB in
                                let context = installContext.map(\.identity)
                                let a1 = installedExtendedLookupTable[elementA.representPackage] == nil ? 0 : 1
                                let a2 = !context.contains(elementA.representPackage) ? 0 : 1

                                let b1 = installedExtendedLookupTable[elementB.representPackage] == nil ? 0 : 1
                                let b2 = !context.contains(elementB.representPackage) ? 0 : 1
                                return a1 + a2 > b1 + b2
                            }

                        inner: for eachElement in sortedDependencyGroups {
                            // can't put something to install while removing
                            if removing.contains(eachElement.representPackage) {
                                // go search for next one
                                continue inner
                            }

                            // lookup in install context first, if already in install queue, mark as satisfied
                            for eachContextItem in currentContextBuilder {
                                if eachContextItem.identity == eachElement.representPackage {
                                    if let version = eachContextItem.latestVersion,
                                       eachElement.doesThisVersionMatchesRequirement(version: version)
                                    {
                                        // break this group as it's being satisfied
                                        debugPrint("this dependency already satisfied in install context")
                                        break group
                                    } else {
                                        break inner
                                    }
                                } else {
                                    // check if being provided
                                    guard let provideLookup = lookupRequirementFromCache(eachContextItem) else { continue }
                                    for provideGroup in provideLookup.group where provideGroup.type == .provides {
                                        for provideElements in provideGroup.requirements.map(\.elements) {
                                            for providedPackage in provideElements
                                                where providedPackage.representPackage == eachElement.representPackage
                                            {
                                                let version = providedPackage.versionValue
                                                if eachElement.doesThisVersionMatchesRequirement(version: version) {
                                                    // break this group as it's being satisfied
                                                    debugPrint("this dependency already satisfied in install context")
                                                    break group
                                                } else {
                                                    break inner
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // already installed, check if version requirement matches it
                            // if not, throws a breaking
                            if let installLookup = installedExtendedLookupTable[eachElement.representPackage],
                               let installVersion = installLookup.latestVersion
                            {
                                if eachElement.doesThisVersionMatchesRequirement(version: installVersion) {
                                    debugPrint("requirement already install \(eachElement.representPackage)")
                                    continue group
                                } else {
                                    // installed, but version failed to match requirement
                                    debugPrint("requirement already install \(eachElement.representPackage) but not working with \(eachElement.original)")
                                    // now let's check if an update is available for this package
                                    let availablePackages = PackageCenter
                                        .default
                                        .obtainPackageSummary(with: eachElement.representPackage)
                                        .values
                                    let availableVersions = availablePackages
                                        .map { ($0.latestVersion, $0) }
                                        .sorted {
                                            switch Package.compareVersion($0.0 ?? "", b: $1.0 ?? "") {
                                            case .aIsBiggerThenB: return true // put a front
                                            case .aIsEqualToB: return true // nvm
                                            case .aIsSmallerThenB: return false // put a back
                                            case .invalidParameter: return false // what?
                                            }
                                        }
                                    // now, from top down
                                    innerSearch: for element in availableVersions {
                                        guard let version = element.0,
                                              Package.validateVersion(version)
                                        else {
                                            continue innerSearch
                                        }
                                        if eachElement.doesThisVersionMatchesRequirement(version: version) {
                                            debugPrint("matched version update for install candidate \(eachElement.representPackage)")
                                            let appendResult = resolveMissingItem(context: currentContextBuilder,
                                                                                  install: element.1,
                                                                                  depth: depth + 1)
                                            if appendResult.success {
                                                debugPrint("matched version update validated for install candidate \(eachElement.representPackage)")
                                                let read = appendResult
                                                    .install
                                                    .filter {
                                                        !currentContextBuilder
                                                            .map(\.identity)
                                                            .contains($0.identity)
                                                    }
                                                currentContextBuilder.append(contentsOf: read)
                                                continue group
                                            }
                                        }
                                    }
                                    continue inner
                                }
                            }

                            // not installed, then we search for it
                            var searchTarget: Package?
                            func lookupAndSetPackage(withIdentity identity: String) {
                                let candidates = PackageCenter
                                    .default
                                    .obtainPackageSummary(with: identity)
                                    .values
                                debugPrint("looking for package \(identity) returns \(candidates.count)")
                                for candidate in candidates {
                                    let versions = [String](candidate.payload.keys)
                                    let targetVersion = eachElement.biggestVersionMatchRequirement(list: versions)
                                    if let targetVersion = targetVersion,
                                       let trimmedPackage = PackageCenter
                                       .default
                                       .trim(package: candidate, toVersion: targetVersion)
                                    {
                                        let compare = Package
                                            .compareVersion(searchTarget?.latestVersion ?? "0", b: targetVersion)
                                        if compare == .aIsSmallerThenB {
                                            debugPrint("setting candidate \(candidate.identity) \(candidate.latestVersion ?? "0")")
                                            searchTarget = trimmedPackage
                                        }
                                    }
                                }
                            }

                            // search in those packages
                            lookupAndSetPackage(withIdentity: eachElement.representPackage)

                            // search in virtual packages
                            do {
                                if searchTarget == nil {
                                    debugPrint("failed to find \(eachElement.original), search virtual refrences")
                                    let virtualReference = PackageCenter
                                        .default
                                        .obtainVirtualPackageReference(withIdentity: eachElement.representPackage)
                                    search: for references in virtualReference {
                                        lookupAndSetPackage(withIdentity: references)
                                        if searchTarget != nil { break search }
                                    }
                                }
                            }

                            // found a searchTarget
                            if let searchTarget = searchTarget {
                                let appendResult = resolveMissingItem(context: currentContextBuilder, install: searchTarget, depth: depth + 1)
                                if appendResult.success {
                                    debugPrint("successfully found additional install")
                                    let read = appendResult
                                        .install
                                        .filter {
                                            !currentContextBuilder
                                                .map(\.identity)
                                                .contains($0.identity)
                                        }
                                    currentContextBuilder.append(contentsOf: read)
                                    continue group
                                }
                                // search failed
                            }
                        }
                        // if we don't break the loop, there should be error
                        debugPrint("missing \(eachDependency.original)")
                        currentMissingBuilder.append(eachDependency.original)
                    }
                }
                if currentBreakingBuilder.count > 0 || currentMissingBuilder.count > 0 {
                    return returnHook(
                        .init(success: false,
                              install: currentContextBuilder,
                              missing: currentMissingBuilder,
                              breaks: currentBreakingBuilder)
                    )
                }

            } else {
                return returnHook(
                    .init(success: true, install: currentContextBuilder, missing: [], breaks: [])
                )
            }
            return returnHook(
                .init(success: currentMissingBuilder.count == 0 && currentBreakingBuilder.count == 0,
                      install: currentContextBuilder,
                      missing: currentMissingBuilder,
                      breaks: currentBreakingBuilder)
            )
        }

        let result = resolveMissingItem(context: installContext,
                                        install: installRequest.represent,
                                        depth: 0)
        missingPackage = result.missing
        breakPackage = result.breaks
        debugPrint("resoled \(result.install.count) installs")
        return result.install
    }
}
