//
//  LXSplitController.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/8.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import UIKit

class LXSplitController: UISplitViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        preferredDisplayMode = .oneBesideSecondary
        applySplitWidth()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if viewControllers.count < 2 {
            makeViewControllers()
        }
    }

    func makeViewControllers() {
        let notificationToken = UUID().uuidString
        let split = LXSplitPanelController()
        let navigator = LXMainNavigator()
        split.notificationToken = notificationToken
        navigator.notificationToken = notificationToken
        viewControllers = [
            /*
             Do not cache them because Apple did it bugly here!
             { viewControllers.count < 2 } will not work
             */
            split, navigator,
        ]
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        applySplitWidth()
    }

    func applySplitWidth() {
        preferredPrimaryColumnWidthFraction = 0.34
        maximumPrimaryColumnWidth = 340
        minimumPrimaryColumnWidth = 340
    }
}
