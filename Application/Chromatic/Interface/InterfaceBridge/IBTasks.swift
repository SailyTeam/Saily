//
//  TaskButton.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/29.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import UIKit

private let kEssentialPackageIdentities = [
    "apt", "essential", "firmware", "bash", "coreutils", "dpkg",
]

extension InterfaceBridge {
    struct TaskDataSection {
        let label: String
        let content: [TaskManager.PackageAction]
    }

    static func buildTaskDataSource() -> [TaskDataSection] {
        var buildSource = [TaskDataSection]()
        let actions = TaskManager.shared.copyEveryActions()

        let userDelete = actions
            .filter(\.isUserRequired)
            .filter { $0.action == .remove }
            .sorted { PackageCenter.default.name(of: $0.represent) < PackageCenter.default.name(of: $1.represent) }
        if userDelete.count > 0 {
            buildSource.append(.init(label: NSLocalizedString("REQUEST_REMOVE", comment: "Request Remove"),
                                     content: userDelete))
        }

        let userInstall = actions
            .filter(\.isUserRequired)
            .filter { $0.action == .install }
            .sorted { PackageCenter.default.name(of: $0.represent) < PackageCenter.default.name(of: $1.represent) }
        if userInstall.count > 0 {
            buildSource.append(.init(label: NSLocalizedString("REQUEST_INSTALL", comment: "Request Install"),
                                     content: userInstall))
        }

        let extraDelete = actions
            .filter { !$0.isUserRequired }
            .filter { $0.action == .remove }
            .sorted { PackageCenter.default.name(of: $0.represent) < PackageCenter.default.name(of: $1.represent) }
        if extraDelete.count > 0 {
            buildSource.append(.init(label: NSLocalizedString("ADDITIONAL_REMOVE", comment: "Additional Remove"),
                                     content: extraDelete))
        }

        let extraInstall = actions
            .filter { !$0.isUserRequired }
            .filter { $0.action == .install }
            .sorted { PackageCenter.default.name(of: $0.represent) < PackageCenter.default.name(of: $1.represent) }
        if extraInstall.count > 0 {
            buildSource.append(.init(label: NSLocalizedString("ADDITIONAL_INSTALL", comment: "Additional Install"),
                                     content: extraInstall))
        }

        return buildSource
    }

    static func processTaskButtonTapped(button sender: UIButton) {
        sender.shineAnimation()
        let operationPayload = TaskProcessor.shared.createOperationPayload()
        guard let paylaod = operationPayload else {
            let alert = UIAlertController(title: NSLocalizedString("ERROR", comment: "Error"),
                                          message: NSLocalizedString("FAILED_TO_CREATE_PAYLOAD_MAYBE_DOWNLOAD_FAILED", comment: "Failed to create operation payload, incomplete download or broken resources. Please try again later."),
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("DISMISS", comment: "Dismiss"), style: .default, handler: nil))
            sender.parentViewController?.present(alert, animated: true, completion: nil)
            return
        }

        guard paylaod.install.count > 0 || paylaod.remove.count > 0 else {
            let alert = UIAlertController(title: NSLocalizedString("ERROR", comment: "Error"),
                                          message: NSLocalizedString("QUEUE_IS_EMPTY", comment: "Queue is empty"),
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("DISMISS", comment: "Dismiss"), style: .default, handler: nil))
            sender.parentViewController?.present(alert, animated: true, completion: nil)
            return
        }

        var safetyCheck = false
        for item in paylaod.remove {
            if kEssentialPackageIdentities.contains(item) {
                safetyCheck = true
                break
            }
        }

        func confirmOperations() {
            if TaskProcessor.shared.inProcessingQueue {
                let alert = UIAlertController(title: "⚠️",
                                              message: NSLocalizedString("TASK_PROCESSOR_BUSY_PROCESSING_ANOTHER_JOB", comment: "Task processor is busy processing another job"),
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("DISMISS", comment: "Dismiss"),
                                              style: .default,
                                              handler: nil))
                sender.parentViewController?.present(alert, animated: true, completion: nil)
                return
            }
            let target = OperationConsoleController()
            target.operationPayload = paylaod
            target.modalTransitionStyle = .coverVertical
            target.modalPresentationStyle = .formSheet
            sender.parentViewController?.present(target, animated: true, completion: nil)
        }

        if safetyCheck {
            let alert = UIAlertController(title: "⚠️",
                                          message: NSLocalizedString("ESSENTIAL_PACKAG_IN_REMOVE_QUEUE", comment: "Essential package in removal queue, this may brick your device."),
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("PROCEED", comment: "Proceed"),
                                          style: .destructive) { _ in
                    confirmOperations()
                })
            alert.addAction(UIAlertAction(title: NSLocalizedString("CANCEL", comment: "Cancel"),
                                          style: .cancel,
                                          handler: nil))
            sender.parentViewController?.present(alert, animated: true, completion: nil)
        } else {
            confirmOperations()
        }
    }

    static func availableUpdateCount() -> Int {
        let fetch = PackageCenter.default.obtainInstalledPackageList()
        var count = 0
        fetch.forEach { package in
            guard let version = package.latestVersion else { return }
            let candidates = PackageCenter
                .default
                .obtainUpdateForPackage(with: package.identity, version: version)
            if candidates.count > 0 { count += 1 }
        }
        return count
    }
}
