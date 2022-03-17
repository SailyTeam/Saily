//
//  RepositoryCenter+Internal.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/6.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import CommonCrypto
import Dog
import Foundation

extension RepositoryCenter {
    // MARK: - PERSIST ENGINE

    /// read from disk
    func initializeRepository() {
        var build = [URL: Repository]()
        let contents = (
            try? FileManager
                .default
                .contentsOfDirectory(atPath: workingLocation.path)
        ) ?? []
        for name in contents {
            do {
                let location = workingLocation.appendingPathComponent(name)
                let data = try Data(contentsOf: location)
                var repo = try persistDecoder.decode(Repository.self, from: data)
                repo.applyNoneFlatWellKnownRepositoryIfNeeded()
                build[repo.url] = repo
            } catch {
                Dog.shared.join(self, "read data and decode failed with error \(error.localizedDescription)", level: .error)
                continue
            }
        }
        container = build
    }

    /// save to disk
    func issueCompileAndStore() {
        compilerThrottle.throttle { [self] in
            accessLock.lock()
            let capture = container.values
            accessLock.unlock()

            do {
                // if not exists in ram, delete
                let contents = try FileManager
                    .default
                    .contentsOfDirectory(atPath: workingLocation.path)
                let filenames = capture
                    .map(\.url)
                    .map(\.absoluteString)
                    .map { $0.sha1() }
                    .compactMap { $0 }
                let delete = contents
                    .filter { !filenames.contains($0) }
                for item in delete {
                    let target = workingLocation.appendingPathComponent(item)
                    try FileManager.default.removeItem(at: target)
                }
                // save what ever in ram
                for repo in capture {
                    let date = try persistEncoder.encode(repo)
                    let name = repo.url.absoluteString.sha1()
                    guard name.count > 0 else {
                        Dog.shared.join(self, "hash on url \(repo.url.absoluteString) failed, persist engine giving up", level: .error)
                        continue
                    }
                    let location = workingLocation.appendingPathComponent(name)
                    try date.write(to: location)
                }
            } catch {
                Dog.shared.join(self, "persist engine catches error \(error.localizedDescription)", level: .error)
            }
            Dog.shared.join(self, "completed disptched compile")
        }
    }

    // MARK: - UPDATE ENGINE

    /// if any part of the repo outdated then it's elegant for it
    /// - Parameter target: the target repository
    /// - Returns: if it is elegant
    func repositoryElegantForSmartUpdate(target: Repository) -> Bool {
        let interval = Double(smartUpdateTimeInterval)
        let current = Date()
        if current.timeIntervalSince(target.lastUpdateRelease) > interval {
            return true
        }
        if current.timeIntervalSince(target.lastUpdatePackage) > interval {
            return true
        }
        return false
    }

    /// the update system
    func dispatchUpdateOnCurrentCenter() {
        updateDispatchThrottle.throttle { [self] in
            // check if needed
            accessLock.lock()
            defer {
                accessLock.unlock()
            }
            let dispatchPrerequisite = true
                && currentlyInUpdate.count <= updateConcurrencyLimit
                && pendingUpdateRequest.count > 0
            if !dispatchPrerequisite {
                return
            }

            // build what need to update
            var dispatchContainer = [URL]()
            while pendingUpdateRequest.count > 0,
                  dispatchContainer.count + currentlyInUpdate.count <= updateConcurrencyLimit
            {
                dispatchContainer.append(pendingUpdateRequest.removeFirst())
            }
            dispatchContainer.forEach { currentlyInUpdate.insert($0) }

            // send to update
            dispatchContainer.forEach { url in
                DispatchQueue.global().async { [self] in
                    asyncUpdate(target: url) { [self] success in
                        // remove from in update queue
                        accessLock.lock()
                        currentlyInUpdate = currentlyInUpdate
                            .filter { $0 != url }
                        currentUpdateProgress.removeValue(forKey: url)
                        Dog.shared.join(self, "update engine reported \(pendingUpdateRequest.count) pending and \(currentlyInUpdate.count) in queue")
                        accessLock.unlock()
                        PackageCenter.default.issueReloadFromRepositoryCenter()
                        DispatchQueue.main.async { [self] in
                            let object = UpdateNotification(representedRepo: url,
                                                            progress: nil,
                                                            complete: true,
                                                            success: success,
                                                            queueLeft: currentlyInUpdate.count)
                            NotificationCenter.default.post(name: RepositoryCenter.metadataUpdate, object: object)
                        }
                    }
                }
            }
        }
    }

