//
//  Project Chromatic
//  Chromatic
//
//  Created by Lakr Aream on 2020/4/18.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import AptPackageVersion
import Foundation

public let PackageBadUrl = URL(string: "https://127.0.0.1:8888/some/bad/url")!

public struct Package: Codable, Hashable, Identifiable {
    // MARK: - Property

    // id
    public var id: String { identity }
    public let identity: String

    // store
    public typealias Version = String
    public typealias Metadata = [String: String]
    public let payload: [Version: Metadata]

    // ref
    public let repoRef: URL?

    public let latestVersion: String?

    // MARK: - Init

    public init(identity: String,
                payload: [Package.Version: Package.Metadata] = [:],
                repoRef: URL? = nil)
    {
        self.identity = identity
        self.payload = payload
        self.repoRef = repoRef
        latestVersion = payload
            .keys
            .sorted { AptPackageVersion.compareA($0, andB: $1) > 0 }
            .first
    }

    public init?(from metadata: String, injecting: [String: String] = [:]) {
        guard let invoke = invokeSingleAptMeta(withContext: metadata),
              let id = invoke["package"]?.lowercased(), // just lowercase
              let ver = invoke["version"],
              Package.validateVersion(ver)
        else {
            return nil
        }
        var build = invoke
        for (key, value) in injecting {
            build[key] = value
        }
        self.init(identity: id,
                  payload: [ver: build],
                  repoRef: nil)
    }

    // MARK: - Computed

    public var latestMetadata: Metadata? {
        if let latestVersion = latestVersion {
            return payload[latestVersion]
        }
        return nil
    }

    public func obtainDownloadLink() -> URL {
        let badUrl = PackageBadUrl
        guard var target = latestMetadata?["filename"] else {
            return badUrl
        }

        func createURL(from string: String) -> URL {
            if let url = URL(string: string) {
                return url
            }
            var charSet = CharacterSet.urlFragmentAllowed
            charSet = charSet.union(.urlHostAllowed)
            charSet = charSet.union(.urlPathAllowed)
            charSet = charSet.union(.urlQueryAllowed)
            if let encode = string.addingPercentEncoding(withAllowedCharacters: charSet),
               let url = URL(string: encode)
            {
                return url
            }
            return badUrl
        }

        if target.hasPrefix("http") {
            return createURL(from: target)
        }
        if target.hasPrefix("./") {
            target.removeFirst(2)
        }
        guard let repo = repoRef else {
            return badUrl
        }

        var builder = repo.absoluteString
        while builder.hasSuffix("/") { builder.removeLast() }
        if !target.hasPrefix("/") { builder += "/" }
        builder += target

        return createURL(from: builder)
        // ? isn't part of a path, will resolve to %3F
    }

    // MARK: - Static Tools

    public static
    func validateVersion(_ str: String) -> Bool {
        AptPackageVersion.isVersionVaild(str)
    }

    public enum VersionCompareResult {
        case aIsBiggerThenB
        case aIsSmallerThenB
        case aIsEqualToB
        case invalidParameter
    }

    public static
    func compareVersion(_ a: String, b: String) -> VersionCompareResult {
        if !Package.validateVersion(a) {
            return .invalidParameter
        }
        if !Package.validateVersion(b) {
            return .invalidParameter
        }
        let result = AptPackageVersion.compareA(a, andB: b)
        if result < 0 { return .aIsSmallerThenB }
        if result > 0 { return .aIsBiggerThenB }
        return .aIsEqualToB
    }

    public
    func propertyListEncoded() -> Data? {
        try? PropertyListEncoder().encode(self)
    }

    public static
    func propertyListDecoded(with data: Data?) -> Self? {
        guard let data = data else {
            return nil
        }
        return try? PropertyListDecoder().decode(self, from: data)
    }
}

public enum PackageDepiction {
    public enum PreferredDepiction: String, CaseIterable {
        case automatically
        case preferredNative
        case preferredWeb
        case onlyNative
        case onlyWeb
        case never
    }

    case web(url: URL)
    case json(url: URL)
    case none
//    case zebra(any: Any)
}
