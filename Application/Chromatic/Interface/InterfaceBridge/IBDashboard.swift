//
//  IBDashboard.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/9/15.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import UIKit

extension InterfaceBridge {
    struct DashboardDataSection {
        let title: String
        let package: [Package]
        let shouldLimit: Bool
        let action: ((UIViewController?) -> Void)?
    }

    static func dashbaordBuildDataSource() -> [DashboardDataSection] {
        var builder = [DashboardDataSection?]()
        builder.append(buildCollections())
        builder.append(buildAvailableUpdate())
        builder.append(buildRepoFeatured())
        builder.append(buildRecentInstall())
        builder.append(buildRecentUpdate())
        return builder
            .compactMap { $0 }
            .filter { $0.package.count > 0 }
    }

    private static func buildCollections() -> DashboardDataSection? {
        DashboardDataSection(title: NSLocalizedString("COLLECTED_PACKAGES", comment: "Collected Packages"),
                             package: collectedPackages.sorted { a, b in
                                 PackageCenter.default.name(of: a)
                                     < PackageCenter.default.name(of: b)
                             },
                             shouldLimit: false,
                             action: { controller in
                                 controller?.present(next: PackageSavedCollectionController())
                             })
    }

    private static func buildAvailableUpdate() -> DashboardDataSection? {
        let everything = PackageCenter
            .default
            .obtainInstalledPackageList()
            .filter { !($0.latestMetadata?["tag"]?.contains("role::cydia") ?? false) }
        var builder = [(Package, Package)]()
        for item in everything {
            guard let installInfo = PackageCenter
                .default
                .obtainPackageInstallationInfo(with: item.identity)
            else {
                continue
            }
            let candidateReader = PackageCenter
                .default
                .obtainUpdateForPackage(with: installInfo.identity,
                                        version: installInfo.version)
            if candidateReader.count > 0,
               let decision = PackageCenter
               .default
               .newestPackage(of: candidateReader)
            {
                let loader = (item, decision)
                builder.append(loader)
            }
        }
        return DashboardDataSection(title: NSLocalizedString("UPDATE_CANDIDATE", comment: "Update Candidate"),
                                    package: builder
                                        .map(\.1)
                                        .sorted { a, b in
                                            PackageCenter.default.name(of: a)
                                                < PackageCenter.default.name(of: b)
                                        },
                                    shouldLimit: false,
                                    action: { controller in
                                        controller?.present(next: UpdateController())
                                    })
    }

    private static func buildRepoFeatured() -> DashboardDataSection? {
        var builder = [Package]()
        let repos = RepositoryCenter
            .default
            .obtainRepositoryUrls()
            .map { RepositoryCenter.default.obtainImmutableRepository(withUrl: $0) }
        for repo in repos {
            guard let featured = repo?.attachment[.featured],
                  let data = featured.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments),
                  let decoded = json as? [String: Any],
                  decoded["class"] as? String == "FeaturedBannersView",
                  let banners = decoded["banners"] as? [[String: Any]]
            else {
                continue
            }
            for banner in banners {
                guard let identity = banner["package"] as? String,
                      let package = repo?.metaPackage[identity]
                else {
                    continue
                }
                builder.append(package)
            }
        }
        return DashboardDataSection(title: NSLocalizedString("REPO_FEATURED", comment: "Repo Featured"),
                                    package: builder.sorted { a, b in
                                        PackageCenter.default.name(of: a)
                                            < PackageCenter.default.name(of: b)
                                    },
                                    shouldLimit: true,
                                    action: nil)
    }

    private static func buildRecentInstall() -> DashboardDataSection? {
        let everything = PackageCenter
            .default
            .obtainInstalledPackageList()
            .filter { !($0.latestMetadata?["tag"]?.contains("role::cydia") ?? false) }

        var builder = [Date?: [Package]]()
        for item in everything {
            let lastModifiedDate = PackageCenter
                .default
                .obtainLastModification(for: item.identity, and: .install)
            var sectionBuilder = builder[lastModifiedDate, default: []]
            sectionBuilder.append(item)
            builder[lastModifiedDate] = sectionBuilder
        }
        for (key, value) in builder {
            let foo = value.sorted { a, b in
                PackageCenter.default.name(of: a)
                    < PackageCenter.default.name(of: b)
            }
            builder[key] = foo
        }
        let none = builder[nil]
        let constructor = builder
            .map { ($0, $1) }
            .filter { $0.0 != nil }
            .sorted { pairA, pairB in
                pairA.0 ?? Date() > pairB.0 ?? Date()
            }
        var result = constructor.map(\.1)
        if let none = none { result.append(none) }

        return DashboardDataSection(title: NSLocalizedString("RECENT_INSTALL", comment: "Recent Install"),
                                    package: result.flatMap { $0 },
                                    shouldLimit: true,
                                    action: nil)
    }

    private static func buildRecentUpdate() -> DashboardDataSection? {
        let list = PackageCenter
            .default
            .obtainRecentUpdatedList()
        guard list.count > 0 else {
            return nil
        }
        var builder = [Package]()
        for key in list.keys.sorted(by: { $0 > $1 }) {
            let compiler = list[key, default: []]
                .map { identity, repoUrl -> Package? in
                    if let url = repoUrl,
                       let repo = RepositoryCenter
                       .default
                       .obtainImmutableRepository(withUrl: url),
                       let package = repo.metaPackage[identity]
                    {
                        return package
                    } else if let pkg = PackageCenter
                        .default
                        .obtainUpdateForPackage(with: identity, version: "0")
                        .first
                    {
                        return pkg
                    } else {
                        return nil
                    }
                }
                .compactMap { $0 }
                .sorted {
                    PackageCenter.default.name(of: $0)
                        < PackageCenter.default.name(of: $1)
                }
            builder.append(contentsOf: compiler)
        }
        return DashboardDataSection(title: NSLocalizedString("RECENT_UPDATE", comment: "Recent Update"),
                                    package: builder,
                                    shouldLimit: true) { controller in
            var list = PackageCenter
                .default
                .obtainRecentUpdatedList()
            guard list.count > 0 else {
                return
            }
            for (key, value) in list {
                list[key] = value.sorted(by: \.0)
            }
            let target = RecentUpdateController()
            target.updateDataSource = list
            controller?.present(next: target)
        }
    }
}
