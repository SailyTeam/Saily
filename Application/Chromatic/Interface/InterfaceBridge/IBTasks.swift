//
//  TaskButton.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/29.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import DropDown
import SPIndicator
import UIKit

private let kEssentialPackageIdentities = [
    "apt", "essential", "firmware", "bash", "coreutils", "dpkg",
]

extension InterfaceBridge {
    struct TaskDataSection {
        let label: String
        let content: [TaskManager.PackageAction]
    }

    struct TaskDropDownAction {
        let label: String
        let action: (UIView, TaskProcessor.OperationPaylad) -> Void
    }

    static let taskDropDownActions: [TaskDropDownAction] = [
        .init(label: NSLocalizedString("COPY_SCRIPT", comment: "Copy Script"), action: {
            let text = TaskProcessor.shared.generateMockCommandScript(operation: $1)
            if InterfaceBridge.enableShareSheet {
                let activityViewController = UIActivityViewController(activityItems: [text],
                                                                      applicationActivities: nil)
                activityViewController
                    .popoverPresentationController?
                    .sourceView = $0
                $0
                    .parentViewController?
                    .present(activityViewController, animated: true, completion: nil)
            } else {
                UIPasteboard.general.string = text
                SPIndicator.present(title: NSLocalizedString("COPIED", comment: "Cpoied"),
                                    message: nil,
                                    preset: .done,
                                    haptic: .success,
                                    from: .top,
                                    completion: nil)
            }
        }),
        .init(label: NSLocalizedString("DRY_RUN", comment: "Dry Run"), action: {
            let target = OperationConsoleController()
            var dryRunPayload = $1
            dryRunPayload.dryRun = true
            target.operationPayload = dryRunPayload
            target.modalTransitionStyle = .coverVertical
            target.modalPresentationStyle = .formSheet
            $0.parentViewController?.present(target, animated: true, completion: nil)
        }),
        .init(label: NSLocalizedString("EXECUTE", comment: "Execute"), action: {
            let target = OperationConsoleController()
            target.operationPayload = $1
            target.modalTransitionStyle = .coverVertical
            target.modalPresentationStyle = .formSheet
            $0.parentViewController?.present(target, animated: true, completion: nil)
        }),
    ]

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
            // resume or retry any broken downloads
            TaskManager.shared.retryAllDownload()
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
            let dataSource = taskDropDownActions
                .map(\.label)
                .invisibleSpacePadding()
            let anchorView = UIView()
            sender.addSubview(anchorView)
            anchorView.snp.makeConstraints { make in
                make.bottom.equalToSuperview()
                make.right.equalToSuperview()
                make.height.equalTo(2)
                make.width.equalTo(280)
            }
            let dropDown = DropDown(
                anchorView: anchorView,
                selectionAction: {
                    debugPrint("\(#function) selecting \($0): \($1)")
                    taskDropDownActions[safe: $0]?.action(sender, paylaod)
                },
                dataSource: dataSource,
                topOffset: nil,
                bottomOffset: nil,
                cellConfiguration: nil,
                cancelAction: nil
            )
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                dropDown.show(onTopOf: sender.window)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                anchorView.removeFromSuperview()
            }
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
