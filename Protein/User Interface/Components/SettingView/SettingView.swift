//
//  SettingView.swift
//  Protein
//
//  Created by Lakr Aream on 2020/7/13.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit
import LTMorphingLabel
import DropDown
import JGProgressHUD

class SettingView: UIView {

    private let container = UIScrollView()
    private let safeAnchor = UIView()
    private var lastAnchor: UIView?
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    required init() {
        super.init(frame: CGRect())
        
        addSubview(container)
        container.snp.makeConstraints { (x) in
            x.edges.equalToSuperview()
        }
        
        container.showsVerticalScrollIndicator = false
        container.showsHorizontalScrollIndicator = false
        container.decelerationRate = .fast
        
        container.addSubview(safeAnchor)
        safeAnchor.snp.makeConstraints { (x) in
            x.left.equalTo(self).offset(28)
            x.right.equalTo(self).offset(-28)
            x.top.equalTo(self.container.snp.top).offset(80)
            x.height.equalTo(1)
        }
        var anchor = safeAnchor
        
        let label00 = UILabel(frame: CGRect())
        label00.font = .systemFont(ofSize: 26, weight: .bold)
        label00.text = "Settings".localized()
        container.addSubview(label00)
        label00.snp.makeConstraints { (x) in
            x.left.equalTo(self.safeAnchor)
            x.right.equalTo(self.safeAnchor)
            x.top.equalTo(anchor.snp.bottom)
            x.height.equalTo(60)
        }
        anchor = label00
        
// MARK: DEVICE INFO
        
        let label0 = UILabel()
        label0.font = .systemFont(ofSize: 22, weight: .semibold)
        label0.text = "DeviceInfo".localized()
        container.addSubview(label0)
        label0.snp.makeConstraints { (x) in
            x.left.equalTo(self.safeAnchor)
            x.right.equalTo(self.safeAnchor)
            x.top.equalTo(anchor.snp.bottom)
            x.height.equalTo(60)
        }
        anchor = label0

        let groupEffect0 = UIView()
        groupEffect0.backgroundColor = UIColor(named: "G-Background-Cell")
        groupEffect0.layer.cornerRadius = 12
        groupEffect0.dropShadow()
        let deviceInfo = SettingSectionView(iconSystemNamed: "info.circle",
                                            text: UIDevice.current.identifierHumanReadable,
                                            dataType: .none, initData: nil) { (_, _) in }
        let systemVersion = SettingSectionView(iconSystemNamed: "",
                                            text: UIDevice.current.systemName + " - " + UIDevice.current.systemVersion,
                                            dataType: .none, initData: nil) { (_, _) in }

        let udid = UDIDSection(iconSystemNamed: "",
                                      text: ConfigManager.shared.CydiaConfig.udid.uppercased(),
                                      dataType: .none, initData:nil) { (_, _) in }
        let enableRandomDeviceInfo = SettingSectionView(iconSystemNamed: "eye.slash",
                                                        text: "EnableRandomDeviceInfo".localized(),
                                                        dataType: .switcher, initData: {
                                                            return ConfigManager.shared.CydiaConfig.mess ? "1" : "0"
        }) { (isOn, _) in
            if let value = isOn {
                if value {
                    let alert = UIAlertController(title: "Warning".localized(), message: "EnableRandomDeviceInfoWarning".localized(), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Confirm".localized(), style: .destructive, handler: { (_) in
                        ConfigManager.shared.CydiaConfig.mess = true
                        NotificationCenter.default.post(name: .SettingsUpdated, object: nil)
                    }))
                    alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: { (_) in
                        ConfigManager.shared.CydiaConfig.mess = false
                        NotificationCenter.default.post(name: .SettingsUpdated, object: nil)
                    }))
                    self.obtainParentViewController?.present(alert, animated: true, completion: nil)
                } else {
                    ConfigManager.shared.CydiaConfig.mess = false
                }
            }
        }
        container.addSubview(groupEffect0)
        container.addSubview(deviceInfo)
        container.addSubview(systemVersion)
        container.addSubview(udid)
        container.addSubview(enableRandomDeviceInfo)
        deviceInfo.snp.makeConstraints { (x) in
            x.left.equalTo(self.safeAnchor.snp.left).offset(8)
            x.right.equalTo(self.safeAnchor.snp.right).offset(-8)
            x.top.equalTo(anchor.snp.bottom).offset(18)
            x.height.equalTo(28)
        }
        anchor = deviceInfo
        systemVersion.snp.makeConstraints { (x) in
            x.left.equalTo(self.safeAnchor.snp.left).offset(8)
            x.right.equalTo(self.safeAnchor.snp.right).offset(-8)
            x.top.equalTo(anchor.snp.bottom).offset(18)
            x.height.equalTo(28)
        }
        anchor = systemVersion
        udid.snp.makeConstraints { (x) in
            x.left.equalTo(self.safeAnchor.snp.left).offset(8)
            x.right.equalTo(self.safeAnchor.snp.right).offset(-8)
            x.top.equalTo(anchor.snp.bottom).offset(18)
            x.height.equalTo(28)
        }
        anchor = udid
        enableRandomDeviceInfo.snp.makeConstraints { (x) in
            x.left.equalTo(self.safeAnchor.snp.left).offset(8)
            x.right.equalTo(self.safeAnchor.snp.right).offset(-8)
            x.top.equalTo(anchor.snp.bottom).offset(18)
            x.height.equalTo(28)
        }
        anchor = enableRandomDeviceInfo
        groupEffect0.snp.makeConstraints { (x) in
            x.left.equalTo(self.safeAnchor.snp.left)
            x.right.equalTo(self.safeAnchor.snp.right)
            x.top.equalTo(deviceInfo.snp.top).offset(-12)
            x.bottom.equalTo(anchor.snp.bottom).offset(16)
        }
        anchor = groupEffect0
        
        
