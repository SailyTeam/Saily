//
//  LXDashboardController.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/10.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import UIKit

class LXDashboardController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        view.backgroundColor = UIColor(light: .white.withAlphaComponent(0.90), dark: .black)
        title = NSLocalizedString("DASHBOARD", comment: "Dashboard")

        setupSearchButton()
    }

    func setupSearchButton() {
        let item = UIBarButtonItem(image: UIImage.fluent(.search24Filled),
                                   style: .plain,
                                   target: self,
                                   action: #selector(searchButton))
        navigationItem.rightBarButtonItem = item
    }

    @objc
    func searchButton() {
        navigationController?.pushViewController(SearchController())
    }
}
