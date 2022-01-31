//
//  SettingRepo.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/28.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import DropDown
import UIKit

private struct TimeIntervalDropDownOption {
    let text: String
    let interval: Int
    init(interval: Int) {
        self.interval = interval
        text = TimeInterval(interval).format(using: [.day, .hour, .minute, .second])!
    }
}

private let smartUpdateAvailableOptions: [TimeIntervalDropDownOption] = [
    .init(interval: 1800), // 30 min
    .init(interval: 3600), // 1 hour
    .init(interval: 21600), // 6 hour
    .init(interval: 43200), // 12 hour
    .init(interval: 86400), // 1 day
    .init(interval: 172_800), // 2 day
    .init(interval: 259_200), // 3 day
    .init(interval: 604_800), // 7 day
    .init(interval: 1_296_000), // 15 day
]

private let timeoutAvailableOptions: [TimeIntervalDropDownOption] = [
    .init(interval: 5), // 5 second
    .init(interval: 10), // 10 second
    .init(interval: 30), // 30 second
    .init(interval: 60), // 1 min
    .init(interval: 120), // 2 min
    .init(interval: 180), // 3 min
    .init(interval: 600), // 10 min
]

extension SettingView {
    func setupRepo(anchor: inout UIView, safeAnchor: UIView) {
        let label1 = UILabel()
        label1.font = .systemFont(ofSize: 18, weight: .semibold)
        label1.text = NSLocalizedString("SOFTWARE_SOURCES", comment: "Software Sources")
        addSubview(label1)
        label1.snp.makeConstraints { x in
            x.left.equalTo(safeAnchor)
            x.right.equalTo(safeAnchor)
            x.top.equalTo(anchor.snp.bottom).offset(10)
            x.height.equalTo(40)
        }
        anchor = label1

        let groupEffect1 = UIView()
        groupEffect1.backgroundColor = UIColor(named: "CARD_BACKGROUND")
        groupEffect1.layer.cornerRadius = 12
//        groupEffect1.dropShadow()
        let repoLogin = SettingElement(iconSystemNamed: "person.crop.square.fill",
                                       text: NSLocalizedString("MANAGE_ACCOUNT_INFO", comment: "Manage Account Info"),
                                       dataType: .submenuWithAction, initData: nil) { _, _ in
            self.parentViewController?.present(next: RepoAccountController())
        }
        let repoDownloadLimit = SettingElement(iconSystemNamed: "link",
                                               text: NSLocalizedString("CONCURRENT_DOWNLOAD", comment: "Concurrent Download"),
                                               dataType: .dropDownWithString,
                                               initData: {
                                                   String(RepositoryCenter.default.updateConcurrencyLimit)
                                               }) { _, anchor in
            let range = [Int](1 ... 16)
            let dropDown = DropDown()
            dropDown.dataSource = range
                .map { "⁠\u{200b}   " + String($0) + "⁠   \u{200b}" }
            dropDown.anchorView = anchor
            dropDown.selectionAction = { (index: Int, _: String) in
                RepositoryCenter.default.updateConcurrencyLimit = range[index]
                self.dispatchValueUpdate()
            }
            dropDown.show(onTopOf: self.window)
        }
        let repoDownloadTimeout = SettingElement(iconSystemNamed: "timer",
                                                 text: NSLocalizedString("NETWORK_TIMEOUT", comment: "Network Timeout"),
                                                 dataType: .dropDownWithString,
                                                 initData: {
                                                     let intval: Int = RepositoryCenter.default.networkingTimeout
                                                     return TimeInterval(intval)
                                                         .format(using: [.minute, .second]) ?? "0"
                                                 }) { _, anchor in
            let dropDown = DropDown()
            let actions = timeoutAvailableOptions
            dropDown.dataSource = actions
                .map(\.text)
                .invisibleSpacePadding()
            dropDown.anchorView = anchor
            dropDown.selectionAction = { (index: Int, _: String) in
                RepositoryCenter.default.networkingTimeout = actions[index].interval
                self.dispatchValueUpdate()
            }
            dropDown.show(onTopOf: self.window)
        }

        let repoRefreshTimeGap = SettingElement(iconSystemNamed: "wand.and.stars",
                                                text: NSLocalizedString("SMART_UPDATE", comment: "Smart Update"),
                                                dataType: .dropDownWithString,
                                                initData: {
                                                    let intval: Int = RepositoryCenter.default.smartUpdateTimeInterval
                                                    return TimeInterval(intval)
                                                        .format(using: [.day, .hour, .minute]) ?? "0"
                                                }) { _, anchor in
            let dropDown = DropDown()
            let actions = smartUpdateAvailableOptions
            dropDown.dataSource = actions
                .map(\.text)
                .invisibleSpacePadding()
            dropDown.anchorView = anchor
            dropDown.selectionAction = { (index: Int, _: String) in
                RepositoryCenter.default.smartUpdateTimeInterval = actions[index].interval
                self.dispatchValueUpdate()
            }
            dropDown.show(onTopOf: self.window)
        }
        let repoHistoryReocrd = SettingElement(iconSystemNamed: "purchased.circle",
                                               text: NSLocalizedString("ENABLE_HISTORY", comment: "Enable History"),
                                               dataType: .switcher,
                                               initData: {
                                                   RepositoryCenter.default.historyRecordsEnabled ? "YES" : "NO"
                                               }) { changeToOpen, _ in
            if changeToOpen ?? false {
                RepositoryCenter.default.historyRecordsEnabled = true
                self.dispatchValueUpdate()
            } else {
                let alert = UIAlertController(title: "⚠️",
                                              message: NSLocalizedString("DISABLE_HISTORY_RECORD_WILL_DELETE_PREVIOUS_HISTORY_REOCRDS",
                                                                         comment: "Disable history record will delete previous history records"),
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("CONFIRM", comment: "Confirm"),
                                              style: .destructive,
                                              handler: { _ in
                                                  RepositoryCenter.default.historyRecordsEnabled = false
                                                  self.dispatchValueUpdate()
                                              }))
                alert.addAction(UIAlertAction(title: NSLocalizedString("CANCEL", comment: "Cancel"),
                                              style: .cancel,
                                              handler: { _ in
                                                  self.dispatchValueUpdate()
                                              }))
                self.parentViewController?.present(alert, animated: true, completion: nil)
            }
        }

