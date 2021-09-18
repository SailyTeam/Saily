//
//  RepoCard.swift
//  Chromatic
//
//  Created by Lakr Aream on 2020/4/18.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import AptRepository
import SPIndicator
import SwiftThrottle
import UIKit

class RepoCard: UIView {
    private let box = UIView()

    private var dataSourceCache: [URL] = RepositoryCenter
        .default
        .obtainRepositoryUrls(sortedByName: true)

    private let btnCoverAdd = UIImageView(image: UIImage(named: "RepoCard.Add"))
    private let btnCoverRefresh = UIImageView(image: UIImage(named: "RepoCard.Refresh"))
    private let btnCoverShare = UIImageView(image: UIImage(named: "RepoCard.Share"))
    private let btnCoverHelp = UIImageView(image: UIImage(named: "RepoCard.Info"))
    private let buttonAdd = UIButton()
    private let buttonRefresh = UIButton()
    private let buttonShare = UIButton()
    private let buttonHelp = UIButton()

    private let tableView = UITableView()
    private let cellidentity = "wiki.qaq.RepoCard.tableView.cellidentity"
    private let cellHeight: CGFloat = 52
    private let dataSourceReloadThrottle = Throttle(minimumDelay: 1, queue: .main)

    private var lastUpdateTouched: Date?

    public var suggestHeight: CGFloat {
        let count = RepositoryCenter.default.obtainRepositoryCount()
        return count < 1
            ? cellHeight + 100
            : CGFloat(count * Int(cellHeight) + 100)
    }

    public enum ActionParent: String, Codable {
        case add
//        case reload
//        case scan
//        case share
    }

