//
//  HDRepoController.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/17.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import MorphingLabel
import SafariServices
import SPIndicator
import UIKit

class HDRepoNavigator: UINavigationController {
    init() {
        super.init(rootViewController: HDRepoController())

        navigationBar.prefersLargeTitles = true

        tabBarItem = UITabBarItem(title: NSLocalizedString("REPOSITORY", comment: "Repository"),
                                  image: UIImage.fluent(.bookCompass24Regular),
                                  tag: 0)

        tabBarItem.badgeColor = .systemOrange
        NotificationCenter
            .default
            .addObserver(self,
                         selector: #selector(updateCoordinateRepoBadge),
                         name: RepositoryCenter.metadataUpdate,
                         object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    func updateCoordinateRepoBadge() {
        let progress = RepositoryCenter
            .default
            .obtainUpdateRemain()
        DispatchQueue.main.async { [self] in
            if progress > 0 {
                tabBarItem.badgeValue = String(progress)
            } else {
                tabBarItem.badgeValue = nil
            }
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class HDRepoController: UIViewController {
    let container = UIScrollView()
    let repoCard = RepoCard()
    var repoCount: Int = RepositoryCenter.default.obtainRepositoryCount() {
        didSet {
            repoCardCountTitle.text = "\(repoCount)"
        }
    }

    let refreshControl = UIRefreshControl()
    let repoCardCountTitle = LTMorphingLabel()
    let scrollViewEndingControl = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("REPOSITORY", comment: "Repository")
        view.backgroundColor = cLXUIDefaultBackgroundColor

        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        container.addSubview(refreshControl)

        container.alwaysBounceVertical = true
        view.addSubview(container)
        container.snp.makeConstraints { x in
            x.edges.equalToSuperview()
        }

        var anchor = UIView()
        let safeAnchor = anchor
        container.addSubview(anchor)
        let padding = 18
        anchor.snp.makeConstraints { x in
            x.leading.equalTo(self.view).offset(padding)
            x.trailing.equalTo(self.view).offset(-padding)
            x.top.equalToSuperview().offset(padding)
            x.height.equalTo(0)
        }

        // MARK: - REPO COLLECTIONS

        let box = UIView()
        box.backgroundColor = UIColor(named: "CARD_BACKGROUND")
        box.layer.cornerRadius = 12
        container.addSubview(box)
        box.snp.makeConstraints { x in
            x.leading.equalTo(safeAnchor.snp.leading)
            x.trailing.equalTo(safeAnchor.snp.trailing)
            x.top.equalTo(anchor.snp.bottom)
            x.height.equalTo(60)
        }
        let icon = UIImageView(image: .fluent(.bookGlobe24Regular))
        icon.tintColor = .systemOrange
        icon.contentMode = .scaleAspectFit
        box.addSubview(icon)
        icon.snp.makeConstraints { x in
            x.centerY.equalToSuperview()
            x.leading.equalToSuperview().offset(10)
            x.width.equalTo(30)
            x.height.equalTo(30)
        }
        let label = UILabel(text: NSLocalizedString("REPO_COLLECTIONS", comment: "Repo Collections"))
        label.font = .roundedFont(ofSize: 16, weight: .semibold)
        box.addSubview(label)
        label.snp.makeConstraints { x in
            x.centerY.equalToSuperview()
            x.leading.equalTo(icon.snp.trailing).offset(8)
            x.trailing.equalToSuperview()
        }
        let indicator = UIImageView(image: .fluent(.arrowRightCircle24Filled))
        indicator.layer.cornerRadius = 8
        indicator.backgroundColor = .white
        indicator.tintColor = .systemGreen
        box.addSubview(indicator)
        indicator.snp.makeConstraints { x in
            x.trailing.equalToSuperview().offset(-10)
            x.centerY.equalToSuperview()
            x.width.equalTo(16)
            x.height.equalTo(16)
        }
        let button = UIButton()
        button.addTarget(self, action: #selector(openGlobalRepoList), for: .touchUpInside)
        box.addSubview(button)
        button.snp.makeConstraints { x in
            x.edges.equalToSuperview()
        }
        anchor = box

        // MARK: - REPO CARD

        let repoCardTitle = UILabel()
        repoCardTitle.text = NSLocalizedString("REGISTERED", comment: "Registered")
        repoCardTitle.font = .systemFont(ofSize: 22, weight: .semibold)
        repoCardTitle.textAlignment = .left
        container.addSubview(repoCardTitle)
        repoCardTitle.snp.makeConstraints { x in
            x.leading.equalTo(safeAnchor.snp.leading)
            x.width.equalTo(188)
            x.height.equalTo(35)
            x.top.equalTo(anchor.snp.bottom).offset(20)
        }
        repoCardCountTitle.text = String(repoCount)
        repoCardCountTitle.morphingEffect = .evaporate
        repoCardCountTitle.font = UIFont
            .roundedFont(ofSize: 22, weight: .semibold)
            .monospacedDigitFont
        repoCardCountTitle.textAlignment = .right
        container.addSubview(repoCardCountTitle)
        repoCardCountTitle.snp.makeConstraints { x in
            x.trailing.equalTo(safeAnchor.snp.trailing)
            x.width.equalTo(188)
            x.height.equalTo(35)
            x.centerY.equalTo(repoCardTitle.snp.centerY)
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

        navigationItem.leftBarButtonItems = [
            UIBarButtonItem(image: .fluent(.broom24Filled),
                            style: .done,
                            target: self,
                            action: #selector(clean)),
        ]

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: .fluent(.collections24Filled),
                            style: .done,
                            target: self,
                            action: #selector(openAdd)),
        ]

        repoCard.actionOverride[.add] = { [weak self] in self?.openAdd() }
    }

    @objc
    func openAdd() {
        let target = RepoAddViewController()
        navigationController?.pushViewController(target)
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

    @objc
    func refresh() {
        refreshControl.endRefreshing()
        DispatchQueue.main.async {
            self.repoCard.eventEmitterRefresh()
        }
    }

    @objc
    func clean() {
        RepositoryCenter
            .default
            .cleanBrokenRepos()
        SPIndicator.present(title: NSLocalizedString("BROKEN_REPO_REMOVED", comment: "Broken Repo Removed"),
                            message: "",
                            preset: .done,
                            from: .top,
                            completion: nil)
    }

    @objc
    func openGlobalRepoList() {
        let url = URL(string: "https://www.ios-repo-updates.com/repositories/popular/")!
        let target = SFSafariViewController(url: url)
        target.title = NSLocalizedString("REPO_COLLECTIONS", comment: "Repo Collections")
        present(target, animated: true, completion: nil)
    }
}
