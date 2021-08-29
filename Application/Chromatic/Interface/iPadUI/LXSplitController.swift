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

        preferredDisplayMode = .allVisible
        applySplitWidth()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if viewControllers.count < 2 {
            makeViewControllers()
        }
    }

    func makeViewControllers() {
        viewControllers = [
            /*
             Do not cache them because Apple did it bugly here!
             { viewControllers.count < 2 } will not work
             */
            LXSplitPanelController(), LXMainNavigator(),
        ]
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        applySplitWidth()
    }

    func applySplitWidth() {
        preferredPrimaryColumnWidthFraction = 0.36
        maximumPrimaryColumnWidth = 360
        minimumPrimaryColumnWidth = 360
    }
}
