//
//  HandyTabBarController.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/8.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import LNPopupController
import UIKit

class HandyTabBarController: UITabBarController, UIGestureRecognizerDelegate {
    let taskPopUpController = HDTaskController()

    override func viewDidLoad() {
        super.viewDidLoad()

        viewControllers = [
            HDMainNavigator(),
            HDRepoNavigator(),
            HDInstalledNavigator(),
            HDSearchNavigator(),
        ]

        selectedIndex = 0

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updatePopupElements),
                                               name: .TaskContainerChanged,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateDownloadProgress),
                                               name: .DownloadProgress,
                                               object: nil)

        popupBar.progressView.tintColor = .systemYellow
        popupBar.progressViewStyle = .bottom
        popupInteractionStyle = .drag

        updatePopupElements()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    func updatePopupElements() {
        let count = TaskManager.shared.obtainTaskCount()
        let formatter = NSLocalizedString("%d_OPERATIONS", comment: "%d Operation")
        taskPopUpController.popupItem.image = UIImage(named: "LNContinue")
        taskPopUpController.popupItem.title = String(format: formatter, count)
        taskPopUpController.popupItem.subtitle = NSLocalizedString("QUEUE", comment: "Queue")
        if count > 0 {
            presentPopupBar(withContentViewController: taskPopUpController,
                            animated: true,
                            completion: nil)
        } else {
            dismissPopupBar(animated: true, completion: nil)
        }
        updateDownloadProgress()
    }

    @objc
    func updateDownloadProgress() {
        let progress = TaskManager
            .shared
            .obtainAllDownloadProgress()
        let value = Float(progress.fractionCompleted)
        DispatchQueue.main.async { [self] in
            if progress.completedUnitCount == progress.totalUnitCount
                || progress.totalUnitCount == 0
            {
                taskPopUpController.popupItem.subtitle = NSLocalizedString("READY", comment: "Ready")
            } else {
                taskPopUpController.popupItem.subtitle = NSLocalizedString("DOWNLOADING", comment: "Downloading")
            }
            UIView.animate(withDuration: 0.2) {
                popupBar.progressView.setProgress(value, animated: true)
            }
        }
    }
}
