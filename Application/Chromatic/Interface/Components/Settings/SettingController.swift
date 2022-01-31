//
//  SettingController.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/29.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import UIKit

class SettingController: UIViewController {
    var _settingView: SettingView?

    var settingView: SettingView {
        if let settingView = _settingView {
            return settingView
        }
        let view = SettingView(shortPadding: true)
        _settingView = view
        return view
    }

    var preferLargeTitle: Bool {
        false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = cLXUIDefaultBackgroundColor
        title = NSLocalizedString("SETTING", comment: "Setting")

        navigationItem.largeTitleDisplayMode = preferLargeTitle ? .automatic : .never

        view.addSubview(settingView)
        settingView.snp.makeConstraints { x in
            x.edges.equalToSuperview()
        }
        settingView.updateContentSize()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        settingView.updateContentSize()
    }
}
