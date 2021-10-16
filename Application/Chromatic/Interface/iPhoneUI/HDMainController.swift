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

class HDMainController: DashboardController {
    var welcomeCard: WelcomeCard?
    let welcomeCardDropDownAnchor = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = cLXUIDefaultBackgroundColor
        title = NSLocalizedString("MAIN", comment: "Main")

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: .fluent(.settings24Regular),
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(rightButtonCall))

        collectionView.contentInset = UIEdgeInsets(top: 200, left: 20, bottom: 50, right: 20)
        searchBar.removeFromSuperview()

        let welcome = WelcomeCard { [weak self] in
            self?.onTouchAvatar()
        } onTouchCard: { [weak self] in
            self?.onTouchCard()
        }

        welcomeCard = welcome

        collectionView.addSubview(welcome)
        welcome.snp.makeConstraints { x in
            x.left.equalTo(view).offset(20)
            x.right.equalTo(view).offset(-20)
            x.bottom.equalTo(collectionView.snp.top)
            x.height.equalTo(220)
        }

        collectionView.addSubview(welcomeCardDropDownAnchor)
        welcomeCardDropDownAnchor.snp.makeConstraints { x in
            x.left.equalTo(view).offset(20)
            x.right.equalTo(view).offset(-20)
            x.bottom.equalTo(collectionView.snp.top).offset(10)
            x.height.equalTo(5)
        }

        refreshControl.alpha = 0

        DispatchQueue.main.async {
            self.updateWelcomeCardHeight()
        }
    }

    var updateDecision: CGSize?
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        DispatchQueue.main.async {
            if self.updateDecision != self.view.frame.size {
                self.updateDecision = self.view.frame.size
                self.updateWelcomeCardHeight()
            }
        }
    }

    func updateWelcomeCardHeight() {
        var height: CGFloat = 200
        let frame = view.frame.width - 30
        height = frame * 0.55
        if height < 150 { height = 150 }
        if height > 250 { height = 250 }
        welcomeCard?.snp.updateConstraints { x in
            x.height.equalTo(height - 10)
        }
        collectionView.contentInset = UIEdgeInsets(top: height, left: 20, bottom: 50, right: 20)
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

    override func collectionView(_: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView
            .dequeueReusableCell(withReuseIdentifier: packageCellID, for: indexPath)
            as! PackageCollectionCell
        cell.prepareForNewValue()
        cell.loadValue(package: dataSource[indexPath.section].package[indexPath.row])
        return cell
    }
}
