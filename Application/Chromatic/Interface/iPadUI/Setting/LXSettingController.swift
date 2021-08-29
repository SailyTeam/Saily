//
//  LXSettingController.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/10.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import UIKit

class LXSettingController: SettingController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(light: .white.withAlphaComponent(0.90), dark: .black)
        navigationItem.hidesBackButton = true
    }
}
