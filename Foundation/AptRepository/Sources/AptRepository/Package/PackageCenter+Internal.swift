//
//  Project Chromatic
//  Chromatic
//
//  Created by Lakr Aream on 2020/4/18.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import Dog
import Foundation

extension PackageCenter {
    /// send notification to ui to reload when install or repo record changes
    func dispatchNotification() {
        notificationThrotte.throttle {
            NotificationCenter.default.post(name: PackageCenter.packageRecordChanged, object: nil)
        }
    }

    /// tells package center to reload items
    func issueReloadFromRepositoryCenter() {
        let token = UUID()
        summaryReloadToken = token
        reloadQueue.async { [self] in
            updatePackageSummary(with: token)
        }
    }

    /// reload packages that was installed on local system
    func reloadLocalInstall() {
        accessLock.lock()
        var retry = 0
        while retry < 3 {
            do {
                let read = try String(contentsOfFile: systemPackageStatusLocation)
                let packages = invokePackages(withContext: read)
                    .filter { _, value in
                        !(value.latestMetadata?["status"]?.contains("deinstall") ?? false)
                    }
                localInstalled = packages
                Dog.shared.join(self, "updating installation info reported \(packages.count) pacakges")
                break
            } catch {
                Dog.shared.join(self, "error occurs when loading system configuration \(error.localizedDescription)", level: .error)
                #if !DEBUG
                    // it does not make scene to wait
                    // while in a sandboxed non-jailbroken device
                    usleep(500_000)
                #endif
                retry += 1
            }
            localInstalled = [:]
            Dog.shared.join(self, "too many failure occurred, giving up!")
        }
        if localInstalled["firmware"] == nil {
            Dog.shared.join(self, "firmware is missing, creating one", level: .info)
            localInstalled["firmware"] = Package(identity: "firmware",
                                                 payload: ["99.0": [
                                                     "package": "firmware",
                                                     "version": "99.0",
                                                     "description": "This package indicate the system version and is required by many packages. Failed to load one from your local system, so we created one for you.",
                                                 ]],
                                                 repoRef: nil)
        }
        accessLock.unlock()
        dispatchNotification()
        updatePackageTracking(disableTableTrace: true)
    }

    /// called when boot or an repo update completed
    /// - Parameters:
    ///   - token: refresh token, will be cancel if new request fired (token changed)
    ///   - repo: ONLY USED WHEN BOOTING
    func updatePackageSummary(with token: UUID, repo: [Repository]? = nil) {
        let begin = Date()
        Dog.shared.join(self, "compiling packages", level: .info)
        autoreleasepool {
            var build = [String: [URL: Package]]()
            var authorList = [String: Set<String>]()
            var virtualBuild = [String: Set<String>]()
            // load repos
            (
                repo ?? (
                    RepositoryCenter
                        .default
                        .obtainRepositoryUrls()
                        .map { RepositoryCenter.default.obtainImmutableRepository(withUrl: $0) }
                        .compactMap { $0 }
                )
            )
            // load packages
            .forEach { repo in
                if self.summaryReloadToken != token {
                    return
                }
                for (key, value) in repo.metaPackage {
                    var fetch = build[key, default: [:]]
                    fetch[repo.url] = value
                    build[key] = fetch
                    let authors = obtainAuthor(of: value)
                    let author = authors.joined(separator: ", ")
                    if author.count > 0 {
                        var read = authorList[author, default: []]
                        read.insert(key)
                        authorList[author] = read
                    }
                    if value.latestMetadata?["provides"] != nil,
                       let invoker = PackageRequirement(with: value)
                    {
                        for section in invoker.group where section.type == .provides {
                            section
                                .requirements
                                .map(\.elements)
                                .flatMap { $0 }
                                .forEach {
                                    var fetch = virtualBuild[$0.representPackage, default: []]
                                    fetch.insert(key)
                                    virtualBuild[$0.representPackage] = fetch
                                }
                        }
                    }
                }
            }
            if summaryReloadToken != token {
                Dog.shared.join(self, "compiler returned due to token mismatch", level: .info)
                return
            }
            let internval = Date().timeIntervalSince(begin)
            let put = String(format: "%.2f", internval)
            Dog.shared.join(self, "completed compiling packages in \(put) seconds", level: .info)
            accessLock.lock()
            summary = build
            authers = authorList
            virtual = virtualBuild
            accessLock.unlock()
            dispatchNotification()
            updatePackageTracking(disableTableTrace: false)
        }
    }

