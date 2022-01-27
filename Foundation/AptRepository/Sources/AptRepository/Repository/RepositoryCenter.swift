//
//  RepoManager.swift
//  Chromatic
//
//  Created by Lakr Aream on 2020/4/18.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import Dog
import Foundation
import PropertyWrapper
import SwiftThrottle

internal let kRepositoryCenterIdentity = "wiki.qaq.chromatic.RepositoryCenter"

/// Repository Center is used to manage any software distribution sources
public final class RepositoryCenter {
    public static let `default` = RepositoryCenter()

    /// used to generate download url for packages
    public static let deviceArchitecture = "iphoneos-arm"

    /// persist engine will work inside this
    public let workingLocation: URL

    /// container accessing lock
    internal var accessLock = NSLock()

    /// our repos
    internal var container: [URL: Repository] = [:]

    /// store deleted repository
    @UserDefaultsWrapper(key: "\(kRepositoryCenterIdentity).historyRecordsEnabled", defaultValue: true)
    public var historyRecordsEnabled: Bool {
        didSet {
            if !historyRecordsEnabled { historyRecords = [] }
        }
    }

    @UserDefaultsWrapper(key: "\(kRepositoryCenterIdentity).historyRecords", defaultValue: [])
    public var _historyRecords: [String]
    public var historyRecords: Set<String> {
        set {
            _historyRecords = [String](newValue)
        }
        get {
            Set<String>(_historyRecords)
        }
    }

    /// smart update time interval in seconds, default 86_400 to 1 day
    @UserDefaultsWrapper(key: "\(kRepositoryCenterIdentity).smartUpdateTimeInterval", defaultValue: 86400)
    public var smartUpdateTimeInterval: Int

    /// used for compile data and persist engine
    internal let compilerThrottle = Throttle(minimumDelay: 5, queue: .global())
    /// used to control update engine
    internal let updateDispatchThrottle = Throttle(minimumDelay: 1, queue: .global())
    /// used to present notification to user interface
    internal let notificationThrotte = Throttle(minimumDelay: 0.5, queue: .main)

    /// notification name
    public static let registrationUpdate = Notification.Name("\(kRepositoryCenterIdentity).registrationUpdate")
    public static let metadataUpdate = Notification.Name("\(kRepositoryCenterIdentity).metadataUpdate")

    /// encoder
    internal let persistEncoder: PropertyListEncoder = .init()
    /// decoder
    internal let persistDecoder: PropertyListDecoder = .init()

    /// update engine
    @UserDefaultsWrapper(key: "\(kRepositoryCenterIdentity).updateConcurrencyLimit",
                         defaultValue: ProcessInfo.processInfo.processorCount)
    public var updateConcurrencyLimit: Int {
        didSet {
            if updateConcurrencyLimit < 1 {
                Dog.shared.join(self, "updateConcurrencyLimit < 1, which is prohibited, changing to 4", level: .error)
                updateConcurrencyLimit = 4
            }
        }
    }

    /// update queue
    internal var pendingUpdateRequest: Set<URL> = []
    internal var currentlyInUpdate: Set<URL> = []
    internal var currentUpdateProgress: [URL: Progress] = [:]

    /// when updating repository property, set by application to user default, not here
    @UserDefaultsWrapper(key: "\(kRepositoryCenterIdentity).networkingHeaders", defaultValue: [:])
    public var networkingHeaders: [String: String]
    @UserDefaultsWrapper(key: "\(kRepositoryCenterIdentity).networkingTimeout", defaultValue: 60)
    public var networkingTimeout: Int
    @UserDefaultsWrapper(key: "\(kRepositoryCenterIdentity).networkingVerboseLogging", defaultValue: false)
    public var networkingVerboseLogging: Bool
    @UserDefaultsWrapper(key: "\(kRepositoryCenterIdentity).networkingRedirect", defaultValue: Data())
    private var _networkingRedirect: Data
    public var networkingRedirect: [URL: URL] {
        set {
            _networkingRedirect = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
        get {
            (try? JSONDecoder().decode([URL: URL].self, from: _networkingRedirect)) ?? [:]
        }
    }

    /// must load after package center
    internal init() {
        // MARK: - PRE SELF

        let storeDirPrefix = UserDefaults
            .standard
            .value(forKey: "wiki.qaq.chromatic.storeDirPrefix") as? String
            ?? "wiki.qaq.chromatic"

        guard let documentLocation = FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first
        else {
            let fatalMessage = "System resource unavailable, terminating due to unstable environment."
            Dog.shared.join("RepositoryCenter", fatalMessage, level: .critical)
            fatalError(fatalMessage)
        }

        workingLocation = documentLocation
            .appendingPathComponent(storeDirPrefix)
            .appendingPathComponent("RepositoryCenter")

        // MARK: - AFTER SELF

        Dog.shared.join(self, "initializing manager")
        Dog.shared.join(self, "reporting to work at \(workingLocation.path)")

        try? FileManager.default.createDirectory(at: workingLocation,
                                                 withIntermediateDirectories: true,
                                                 attributes: nil)

        // permission validation
        var isDir = ObjCBool(false)
        let foo = FileManager.default.fileExists(atPath: workingLocation.path, isDirectory: &isDir)
        if !(foo && isDir.boolValue) {
            let fatalMessage = "Failed to setup document permission, terminating due to unstable environment."
            Dog.shared.join("RepositoryCenter", fatalMessage, level: .critical)
            fatalError(fatalMessage)
        }

        // setup persist data
        initializeRepository()
        Dog.shared.join(self, "persist engine reported \(container.keys.count) repository", level: .info)

        // tell package center to load
        let token = PackageCenter.default.summaryReloadToken
        PackageCenter
            .default
            .updatePackageSummary(with: token, repo: [Repository](container.values))

        // will update on them
        DispatchQueue.global().asyncAfter(deadline: .now() + 3) { [self] in
            dispatchSmartUpdateRequestOnAll()
        }

        // check history if should exists
        if !historyRecordsEnabled { historyRecords = [] }

        let timer = Timer(timeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.global().async { [self] in
                dispatchUpdateOnCurrentCenter()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
    }
}
