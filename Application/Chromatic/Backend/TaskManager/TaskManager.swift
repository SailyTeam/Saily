//
//  TaskMaster.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/19.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import Dog
import Foundation
import PropertyWrapper
import SwiftThrottle

internal final class TaskManager {
    static let shared = TaskManager()
    private init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(receivedRefreshNotification),
                                               name: PackageCenter.packageRecordChanged,
                                               object: nil)
    }

    // MARK: - User Default

    @UserDefaultsWrapper(key: "wiki.qaq.chromatic.automaticUpdateWhenAvailable", defaultValue: false)
    var automaticUpdateWhenAvailable: Bool

    // MARK: - Container

    private let accessLock = NSLock()
    private let notificationThrottle = Throttle(minimumDelay: 0.5, queue: .main)
    private var userAction: [PackageAction] = []
    private var resolvedAction: [PackageAction] = [] {
        didSet {
            notificationThrottle.throttle {
                NotificationCenter
                    .default
                    .post(name: .TaskContainerChanged, object: nil)
            }
        }
    }

    @objc
    func receivedRefreshNotification() {
        if !automaticUpdateWhenAvailable {
            return
        }
        DispatchQueue.global().async {
            self.updateEverything()
        }
    }

    // MARK: - Container Operator

    func isQueueContains(package identity: String) -> Bool {
        accessLock.lock()
        let result = resolvedAction.contains { $0.represent.identity == identity }
        accessLock.unlock()
        return result
    }

    func isQueueContainsUserRequest(package identity: String) -> Bool {
        accessLock.lock()
        let result = userAction.contains { $0.represent.identity == identity }
        accessLock.unlock()
        return result
    }

    func copyCurrentUserActions() -> [PackageAction] {
        accessLock.lock()
        let copy = userAction
        accessLock.unlock()
        return copy
    }

    func copyEveryActions() -> [PackageAction] {
        accessLock.lock()
        let result = resolvedAction
        accessLock.unlock()
        return result
    }

    func commitResolved(resolvedActions: [PackageAction]) {
        accessLock.lock()
        userAction = resolvedActions
            .filter(\.isUserRequired)
        resolvedAction = resolvedActions
        accessLock.unlock()
        dispatchNotification()
        let downloadList = resolvedActions
            .filter { $0.action == .install }
            .map(\.represent)
        CariolNetwork
            .shared
            .syncDownloadRequest(packageList: downloadList)
    }

    func retryAllDownload() {
        accessLock.lock()
        let actions = resolvedAction
        accessLock.unlock()
        dispatchNotification()
        let downloadList = actions
            .filter { $0.action == .install }
            .map(\.represent)
        CariolNetwork
            .shared
            .syncDownloadRequest(packageList: downloadList)
    }

    func obtainTaskCount() -> Int {
        accessLock.lock()
        let result = resolvedAction.count
        accessLock.unlock()
        return result
    }

    private let throttle = Throttle(minimumDelay: 0.5, queue: .main)
    private func dispatchNotification() {
        throttle.throttle {
            NotificationCenter.default.post(name: .TaskContainerChanged, object: nil)
        }
    }
}
