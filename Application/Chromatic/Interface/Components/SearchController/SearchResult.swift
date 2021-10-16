//
//  SearchResult.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/13.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import Dog
import Foundation

struct SearchResult {
    enum RepresentTarget {
        case installed(package: Package)
        case collection(package: Package)
        case repository(url: URL)
        case package(identity: String, repository: URL)
        case author(name: String)
    }

    let associatedValue: RepresentTarget
    let searchText: String
    let underKey: String
    let ratio: Double
}

extension SearchController {
    func buildSearchResultWith(key: String, andToken current: UUID) {
        var result = [[SearchResult]]()
        result.append(searchInstalled(key: key, token: current))
        if searchToken != current { return }
        result.append(searchCollections(key: key, token: current))
        if searchToken != current { return }
        result.append(searchPackages(key: key, token: current))
        if searchToken != current { return }
        result.append(searchRepository(key: key, token: current))
        if searchToken != current { return }
        result.append(searchAuthor(key: key, token: current))
        if searchToken != current { return }
        result = result.filter { $0.count > 0 }
        if searchToken != current { return }
        setSearchResult(with: result)
    }

    private func searchLookupInside(packages: [Package], key: String, token: UUID, compiler: (Package) -> (SearchResult.RepresentTarget)) -> [SearchResult] {
        var result = [(String, SearchResult)]()
        var key = key
        if !searchWithCaseSensitive { key = key.lowercased() }
        autoreleasepool {
            for package in packages {
                if token != self.searchToken { return }
                var searchableContent = """
                \(package.latestMetadata?["name"] ?? "")
                \(package.latestMetadata?["author"] ?? "")
                \(package.latestMetadata?["section"] ?? "")
                \(package.latestMetadata?["description"] ?? "")
                \(package.latestMetadata?["package"] ?? "")
                """
                if !searchWithCaseSensitive {
                    searchableContent = searchableContent.lowercased()
                }
                if searchableContent.contains(key) {
                    var ratio = 1.0
                    var extraDecisions = [String]()
                    extraDecisions.append(PackageCenter.default.name(of: package))
                    extraDecisions.append(package.identity)
                    if !searchWithCaseSensitive {
                        extraDecisions = extraDecisions.map { $0.lowercased() }
                    }
                    extraDecisions.forEach { if $0.hasPrefix(key) { ratio += 1.0 } }
                    let val = compiler(package)
                    let search = SearchResult(associatedValue: val,
                                              searchText: searchableContent,
                                              underKey: key,
                                              ratio: ratio)
                    let name = package
                        .latestMetadata?["name"]
                        ?? package.identity
                    result.append((name, search))
                }
            }
        }
        return result
            .sorted(by: \.0)
            .sorted(by: \.0.count)
            .sorted(by: \.1.ratio, with: >)
            .map(\.1)
    }

    private func searchInstalled(key: String, token: UUID) -> [SearchResult] {
        let packages = PackageCenter
            .default
            .obtainInstalledPackageList()
            .filter {
                !($0.latestMetadata?["tag"]?.contains("role::cydia") ?? false)
                    || key.hasPrefix("gsc")
            }
        return searchLookupInside(packages: packages, key: key, token: token) { package in
            SearchResult.RepresentTarget.installed(package: package)
        }
    }

    private func searchCollections(key: String, token: UUID) -> [SearchResult] {
        let packages = InterfaceBridge
            .collectedPackages
            .sorted { a, b in
                PackageCenter.default.name(of: a)
                    < PackageCenter.default.name(of: b)
            }
        return searchLookupInside(packages: packages, key: key, token: token) { package in
            SearchResult.RepresentTarget.collection(package: package)
        }
    }

    private func searchRepository(key: String, token: UUID) -> [SearchResult] {
        var result = [SearchResult]()
        var key = key
        if !searchWithCaseSensitive { key = key.lowercased() }
        RepositoryCenter
            .default
            .obtainRepositoryUrls()
            .forEach { url in
                if token != self.searchToken { return }
                guard let repo = RepositoryCenter
                    .default
                    .obtainImmutableRepository(withUrl: url)
                else {
                    Dog.shared.join(self, "search failed with broken resource on \(url.absoluteString)")
                    return
                }
                var searchableContent = """
                \(url.absoluteString)
                \(repo.nickName)
                \(repo.repositoryDescription ?? "")
                """
                if !searchWithCaseSensitive {
                    searchableContent = searchableContent.lowercased()
                }
                if searchableContent.contains(key) {
                    let build = SearchResult(associatedValue: .repository(url: url),
                                             searchText: searchableContent,
                                             underKey: key,
                                             ratio: 1.0)
                    result.append(build)
                }
            }
        return result
    }

    private func searchPackages(key: String, token: UUID) -> [SearchResult] {
        var result = [(String, SearchResult)]()
        var key = key
        if !searchWithCaseSensitive { key = key.lowercased() }
        autoreleasepool {
            let compilers = PackageCenter
                .default
                .obtainAllPackageIdentity()
                .map { PackageCenter.default.obtainPackageSummary(with: $0) }
                .compactMap { $0 }
            for compiler in compilers {
                if token != self.searchToken { return }
                compiler.forEach { url, package in
                    if token != self.searchToken { return }
                    var searchableContent = """
                    \(package.latestMetadata?["name"] ?? "")
                    \(package.latestMetadata?["author"] ?? "")
                    \(package.latestMetadata?["section"] ?? "")
                    \(package.latestMetadata?["description"] ?? "")
                    \(package.latestMetadata?["package"] ?? "")
                    """
                    if !searchWithCaseSensitive {
                        searchableContent = searchableContent.lowercased()
                    }
                    if searchableContent.contains(key) {
                        var ratio = 1.0
                        var extraDecisions = [String]()
                        extraDecisions.append(PackageCenter.default.name(of: package))
                        extraDecisions.append(package.identity)
                        if !searchWithCaseSensitive {
                            extraDecisions = extraDecisions.map { $0.lowercased() }
                        }
                        extraDecisions.forEach { if $0.hasPrefix(key) { ratio += 1.0 } }
                        let val = SearchResult.RepresentTarget.package(identity: package.identity,
                                                                       repository: url)
                        let search = SearchResult(associatedValue: val,
                                                  searchText: searchableContent,
                                                  underKey: key,
                                                  ratio: ratio)
                        let name = package
                            .latestMetadata?["name"]
                            ?? package.identity
                        result.append((name, search))
                    }
                }
            }
        }
        return result
            .sorted(by: \.0)
            .sorted(by: \.0.count)
            .sorted(by: \.1.ratio, with: >)
            .map(\.1)
    }

    private func searchAuthor(key: String, token: UUID) -> [SearchResult] {
        var result = [SearchResult]()
        var key = key
        if !searchWithCaseSensitive { key = key.lowercased() }
        let authors = PackageCenter
            .default
            .obtainAuthorList()
        autoreleasepool {
            for author in authors {
                if token != self.searchToken { return }
                var searchableContent = author
                if !searchWithCaseSensitive {
                    searchableContent = searchableContent.lowercased()
                }
                if searchableContent.contains(key) {
                    result.append(SearchResult(associatedValue: .author(name: author),
                                               searchText: searchableContent,
                                               underKey: key,
                                               ratio: 1.0))
                }
            }
        }
        return result
    }
}
