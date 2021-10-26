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
    var displayController = LXMainController()

    var notificationToken: String {
        set {
            displayController.notificationToken = newValue
        }
        get {
            displayController.notificationToken
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewControllers = [displayController]
        navigationBar.prefersLargeTitles = true
    }
}

class LXMainController: UIViewController {
    var notificationToken: String = ""

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

        presentAsRoot(target: dashboard)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private let dashboard = LXDashboardController()
    private let setting = LXSettingController()
    private let tasks = LXTaskController()
    private let installed = LXInstalledController()

    private var lastNotification: Notification?

    @objc
    func presentNewRootController(withNotification notification: Notification) {
        lastNotification = notification
        debugPrint("received notificationToken \(notificationToken)")
        if let object = notification.object, let token = object as? String {
            guard token == notificationToken else {
                debugPrint("token mismatch \(token) != \(notificationToken)")
                return
            }
        }
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        navigationController?.navigationBar.shadowImage = nil
        switch notification.name {
        case .LXMainControllerSwitchDashboard:
            presentAsRoot(target: dashboard)
        case .LXMainControllerSwitchSettings:
            presentAsRoot(target: setting)
        case .LXMainControllerSwitchTasks:
            presentAsRoot(target: tasks)
        case .LXMainControllerSwitchInstalled:
            presentAsRoot(target: installed)
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // this is fix for
        // https://github.com/SailyTeam/Saily/issues/40

        debugPrint("\(#file) \(#function) \(#line)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            // check if there is no view controller exists
            let top = self.navigationController?.topViewController
            if top == self { // fatal if nil, don't handle it
                if let notification = self.lastNotification {
                    self.presentNewRootController(withNotification: notification)
                } else {
                    self.presentNewRootController(withNotification: Notification(name: .LXMainControllerSwitchDashboard))
                }
            }
        }
    }
}
