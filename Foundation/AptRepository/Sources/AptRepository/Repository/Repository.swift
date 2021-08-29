//
//  Repository.swift
//  Chromatic
//
//  Created by Lakr Aream on 2020/4/26.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import Foundation

public struct Repository: Codable, Hashable, Identifiable {
    // MARK: - USER GRANTED

    public let url: URL
    public var id: String { url.absoluteString }

    // MARK: - METADATA

    public internal(set) var avatar = Data()
    public var avatarUrl: URL {
        let defaultUrl = url
            .appendingPathComponent("CydiaIcon")
            .appendingPathExtension("png")
        return RepositoryCenter
            .default
            .networkingRedirect[defaultUrl, default: defaultUrl]
    }

    public internal(set) var lastUpdateRelease = Date(timeIntervalSince1970: 0)
    public internal(set) var metaRelease: [String: String] = [:] {
        didSet {
            lastUpdateRelease = Date()
        }
    }

    public var metaReleaseUrl: URL {
        let defaultUrl = url.appendingPathComponent("Release")
        return RepositoryCenter
            .default
            .networkingRedirect[defaultUrl, default: defaultUrl]
    }

    public internal(set) var lastUpdatePackage = Date(timeIntervalSince1970: 0)
    public internal(set) var metaPackage: [String: Package] = [:] {
        didSet {
            lastUpdatePackage = Date()
        }
    }

    public var metaPackageUrl: URL {
        let defaultUrl = url.appendingPathComponent("Packages")
        return RepositoryCenter
            .default
            .networkingRedirect[defaultUrl, default: defaultUrl]
    }

    public internal(set) var preferredSearchPath = "bz2"
    public internal(set) var availableSearchPath = ["bz2", "", "xz", "gz", "lzma", "lzma2", "bz", "xz2", "gz2"]

    public internal(set) var attachment: [AttachInfo: String] = [:]
    public var nickName: String {
        attachment[.nickName, default: "repo"]
    }

    public enum AttachInfo: String, Codable {
        case nickName
        case nickNamePinned
        case featured
    }

    public internal(set) var paymentInfo: [PaymentInfo: String] = [:]
    public var endpoint: URL? {
        if let endpoint = paymentInfo[.endpoint],
           let url = URL(string: endpoint)
        {
            return url
        }
        return nil
    }

    public enum PaymentInfo: String, Codable {
        case endpoint
    }

    public var repositoryDescription: String? {
        if let description = metaRelease["description"] {
            return description
        }
        if let version = metaRelease["version"] {
            return version
        }
        return nil
    }

    // MARK: - INIT

    public init(url: URL) {
        self.url = url
        attachment[.nickName] = regenerateNickName()
    }

    // MARK: - PROTOCOL

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Repository, rhs: Repository) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Helper

    public mutating func regenerateNickName(apply: Bool = false) -> String {
        // build nick name
        var build = "repo"
        if let nickName = attachment[.nickName],
           let pinned = attachment[.nickNamePinned],
           pinned == "true"
        {
            return nickName
        } else if let name = metaRelease["label"] {
            build = name
        } else if let name = metaRelease["origin"] {
            build = name
        } else if var host = url.host {
            let trimmer = [
                "www", "apt", "repo", "deb",
            ]
            for item in trimmer {
                let prefix = item + "."
                if host.hasPrefix(prefix) {
                    host.removeFirst(prefix.count)
                }
            }
            build = host
        }
        if apply {
            attachment[.nickName] = build
        }
        return build
    }
}
