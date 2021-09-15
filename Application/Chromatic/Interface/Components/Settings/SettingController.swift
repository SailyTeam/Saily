//
//  SettingController.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/29.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import UIKit

class SettingController: UIViewController {
    let setting = SettingView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = cLXUIDefaultBackgroundColor
        title = NSLocalizedString("SETTING", comment: "Setting")

        view.addSubview(setting)
        setting.snp.makeConstraints { x in
            x.edges.equalToSuperview()
        }

        setting.updateContentSize()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setting.updateContentSize()
    }
}