// MARK: REPOS
        
        let label1 = UILabel()
        label1.font = .systemFont(ofSize: 22, weight: .semibold)
        label1.text = "SoftwareSources".localized()
        container.addSubview(label1)
        label1.snp.makeConstraints { (x) in
            x.left.equalTo(self.safeAnchor)
            x.right.equalTo(self.safeAnchor)
            x.top.equalTo(anchor.snp.bottom)
            x.height.equalTo(60)
        }
        anchor = label1
        
        let groupEffect1 = UIView()
        groupEffect1.backgroundColor = UIColor(named: "G-Background-Cell")
        groupEffect1.layer.cornerRadius = 12
        groupEffect1.dropShadow()
        let repoLogin = SettingSectionView(iconSystemNamed: "person.crop.square.fill",
                                           text: "RepoLoginHint".localized(),
                                           dataType: .submenuWithAction, initData: nil) { (_, _) in
                                            let pop = RepoPaymentViewController()
                                            pop.modalPresentationStyle = .formSheet
                                            pop.modalTransitionStyle = .coverVertical
                                            self.obtainParentViewController?.present(pop, animated: true, completion: nil)
        }
        let repoDownloadLimit = SettingSectionView(iconSystemNamed: "link",
                                                   text: "RepoDownloadLimit".localized(),
                                           dataType: .dropDownWithString,
                                           initData: {
                                            return String(ConfigManager.shared.Networking.maxRepoUpdateQueueNumber)
        }) { (_, _) in
            let alertController = UIAlertController(title: "EnterNumber".localized(), message: "", preferredStyle: .alert)
            alertController.addTextField { textField in
                textField.placeholder = "Number".localized()
                textField.isSecureTextEntry = false
                textField.keyboardType = .numberPad
            }
            let confirmAction = UIAlertAction(title: "Confirm".localized(), style: .default) { [weak alertController] _ in
                guard let alertController = alertController, let text = alertController.textFields?.first?.text else { return }
                if let value = Int(text), value > 0 && value <= 24 {
                    ConfigManager.shared.Networking.maxRepoUpdateQueueNumber = value
                    NotificationCenter.default.post(name: .SettingsUpdated, object: nil)
                } else {
                    let alert = UIAlertController(title: "Warning".localized(), message: "DownloadQueueNumberMinMax".localized(), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Confirm".localized(), style: .default, handler: { (_) in
                    }))
                    self.obtainParentViewController?.present(alert, animated: true, completion: nil)
                }
            }
            alertController.addAction(confirmAction)
            let cancelAction = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            self.obtainParentViewController?.present(alertController, animated: true, completion: nil)
        }
        let repoDownloadTimeout = SettingSectionView(iconSystemNamed: "timer",
                                                     text: "RepoDownloadTimeLimit".localized(),
                                           dataType: .dropDownWithString,
                                           initData: {
                                            return String(ConfigManager.shared.Networking.maxWaitTimeToDownloadRepo)
        }) { (_, _) in
            let alertController = UIAlertController(title: "EnterNumber".localized(), message: "", preferredStyle: .alert)
            alertController.addTextField { textField in
                textField.placeholder = "Number".localized()
                textField.isSecureTextEntry = false
                textField.keyboardType = .numberPad
            }
            let confirmAction = UIAlertAction(title: "Confirm".localized(), style: .default) { [weak alertController] _ in
                guard let alertController = alertController, let text = alertController.textFields?.first?.text else { return }
                if let value = Int(text), value >= 6 && value <= 180 {
                    ConfigManager.shared.Networking.maxWaitTimeToDownloadRepo = value
                    NotificationCenter.default.post(name: .SettingsUpdated, object: nil)
                } else {
                    let alert = UIAlertController(title: "Warning".localized(), message: "DownloadWaitMinMax".localized(), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Confirm".localized(), style: .default, handler: { (_) in
                    }))
                    self.obtainParentViewController?.present(alert, animated: true, completion: nil)
                }
            }
            alertController.addAction(confirmAction)
            let cancelAction = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            self.obtainParentViewController?.present(alertController, animated: true, completion: nil)
        }
        
        let repoRefreshTimeGap = SettingSectionView(iconSystemNamed: "wand.and.stars",
                                                     text: "RepoRefreshTimeGap".localized(),
                                           dataType: .dropDownWithString,
                                           initData: {
                                            let intval: Int = ConfigManager.shared.Application.smartRefreshTimeGapInMin
                                            let get: Double = Double(intval * 10) / 600
                                            var str = String(get)
                                            if str.hasSuffix(".0") {
                                                str.removeLast(2)
                                            }
                                            return String(str + " " + "Hours".localized())
        }) { (_, _) in
            let alertController = UIAlertController(title: "EnterNumber".localized(), message: "", preferredStyle: .alert)
            alertController.addTextField { textField in
                textField.placeholder = "Number".localized()
                textField.isSecureTextEntry = false
                textField.keyboardType = .numberPad
            }
            let confirmAction = UIAlertAction(title: "Confirm".localized(), style: .default) { [weak alertController] _ in
                guard let alertController = alertController, let text = alertController.textFields?.first?.text else { return }
                if let value = Double(text), value >= 0.5 && value <= 240 {
                    ConfigManager.shared.Application.smartRefreshTimeGapInMin = Int(value * 60)
                    NotificationCenter.default.post(name: .SettingsUpdated, object: nil)
                } else {
                    let alert = UIAlertController(title: "Warning".localized(), message: "RepoRefreshTimeGapMinMax".localized(), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Confirm".localized(), style: .default, handler: { (_) in
                    }))
                    self.obtainParentViewController?.present(alert, animated: true, completion: nil)
                }
            }
            alertController.addAction(confirmAction)
            let cancelAction = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            self.obtainParentViewController?.present(alertController, animated: true, completion: nil)
        }
        let repoHistoryReocrd = SettingSectionView(iconSystemNamed: "purchased.circle",
                                            text: "AllowRepoHistory".localized(),
                                            dataType: .switcher,
                                            initData: {
                                                return ConfigManager.shared.Application.shouldSaveRepoRecord ? "1" : "0"
        }) { (isOn, _) in
            if let value = isOn {
                if !value {
                    let alert = UIAlertController(title: "Warning".localized(), message: "DeleteRepoHistory".localized(), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Confirm".localized(), style: .destructive, handler: { (_) in
                        ConfigManager.shared.Application.shouldSaveRepoRecord = false
                        let _ = RepoManager.shared.getHistory()
                        NotificationCenter.default.post(name: .SettingsUpdated, object: nil)
                    }))
                    alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: { (_) in
                        ConfigManager.shared.Application.shouldSaveRepoRecord = true
                        NotificationCenter.default.post(name: .SettingsUpdated, object: nil)
                    }))
                    self.obtainParentViewController?.present(alert, animated: true, completion: nil)
                } else {
                    ConfigManager.shared.Application.shouldSaveRepoRecord = true
                }
            }
        }
        let repoReport = SettingSectionView(iconSystemNamed: "heart",
                                            text: "AllowReportRepos".localized(),
                                            dataType: .switcher,
                                            initData: {
                                                return ConfigManager.shared.Application.shouldUploadRepoAnalysis ? "1" : "0"
        }) { (isOn, _) in
            
        }
        repoReport.setSwitcherUnavailable()

        container.addSubview(groupEffect1)
        container.addSubview(repoLogin)
        container.addSubview(repoDownloadLimit)
        container.addSubview(repoDownloadTimeout)
        container.addSubview(repoRefreshTimeGap)
        container.addSubview(repoHistoryReocrd)
        container.addSubview(repoReport)
        repoLogin.snp.makeConstraints { (x) in
            x.left.equalTo(self.safeAnchor.snp.left).offset(8)
            x.right.equalTo(self.safeAnchor.snp.right).offset(-8)
            x.top.equalTo(anchor.snp.bottom).offset(18)
            x.height.equalTo(28)
        }
        anchor = repoLogin
        repoDownloadLimit.snp.makeConstraints { (x) in
            x.left.equalTo(self.safeAnchor.snp.left).offset(8)
            x.right.equalTo(self.safeAnchor.snp.right).offset(-8)
            x.top.equalTo(anchor.snp.bottom).offset(18)
            x.height.equalTo(28)
        }
        anchor = repoDownloadLimit
        repoDownloadTimeout.snp.makeConstraints { (x) in
            x.left.equalTo(self.safeAnchor.snp.left).offset(8)
            x.right.equalTo(self.safeAnchor.snp.right).offset(-8)
            x.top.equalTo(anchor.snp.bottom).offset(18)
            x.height.equalTo(28)
        }
        anchor = repoDownloadTimeout
        repoRefreshTimeGap.snp.makeConstraints { (x) in
            x.left.equalTo(self.safeAnchor.snp.left).offset(8)
            x.right.equalTo(self.safeAnchor.snp.right).offset(-8)
            x.top.equalTo(anchor.snp.bottom).offset(18)
            x.height.equalTo(28)
        }
        anchor = repoRefreshTimeGap
        repoHistoryReocrd.snp.makeConstraints { (x) in
            x.left.equalTo(self.safeAnchor.snp.left).offset(8)
            x.right.equalTo(self.safeAnchor.snp.right).offset(-8)
            x.top.equalTo(anchor.snp.bottom).offset(18)
            x.height.equalTo(28)
        }
        anchor = repoHistoryReocrd
        repoReport.snp.makeConstraints { (x) in
            x.left.equalTo(self.safeAnchor.snp.left).offset(8)
            x.right.equalTo(self.safeAnchor.snp.right).offset(-8)
            x.top.equalTo(anchor.snp.bottom).offset(18)
            x.height.equalTo(28)
        }
        anchor = repoReport
        groupEffect1.snp.makeConstraints { (x) in
            x.left.equalTo(self.safeAnchor.snp.left)
            x.right.equalTo(self.safeAnchor.snp.right)
            x.top.equalTo(repoLogin.snp.top).offset(-12)
            x.bottom.equalTo(anchor.snp.bottom).offset(16)
        }
        anchor = groupEffect1
        
