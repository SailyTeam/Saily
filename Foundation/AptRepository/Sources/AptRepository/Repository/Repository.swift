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

    public internal(set) var url: URL
    public internal(set) var distribution: String? // flat repo will not get it
    public internal(set) var component: String? // only accept one

    public var id: String { url.absoluteString }

    // MARK: - METADATA

    public internal(set) var avatar = Data()
    public var avatarUrl: URL {
        url
            .appendingPathComponent("CydiaIcon")
            .appendingPathExtension("png")
    }

    public internal(set) var lastUpdateRelease = Date(timeIntervalSince1970: 0)
    public internal(set) var metaRelease: [String: String] = [:] {
        didSet {
            lastUpdateRelease = Date()
        }
    }

    public var metaReleaseUrl: URL {
        guard let distribution = distribution else {
            return url.appendingPathComponent("Release")
        }
        return url
            .appendingPathComponent("dists")
            .appendingPathComponent(distribution)
            .appendingPathComponent("Release")
    }

    public internal(set) var lastUpdatePackage = Date(timeIntervalSince1970: 0)
    public internal(set) var metaPackage: [String: Package] = [:] {
        didSet {
            lastUpdatePackage = Date()
        }
    }

    public var metaPackageUrl: URL {
        guard let distribution = distribution else {
            return url.appendingPathComponent("Packages")
        }
        guard let component = component else {
            return url
                .appendingPathComponent("dists")
                .appendingPathComponent(distribution)
                .appendingPathComponent("binary-\(RepositoryCenter.deviceArchitecture)")
                .appendingPathComponent("Packages")
        }
        return url
            .appendingPathComponent("dists")
            .appendingPathComponent(distribution)
            .appendingPathComponent(component)
            .appendingPathComponent("binary-\(RepositoryCenter.deviceArchitecture)")
            .appendingPathComponent("Packages")
    }

    public internal(set) var preferredSearchPath = "bz2"
    public internal(set) var availableSearchPath = ["bz2", "", "xz", "gz", "lzma", "lzma2", "bz", "xz2", "gz2"]

    public internal(set) var attachment: [AttachInfo: String] = [:]
    public var nickName: String {
        attachment[.nickName, default: "repo"]
    }

    public enum AttachInfo: String, Codable {
        /*
         if nickNamePinned is true
         - that means user has pinned the name for repo
         - nickName will return userPinnedName

         if nickNamePinned is false
         - check repo release metadata
         - the name may be calculated from repo url if no meta
         */
        case nickName
        case nickNamePinned
        /*
         used to store featured packages
         */
        case featured
        /*
         tag for tracing, not set means true [for backward capability]
         */
        case initialInstall
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

    /// Initialize a flat repo with url only
    /// - Parameter url: the key to the repo
    public init(url: URL) {
        self.url = url
        attachment[.nickName] = regenerateNickName()
        attachment[.initialInstall] = "YES"
        applyNoneFlatWellKnownRepositoryIfNeeded()
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
