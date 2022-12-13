//
//  RepositoryCenter+Api.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/6.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import Dog
import Foundation
import SwiftThrottle

public extension RepositoryCenter {
    /// Register a repo to let us manage it
    /// - Parameter withUrl: target url without suffix "/"
    func registerRepository(withUrl: URL) {
        defer { issueNotification() }
        var withUrl = withUrl
        while withUrl.absoluteString.hasSuffix("/") {
            guard let newUrl = URL(string: String(withUrl.absoluteString.dropLast())) else {
                return
            }
            withUrl = newUrl
        }

        // Duplicate Exam
        var alreadyExists = false
        accessLock.lock()
        if container[withUrl] != nil {
            alreadyExists = true
        }
        accessLock.unlock()
        if alreadyExists {
            Dog.shared.join(self, "repository already exists, abort!", level: .error)
            return
        }

        // Registration Here
        let builder = Repository(url: withUrl)
        accessLock.lock()
        container[withUrl] = builder
        accessLock.unlock()

        // Report
        Dog.shared.join(self, "registering repository with url \(withUrl.absoluteString) giving nickname \(builder.nickName)")

        // Update
        dispatchUpdateOnRepository(withUrl: withUrl)
    }

    /// grab repo detail
    /// - Parameter withUrl: the url of repository
    func obtainImmutableRepository(withUrl url: URL) -> Repository? {
        accessLock.lock()
        let access = container[url]
        accessLock.unlock()
        guard let access else {
            Dog.shared.join(self, "repository \(url.absoluteString) was not found")
            return nil
        }
        return access
    }

    /// grab count of remaining update task
    /// - Returns: count
    func obtainUpdateRemain() -> Int {
        accessLock.lock()
        let pending = pendingUpdateRequest.count
        let current = currentlyInUpdate.count
        accessLock.unlock()
        return pending + current
    }

    /// grab repo update progress if in update
    /// - Parameter url: the url of repository
    /// - Returns: progress if in update
    func obtainUpdateProgress(withUrl url: URL) -> Progress? {
        accessLock.lock()
        let read = currentUpdateProgress[url]
        accessLock.unlock()
        return read
    }

    /// indicates if this repo is good enough, update to data, and reliable
    /// - Parameter url: the url of repository
    /// - Returns: if it is
    func isRepositoryReadyForUse(withUrl url: URL) -> Bool? {
        accessLock.lock()
        let read = container[url]
        accessLock.unlock()
        guard let repo = read else {
            Dog.shared.join(self, "requested repository \(url.absoluteString) was not found")
            return nil
        }
        if repo.metaPackage.count < 1 || repo.metaRelease.count < 1 {
            return false
        }
        if repositoryElegantForSmartUpdate(target: repo) {
            return false
        }
        return true
    }

    /// indicates if this repo is in update queue, both pending and current
    /// - Parameter url: the url of repository
    /// - Returns: if it is
    func isRepositoryPreparedForUpdate(withUrl url: URL) -> Bool {
        accessLock.lock()
        let result = pendingUpdateRequest.contains(url)
            || currentlyInUpdate.contains(url)
        accessLock.unlock()
        return result
    }

    /// grab the count of repo
    /// - Returns: count
    func obtainRepositoryCount() -> Int {
        accessLock.lock()
        let result = container.count
        accessLock.unlock()
        return result
    }

    /// grab all repo urls
    /// - Returns: url can be used to identify the repo
    func obtainRepositoryUrls(sortedByName: Bool = false) -> [URL] {
        accessLock.lock()
        var result = [URL](container.keys)
        if sortedByName {
            result = result.sorted(by: { a, b in
                guard let repoA = container[a]?.nickName,
                      let repoB = container[b]?.nickName
                else {
                    return false
                }
                return repoA < repoB
            })
        } else {
            result = result.sorted { $0.absoluteString < $1.absoluteString }
        }
        accessLock.unlock()
        return result
    }

    /// modify repository within sync call block
    /// - Parameters:
    ///   - url: the url of repository
    ///   - withUpdate: modify the value passed in this sync inout block
    func updateRepository(withUrl url: URL, withUpdate: (inout Repository) -> Void) {
        accessLock.lock()
        let access = container[url]
        accessLock.unlock()
        guard var builder = access else {
            Dog.shared.join(self, "requesting update on repository \(url.absoluteString) was not found")
            return
        }
        withUpdate(&builder)
        accessLock.lock()
        container[url] = builder
        accessLock.unlock()
        issueCompileAndStore()
    }

    /// delete repository, default will save it to history
    /// - Parameter withUrl: the url of repository
    @discardableResult
    func deleteRepository(withUrl: URL) -> Repository? {
        defer {
            issueCompileAndStore()
            issueNotification()
            PackageCenter.default.issueReloadFromRepositoryCenter()
        }
        accessLock.lock()
        let deleted = container.removeValue(forKey: withUrl)
        pendingUpdateRequest = pendingUpdateRequest
            .filter { $0 != withUrl }
        currentUpdateProgress.removeValue(forKey: withUrl)
        accessLock.unlock()
        if let deleted {
            if historyRecordsEnabled { historyRecords.insert(deleted.url.absoluteString) }
            return deleted
        } else {
            Dog.shared.join(self, "requesting delete on repository \(withUrl.absoluteString) was not found")
            return nil
        }
    }

    /// check every repository if it requires an update
    /// and dispatch them if needed
    /// - Returns: has update dispatched
    @discardableResult
    func dispatchSmartUpdateRequestOnAll() -> Bool {
        var dispatched = false
        accessLock.lock()
        container
            .values
            .filter { repositoryElegantForSmartUpdate(target: $0) }
            .filter { !currentlyInUpdate.contains($0.url) }
            .map(\.url)
            .forEach {
                dispatched = true
                pendingUpdateRequest.insert($0)
            }
        accessLock.unlock()
        dispatchUpdateOnCurrentCenter()
        return dispatched
    }

    /// send everything to update queue
    func dispatchForceUpdateRequestOnAll() {
        accessLock.lock()
        container
            .values
            .filter { !currentlyInUpdate.contains($0.url) }
            .map(\.url)
            .forEach { pendingUpdateRequest.insert($0) }
        accessLock.unlock()
        dispatchUpdateOnCurrentCenter()
    }

    /// send this repo to update
    /// - Parameter url: the url of repository
    func dispatchUpdateOnRepository(withUrl url: URL) {
        accessLock.lock()
        let access = container[url]
        accessLock.unlock()
        guard let target = access?.url else {
            Dog.shared.join(self, "repository \(url.absoluteString) was not found for metadata update")
            return
        }
        accessLock.lock()
        pendingUpdateRequest.insert(target)
        accessLock.unlock()
        dispatchUpdateOnCurrentCenter()
    }

    /// delete repository that is not in or pending refresh and has no package available
    func cleanBrokenRepos() {
        accessLock.lock()
        let urls = container
            .values
            .filter { $0.metaPackage.keys.count < 1 }
            .filter { !(pendingUpdateRequest.contains($0.url) || currentlyInUpdate.contains($0.url)) }
            .map(\.url)
        accessLock.unlock()
        urls.forEach { brokenRepo in
            deleteRepository(withUrl: brokenRepo)
        }
    }

    // save all the repos to disk
    func issueCompileAndStore(sync: Bool = false) {
        if sync {
            Dog.shared.join(self, "compiling called with sync!", level: .info)
            issueCompileAndStoreExec()
        } else {
            compilerThrottle.throttle { [self] in
                issueCompileAndStoreExec()
            }
        }
    }
}
