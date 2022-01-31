//
//  LXSettingController.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/10.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import UIKit

class LXSettingController: SettingController {
    override var settingView: SettingView {
        if let settingView = _settingView {
            return settingView
        }
        let view = SettingView(shortPadding: false)
        _settingView = view
        return view
    }

    override var preferLargeTitle: Bool {
        true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = cLXUIDefaultBackgroundColor
        navigationItem.hidesBackButton = true
    }
}
