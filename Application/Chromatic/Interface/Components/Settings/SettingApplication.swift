//
//  SettingApplication.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/28.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import SPIndicator
import UIKit
import Bugsnag

extension SettingView {
    func setupApplicationView(anchor: inout UIView, safeAnchor: UIView) {
        // MARK: - HEADLINE

        let headline = UILabel()
        headline.font = .systemFont(ofSize: 22, weight: .semibold)
        headline.text = NSLocalizedString("ACTIONS", comment: "Actions")
        addSubview(headline)
        headline.snp.makeConstraints { x in
            x.left.equalTo(safeAnchor)
            x.right.equalTo(safeAnchor)
            x.top.equalTo(anchor.snp.bottom).offset(12)
            x.height.equalTo(60)
        }
        anchor = headline

        // MARK: - CONTENT

        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor(named: "CARD_BACKGROUND")
        backgroundView.layer.cornerRadius = 12
//        backgroundView.dropShadow()
        let doUicache = SettingElement(iconSystemNamed: "square.grid.2x2",
                                       text: NSLocalizedString("REBUILD_ICONS", comment: "Rebuild Icons"),
                                       dataType: .submenuWithAction,
                                       initData: nil) { _, anchor in
            self.dropDownConfirm(anchor: anchor,
                                 text: NSLocalizedString("REBUILD_ICONS", comment: "Rebuild Icons")) { [weak self] in
                let alert = UIAlertController(title: "⚠️",
                                              message: NSLocalizedString("RELOAD_ICON_CACHE_TASKES_TIME", comment: "Reloading home screen icons will take some time"),
                                              preferredStyle: .alert)
                self?.parentViewController?.present(alert, animated: true) {
                    DispatchQueue.global().async {
                        AuxiliaryExecute.rootspawn(command: AuxiliaryExecute.uicache,
                                                   args: ["--all"],
                                                   timeout: 120,
                                                   output: { _ in })
                        DispatchQueue.main.async {
                            alert.dismiss(animated: true, completion: nil)
                        }
                    }
                }
            }
        }
        let doRespring = SettingElement(iconSystemNamed: "rays",
                                        text: NSLocalizedString("RELOAD_DESKTOP", comment: "Reload Desktop"),
                                        dataType: .submenuWithAction,
                                        initData: nil) { _, anchor in
            self.dropDownConfirm(anchor: anchor,
                                 text: NSLocalizedString("RELOAD_DESKTOP", comment: "Reload Desktop")) {
                AuxiliaryExecute.suspendApplication()
                sleep(1)
                AuxiliaryExecute.reloadSpringboard()
            }
        }
        let safemode = SettingElement(iconSystemNamed: "shield",
                                      text: NSLocalizedString("ENTER_SAFE_MODE", comment: "Enter Safe Mode"),
                                      dataType: .submenuWithAction,
                                      initData: nil) { _, anchor in
            self.dropDownConfirm(anchor: anchor,
                                 text: NSLocalizedString("ENTER_SAFE_MODE", comment: "Enter Safe Mode")) {
                AuxiliaryExecute.suspendApplication()
                sleep(1)
                AuxiliaryExecute.rootspawn(command: AuxiliaryExecute.killall,
                                           args: ["-SEGV", "SpringBoard"],
                                           timeout: 1) { _ in
                }
            }
        }
        let sourceCode = SettingElement(iconSystemNamed: "chevron.left.slash.chevron.right",
                                        text: NSLocalizedString("SOURCE_CODE", comment: "Source Code"),
                                        dataType: .submenuWithAction,
                                        initData: nil) { _, _ in
            UIApplication.shared.open(URL(string: cWebLocationSource)!,
                                      options: [:],
                                      completionHandler: nil)
        }
        addSubview(backgroundView)
        addSubview(doUicache)
        addSubview(safemode)
        addSubview(doRespring)
        addSubview(sourceCode)
        doUicache.snp.makeConstraints { x in
            x.left.equalTo(safeAnchor.snp.left).offset(8)
            x.right.equalTo(safeAnchor.snp.right).offset(-8)
            x.top.equalTo(anchor.snp.bottom).offset(18)
            x.height.equalTo(28)
        }
        anchor = doUicache
        doRespring.snp.makeConstraints { x in
            x.left.equalTo(safeAnchor.snp.left).offset(8)
            x.right.equalTo(safeAnchor.snp.right).offset(-8)
            x.top.equalTo(anchor.snp.bottom).offset(18)
            x.height.equalTo(28)
        }
        anchor = doRespring
        safemode.snp.makeConstraints { x in
            x.left.equalTo(safeAnchor.snp.left).offset(8)
            x.right.equalTo(safeAnchor.snp.right).offset(-8)
            x.top.equalTo(anchor.snp.bottom).offset(18)
            x.height.equalTo(28)
        }
        anchor = safemode
        sourceCode.snp.makeConstraints { x in
            x.left.equalTo(safeAnchor.snp.left).offset(8)
            x.right.equalTo(safeAnchor.snp.right).offset(-8)
            x.top.equalTo(anchor.snp.bottom).offset(18)
            x.height.equalTo(28)
        }
        anchor = sourceCode
        backgroundView.snp.makeConstraints { x in
            x.left.equalTo(safeAnchor.snp.left)
            x.right.equalTo(safeAnchor.snp.right)
            x.top.equalTo(doUicache.snp.top).offset(-12)
            x.bottom.equalTo(anchor.snp.bottom).offset(16)
        }
        anchor = backgroundView
    }
}
