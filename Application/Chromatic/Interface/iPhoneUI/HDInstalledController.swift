//
//  HDInstalledController.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/17.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import UIKit

class HDInstalledNavigator: UINavigationController {
    init() {
        super.init(rootViewController: HDInstalledController())

        navigationBar.prefersLargeTitles = true

        tabBarItem = UITabBarItem(title: NSLocalizedString("INSTALLED", comment: "Installed"),
                                  image: UIImage.fluent(.textChangeAccept24Filled),
                                  tag: 0)
        tabBarItem.badgeColor = .systemBlue

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateAvailableUpdateBadge),
                                               name: PackageCenter.packageRecordChanged,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    func updateAvailableUpdateBadge() {
        DispatchQueue.global().async {
            let count = InterfaceBridge.availableUpdateCount()
            DispatchQueue.main.async { [self] in
                if count > 0 {
                    tabBarItem.badgeValue = String(count)
                } else {
                    tabBarItem.badgeValue = nil
                }
            }
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class HDInstalledController: InstalledController {}
