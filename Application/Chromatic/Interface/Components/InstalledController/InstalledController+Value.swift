//
//  InstalledController+Value.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/29.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import UIKit

extension InstalledController {
    /// Update datasource in this routine
    /// - Parameter withSearchText: search controller passed text
    func updateSource(withSearchText: String? = nil) {
        let everything = PackageCenter
            .default
            .obtainInstalledPackageList()
            .filter {
                !($0.latestMetadata?["tag"]?.contains("role::cydia") ?? false)
                    || (withSearchText?.hasPrefix("gsc") ?? false)
            }
        var read = everything
        if let search = withSearchText, search.count > 0 {
            searchFiltering(key: search, result: &read)
        }
        switch sortOption {
        case .name:
            read = read.sorted { compareName(a: $0, b: $1) }
            if sortReversed { read = read.reversed() }
            dataSource = [.init(section: nil, package: read)]
        case .lastModification:
            var builder = [Date?: InstalledData]()
            for item in read {
                let lastModifiedDate = PackageCenter
                    .default
                    .obtainLastModification(for: item.identity, and: .install)
                var section: String
                if let lastModifiedDate {
                    section = formatter.string(from: lastModifiedDate)
                } else {
                    section = NSLocalizedString("NOT_MODIFIED", comment: "Not Modified")
                }
                var sectionBuilder = builder[lastModifiedDate, default: InstalledData(section: section, package: [])]
                sectionBuilder.package.append(item)
                builder[lastModifiedDate] = sectionBuilder
            }
            for (key, value) in builder {
                let foo = value.package.sorted { compareName(a: $0, b: $1) }
                builder[key] = InstalledData(section: value.section, package: foo)
            }
            let none = builder[nil]
            let constructor = builder
                .map { ($0, $1) }
                .filter { $0.0 != nil }
                .sorted { pairA, pairB in
                    pairA.0 ?? Date() > pairB.0 ?? Date()
                }
            var result = constructor.map(\.1)
            if let none { result.append(none) }
            if sortReversed { result = result.reversed() }
            dataSource = result
        }
        collectionView.reloadData()
        updateFound = false
        updateLookup: for item in everything {
            guard let installInfo = PackageCenter
                .default
                .obtainPackageInstallationInfo(with: item.identity)
            else {
                continue
            }
            if PackageCenter
                .default
                .obtainUpdateForPackage(with: installInfo.identity,
                                        version: installInfo.version)
                .count > 0
            {
                updateFound = true
                break updateLookup
            }
        }
        setupRightButtonItem()
    }

    func searchFiltering(key: String, result: inout [Package]) {
        var key = key
        if !searchWithCaseSensitive { key = key.lowercased() }
        result = result
            .filter {
                var name = PackageCenter.default.name(of: $0)
                var describe = PackageCenter.default.description(of: $0)
                if !searchWithCaseSensitive {
                    name = name.lowercased()
                    describe = describe.lowercased()
                }
                return name.contains(key)
            }
    }

    func compareName(a: Package, b: Package) -> Bool {
        PackageCenter.default.name(of: a).lowercased()
            <
            PackageCenter.default.name(of: b).lowercased()
    }
}