        addSubview(groupEffect1)
        addSubview(repoLogin)
        addSubview(repoDownloadLimit)
        addSubview(repoDownloadTimeout)
        addSubview(repoRefreshTimeGap)
        addSubview(repoHistoryReocrd)
        repoLogin.snp.makeConstraints { x in
            makeElement(constraint: x, widthAnchor: safeAnchor, topAnchor: anchor)
        }
        anchor = repoLogin
        repoDownloadLimit.snp.makeConstraints { x in
            makeElement(constraint: x, widthAnchor: safeAnchor, topAnchor: anchor)
        }
        anchor = repoDownloadLimit
        repoDownloadTimeout.snp.makeConstraints { x in
            makeElement(constraint: x, widthAnchor: safeAnchor, topAnchor: anchor)
        }
        anchor = repoDownloadTimeout
        repoRefreshTimeGap.snp.makeConstraints { x in
            makeElement(constraint: x, widthAnchor: safeAnchor, topAnchor: anchor)
        }
        anchor = repoRefreshTimeGap
        repoHistoryReocrd.snp.makeConstraints { x in
            makeElement(constraint: x, widthAnchor: safeAnchor, topAnchor: anchor)
        }
        anchor = repoHistoryReocrd
        groupEffect1.snp.makeConstraints { x in
            x.left.equalTo(safeAnchor.snp.left)
            x.right.equalTo(safeAnchor.snp.right)
            x.top.equalTo(repoLogin.snp.top).offset(-12)
            x.bottom.equalTo(anchor.snp.bottom).offset(16)
        }
        anchor = groupEffect1
    }
}