// MARK: PACKAGES
        
        let label2 = UILabel()
        label2.font = .systemFont(ofSize: 22, weight: .semibold)
        label2.text = "SoftwareBehaves".localized()
        container.addSubview(label2)
        label2.snp.makeConstraints { (x) in
            x.left.equalTo(self.safeAnchor)
            x.right.equalTo(self.safeAnchor)
            x.top.equalTo(anchor.snp.bottom).offset(12)
            x.height.equalTo(60)
        }
        anchor = label2
        
        let groupEffect2 = UIView()
        groupEffect2.backgroundColor = UIColor(named: "G-Background-Cell")
        groupEffect2.layer.cornerRadius = 12
        groupEffect2.dropShadow()
        let openDownloadedPackages = SettingSectionView(iconSystemNamed: "tray.full",
                                                       text: "OpenDownload".localized(),
                                                       dataType: .submenuWithAction, initData: nil) { (_, _) in
                                                        let urlString = "filza://" + TaskManager.shared.downloadManager.downloadedContainerLocation
                                                        if let url = URL(string: urlString) {
                                                            UIApplication.shared.open(url, options: [:]) { (did) in
                                                                if !did {
                                                                    let alert = UIAlertController(title: "Error".localized(),
                                                                                                  message: "FilzaRequiredAlert".localized(),
                                                                                                  preferredStyle: .alert)
                                                                    alert.addAction(UIAlertAction(title: "Dismiss".localized(),
                                                                                                  style: .default, handler: nil))
                                                                    self.obtainParentViewController?.present(alert, animated: true, completion: nil)
                                                                }
                                                            }
                                                        }
        }
        let cleanAllDownload = SettingSectionView(iconSystemNamed: "trash",
                                                       text: "DeleteAllDownload".localized(),
                                                       dataType: .dropDownWithString, initData: {
                                                        var read: String?
                                                        let sem = DispatchSemaphore(value: 0)
                                                        DispatchQueue.global(qos: .background).async {
                                                            let url = URL(fileURLWithPath: TaskManager.shared.downloadManager.downloadedContainerLocation)
                                                            if let size = FileManager.default.directorySize(url) {
                                                                read = String(size / 1024 / 1024) + " MB"
                                                            }
                                                            sem.signal()
                                                        }
                                                        let timeout = sem.wait(timeout: .now() + 1)
                                                        if let size = read {
                                                            return size
                                                        }
                                                        if timeout == .timedOut {
                                                            return "DownloadSizeCalculateTimeout".localized()
                                                        }
                                                        return "UnknownSize".localized()
        }) { (_, dropDownAnchor) in
            NotificationCenter.default.post(name: .SettingsUpdated, object: nil)
            let dropDown = DropDown()
            let actionSource = ["DeleteAllDownload", "Cancel"]
            dropDown.dataSource = actionSource.map({ (str) -> String in
               return "   " + str.localized()
            })
            dropDown.anchorView = dropDownAnchor
            dropDown.selectionAction = { (index: Int, _: String) in
               if actionSource[index] == "DeleteAllDownload" {
                   TaskManager.shared.downloadManager.deleteEverything()
                   NotificationCenter.default.post(name: .SettingsUpdated, object: nil)
               }
            }
            dropDown.show(onTopOf: self.window)
        }
        let softwareAutoUpdateWhenLaunch = SettingSectionView(iconSystemNamed: "paperplane",
                                                              text: "SoftwareAutoUpdateWhenLaunch".localized(),
                                                              dataType: .switcher,
                                                              initData: {
                                                                return ConfigManager.shared.Application.shouldAutoUpdateWhenAppLaunch ? "1" : "0"
        }) { (isOn, _) in
            if let val = isOn {
                ConfigManager.shared.Application.shouldAutoUpdateWhenAppLaunch = val
                NotificationCenter.default.post(name: .SettingsUpdated, object: nil)
            }
        }
        let softwareUpdateNotify = SettingSectionView(iconSystemNamed: "bell",
                                                  text: "UpdateNotification".localized(),
                                                  dataType: .switcher,
                                                  initData: {
                                                    return ConfigManager.shared.Application.shouldNotifyWhenUpdateAvailable ? "1" : "0"
        }) { (isOn, _) in
            if let val = isOn {
                ConfigManager.shared.Application.shouldNotifyWhenUpdateAvailable = val
                NotificationCenter.default.post(name: .SettingsUpdated, object: nil)
            }
        }
        let softwareReport = SettingSectionView(iconSystemNamed: "heart",
                                            text: "AllowReportSoftwares".localized(),
                                            dataType: .switcher,
                                            initData: {
                                                return ConfigManager.shared.Application.shouldUploadPackageAnalysis ? "1" : "0"
        }) { (isOn, _) in
            
        }
        let showAPTReport = SettingSectionView(iconSystemNamed: "exclamationmark.bubble",
                                            text: "ShowAPTReportSection".localized(),
                                            dataType: .switcher,
                                            initData: {
                                                return ConfigManager.shared.Application.shouldShowAPTReportSection ? "1" : "0"
        }) { (isOn, _) in
            if let val = isOn {
                ConfigManager.shared.Application.shouldShowAPTReportSection = val
                NotificationCenter.default.post(name: .SettingsUpdated, object: nil)
            }
        }
        softwareReport.setSwitcherUnavailable()
        container.addSubview(groupEffect2)
        container.addSubview(openDownloadedPackages)
        container.addSubview(cleanAllDownload)
        container.addSubview(softwareAutoUpdateWhenLaunch)
        container.addSubview(softwareUpdateNotify)
        container.addSubview(showAPTReport)
        container.addSubview(softwareReport)
        openDownloadedPackages.snp.makeConstraints { (x) in
            x.left.equalTo(self.safeAnchor.snp.left).offset(8)
            x.right.equalTo(self.safeAnchor.snp.right).offset(-8)
            x.top.equalTo(anchor.snp.bottom).offset(18)
            x.height.equalTo(28)
        }
        anchor = openDownloadedPackages
        cleanAllDownload.snp.makeConstraints { (x) in
            x.left.equalTo(self.safeAnchor.snp.left).offset(8)
            x.right.equalTo(self.safeAnchor.snp.right).offset(-8)
            x.top.equalTo(anchor.snp.bottom).offset(18)
            x.height.equalTo(28)
        }
        anchor = cleanAllDownload
        softwareAutoUpdateWhenLaunch.snp.makeConstraints { (x) in
            x.left.equalTo(self.safeAnchor.snp.left).offset(8)
            x.right.equalTo(self.safeAnchor.snp.right).offset(-8)
            x.top.equalTo(anchor.snp.bottom).offset(18)
            x.height.equalTo(28)
        }
        anchor = softwareAutoUpdateWhenLaunch
        softwareUpdateNotify.snp.makeConstraints { (x) in
            x.left.equalTo(self.safeAnchor.snp.left).offset(8)
            x.right.equalTo(self.safeAnchor.snp.right).offset(-8)
            x.top.equalTo(anchor.snp.bottom).offset(18)
            x.height.equalTo(28)
        }
        anchor = softwareUpdateNotify
        showAPTReport.snp.makeConstraints { (x) in
            x.left.equalTo(self.safeAnchor.snp.left).offset(8)
            x.right.equalTo(self.safeAnchor.snp.right).offset(-8)
            x.top.equalTo(anchor.snp.bottom).offset(18)
            x.height.equalTo(28)
        }
        anchor = showAPTReport
        softwareReport.snp.makeConstraints { (x) in
            x.left.equalTo(self.safeAnchor.snp.left).offset(8)
            x.right.equalTo(self.safeAnchor.snp.right).offset(-8)
            x.top.equalTo(anchor.snp.bottom).offset(18)
            x.height.equalTo(28)
        }
        anchor = softwareReport
        groupEffect2.snp.makeConstraints { (x) in
            x.left.equalTo(self.safeAnchor.snp.left)
            x.right.equalTo(self.safeAnchor.snp.right)
            x.top.equalTo(openDownloadedPackages.snp.top).offset(-12)
            x.bottom.equalTo(anchor.snp.bottom).offset(16)
        }
        anchor = groupEffect2

