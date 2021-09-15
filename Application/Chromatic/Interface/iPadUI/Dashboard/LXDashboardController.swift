//
//  LXDashboardController.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/9/15.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import UIKit

class LXDashboardController: DashboardController {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        view.backgroundColor = cLXUIDefaultBackgroundColor
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationItem.largeTitleDisplayMode = .never
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        navigationController?.navigationBar.shadowImage = nil
        navigationItem.largeTitleDisplayMode = .always
    }
}
