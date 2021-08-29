//
//  LXMainController.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/8.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import Dog
import SwiftThrottle
import UIKit

class LXMainNavigator: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        viewControllers = [LXMainController()]
        navigationBar.prefersLargeTitles = true
    }
}

class LXMainController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        let indicator = UIActivityIndicatorView()
        indicator.startAnimating()
        view.addSubview(indicator)
        indicator.snp.makeConstraints { x in
            x.center.equalToSuperview()
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(presentNewRootController),
                                               name: .LXMainControllerSwitchDashboard,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(presentNewRootController),
                                               name: .LXMainControllerSwitchSettings,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(presentNewRootController),
                                               name: .LXMainControllerSwitchTasks,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(presentNewRootController),
                                               name: .LXMainControllerSwitchInstalled,
                                               object: nil)

        presentAsRoot(target: LXDashboardController())
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    func presentNewRootController(withNotification notification: Notification) {
        switch notification.name {
        case .LXMainControllerSwitchDashboard:
            presentAsRoot(target: LXDashboardController())
        case .LXMainControllerSwitchSettings:
            presentAsRoot(target: LXSettingController())
        case .LXMainControllerSwitchTasks:
            presentAsRoot(target: LXTaskController())
        case .LXMainControllerSwitchInstalled:
            presentAsRoot(target: LXInstalledController())
        default:
            Dog.shared.join(self, "failed to obtain coordinated view controller, giving up with notification [\(notification.name)]", level: .error)
        }
    }

    func presentAsRoot(target: UIViewController) {
        DispatchQueue.main.async { [weak self] in
            self?.navigationController?.popToRootViewController(animated: false)
            self?.navigationController?.pushViewController(target, animated: false)
        }
    }
}