// MARK: MANAGER
        
        let label3 = UILabel()
        label3.font = .systemFont(ofSize: 22, weight: .semibold)
        label3.text = "Other".localized()
        container.addSubview(label3)
        label3.snp.makeConstraints { (x) in
            x.left.equalTo(self.safeAnchor)
            x.right.equalTo(self.safeAnchor)
            x.top.equalTo(anchor.snp.bottom).offset(12)
            x.height.equalTo(60)
        }
        anchor = label3
        
        let groupEffect3 = UIView()
        groupEffect3.backgroundColor = UIColor(named: "G-Background-Cell")
        groupEffect3.layer.cornerRadius = 12
        groupEffect3.dropShadow()
        let appLanguage = SettingSectionView(iconSystemNamed: "textformat.alt",
                                                              text: "AppLanguage".localized(),
                                                              dataType: .dropDownWithString,
                                                              initData: {
                                                                return "LANGUAGE_FALG_233".localized()
        }) { (_, dropDownAnchor) in
            let dropDown = DropDown()
            let actionSource = ConfigManager.availableLanguage
            dropDown.dataSource = actionSource.map({ (str) -> String in
                return "   " + "LANGUAGE_FALG_233".localized(str)
            })
            dropDown.anchorView = dropDownAnchor
            dropDown.selectionAction = { [unowned self] (index: Int, _: String) in
                let target = ConfigManager.availableLanguage[index]
                let alert = UIAlertController(title: "LANGUAGE_FALG_233".localized(target), message: "RestartAppHint".localized(), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Confirm".localized(), style: .destructive, handler: { (_) in
                    ConfigManager.shared.Application.usedLanguage = target
                    let _ = Tools.spawnCommandAndWriteToFileReturnFileLocationAndSignalFileLocation("sleep 1 && openApplication wiki.qaq.Protein")
                    NotificationCenter.default.post(name: .SettingsUpdated, object: nil)
                    UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
                    usleep(23333);
                    Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { (timer) in
                        exit(0)
                    }
                }))
                alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: { (_) in
                }))
                self.obtainParentViewController?.present(alert, animated: true, completion: nil)
            }
            dropDown.show(onTopOf: self.window)
        }
        let doUICACHE = SettingSectionView(iconSystemNamed: "square.grid.2x2",
                                            text: "RebuildUIcache".localized(),
                                            dataType: .submenuWithAction,
                                            initData: nil) { (_, dropDownAnchor) in
            let dropDown = DropDown()
            let actionSource = ["RebuildUIcache", "Cancel"]
            dropDown.dataSource = actionSource.map({ (str) -> String in
                return "   " + str.localized()
            })
            dropDown.anchorView = dropDownAnchor
            dropDown.selectionAction = { (index: Int, _: String) in
                if actionSource[index] == "RebuildUIcache" {
                    let dir = ConfigManager.shared.documentString + "/SystemEvents/"
                    let signalFile = dir + UUID().uuidString
                    print("[System] Signal to " + signalFile)
                    try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
                    var hud: JGProgressHUD?
                    if let view = self.obtainParentViewController?.view {
                        if self.traitCollection.userInterfaceStyle == .dark {
                            hud = .init(style: .dark)
                        } else {
                            hud = .init(style: .light)
                        }
                        hud?.show(in: view)
                    }
                    DispatchQueue.global(qos: .background).async {
                        print(Tools.spawnCommandSycn("uicache -a && echo done >> " + signalFile))
                    }
                    DispatchQueue.global(qos: .background).async {
                        var count = 0
                        while count < 120 {
                            sleep(1)
                            if let str = try? String(contentsOfFile: signalFile),
                                str.hasPrefix("done") {
                                break
                            }
                            count += 1
                        }
                        hud?.dismiss()
                        try? FileManager.default.removeItem(atPath: signalFile)
                    }
                }
            }
            dropDown.show(onTopOf: self.window)
        }
        let doRespring = SettingSectionView(iconSystemNamed: "rays",
                                            text: "ReloadSpringBoard".localized(),
                                            dataType: .submenuWithAction,
                                            initData: nil) { (_, dropDownAnchor) in
            let dropDown = DropDown()
            let actionSource = ["ReloadSpringBoard", "Cancel"]
            dropDown.dataSource = actionSource.map({ (str) -> String in
                return "   " + str.localized()
            })
            dropDown.anchorView = dropDownAnchor
            dropDown.selectionAction = { (index: Int, _: String) in
                if actionSource[index] == "ReloadSpringBoard" {
                    print(Tools.spawnCommandSycn("killall -9 backboardd"))
                }
            }
            dropDown.show(onTopOf: self.window)
        }
        let safemode = SettingSectionView(iconSystemNamed: "shield",
                                            text: "EnterSafeMode".localized(),
                                            dataType: .submenuWithAction,
                                            initData: nil) { (_, dropDownAnchor) in
            let dropDown = DropDown()
            let actionSource = ["EnterSafeMode", "Cancel"]
            dropDown.dataSource = actionSource.map({ (str) -> String in
                return "   " + str.localized()
            })
            dropDown.anchorView = dropDownAnchor
            dropDown.selectionAction = { (index: Int, _: String) in
                if actionSource[index] == "EnterSafeMode" {
                    print(Tools.spawnCommandSycn("killall -SEGV SpringBoard"))
                }
            }
            dropDown.show(onTopOf: self.window)
        }
        let userSpaceReboot = SettingSectionView(iconSystemNamed: "arrow.3.trianglepath",
                                            text: "RebootUserSpace".localized(),
                                            dataType: .submenuWithAction,
                                            initData: nil) { (_, dropDownAnchor) in
            let dropDown = DropDown()
            let actionSource = ["RebootUserSpace", "Cancel"]
            dropDown.dataSource = actionSource.map({ (str) -> String in
                return "   " + str.localized()
            })
            dropDown.anchorView = dropDownAnchor
            dropDown.selectionAction = { (index: Int, _: String) in
                if actionSource[index] == "RebootUserSpace" {
                    print(Tools.spawnCommandSycn("launchctl reboot userspace"))
                }
            }
            dropDown.show(onTopOf: self.window)
        }
        let sourceCode = SettingSectionView(iconSystemNamed: "chevron.left.slash.chevron.right",
                                            text: "WebOpenSourceCode".localized(),
                                            dataType: .submenuWithAction,
                                            initData: nil) { (_, dropDownAnchor) in
                                                let urlString = DEFINE.SOURCE_CODE_LOCATION
                                                if let url = URL(string: urlString) {
                                                    UIApplication.shared.open(url, options: [:]) { (_) in }
                                                }
        }
        container.addSubview(groupEffect3)
        container.addSubview(doUICACHE)
        container.addSubview(appLanguage)
        container.addSubview(safemode)
        container.addSubview(userSpaceReboot)
        container.addSubview(doRespring)
        container.addSubview(sourceCode)
        appLanguage.snp.makeConstraints { (x) in
            x.left.equalTo(self.safeAnchor.snp.left).offset(8)
            x.right.equalTo(self.safeAnchor.snp.right).offset(-8)
            x.top.equalTo(anchor.snp.bottom).offset(18)
            x.height.equalTo(28)
        }
        anchor = appLanguage
        doUICACHE.snp.makeConstraints { (x) in
            x.left.equalTo(self.safeAnchor.snp.left).offset(8)
            x.right.equalTo(self.safeAnchor.snp.right).offset(-8)
            x.top.equalTo(anchor.snp.bottom).offset(18)
            x.height.equalTo(28)
        }
        anchor = doUICACHE
        doRespring.snp.makeConstraints { (x) in
            x.left.equalTo(self.safeAnchor.snp.left).offset(8)
            x.right.equalTo(self.safeAnchor.snp.right).offset(-8)
            x.top.equalTo(anchor.snp.bottom).offset(18)
            x.height.equalTo(28)
        }
        anchor = doRespring
        safemode.snp.makeConstraints { (x) in
            x.left.equalTo(self.safeAnchor.snp.left).offset(8)
            x.right.equalTo(self.safeAnchor.snp.right).offset(-8)
            x.top.equalTo(anchor.snp.bottom).offset(18)
            x.height.equalTo(28)
        }
        anchor = safemode
        if FileManager.default.fileExists(atPath: "/.installed_unc0ver") {
            userSpaceReboot.snp.makeConstraints { (x) in
                x.left.equalTo(self.safeAnchor.snp.left).offset(8)
                x.right.equalTo(self.safeAnchor.snp.right).offset(-8)
                x.top.equalTo(anchor.snp.bottom).offset(18)
                x.height.equalTo(28)
            }
            anchor = userSpaceReboot
        }
        sourceCode.snp.makeConstraints { (x) in
            x.left.equalTo(self.safeAnchor.snp.left).offset(8)
            x.right.equalTo(self.safeAnchor.snp.right).offset(-8)
            x.top.equalTo(anchor.snp.bottom).offset(18)
            x.height.equalTo(28)
        }
        anchor = sourceCode
        groupEffect3.snp.makeConstraints { (x) in
            x.left.equalTo(self.safeAnchor.snp.left)
            x.right.equalTo(self.safeAnchor.snp.right)
            x.top.equalTo(appLanguage.snp.top).offset(-12)
            x.bottom.equalTo(anchor.snp.bottom).offset(16)
        }
        anchor = groupEffect3
        lastAnchor = anchor
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.loadContentSize()
        }
        
    }
    
    func loadContentSize() {
        if let anchor = self.lastAnchor {
            container.contentSize = CGSize(width: 0, height: anchor.frame.maxY + 50)
        }
    }
    
}

