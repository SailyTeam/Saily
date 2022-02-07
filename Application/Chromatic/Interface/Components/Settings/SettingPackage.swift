//
//  SettingPackage.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/28.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import Digger
import DropDown
import UIKit

extension SettingView {
    func setupPackages(anchor: inout UIView, safeAnchor: UIView) {
        let headline = UILabel()
        headline.font = .systemFont(ofSize: 18, weight: .semibold)
        headline.text = NSLocalizedString("PACKAGES", comment: "Packages")
        addSubview(headline)
        headline.snp.makeConstraints { x in
            x.left.equalTo(safeAnchor)
            x.right.equalTo(safeAnchor)
            x.top.equalTo(anchor.snp.bottom).offset(10)
            x.height.equalTo(40)
        }
        anchor = headline

        let backgroundEffect = UIView()
        backgroundEffect.backgroundColor = UIColor(named: "CARD_BACKGROUND")
        backgroundEffect.layer.cornerRadius = 12
//        backgroundEffect.dropShadow()
        let openDownloadedPackages = SettingElement(iconSystemNamed: "tray.full",
                                                    text: NSLocalizedString("OPEN_DOWNLOAD", comment: "Open Download"),
                                                    dataType: .submenuWithAction, initData: nil) { _, _ in
            let urlString = "filza://" + CariolNetwork.shared.workingLocation.path
            if let url = URL(string: urlString),
               UIApplication.shared.canOpenURL(url)
            {
                UIApplication.shared.open(url, options: [:])
            } else {
                let alert = UIAlertController(title: NSLocalizedString("ERROR", comment: "Error"),
                                              message: NSLocalizedString("FILZA_REQUIRED", comment: "Filza is required for this operation"),
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("DISMISS", comment: "Dismiss"),
                                              style: .default, handler: nil))
                self.parentViewController?.present(alert, animated: true, completion: nil)
            }
        }
        let cleanAllDownload = SettingElement(iconSystemNamed: "trash",
                                              text: NSLocalizedString("DELETE_ALL_DOWNLOADS", comment: "Delete All Downloads"),
                                              dataType: .dropDownWithString, initData: {
                                                  var compute = 0
                                                  if let cache = try? URL(fileURLWithPath: DiggerCache.cachesDirectory)
                                                      .directoryTotalAllocatedSize()
                                                  {
                                                      compute += cache
                                                  }
                                                  if let download = try? CariolNetwork
                                                      .shared
                                                      .workingLocation
                                                      .directoryTotalAllocatedSize()
                                                  {
                                                      compute += download
                                                  }
                                                  if let directInstallSize = try? documentsDirectory
                                                      .appendingPathComponent("DirectInstallCache")
                                                      .directoryTotalAllocatedSize()
                                                  {
                                                      compute += directInstallSize
                                                  }
                                                  let formatter = ByteCountFormatter()
                                                  formatter.allowedUnits = [.useAll]
                                                  formatter.countStyle = .file
                                                  if compute < 0 { compute = 0 } // avoid crash
                                                  return formatter.string(fromByteCount: Int64(compute))
                                              }) { _, anchor in
            self.dropDownConfirm(anchor: anchor,
                                 text: NSLocalizedString("DELETE_ALL_DOWNLOADS", comment: "Delete All Downloads"))
            {
                let cache = URL(fileURLWithPath: DiggerCache.cachesDirectory)
                try? FileManager.default.removeItem(at: cache)
                let download = CariolNetwork.shared.workingLocation
                try? FileManager.default.removeItem(at: download)
                let directInstall = documentsDirectory.appendingPathComponent("DirectInstallCache")
                try? FileManager.default.removeItem(at: directInstall)
                self.dispatchValueUpdate()
                CariolNetwork.shared.clear()
            }
        }
        let softwareAutoUpdateWhenLaunch = SettingElement(iconSystemNamed: "paperplane",
                                                          text: NSLocalizedString("UPDATE_WHEN_AVAILABLE", comment: "Update When Available"),
                                                          dataType: .switcher,
                                                          initData: {
                                                              TaskManager.shared.automaticUpdateWhenAvailable ? "YES" : "NO"
                                                          }) { changeToOpen, _ in
            TaskManager.shared.automaticUpdateWhenAvailable = changeToOpen ?? false
            self.dispatchValueUpdate()
        }
        let blockedUpdate = SettingElement(iconSystemNamed: "hand.raised.fill",
                                           text: NSLocalizedString("BLOCK_UPDATE", comment: "Block Update"),
                                           dataType: .submenuWithAction,
                                           initData: nil,
                                           withAction: { _, _ in
                                               self.parentViewController?.present(next: BlockUpdateController())
                                           })
        let preferredDepiction = SettingElement(iconSystemNamed: "barcode.viewfinder",
                                                text: NSLocalizedString("DEPICTION", comment: "Depiction"),
                                                dataType: .submenuWithAction) {
            PackageCenter.default.preferredDepiction.localizedDescription()
        } withAction: { _, dropDownAnchor in
            let dropDownDataSource = PackageDepiction
                .PreferredDepiction
                .allCases
            let displayDataSource = dropDownDataSource
                .map { $0.localizedDescription() }
                .invisibleSpacePadding()
            let dropDown = DropDown(anchorView: dropDownAnchor, selectionAction: { index, _ in
                PackageCenter.default.preferredDepiction = dropDownDataSource[safe: index] ?? .automatically
            }, dataSource: displayDataSource)
            dropDown.show(onTopOf: dropDownAnchor.window)
        }

        addSubview(backgroundEffect)
        addSubview(openDownloadedPackages)
        addSubview(cleanAllDownload)
        addSubview(softwareAutoUpdateWhenLaunch)
        addSubview(blockedUpdate)
        addSubview(preferredDepiction)

        openDownloadedPackages.snp.makeConstraints { x in
            makeElement(constraint: x, widthAnchor: safeAnchor, topAnchor: anchor)
        }
        anchor = openDownloadedPackages
        cleanAllDownload.snp.makeConstraints { x in
            makeElement(constraint: x, widthAnchor: safeAnchor, topAnchor: anchor)
        }
        anchor = cleanAllDownload
        softwareAutoUpdateWhenLaunch.snp.makeConstraints { x in
            makeElement(constraint: x, widthAnchor: safeAnchor, topAnchor: anchor)
        }
        anchor = softwareAutoUpdateWhenLaunch
        blockedUpdate.snp.makeConstraints { x in
            makeElement(constraint: x, widthAnchor: safeAnchor, topAnchor: anchor)
        }
        anchor = blockedUpdate
        preferredDepiction.snp.makeConstraints { x in
            makeElement(constraint: x, widthAnchor: safeAnchor, topAnchor: anchor)
        }
        anchor = preferredDepiction
        backgroundEffect.snp.makeConstraints { x in
            x.left.equalTo(safeAnchor.snp.left)
            x.right.equalTo(safeAnchor.snp.right)
            x.top.equalTo(openDownloadedPackages.snp.top).offset(-12)
            x.bottom.equalTo(anchor.snp.bottom).offset(16)
        }
        anchor = backgroundEffect
    }
}
