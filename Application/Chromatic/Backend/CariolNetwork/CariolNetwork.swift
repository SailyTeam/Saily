//
//  CariolNetwork.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/24.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import Digger
import Dog
import Foundation
import PropertyWrapper
import SwiftMD5

class CariolNetwork {
    struct DownloadNotification {
        let completed: Bool
        let represent: Package?
        let representUrl: URL
        let progress: Progress
        let speedBytes: Int
        let targetLocation: URL?
        let error: Error?
    }

    static let shared = CariolNetwork()

    public private(set) var workingLocation: URL

    public let illegalFileNameCharacters: CharacterSet = {
        var invalidCharacters = CharacterSet(charactersIn: ":/")
        invalidCharacters.formUnion(.newlines)
        invalidCharacters.formUnion(.illegalCharacters)
        invalidCharacters.formUnion(.controlCharacters)
        return invalidCharacters
    }()

    private let accessLock = NSLock()
    private var notificationRecord: [URL: DownloadNotification] = [:]
    private let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter
    }()

    @UserDefaultsWrapper(key: "wiki.qaq.chromatic.cariol.network", defaultValue: Data())
    private var _completedFileLookup: Data
    public var completedFileLookup: [URL: URL] {
        set {
            _completedFileLookup = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
        get {
            (try? JSONDecoder().decode([URL: URL].self, from: _completedFileLookup)) ?? [:]
        }
    }

    private init() {
        workingLocation = documentsDirectory.appendingPathComponent("Downloads")

        // fixup urls if app container changes
        do {
            var builder = completedFileLookup
            for (key, value) in builder {
                // takeout the filename
                let filename = value.lastPathComponent
                // recompile
                builder[key] = workingLocation.appendingPathComponent(filename)
            }
            completedFileLookup = builder
        }

        // verify every completed task
        let fetch = completedFileLookup
        for (key, val) in fetch {
            var isDir = ObjCBool(false)
            let check = FileManager.default.fileExists(atPath: val.path, isDirectory: &isDir)
            if !(check && !isDir.boolValue) {
                completedFileLookup.removeValue(forKey: key)
                Dog.shared.join(self, "removing invalid download file: \(val.path)")
            }
        }
        Dog.shared.join(self, "reporting \(completedFileLookup.keys.count) download caches")

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(recordDownloadProgress(notification:)),
                                               name: .DownloadProgress,
                                               object: nil)
    }

    deinit {
        #if DEBUG
            fatalError("wtf?")
        #else
            NotificationCenter.default.removeObserver(self)
        #endif
    }

    func clear() {
        completedFileLookup = [:]
    }

    @objc
    func recordDownloadProgress(notification: Notification) {
        guard let info = notification.object as? DownloadNotification else {
            return
        }
        accessLock.lock()
        notificationRecord[info.representUrl] = info
        accessLock.unlock()
    }

    func progressRecord(for url: URL) -> DownloadNotification? {
        accessLock.lock()
        let result = notificationRecord[url]
        accessLock.unlock()
        return result
    }

    func byteFormat(bytes: Int) -> String {
        if bytes > 0 {
            return byteFormatter.string(fromByteCount: Int64(bytes))
        }
        return ""
    }

    func syncDownloadRequest(packageList list: [Package]) {
        debugPrint("syncing download requests")
        let allUrls = list
            .map { $0.obtainDownloadLink() }
        let diggerSeeds = DiggerManager
            .shared
            .obtainAllTasks()
        let cancelItems = diggerSeeds
            .filter { !allUrls.contains($0) }
        for item in cancelItems {
            debugPrint("canceling digger seeds on \(item.absoluteString)")
            DiggerManager.shared.stopTask(for: item)
        }
        for item in list {
            if item.latestMetadata?[DirectInstallInjectedPackageLocationKey] != nil {
                continue
            }
            let link = item.obtainDownloadLink()
            if diggerSeeds.contains(link) {
                DiggerManager.shared.startTask(for: link)
            } else {
                DispatchQueue.global().async {
                    self.handleDownloadWith(url: link, represents: item)
                }
            }
        }
    }

    /// All package download start here
    /// - Parameters:
    ///   - url: url to download
    ///   - represents: for this package
    func handleDownloadWith(url: URL, represents: Package) {
        if let cache = completedFileLookup[url],
           FileManager.default.fileExists(atPath: cache.path)
        {
            Dog.shared.join(self, "found cache file at \(cache.path) for request \(url.absoluteString)")
            let progress = Progress(totalUnitCount: 1)
            progress.completedUnitCount = 1
            let notification = CariolNetwork.DownloadNotification(completed: true,
                                                                  represent: represents,
                                                                  representUrl: url,
                                                                  progress: progress,
                                                                  speedBytes: 0,
                                                                  targetLocation: cache,
                                                                  error: nil)
            NotificationCenter.default.post(name: .DownloadProgress, object: notification)
            return
        }

        debugPrint("preparing request to \(url.absoluteString)")
        // digger will call blocks in a sequence, no need to lock
        var completedCache = false
        var speedCache = 0
        // before we can get the size of remote
        // set this number to package size
        // or really big size, coordinated to package deb file
        // so progress bar wont go back when server returns the real value
        var progressCache = Progress(totalUnitCount: 1 * 1024 * 1024 * 256) // 256 MB, if size not found
        if let sizeStr = represents.latestMetadata?["size"],
           let val = Int64(sizeStr)
        {
            progressCache.totalUnitCount = val
        }
        var errorCache: Error?
        var targetLocationCache: URL?
        func makeNotification() {
            let notification = CariolNetwork.DownloadNotification(completed: completedCache,
                                                                  represent: represents,
                                                                  representUrl: url,
                                                                  progress: progressCache,
                                                                  speedBytes: speedCache,
                                                                  targetLocation: targetLocationCache,
                                                                  error: errorCache)
            NotificationCenter.default.post(name: .DownloadProgress, object: notification)
        }
        makeNotification()
        DiggerManager
            .shared
            .download(with: url)
            .speed { bytes in
                speedCache = Int(bytes)
                makeNotification()
            }
            .progress { progress in
                progressCache = progress
                makeNotification()
            }
            .completion { result in
                progressCache.completedUnitCount = progressCache.completedUnitCount
                makeNotification()
                completedCache = true
                switch result {
                case let .success(targetLocation):
                    Dog.shared.join(self,
                                    "download on \(url.lastPathComponent) succeed with target location \(targetLocation.path)",
                                    level: .info)
                    DispatchQueue.global().async {
                        let success = self.finalizeDownload(for: represents,
                                                            downloadFrom: url,
                                                            dataAt: targetLocation)
                        if success {
                            targetLocationCache = targetLocation
                            makeNotification()
                        } else {
                            let error = NSLocalizedString("VERIFICATION_FAILURE_OCCURRED", comment: "verification failure occurred")
                            errorCache = NSError(domain: error,
                                                 code: Int(EPERM),
                                                 userInfo: [:])
                            makeNotification()
                        }
                    }
                case let .failure(error):
                    errorCache = error
                    Dog.shared.join(self,
                                    "download on \(url.lastPathComponent) returned with failure \(error.localizedDescription)",
                                    level: .info)
                    makeNotification()
                }
            }
        DiggerManager.shared.startTask(for: url)
    }

    typealias Success = Bool

    /// called when digger returns the target url
    ///   - validate sum hash
    ///   - copy to download dir
    ///   - remove the digger cache
    ///   - save to user default
    /// - Parameters:
    ///   - package: the package that downloaded
    ///   - target: digger seed location
    func finalizeDownload(for package: Package, downloadFrom: URL, dataAt: URL) -> Success {
        guard let data = try? Data(contentsOf: dataAt) else {
            try? FileManager.default.removeItem(atPath: dataAt.path)
            Dog.shared.join(self, "failed to read \(package.identity) from \(dataAt.path)", level: .error)
            return false
        }

        // MARK: - HASH VALIDATE

        // verify only one component
        // the md5 takes really long time
        // (using method rather than CommonCrypto)
        // to kill system library warning

        var verified = false
        func hashFailureOut(expect: String, has: String, type: String) {
            try? FileManager.default.removeItem(atPath: dataAt.path)
            Dog.shared.join(self, "failed to hash \(package.identity) \(dataAt.path) expect: \(expect) has: \(has) [\(type)]", level: .error)
        }
        if !verified, let predicatedHashSHA1 = package.latestMetadata?["sha1"] {
            let sha1 = String.sha1From(data: data)
            if sha1 != predicatedHashSHA1 {
                hashFailureOut(expect: predicatedHashSHA1, has: sha1, type: "sha1")
                return false
            }
            verified = true
        }
        if !verified, let predicatedHashSHA256 = package.latestMetadata?["sha256"] {
            let sha256 = String.sha256From(data: data)
            if sha256 != predicatedHashSHA256 {
                hashFailureOut(expect: predicatedHashSHA256, has: sha256, type: "sha1")
                return false
            }
            verified = true
        }
        if !verified, let predicatedHashMD5 = package.latestMetadata?["md5sum"] {
            let md5sum = SwiftMD5.md5From(data)
            if md5sum != predicatedHashMD5 {
                hashFailureOut(expect: predicatedHashMD5, has: md5sum, type: "md5")
                return false
            }
            verified = true
        }

        if !verified {
            Dog.shared.join(self,
                            "package \(package.identity) unable to verify due to missing hash tag, treating as success",
                            level: .warning)
        }

        // MARK: - GENERATE CACHE FILE NAME

        let cacheUrl = generateDownloadFileUrlWith(downloadUrl: downloadFrom)
        try? FileManager.default.createDirectory(at: workingLocation,
                                                 withIntermediateDirectories: true,
                                                 attributes: nil)
        do {
            try FileManager.default.moveItem(at: dataAt, to: cacheUrl)
        } catch {
            Dog.shared.join(self,
                            "checking out \(package.identity) failed \(error.localizedDescription)",
                            level: .error)
            try? FileManager.default.removeItem(atPath: dataAt.path)
            return false
        }

        // MARK: - SAVE TO CONTAINER

        completedFileLookup[downloadFrom] = cacheUrl
        Dog.shared.join(self,
                        "package \(package.identity) checkout successfully to \(cacheUrl.path)",
                        level: .info)
        return true
    }

    private func generateDownloadFileUrlWith(downloadUrl: URL) -> URL {
        try? FileManager.default.createDirectory(at: workingLocation,
                                                 withIntermediateDirectories: true,
                                                 attributes: nil)
        var buildName = downloadUrl
            .lastPathComponent
            .components(separatedBy: illegalFileNameCharacters)
            .joined()
        var justInCase = 0
        while FileManager
            .default
            .fileExists(atPath: workingLocation.appendingPathComponent(buildName).path),
            justInCase < 10
        {
            var ext = downloadUrl.pathExtension
            if ext.count < 1 { ext = "dld" }
            if buildName.hasSuffix(ext) {
                buildName.removeLast(ext.count)
            }
            if buildName.hasSuffix(".") {
                buildName.removeLast()
            }
            var random = ""
            while random.count < 6 {
                random += String(Character.randomAlphanumeric())
            }
            buildName += "_\(random)"
            buildName += "."
            buildName += ext
            justInCase += 1
        }
        return workingLocation.appendingPathComponent(buildName)
    }

    /// get downloaded file for package
    /// - Parameter package: package
    /// - Returns: file url
    func obtainDownloadedFile(for package: Package) -> URL? {
        accessLock.lock()
        let fetch = completedFileLookup[package.obtainDownloadLink()]
        accessLock.unlock()
        return fetch
    }
}