fileprivate enum SettingSectionDataType: String {
    case none
    case submenuWithAction
    case switcher
    case dropDownWithString
}

fileprivate class SettingSectionView: UIView {
    
    private let iconView = UIImageView()
    private let label = UILabel()
    private let switcher = UISwitch()
    private let buttonImage = UIImageView()
    private let button = UIButton()
    private let dropDownHit = LTMorphingLabel()
    private let dropDownAnchor = UIView()
    
    private let type: SettingSectionDataType
    private let dataProvider: (() -> String)?
    private let actionCall: ((_ switcherValueIfAvailable: Bool?, _ dropDownAnchor: UIView) -> ())?
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    required init(iconSystemNamed: String,
                  text: String,
                  dataType: SettingSectionDataType,
                  initData: (() -> (String))?,
                  withAction: ((_ switcherValueIfAvailable: Bool?, _ dropDownAnchor: UIView) -> ())?) {
        
        type = dataType
        dataProvider = initData
        actionCall = withAction
        
        super.init(frame: CGRect())
            
        NotificationCenter.default.addObserver(self, selector: #selector(udpateDatas), name: .SettingsUpdated, object: nil)
        
        addSubview(iconView)
        addSubview(label)
        addSubview(switcher)
        addSubview(buttonImage)
        addSubview(button)
        addSubview(dropDownHit)
        addSubview(dropDownAnchor)
        
        iconView.contentMode = .scaleAspectFit
        iconView.image = UIImage(systemName: iconSystemNamed)
        iconView.snp.makeConstraints { (x) in
            x.centerX.equalTo(self.snp.left).offset(4 + 20)
            x.centerY.equalTo(self.snp.centerY)
            x.top.equalToSuperview().offset(0)
        }
        
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.text = text
        label.snp.makeConstraints { (x) in
            x.left.equalTo(self.iconView.snp.centerX).offset(12 + 12)
            x.centerY.equalTo(self.snp.centerY)
            x.right.equalTo(self.switcher.snp.left).offset(-8)
        }
        
        switcher.addTarget(self, action: #selector(buttonAnimate), for: .valueChanged)
        switcher.snp.makeConstraints { (x) in
            x.centerY.equalTo(self.snp.centerY)
            x.right.equalTo(self.snp.right).offset(-12)
        }
        
        buttonImage.image = UIImage(named: "PackageCollectionView.Next")
        buttonImage.snp.makeConstraints { (x) in
            x.centerY.equalTo(self.snp.centerY)
            x.right.equalTo(self.switcher.snp.right)
            x.width.equalTo(20)
            x.height.equalTo(20)
        }
        
        button.addTarget(self, action: #selector(buttonAnimate), for: .touchUpInside)
        button.snp.makeConstraints { (x) in
            x.center.equalTo(self.buttonImage)
            x.width.equalTo(30)
            x.height.equalTo(30)
        }
        
        dropDownHit.morphingEffect = .evaporate
        dropDownHit.font = UIFont.roundedFont(ofSize: 18, weight: .bold).monospacedDigitFont
        dropDownHit.textColor = UIColor(named: "RepoTableViewCell.SubText")
        dropDownHit.snp.makeConstraints { (x) in
            x.centerY.equalTo(self.snp.centerY)
            x.right.equalTo(self.snp.right).offset(-12)
        }
        
        dropDownAnchor.snp.makeConstraints { (x) in
            x.top.equalTo(label.snp.bottom).offset(8)
            x.right.equalTo(self.snp.right).offset(12)
            x.width.equalTo(250)
            x.height.equalTo(2)
        }
        
        switch dataType {
        case .none:
            switcher.isHidden = true
            button.isHidden = true
            buttonImage.isHidden = true
            dropDownHit.isHidden = true
            dropDownAnchor.isHidden = true
        case .switcher:
            button.isHidden = true
            buttonImage.isHidden = true
            dropDownHit.isHidden = true
            dropDownAnchor.isHidden = true
        case .submenuWithAction:
            switcher.isHidden = true
            dropDownHit.isHidden = true
            dropDownAnchor.isHidden = true
        case .dropDownWithString:
            switcher.isHidden = true
            buttonImage.isHidden = true
            button.snp.remakeConstraints { (x) in
                x.centerY.equalTo(self.snp.centerY)
                x.right.equalTo(self)
                x.width.equalTo(100)
            }
        }
        
        udpateDatas()
        
    }
    
    @objc
    func udpateDatas() {
        self.bringSubviewToFront(button)
        switch type {
        case .switcher:
            self.bringSubviewToFront(switcher)
            if let delegate = dataProvider {
                let ret = delegate()
                switcher.setOn(ret == "1" ? true : false, animated: true)
            }
        case .dropDownWithString:
            if let delegate = dataProvider {
                dropDownHit.text = delegate()
            }
        default:
            break
        }
    }
    
    @objc
    func buttonAnimate() {
        if type == .submenuWithAction {
            buttonImage.shineAnimation()
        }
        if let withAction = actionCall {
            if type == .switcher {
                withAction(switcher.isOn, dropDownAnchor)
            } else {
                dropDownHit.puddingAnimate()
                withAction(nil, dropDownAnchor)
            }
            NotificationCenter.default.post(name: .SettingsUpdated, object: nil)
        }
    }
    
    func setLabelText(str: String) {
        label.text = str
    }
    
    func setSwitcherUnavailable() {
        switcher.alpha = 0.5
        switcher.isUserInteractionEnabled = false
    }
    
}

fileprivate class UDIDSection: SettingSectionView {
    
    required init(iconSystemNamed: String,
                  text: String,
                  dataType: SettingSectionDataType,
                  initData: (() -> (String))?,
                  withAction: ((_ switcherValueIfAvailable: Bool?, _ dropDownAnchor: UIView) -> ())?) {
        super.init(iconSystemNamed: iconSystemNamed, text: text, dataType: dataType, initData: initData, withAction: withAction)
        
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadUDID), name: .SettingsUpdated, object: nil)
        
        reloadUDID()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    func reloadUDID() {
        var str = ""
        if ConfigManager.shared.CydiaConfig.mess ||
            ConfigManager.shared.CydiaConfig.udid == "0000000000000000000000000000000000000000" {
            str = "RandomDeviceInfoEnabledOrUDIDNotAvailable".localized()
        } else {
            str = ConfigManager.shared.CydiaConfig.udid.uppercased()
        }
        setLabelText(str: str)
    }
    
}
