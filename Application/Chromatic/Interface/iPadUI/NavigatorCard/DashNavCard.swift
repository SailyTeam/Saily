//
//  DashNavCard.swift
//  Chromatic
//
//  Created by Lakr Aream on 2020/4/18.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import AptRepository
import UIKit

private let kCardSelectNotificationBlockDashboard = {
    NotificationCenter.default.post(name: .LXMainControllerSwitchDashboard, object: nil)
}

private let kCardSelectNotificationBlockSettings = {
    NotificationCenter.default.post(name: .LXMainControllerSwitchSettings, object: nil)
}

private let kCardSelectNotificationBlockTasks = {
    NotificationCenter.default.post(name: .LXMainControllerSwitchTasks, object: nil)
}

private let kCardSelectNotificationBlockInstalled = {
    NotificationCenter.default.post(name: .LXMainControllerSwitchInstalled, object: nil)
}

class DashNavCard: UIView {
    private let dashCard = DashNavCardInstance(text: NSLocalizedString("DASHBOARD", comment: "Dashboard"),
                                               selectIconName: "DashNAV.DashboardSelected",
                                               selectBackgroundColor: UIColor(named: "DashNAV.DashboardSelectedColor")!,
                                               unselectIconName: "DashNAV.DashboardUnselected",
                                               defaultSelected: true)

    private let settCard = DashNavCardInstance(text: NSLocalizedString("SETTINGS", comment: "Settings"),
                                               selectIconName: "DashNAV.SettingSelected",
                                               selectBackgroundColor: UIColor(named: "DashNAV.SettingSelectedColor")!,
                                               unselectIconName: "DashNAV.SettingUnselected",
                                               defaultSelected: false)

    private let taskCard = DashNavCardInstance(text: NSLocalizedString("TASKS", comment: "Tasks"),
                                               selectIconName: "DashNAV.TaskSelected",
                                               selectBackgroundColor: UIColor(named: "DashNAV.TaskSelectedColor")!,
                                               unselectIconName: "DashNAV.TaskUnselected",
                                               defaultSelected: false)

    private let instCard = DashNavCardInstance(text: NSLocalizedString("INSTALLED", comment: "Installed"),
                                               selectIconName: "DashNAV.InstalledSelected",
                                               selectBackgroundColor: UIColor(named: "DashNAV.InstalledSelectedColor")!,
                                               unselectIconName: "DashNAV.InstalledUnselected",
                                               defaultSelected: false)

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    required init() {
        super.init(frame: CGRect())

        addSubview(dashCard)
        dashCard.setTouchEvent { [weak self] in
            self?.selectDash()
            kCardSelectNotificationBlockDashboard()
        }
        dashCard.snp.makeConstraints { x in
            x.top.equalTo(self.snp.top).offset(8)
            x.leading.equalTo(self.snp.leading)
            x.bottom.equalTo(self.snp.centerY).offset(-8)
            x.trailing.equalTo(self.snp.centerX).offset(-8)
        }

        addSubview(settCard)
        settCard.setTouchEvent { [weak self] in
            self?.selectSetting()
            kCardSelectNotificationBlockSettings()
        }
        settCard.snp.makeConstraints { x in
            x.top.equalTo(self.snp.top).offset(8)
            x.leading.equalTo(self.snp.centerX).offset(8)
            x.bottom.equalTo(self.snp.centerY).offset(-8)
            x.trailing.equalTo(self.snp.trailing)
        }

        addSubview(taskCard)
        taskCard.setTouchEvent { [weak self] in
            self?.selectTask()
            kCardSelectNotificationBlockTasks()
        }
        taskCard.snp.makeConstraints { x in
            x.top.equalTo(self.snp.centerY).offset(8)
            x.leading.equalTo(self.snp.leading)
            x.bottom.equalTo(self.snp.bottom).offset(-8)
            x.trailing.equalTo(self.snp.centerX).offset(-8)
        }

        addSubview(instCard)
        instCard.setTouchEvent { [weak self] in
            self?.selectInstalled()
            kCardSelectNotificationBlockInstalled()
        }
        instCard.snp.makeConstraints { x in
            x.top.equalTo(self.snp.centerY).offset(8)
            x.leading.equalTo(self.snp.centerX).offset(8)
            x.bottom.equalTo(self.snp.bottom).offset(-8)
            x.trailing.equalTo(self.snp.trailing)
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateTaskCardBadgeText),
                                               name: .TaskContainerChanged,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateAvailableUpdateBadge),
                                               name: PackageCenter.packageRecordChanged,
                                               object: nil)

        updateTaskCardBadgeText()
        updateAvailableUpdateBadge()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func selectDash() {
        dashCard.select()
        settCard.deselecte()
        taskCard.deselecte()
        instCard.deselecte()
    }

    func selectSetting() {
        dashCard.deselecte()
        settCard.select()
        taskCard.deselecte()
        instCard.deselecte()
    }

    func selectTask() {
        dashCard.deselecte()
        settCard.deselecte()
        taskCard.select()
        instCard.deselecte()
    }

    func selectInstalled() {
        dashCard.deselecte()
        settCard.deselecte()
        taskCard.deselecte()
        instCard.select()
    }

    @objc private
    func updateTaskCardBadgeText() {
        taskCard.badgeText = String(TaskManager.shared.obtainTaskCount())
    }

    @objc private
    func updateAvailableUpdateBadge() {
        DispatchQueue.global().async {
            let count = InterfaceBridge.availableUpdateCount()
            DispatchQueue.main.async { [self] in
                if count > 0 {
                    instCard.badgeText = String(count)
                } else {
                    instCard.badgeText = "" // for animation
                }
            }
        }
    }
}
