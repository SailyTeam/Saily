//
//  LXSplitView.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/8.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import DropDown
import MorphingLabel
import SnapKit
import UIKit

class LXSplitPanelController: UIViewController, UINavigationControllerDelegate {
    var notificationToken: String = ""

    private let container: UIScrollView = {
        let builder = UIScrollView()
        builder.showsVerticalScrollIndicator = false
        builder.showsHorizontalScrollIndicator = false
        builder.alwaysBounceVertical = true
        builder.alwaysBounceHorizontal = false
        return builder
    }()

    let welcomeCardDropDownAnchor = UIView()
    let dashNavCard = DashNavCard()

    let repoCard = RepoCard()
    var repoCount: Int = RepositoryCenter.default.obtainRepositoryCount() {
        didSet {
            repoCardCountTitle.text = "\(repoCount)"
        }
    }

    let repoCardCountTitle = LTMorphingLabel()
    let scrollViewEndingControl = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(light: UIColor(hex: 0xF2F2F7)!, dark: .black)

        setupLayout()
    }

    func setupLayout() {
        view.addSubview(container)
        container.snp.makeConstraints { x in
            x.edges.equalToSuperview()
        }

        var anchor = UIView()
        let safeAnchor = anchor
        container.addSubview(anchor)
        anchor.snp.makeConstraints { x in
            x.top.equalTo(container.snp.top).offset(20)
            x.height.equalTo(2)
            x.leading.equalTo(self.view.snp.leading).offset(20)
            x.trailing.equalTo(self.view.snp.trailing).offset(-20)
        }

        let welcomeCard = WelcomeCard { [weak self] in
            self?.welcomeCardAvatarTapped()
        } onTouchCard: { [weak self] in
            self?.welcomeCardTapped()
        }

        container.addSubview(welcomeCard)
        welcomeCard.snp.makeConstraints { x in
            x.leading.equalTo(safeAnchor.snp.leading)
            x.trailing.equalTo(safeAnchor.snp.trailing)
            x.top.equalTo(anchor.snp.bottom).offset(35)
            x.height.equalTo(180)
        }
        anchor = welcomeCard

        container.addSubview(welcomeCardDropDownAnchor)
        welcomeCardDropDownAnchor.snp.makeConstraints { x in
            x.leading.equalTo(safeAnchor.snp.leading)
            x.trailing.equalTo(safeAnchor.snp.trailing)
            x.top.equalTo(welcomeCard.snp.bottom).offset(10)
            x.height.equalTo(0)
        }

        let dashNavCardTitle = UILabel()
        dashNavCard.notificationToken = notificationToken
        dashNavCardTitle.text = NSLocalizedString("FEATURES", comment: "Features")
        dashNavCardTitle.font = .systemFont(ofSize: 22, weight: .heavy)
        dashNavCardTitle.textAlignment = .left
        container.addSubview(dashNavCardTitle)
        dashNavCardTitle.snp.makeConstraints { x in
            x.leading.equalTo(safeAnchor.snp.leading)
            x.width.equalTo(188)
            x.height.equalTo(35)
            x.top.equalTo(anchor.snp.bottom).offset(20)
        }
        anchor = dashNavCardTitle

        container.addSubview(dashNavCard)
        dashNavCard.snp.makeConstraints { x in
            x.leading.equalTo(safeAnchor.snp.leading)
            x.trailing.equalTo(safeAnchor.snp.trailing)
            x.top.equalTo(anchor.snp.bottom).offset(8)
            x.height.equalTo(210)
        }
        anchor = dashNavCard

        let repoCardTitle = UILabel()
        repoCardTitle.text = NSLocalizedString("REPOSITORY", comment: "Repository")
        repoCardTitle.font = .systemFont(ofSize: 22, weight: .heavy)
        repoCardTitle.textAlignment = .left
        container.addSubview(repoCardTitle)
        repoCardTitle.snp.makeConstraints { x in
            x.leading.equalTo(safeAnchor.snp.leading)
            x.width.equalTo(188)
            x.height.equalTo(35)
            x.top.equalTo(anchor.snp.bottom).offset(10)
        }
        repoCardCountTitle.text = String(repoCount)
        repoCardCountTitle.morphingEffect = .evaporate
        repoCardCountTitle.font = UIFont.roundedFont(ofSize: 22, weight: .bold).monospacedDigitFont
        repoCardCountTitle.textAlignment = .right
        container.addSubview(repoCardCountTitle)
        repoCardCountTitle.snp.makeConstraints { x in
            x.trailing.equalTo(safeAnchor.snp.trailing)
            x.width.equalTo(188)
            x.height.equalTo(35)
            x.top.equalTo(anchor.snp.bottom).offset(10)
        }
        anchor = repoCardTitle

        container.addSubview(repoCard)
        repoCard.snp.makeConstraints { x in
            x.top.equalTo(anchor.snp.bottom).offset(8)
            x.leading.equalTo(safeAnchor.snp.leading)
            x.trailing.equalTo(safeAnchor.snp.trailing)
            x.height.equalTo(repoCard.suggestHeight)
        }
        anchor = repoCard

        scrollViewEndingControl.isHidden = true
        container.addSubview(scrollViewEndingControl)
        scrollViewEndingControl.snp.makeConstraints { x in
            x.top.equalTo(safeAnchor.snp.top)
            x.bottom.equalTo(anchor.snp.bottom)
            x.centerX.equalToSuperview()
            x.width.equalTo(200)
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateRepoCount),
                                               name: RepositoryCenter.registrationUpdate,
                                               object: nil)

        updateRepoCount()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateRepoCount()
    }

    @objc
    func updateRepoCount() {
        DispatchQueue.main.async { [self] in
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: { [self] in
                repoCount = RepositoryCenter.default.obtainRepositoryCount()
                repoCard.snp.updateConstraints { x in
                    x.height.equalTo(repoCard.suggestHeight)
                }
                view.layoutIfNeeded()
            }, completion: { _ in
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: { [self] in
                    container.contentSize = CGSize(width: 100, height: scrollViewEndingControl.frame.height + 100)
                    view.layoutIfNeeded()
                })
            })
        }
    }

    func welcomeCardAvatarTapped() {
        welcomeCardTapped()
    }

    func welcomeCardTapped() {
        InterfaceBridge.appleCardTouched(dropDownAnchor: welcomeCardDropDownAnchor)
    }
}