    /// Update repo metadata
    /// - Parameters:
    ///   - target: url of repp
    ///   - onComplete: when complete, pass if success
    private func asyncUpdate(target: URL, onComplete: @escaping (Bool) -> Void) {
        // don't copy the repo since it is a struct would cost too much ram
        // and plain down the control flow

        // grab what we need
        accessLock.lock()
        let id = container[target]?.id ?? UUID().uuidString
        let _avatarUrl = container[target]?.avatarUrl
        let _releaseUrl = container[target]?.metaReleaseUrl
        let _packageBaseUrl = container[target]?.metaPackageUrl
        let _preferredSearchPath = container[target]?.preferredSearchPath
        let _availableSearchPath = container[target]?.availableSearchPath
        accessLock.unlock()

        // check if we have them
        guard let avatarUrl = _avatarUrl,
              let releaseUrl = _releaseUrl,
              let packageBaseUrl = _packageBaseUrl,
              let preferredSearchPath = _preferredSearchPath,
              let availableSearchPath = _availableSearchPath,
              availableSearchPath.count > 0
        else {
            Dog.shared.join(self, "the repository being dispatch to update was not found or broken", level: .error)
            onComplete(false)
            return
        }

        let progress = Progress(totalUnitCount: 100)

        func updateProgressAndSendNotification() {
            accessLock.lock()
            currentUpdateProgress[target] = progress
            let count = currentlyInUpdate.count
            DispatchQueue.main.async {
                let object = UpdateNotification(representedRepo: target,
                                                progress: progress,
                                                complete: false,
                                                success: false,
                                                queueLeft: count)
                NotificationCenter.default.post(name: RepositoryCenter.metadataUpdate, object: object)
            }
            accessLock.unlock()
        }
        updateProgressAndSendNotification()

        // measuring
        let updateStart = Date()

        // MARK: - STAGE 1

        // allocate download
        var avatarData: Data?
        var releaseStr: String?
        var packageStr: String?
        var paymentEndpoint: URL?
        var featured: String?
        var completedSearchPath: String?

        // dispatch
        let queue = DispatchQueue(label: "wiki.qaq.update.\(id)", attributes: .concurrent)
        let group = DispatchGroup()

        // STAGE 1 [try preferred search path]
        Dog.shared.join(self, "update \(id) enter stage 1", level: .verbose)

        group.enter()
        queue.async { [self] in
            avatarData = downloadUpdateAvatar(withUrl: avatarUrl)
            progress.completedUnitCount += 10
            updateProgressAndSendNotification()
            group.leave()
        }

        group.enter()
        queue.async { [self] in
            releaseStr = downloadUpdateRelease(withUrl: releaseUrl)
            progress.completedUnitCount += 10
            updateProgressAndSendNotification()
            group.leave()
        }

        group.enter()
        queue.async { [self] in
            packageStr = downloadUpdatePackage(withBaseUrl: packageBaseUrl, suffix: preferredSearchPath)
            progress.completedUnitCount += 10
            updateProgressAndSendNotification()
            group.leave()
        }

        group.enter()
        queue.async { [self] in
            if let result = detectPaymentEndpoint(withUrl: target),
               let endpoint = URL(string: result)
            {
                paymentEndpoint = endpoint
            }
            progress.completedUnitCount += 10
            updateProgressAndSendNotification()
            group.leave()
        }

        group.enter()
        queue.async { [self] in
            featured = detectFeaturedMetadata(withUrl: target)
            progress.completedUnitCount += 10
            updateProgressAndSendNotification()
            group.leave()
        }

        _ = group.wait(timeout: .now() + Double(networkingTimeout))

        updateProgressAndSendNotification()

        // MARK: - STAGE 2

        // STAGE 2 [compile data]
        Dog.shared.join(self, "update \(id) enter stage 2", level: .verbose)
        let compileStart = Date()
        var buildRelease: [String: String]?
        var buildPackage: [String: Package]?
        if let release = releaseStr {
            buildRelease = invokeSingleAptMeta(withContext: release)
        }
        if let package = packageStr {
            buildPackage = invokePackages(withContext: package, fromRepo: target)
        }
        do {
            let compileInterval = Date().timeIntervalSince(compileStart)
            let put = String(format: "%.2f", compileInterval)
            Dog.shared.join(self, "\(id) complete compiler invoke in \(put) second", level: .info)
        }

        progress.completedUnitCount += 20
        updateProgressAndSendNotification()

        // MARK: - STAGE 3

        // STAGE 3 [try all search path for package if needed]
        Dog.shared.join(self, "update \(id) enter stage 3", level: .verbose)

        if buildPackage?.count ?? 0 < 1 {
            packageStr = nil // clear it
            // ===
            let sem = DispatchSemaphore(value: 0)
            var knockCount = 0
            let knockLock = NSLock()
            // ===
            availableSearchPath.forEach { searchPath in
                // counter += 1
                knockLock.lock()
                knockCount += 1
                knockLock.unlock()
                // dispatch
                queue.async { [self] in
                    let knockResult = downloadUpdatePackage(withBaseUrl: packageBaseUrl, suffix: searchPath)
                    // download complete, counter -= 1
                    knockLock.lock()
                    knockCount -= 1
                    // have result this time, and no result currently available
                    if let knockResult = knockResult, packageStr == nil {
                        let builder = invokePackages(withContext: knockResult, fromRepo: target)
                        debugPrint("search path\(searchPath) with knockResult \(knockResult) getting \(builder.count)")
                        if builder.count > 0 {
                            packageStr = knockResult
                            buildPackage = builder
                            completedSearchPath = searchPath
                            sem.signal()
                        }
                    } else if knockCount == 0 { // no task available
                        sem.signal()
                    }
                    knockLock.unlock()
                }
            }
            _ = sem.wait(timeout: .now() + Double(networkingTimeout))
        } else {
            completedSearchPath = preferredSearchPath
        }

        progress.completedUnitCount = 90
        updateProgressAndSendNotification()

        // MARK: - STAGE 4

        // STAGE 4 [write available info]
        Dog.shared.join(self, "update \(id) enter stage 4", level: .verbose)
        var printName = id
        var printDescription = ""
        updateRepository(withUrl: target) { builder in
            if let avatar = avatarData {
                builder.avatar = avatar
            }
            if let release = buildRelease {
                builder.metaRelease = release
            }
            if let searchPath = completedSearchPath {
                builder.preferredSearchPath = searchPath
            }
            if let package = buildPackage {
                // check if any package already available
                if builder.metaPackage.count > 0 {
                    builder.attachment[.initialInstall] = "NO"
                } else {
                    builder.attachment[.initialInstall] = "YES"
                }
                builder.metaPackage = package
            }
            printName = builder.regenerateNickName(apply: true)
            if let description = builder.repositoryDescription {
                printDescription = description
            }
            if let paymentEndpoint = paymentEndpoint {
                builder.paymentInfo[.endpoint] = paymentEndpoint.absoluteString
            } else {
                builder.paymentInfo.removeValue(forKey: .endpoint)
            }
            if let featured = featured {
                builder.attachment[.featured] = featured
            } else {
                builder.attachment.removeValue(forKey: .featured)
            }
        }

        // MARK: - STAGE 5

        // STAGE 5 [remove from queue]
        let completeInterval = Date().timeIntervalSince(updateStart)
        let measureFormatter = String(format: "%.2f", completeInterval)
        let finalLog = """
        Complete update on \(id) in \(measureFormatter) seconds
        ===>
            Repository [\(printName)] \(printDescription)
            * Release: \(buildRelease?.keys.count ?? 0)
            * Package: \(buildPackage?.keys.count ?? 0)
        ===>
        """
        Dog.shared.join(self, finalLog, level: .info)

        issueCompileAndStore()
        onComplete(buildPackage?.count ?? 0 > 0)
    }

    // MARK: - Notification Emitter

    func issueNotification() {
        notificationThrotte.throttle {
            NotificationCenter.default.post(name: RepositoryCenter.registrationUpdate, object: nil)
        }
    }
}

private extension String {
    func sha1() -> String {
        let data = Data(utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &digest)
        }
        let hexBytes = digest.map { String(format: "%02hhx", $0) }
        return hexBytes.joined()
    }
}