    /// tracking packages
    /// - Parameter disableTableTrace: only update table trace when a repo refreshed
    func updatePackageTracking(disableTableTrace: Bool) {
        // create trace token, cancel if not match
        let token = UUID()
        traceToken = token
        let date = Date()

        DispatchQueue.global().async { // don't use [self] in to get things complicated
            // MARK: - INSTALL TRACE

            var installTraceBuilder = self.installationTrace
            do {
                let installed = self.obtainInstalledPackageList()
                installTraceBuilder = installTraceBuilder
                    .filter { installed.map(\.identity).contains($0.key) }
                for item in installed where token == self.traceToken {
                    guard let version = item.latestVersion else { continue }
                    if let fetch = installTraceBuilder[item.identity] {
                        // found, check version
                        if fetch.version != item.latestVersion {
                            // modified?
                            installTraceBuilder[item.identity] = .init(identity: item.identity,
                                                                       version: version,
                                                                       repo: nil,
                                                                       lastModification: date)
                        }
                    } else {
                        // not found, add it and record the day we see it tho
                        installTraceBuilder[item.identity] = .init(identity: item.identity,
                                                                   version: version,
                                                                   repo: nil,
                                                                   lastModification: date)
                    }
                }
            }
            if token != self.traceToken { return }

            // MARK: - TABLE TRACE

            var tableTraceBuilder = [String: PackageTrace]()

            if !disableTableTrace {
                let allIdentities = Set<String>(self.obtainAllPackageIdentity())
                tableTraceBuilder = self.tableTrace
                    // delete removed packages
                    .filter { allIdentities.contains($0.key) }
                for item in allIdentities where token == self.traceToken {
                    // get newest version that exists
                    let summay = [Package](self.obtainPackageSummary(with: item).values)
                    guard summay.count > 0 else { continue }
                    var repoRef: URL? = summay[0].repoRef
                    var newestVersion = summay[0].latestVersion ?? "0"
                    for value in summay {
                        if let version = value.latestVersion,
                           Package.compareVersion(version, b: newestVersion) == .aIsBiggerThenB
                        {
                            newestVersion = version
                            repoRef = value.repoRef
                        }
                    }
                    // compare to what we have
                    if let fetch = tableTraceBuilder[item] {
                        // found, check if updated
                        let compare = Package.compareVersion(newestVersion, b: fetch.version)
                        if compare == .aIsBiggerThenB {
                            // updated
                            tableTraceBuilder[item] = .init(identity: item,
                                                            version: newestVersion,
                                                            repo: repoRef,
                                                            lastModification: date)
                        } else if compare == .aIsSmallerThenB {
                            // newer one removed!
                            tableTraceBuilder[item] = .init(identity: item,
                                                            version: newestVersion,
                                                            repo: repoRef,
                                                            lastModification: nil)
                        }
                    } else {
                        if let repoRef = repoRef,
                           let repo = RepositoryCenter
                           .default
                           .obtainImmutableRepository(withUrl: repoRef),
                           repo.attachment[.initialInstall] ?? "YES" == "YES"
                        {
                            // this package is first seen here
                            // and the repo is not currently in any initial load's commit
                            // we need to put it into display
                            tableTraceBuilder[item] = .init(identity: item,
                                                            version: newestVersion,
                                                            repo: repoRef,
                                                            lastModification: nil)
                        } else {
                            tableTraceBuilder[item] = .init(identity: item,
                                                            version: newestVersion,
                                                            repo: repoRef,
                                                            lastModification: date)
                        }
                    }
                }
            }

            if token != self.traceToken { return }
            self.installationTrace = installTraceBuilder
            if !disableTableTrace {
                self.tableTrace = tableTraceBuilder
            }

            let interval = Date().timeIntervalSince(date)
            Dog.shared.join(self,
                            String(format: "package tracing database updated in %.2fs", interval),
                            level: .info)

            self.dispatchNotification()
        }
    }
}
