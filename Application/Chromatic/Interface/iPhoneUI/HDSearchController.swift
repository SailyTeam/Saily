//
//  HDSearchController.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/17.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import UIKit

class HDSearchNavigator: UINavigationController {
    init() {
        super.init(rootViewController: SearchController())

        navigationBar.prefersLargeTitles = true

        tabBarItem = UITabBarItem(title: NSLocalizedString("SEARCH", comment: "Search"),
                                  image: UIImage.fluent(.bookSearch24Regular),
                                  tag: 0)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
