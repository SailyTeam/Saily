//
//  HDMainController.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/8.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import DropDown
import FluentIcon
import SPIndicator
import SwiftMD5
import UIKit

class HDMainNavigator: UINavigationController {
    init() {
        super.init(rootViewController: HDMainController())

        navigationBar.prefersLargeTitles = true

        tabBarItem = UITabBarItem(title: NSLocalizedString("MAIN", comment: "Main"),
                                  image: UIImage.fluent(.timeline24Regular),
                                  tag: 0)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class HDMainController: UIViewController {
    let container = UIScrollView()

    let padding: CGFloat = 15

    let welcomeCardDropDownAnchor = UIView()
    let recentUpdateView = RecentUpdateView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("MAIN", comment: "Main")
        view.backgroundColor = UIColor(light: .systemGray6, dark: .black)

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: .fluent(.settings24Regular),
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(rightButtonCall))

        container.alwaysBounceVertical = true
        view.addSubview(container)
        container.snp.makeConstraints { x in
            x.edges.equalToSuperview()
        }

        var anchor = UIView()
        container.addSubview(anchor)
        anchor.snp.makeConstraints { x in
            x.leading.equalTo(self.view).offset(padding)
            x.trailing.equalTo(self.view).offset(-padding)
            x.top.equalTo(container)
            x.height.equalTo(0)
        }
        let safeAnchor = anchor

        // MARK: - APPLE CARD

        let welcomeView = WelcomeCard(onTouchAvatar: { self.onTouchAvatar() },
                                      onTouchCard: { self.onTouchCard() })
        container.addSubview(welcomeView)
        welcomeView.snp.makeConstraints { x in
            x.leading.equalTo(safeAnchor)
            x.trailing.equalTo(safeAnchor)
            x.top.equalTo(anchor.snp.bottom)
            x.height.equalTo(188)
        }
        anchor = welcomeView
        container.addSubview(welcomeCardDropDownAnchor)
        welcomeCardDropDownAnchor.snp.makeConstraints { x in
            x.leading.equalTo(safeAnchor)
            x.width.equalTo(280)
            x.top.equalTo(welcomeView.snp.bottom).offset(10)
            x.height.equalTo(0)
        }

        // MARK: - FEATURES

        let recentUpdate = UILabel()
        recentUpdate.text = NSLocalizedString("PACKAGES", comment: "Packages")
        recentUpdate.font = .systemFont(ofSize: 18, weight: .semibold)
        recentUpdate.textAlignment = .left
        container.addSubview(recentUpdate)
        recentUpdate.snp.makeConstraints { x in
            x.leading.equalTo(safeAnchor.snp.leading)
            x.width.equalTo(188)
            x.height.equalTo(35)
            x.top.equalTo(anchor.snp.bottom).offset(5)
        }
        anchor = recentUpdate

        container.addSubview(recentUpdateView)
        recentUpdateView.snp.makeConstraints { x in
            x.leading.equalTo(safeAnchor)
            x.trailing.equalTo(safeAnchor)
            x.top.equalTo(anchor.snp.bottom).offset(5)
            x.height.equalTo(60)
        }
        anchor = recentUpdateView
    }

    @objc
    func rightButtonCall() {
        let target = SettingController()
        present(next: target)
    }

    func onTouchAvatar() {
        onTouchCard()
    }

    func onTouchCard() {
        InterfaceBridge.appleCardTouched(dropDownAnchor: welcomeCardDropDownAnchor)
    }
}
