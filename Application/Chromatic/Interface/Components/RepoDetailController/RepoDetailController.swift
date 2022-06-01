//
//  RepoDetailController.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/17.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import SPIndicator
import UIKit

class RepoDetailController: UIViewController {
    var repo: Repository

    var sectionDetailsSortedKeys = [String]()
    var sectionDetails = [String: [Package]]()
    var collectionView: UICollectionView?

    let subtitle = UITextView()
    let ending = UIView()

    init(withRepo: Repository) {
        repo = withRepo
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        print("[ARC] RepoViewController has been deinited")
    }

    let container = UIScrollView()

    let padding = 15

    override func viewDidLoad() {
        super.viewDidLoad()

        title = repo.nickName
        view.backgroundColor = .systemBackground
        preferredContentSize = preferredPopOverSize

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: .fluent(.shareIos24Filled),
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(openShareView))

        container.alwaysBounceVertical = true
        view.addSubview(container)
        container.snp.makeConstraints { x in
            x.edges.equalToSuperview()
        }

        repo.metaPackage.values.forEach { package in
            guard let section = package.latestMetadata?["section"] else {
                return
            }
            sectionDetails[section, default: []].append(package)
        }
        for item in sectionDetails.sorted(by: { a, b -> Bool in
            a.key.lowercased() < b.key.lowercased() ? true : false
        }) {
            sectionDetailsSortedKeys.append(item.key)
        }

        var anchor = UIView()
        container.addSubview(anchor)
        anchor.snp.makeConstraints { x in
            x.leading.equalTo(self.view).offset(padding)
            x.trailing.equalTo(self.view).offset(-padding)
            x.top.equalTo(container)
            x.height.equalTo(2)
        }

        if navigationController == nil {
            let bigTitle = UILabel()
            bigTitle.text = repo.nickName
            bigTitle.font = .systemFont(ofSize: 28, weight: .bold)
            container.addSubview(bigTitle)
            bigTitle.snp.makeConstraints { x in
                x.leading.equalTo(anchor)
                x.right.equalTo(anchor)
                x.top.equalTo(anchor.snp.bottom).offset(20)
                x.height.equalTo(40)
            }
            anchor = bigTitle
        }

        subtitle.textContainerInset = UIEdgeInsets()
        subtitle.textContainer.lineFragmentPadding = 0
        subtitle.font = .systemFont(ofSize: 12, weight: .semibold)
        subtitle.alpha = 0.5
        subtitle.text = repo.repositoryDescription
        if subtitle.text.count < 1 {
            subtitle.text = NSLocalizedString("NO_DESCRIPTION_AVAILABLE", comment: "No Description Available")
        }
        container.addSubview(subtitle)
        subtitle.snp.makeConstraints { x in
            x.leading.equalTo(anchor)
            x.right.equalTo(anchor)
            x.top.equalTo(anchor.snp.bottom)
            x.height.equalTo(20)
        }
        anchor = subtitle

        if let endpoint = repo.paymentInfo[.endpoint],
           let url = URL(string: endpoint)
        {
            let view = setupPayment(withEndpoint: url)
            container.addSubview(view)
            view.snp.makeConstraints { x in
                x.leading.equalTo(anchor)
                x.trailing.equalTo(anchor)
                x.top.equalTo(anchor.snp.bottom).offset(10)
                x.height.equalTo(50)
            }
            anchor = view
        }

        if let featured = repo.attachment[.featured],
           let data = featured.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments),
           let decoded = json as? [String: Any],
           decoded["class"] as? String == "FeaturedBannersView"
        {
            let height = CGFloat(170)
            let scrollView = setupFeatured(with: decoded, height: height)
            container.addSubview(scrollView)
            scrollView.snp.makeConstraints { x in
                x.leading.equalTo(anchor)
                x.trailing.equalTo(anchor)
                x.top.equalTo(anchor.snp.bottom).offset(10)
                x.height.equalTo(height)
            }
            anchor = scrollView
        }

        setupCollectionView(anchor: &anchor)

        let formatter = DateFormatter()
        formatter.formatterBehavior = .behavior10_4
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        let update = UILabel()
        update.text = formatter.string(from: repo.lastUpdatePackage)
        update.font = .systemFont(ofSize: 12, weight: .semibold)
        update.alpha = 0.5
        update.text = NSLocalizedString("LAST_UPDATE", comment: "Last Update")
        let date = UILabel()
        date.font = .systemFont(ofSize: 12, weight: .semibold)
        date.alpha = 0.5
        date.text = formatter.string(from: repo.lastUpdatePackage)
        container.addSubview(update)
        container.addSubview(date)
        update.textAlignment = .left
        update.snp.makeConstraints { x in
            x.leading.equalTo(anchor)
            x.trailing.equalTo(anchor)
            x.top.equalTo(anchor.snp.bottom).offset(10)
            x.height.equalTo(20)
        }
        date.textAlignment = .right
        date.snp.makeConstraints { x in
            x.leading.equalTo(anchor)
            x.trailing.equalTo(anchor)
            x.top.equalTo(anchor.snp.bottom).offset(10)
            x.height.equalTo(20)
        }
        anchor = update

        ending.isUserInteractionEnabled = false
        container.addSubview(ending)
        ending.snp.makeConstraints { x in
            x.top.equalTo(container)
            x.leading.equalTo(anchor)
            x.trailing.equalTo(anchor)
            x.bottom.equalTo(anchor)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        DispatchQueue.main.async { [self] in
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: { [self] in
                layoutCollectionView()
                subtitle.sizeToFit()
                var f1 = subtitle.contentSize.height
                if f1 < 20 { f1 = 20 }
                subtitle.snp.updateConstraints { x in
                    x.height.equalTo(f1)
                }
                container.contentSize = CGSize(width: 0, height: ending.frame.height + 50)
                view.layoutIfNeeded()
            }, completion: nil)
        }
    }

    @objc
    func openShareView() {
        if InterfaceBridge.enableShareSheet {
            let activityViewController = UIActivityViewController(activityItems: [repo.url.absoluteString],
                                                                  applicationActivities: nil)
            activityViewController
                .popoverPresentationController?
                .sourceView = container
            present(activityViewController, animated: true, completion: nil)
        } else {
            UIPasteboard.general.string = repo.url.absoluteString
            SPIndicator.present(title: NSLocalizedString("COPIED", comment: "Cpoied"),
                                message: nil,
                                preset: .done,
                                haptic: .success,
                                from: .top,
                                completion: nil)
        }
    }
}
