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
    func buildSearchResultWith(key: String) {
        var result = [SearchResult]()
        result.append(contentsOf: searchCollections(key: key))
        result.append(contentsOf: searchPackages(key: key))
        result.append(contentsOf: searchRepository(key: key))
        result.append(contentsOf: searchAuthor(key: key))
        setSearchResult(with: result)
    }

    private func searchCollections(key _: String) -> [SearchResult] {
        []
    }

    private func searchRepository(key: String) -> [SearchResult] {
        var result = [SearchResult]()
        var key = key
        if !searchWithCaseSensitive { key = key.lowercased() }
        RepositoryCenter
            .default
            .obtainRepositoryUrls()
            .forEach { url in
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

    private func searchPackages(key: String) -> [SearchResult] {
        var result = [(String, SearchResult)]()
        var key = key
        if !searchWithCaseSensitive { key = key.lowercased() }
        autoreleasepool {
            PackageCenter
                .default
                .obtainAllPackageIdentity()
                .map { PackageCenter.default.obtainPackageSummary(with: $0) }
                .compactMap { $0 }
                .forEach { compiler in
                    compiler.forEach { url, package in
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

    private func searchAuthor(key: String) -> [SearchResult] {
        var result = [SearchResult]()
        var key = key
        if !searchWithCaseSensitive { key = key.lowercased() }
        PackageCenter
            .default
            .obtainAuthorList()
            .forEach { author in
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
        return result
    }
}