    public var actionOverride = [ActionParent: () -> Void]()

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    required init() {
        super.init(frame: CGRect())

        addSubview(box)
        addSubview(btnCoverAdd)
        addSubview(btnCoverRefresh)
        addSubview(btnCoverShare)
        addSubview(btnCoverHelp)
        addSubview(buttonAdd)
        addSubview(buttonRefresh)
        addSubview(buttonShare)
        addSubview(buttonHelp)

        box.backgroundColor = UIColor(named: "CARD_BACKGROUND")
        box.layer.cornerRadius = 14
        box.snp.makeConstraints { x in
            x.left.equalTo(self.snp.left)
            x.right.equalTo(self.snp.right)
            x.bottom.equalTo(self.snp.bottom)
            x.top.equalTo(self.snp.top).offset(22)
        }

        btnCoverAdd.contentMode = .scaleAspectFit
        btnCoverRefresh.contentMode = .scaleAspectFit
        btnCoverShare.contentMode = .scaleAspectFit
        btnCoverHelp.contentMode = .scaleAspectFit

        let size = 38
        let gap = 15

        btnCoverAdd.snp.makeConstraints { x in
            x.centerY.equalTo(box.snp.top)
            x.left.equalTo(box.snp.left).offset(15)
            x.width.equalTo(size)
            x.height.equalTo(size)
        }
        btnCoverRefresh.snp.makeConstraints { x in
            x.centerY.equalTo(box.snp.top)
            x.left.equalTo(btnCoverAdd.snp.right).offset(gap)
            x.width.equalTo(size)
            x.height.equalTo(size)
        }
        btnCoverShare.snp.makeConstraints { x in
            x.centerY.equalTo(box.snp.top)
            x.left.equalTo(btnCoverRefresh.snp.right).offset(gap)
            x.width.equalTo(size)
            x.height.equalTo(size)
        }
        btnCoverHelp.snp.makeConstraints { x in
            x.right.equalTo(box.snp.right).offset(0)
            x.top.equalTo(box.snp.top).offset(0)
            x.width.equalTo(Double(size) / 1.344)
            x.height.equalTo(Double(size) / 1.344)
        }
        buttonAdd.snp.makeConstraints { x in
            x.edges.equalTo(btnCoverAdd.snp.edges)
        }
        buttonRefresh.snp.makeConstraints { x in
            x.edges.equalTo(btnCoverRefresh.snp.edges)
        }
        buttonShare.snp.makeConstraints { x in
            x.edges.equalTo(btnCoverShare.snp.edges)
        }
        buttonHelp.snp.makeConstraints { x in
            x.edges.equalTo(btnCoverHelp.snp.edges)
        }

        buttonAdd.addTarget(self, action: #selector(eventEmitterAdd), for: .touchUpInside)
        buttonRefresh.addTarget(self, action: #selector(eventEmitterRefresh), for: .touchUpInside)
        buttonShare.addTarget(self, action: #selector(eventEmitterShare), for: .touchUpInside)
        buttonHelp.addTarget(self, action: #selector(eventEmitterHelp), for: .touchUpInside)

        addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(RepoTableViewCell.self, forCellReuseIdentifier: cellidentity)
        tableView.isScrollEnabled = false
        tableView.snp.makeConstraints { x in
            x.top.equalTo(btnCoverAdd.snp.bottom).offset(30)
            x.bottom.equalTo(box.snp.bottom).offset(-8)
            x.left.equalTo(box.snp.left).offset(8)
            x.right.equalTo(box.snp.right).offset(-8)
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(eventEmitterReloadDataSource),
                                               name: RepositoryCenter.registrationUpdate,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: Button Touches Events

extension RepoCard {
    @objc
    func eventEmitterReloadDataSource() {
        dataSourceReloadThrottle.throttle { [weak self] in
            let dataSource = RepositoryCenter
                .default
                .obtainRepositoryUrls(sortedByName: true)
            self?.dataSourceCache = dataSource
            self?.tableView.reloadData()
        }
    }

    @objc
    func eventEmitterAdd() {
        buttonAdd.shineAnimation()
        if let action = actionOverride[.add] {
            action()
            return
        }
        // because of a bug in large title
        let target = RepoAddViewController()
        target.modalPresentationStyle = .formSheet
        target.modalTransitionStyle = .coverVertical
        var presenter = window?.rootViewController
        while let next = presenter?.presentedViewController {
            presenter = next
        }
        presenter?.present(target, animated: true, completion: nil)
    }

    @objc
    func eventEmitterRefresh() {
        buttonRefresh.shineAnimation()
        if let date = lastUpdateTouched,
           abs(date.timeIntervalSinceNow) < 2
        {
            RepositoryCenter.default.dispatchForceUpdateRequestOnAll()
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .RepositoryQueueChanged, object: nil)
            }
        } else {
            if !RepositoryCenter.default.dispatchSmartUpdateRequestOnAll() {
                SPIndicator.present(title: NSLocalizedString("NO_UPDATE_REQUIRED", comment: "No Update Required"),
                                    message: NSLocalizedString("DO_AGAIN_TO_FORCE_RELOAD", comment: "Do again to force reload"),
                                    preset: .done,
                                    from: .top,
                                    completion: nil)
            } else {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .RepositoryQueueChanged, object: nil)
                }
            }
        }
        lastUpdateTouched = Date()
    }

    @objc
    func eventEmitterShare() {
        buttonShare.shineAnimation()

        let shareContent = RepositoryCenter
            .default
            .obtainRepositoryUrls()
            .map(\.absoluteString)
            .joined(separator: "\n")
        var target: UIViewController
        if shareContent.count > 0 {
            if InterfaceBridge.enableShareSheet {
                let activityViewController = UIActivityViewController(activityItems: [shareContent],
                                                                      applicationActivities: nil)
                activityViewController
                    .popoverPresentationController?
                    .sourceView = buttonShare
                target = activityViewController
            } else {
                UIPasteboard.general.string = shareContent
                SPIndicator.present(title: NSLocalizedString("COPIED", comment: "Cpoied"),
                                    message: nil,
                                    preset: .done,
                                    haptic: .success,
                                    from: .top,
                                    completion: nil)
                return
            }
        } else {
            let alert = UIAlertController(title: "ヽ(*。>Д<)o゜", defaultActionButtonTitle: "✧(≖ ◡ ≖✿)")
            target = alert
        }
        window?
            .topMostViewController?
            .present(next: target)
    }

    @objc
    func eventEmitterHelp() {
        let target = RamLogController()
        window?.topMostViewController?.present(next: target)
    }
}

// MARK: TABLE VIEW

extension RepoCard: UITableViewDataSource, UITableViewDelegate {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        dataSourceCache.count < 1 ? 1 : dataSourceCache.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView
            .dequeueReusableCell(withIdentifier: cellidentity, for: indexPath)
            as! RepoTableViewCell

        cell.prepareForNewValue()
        tableView.separatorColor = .clear
        tableView.backgroundColor = .clear

        if dataSourceCache.count < 1 {
            cell.setNoRepoAvailable()
        } else {
            let url = dataSourceCache[indexPath.row]
            cell.setRepository(withUrl: url)
        }

        return cell
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        cellHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if dataSourceCache.count > 0 {
            let value = dataSourceCache[indexPath.row]
            guard let repo = RepositoryCenter
                .default
                .obtainImmutableRepository(withUrl: value)
            else {
                return
            }
            let target = RepoDetailController(withRepo: repo)
            parentViewController?.present(next: target)
        }
    }

    func tableView(_: UITableView, trailingSwipeActionsConfigurationForRowAt index: IndexPath) -> UISwipeActionsConfiguration? {
        if dataSourceCache.count < 1 { return nil }
        let deleteItem = UIContextualAction(style: .destructive, title: "Delete".localized()) { _, _, _ in
            if self.dataSourceCache.count < 1 { return }
            let url = self.dataSourceCache[index.row]
            self.dataSourceCache.remove(at: index.row)
            if self.dataSourceCache.count == 0 {
                self.tableView.reloadData()
            } else {
                self.tableView.deleteRows(at: [index], with: .automatic)
            }
            SPIndicator.present(title: NSLocalizedString("DELETED", comment: "Deleted"), preset: .done)
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                PaymentManager.shared.deleteSignInRecord(for: url) // delete this first
                RepositoryCenter.default.deleteRepository(withUrl: url)
            }
        }
        deleteItem.backgroundColor = UIColor(hex: 0xFA685C)
        let reloadItem = UIContextualAction(style: .normal, title: "Refresh".localized()) { _, _, _ in
            if self.dataSourceCache.count < 1 { return }
            let url = self.dataSourceCache[index.row]
            RepositoryCenter.default.dispatchUpdateOnRepository(withUrl: url)
            self.tableView.setEditing(false, animated: true)
            SPIndicator.present(title: NSLocalizedString("QUEUED", comment: "Queued"), preset: .done)
        }
        reloadItem.backgroundColor = UIColor(hex: 0x7A95DF)
        return UISwipeActionsConfiguration(actions: [reloadItem, deleteItem])
    }

    func tableView(_: UITableView, leadingSwipeActionsConfigurationForRowAt index: IndexPath) -> UISwipeActionsConfiguration? {
        if dataSourceCache.count < 1 { return nil }
        let copyItem = UIContextualAction(style: .normal, title: "Share".localized()) { _, _, _ in
            if self.dataSourceCache.count < 1 { return }
            let url = self.dataSourceCache[index.row]
            UIPasteboard.general.string = url.absoluteString
            self.tableView.setEditing(false, animated: true)
            SPIndicator.present(title: NSLocalizedString("COPIED", comment: "Copied"), preset: .done)
        }
        copyItem.backgroundColor = UIColor(hex: 0xBA82D0)
        return UISwipeActionsConfiguration(actions: [copyItem])
    }
}
