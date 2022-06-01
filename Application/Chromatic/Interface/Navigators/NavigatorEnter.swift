//
//  NavigatorEnterViewController.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/8.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import UIKit

class NavigatorEnterViewController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        tabBar.isHidden = true

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(setExceptedRootViewController),
                                               name: .UserInterfaceFrameChanged,
                                               object: nil)
        setExceptedRootViewController()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .UserInterfaceFrameChanged, object: nil)
        }
    }

    private var hdMain: HandyTabBarController?
    private var lxMain: LXSplitController?

    @objc
    func setExceptedRootViewController() {
        if shouldUseLargeUI() {
            debugPrint("loading lx ui")
            if let lxMain = lxMain {
                viewControllers = [lxMain]
            } else {
                let controller = LXSplitController()
                lxMain = controller
                viewControllers = [controller]
            }
        } else {
            debugPrint("loading handy ui")
            if let hdMain = hdMain {
                viewControllers = [hdMain]
            } else {
                let controller = HandyTabBarController()
                hdMain = controller
                viewControllers = [controller]
            }
        }
    }

    func shouldUseLargeUI() -> Bool {
        let currentIdiom = UIDevice.current.userInterfaceIdiom
        if #available(iOS 14.0, *) {
            if !(currentIdiom == .pad || currentIdiom == .mac) {
                return false
            }
        } else {
            if !(currentIdiom == .pad) {
                return false
            }
        }
        if !(view.frame.width > 700 && view.frame.height > 700) {
            return false
        }
        return true
    }
}
