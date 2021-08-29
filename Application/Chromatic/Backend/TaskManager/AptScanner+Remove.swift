//
//  AptScanner+Remove.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/21.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import Dog
import Foundation

extension TaskManager {
    /// search for all packages that will be broke
    /// if we process removal request so also remove them all
    /// - Parameters:
    ///   - success: if we make requirement clear
    ///   - removeRequest: request
    ///   - removedContext: context to build
    ///   - installation: copy of package local installation info
    /// - Returns: packages to be removed
    func searchRemovalBarrier(success: inout Bool,
                              removeRequest: PackageAction,
                              removedContext: [Package],
                              installation: [Package])
        -> [Package]
    {
        var currentRemovalContext = removedContext
        currentRemovalContext.append(removeRequest.represent)

        var currentInstallationExtended = Set<String>()
        func rebuildExtendedInstallation() {
            let filter = currentRemovalContext.map(\.identity)
            var newInstallationExtended = Set<String>()
            // extend any virtual package, create by provide section in package metadata
            for install in installation where !filter.contains(install.identity) {
                newInstallationExtended.insert(install.identity)
                guard let info = PackageRequirement(with: install) else { continue }
                for item in info.group where item.type == .provides {
                    item
                        .requirements
                        .map(\.elements)
                        .flatMap { $0 }
                        .compactMap { $0 }
                        .forEach { newInstallationExtended.insert($0.representPackage) }
                }
            }
            currentInstallationExtended = newInstallationExtended
        }
        rebuildExtendedInstallation()

        // it won't change during the scan
        var installAnalysisCache = [String: PackageRequirement]()
        for installed in installation {
            if let fetch = PackageRequirement(with: installed) {
                installAnalysisCache[installed.identity] = fetch
            }
        }

        // loop a controlled time to get removal details
        // each time we iterate over installed packages
        // to find the packages that their dependencies
        // was broke by current removal request
        // then we add them to the list and do again
        // break the loop until there is no more case that we need to handle
        // if the loop didn't finish in a controlled time the request will be denied
        var currentDepth = 0
        var loopSuccess = false
        while currentDepth < 500, !loopSuccess { // protect my stack frame
            currentDepth += 1
            var foundExtra = false
            // oh my little ram
            autoreleasepool {
                for installed in installation {
                    // skipping in queue package
                    if currentRemovalContext.map(\.identity).contains(installed.identity) {
                        continue
                    }
                    let requirement = installAnalysisCache[installed.identity]
                    var affected: [PackageRequirement.PackageRequirementGroup.Requirement] = []
                    search: for item in requirement?.group ?? [] {
                        if item.type == .depends {
                            // depends or pre-depends, don't cut them using break!
                            affected.append(contentsOf: item.requirements)
                        }
                    }
                    // check if we breaks all the requirement elements
                    var canSurvive = true
                    // group: aaa | bbb (>= 1.1) | ccc, ddd (<=888), eee, fff, ggg(=99)
                    // requires to match them all
                    group: for group in affected {
                        // tells this package requires lookup, now grab the virtual space
                        var canSurviveThisRound = false
                        // element: bbb (>= 1.1)
                        // requires to match at least one
                        inner: for element in group.elements {
                            // if one of the element can be found in virtual installed array
                            // we don't need to delete it
                            if currentInstallationExtended.contains(element.representPackage) {
                                canSurviveThisRound = true
                                break inner
                            }
                        }
                        if !canSurviveThisRound {
                            canSurvive = false
                            debugPrint("\(installed.identity) not surviving due to breaking \(group.original)")
                            break group
                        }
                    }
                    // no, totally breaks
                    if !canSurvive {
                        foundExtra = true
                        currentRemovalContext.append(installed)
                        rebuildExtendedInstallation()
                    }
                }
                if !foundExtra {
                    loopSuccess = true
                }
            }
        }

        if !loopSuccess {
            success = false
            Dog.shared.join(self, "canceling removal request due to breaking too many dependencies")
            return []
        }

        return currentRemovalContext
    }
}
