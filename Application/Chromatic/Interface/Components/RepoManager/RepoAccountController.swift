//
//  RepoAccountController.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/28.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import UIKit

class RepoAccountController: UIViewController {
    let container = UIScrollView()
    let sizeControl = UIView()

    let padding = 15

    override func viewDidLoad() {
        super.viewDidLoad()

        container.alwaysBounceVertical = true

        view.backgroundColor = .systemBackground
        preferredContentSize = preferredPopOverSize
        title = NSLocalizedString("ACCOUNTS", comment: "Accounts")

        view.addSubview(container)
        container.snp.makeConstraints { x in
            x.edges.equalToSuperview()
        }

        var anchor = UIView()
        container.addSubview(anchor)
        anchor.snp.makeConstraints { x in
            x.leading.equalTo(view).offset(padding)
            x.trailing.equalTo(view).offset(-padding)
            x.top.equalToSuperview()
            x.height.equalTo(0)
        }

        let repo = RepositoryCenter
            .default
            .obtainRepositoryUrls()
            .map { RepositoryCenter.default.obtainImmutableRepository(withUrl: $0) }
            .compactMap { $0 }
        for item in repo {
            guard let endpoint = item.endpoint else { continue }
            let cell = RepoCompactCell()
            cell.prepareForNewValue()
            cell.setRepository(withUrl: item.url)
            container.addSubview(cell)
            cell.snp.makeConstraints { x in
                x.leading.equalTo(anchor)
                x.trailing.equalTo(anchor)
                x.height.equalTo(25)
                x.top.equalTo(anchor.snp.bottom).offset(10)
            }
            anchor = cell
            let view = RepoPaymentView(repo: item, endpoint: endpoint)
            container.addSubview(view)
            view.snp.makeConstraints { x in
                x.leading.equalTo(anchor)
                x.trailing.equalTo(anchor)
                x.height.equalTo(60)
                x.top.equalTo(anchor.snp.bottom).offset(10)
            }
            anchor = view
        }

        container.addSubview(sizeControl)
        sizeControl.snp.makeConstraints { x in
            x.centerX.equalToSuperview()
            x.top.equalToSuperview()
            x.bottom.equalTo(anchor)
            x.width.equalTo(100)
        }
        sizeControl.isHidden = true
        sizeControl.isUserInteractionEnabled = false
        updateContentSize()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateContentSize()
    }

    func updateContentSize() {
        DispatchQueue.main.async { [self] in
            let height = sizeControl.frame.height + 100
            container.contentSize = CGSize(width: 100, height: height)
        }
    }
}
