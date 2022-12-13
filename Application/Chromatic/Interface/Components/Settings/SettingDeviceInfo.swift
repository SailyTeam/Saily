//
//  SettingDeviceInfo.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/28.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import SPIndicator
import UIKit
extension SettingView {
    @objc func copyUDIDAction(sender: UITapGestureRecognizer) {
        let view: SettingElement = sender.view as! SettingElement
        let text: String = view.label.text ?? ""
        if InterfaceBridge.enableShareSheet {
            let activityViewController = UIActivityViewController(activityItems: [text],
                                                                  applicationActivities: nil)
            activityViewController
                .popoverPresentationController?
                .sourceView = view
            view
                .parentViewController?
                .present(activityViewController, animated: true, completion: nil)
        } else {
            UIPasteboard.general.string = view.label.text
            SPIndicator.present(title: NSLocalizedString("COPIED", comment: "Cpoied"),
                                message: nil,
                                preset: .done,
                                haptic: .success,
                                from: .top,
                                completion: nil)
        }
    }

    func setupDeviceInfoSection(anchor: inout UIView, safeAnchor: UIView) {
        let label0 = UILabel()
        label0.font = .systemFont(ofSize: 18, weight: .semibold)
        label0.text = NSLocalizedString("DEVICE_INFORMATION", comment: "Device Information")
        addSubview(label0)
        label0.snp.makeConstraints { x in
            x.left.equalTo(safeAnchor)
            x.right.equalTo(safeAnchor)
            x.top.equalTo(anchor.snp.bottom) // .offset(20)
            x.height.equalTo(40)
        }
        anchor = label0

        let groupEffect0 = UIView()
        groupEffect0.backgroundColor = UIColor(named: "CARD_BACKGROUND")
        groupEffect0.layer.cornerRadius = 12
//        groupEffect0.dropShadow()
        let deviceInfo = SettingElement(iconSystemNamed: "info.circle",
                                        text: DeviceInfo.current.machine,
                                        dataType: .none, initData: nil) { _, _ in }
        let systemVersion = SettingElement(iconSystemNamed: "",
                                           text: UIDevice.current.systemName + " - " + UIDevice.current.systemVersion,
                                           dataType: .none, initData: nil) { _, _ in }

        let udid = SettingElement(iconSystemNamed: "",
                                  text: DeviceInfo.current.realDeviceIdentity.uppercased(),
                                  dataType: .none, initData: nil, withAction: nil)
        udid.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(copyUDIDAction(sender:))))
        udid.label.font = .monospacedSystemFont(ofSize: 16, weight: .semibold)
        let enableRandomDeviceInfo = SettingElement(iconSystemNamed: "eye.slash",
                                                    text: NSLocalizedString("RANDOM_INDO", comment: "Random Info"),
                                                    dataType: .switcher,
                                                    initData: {
                                                        !DeviceInfo.current.useRealDeviceInfo ? "YES" : "NO"
                                                    }) { changeValueTo, _ in
            if changeValueTo ?? false {
                let alert = UIAlertController(title: "⚠️",
                                              message: NSLocalizedString("ENABLE_RANDOM_DEVICE_INFO_WILL_DISABLE_COMMERCIAL_OPERATIONS", comment: "Enable random device info will disable commercial operations"),
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("CONFIRM", comment: "Confirm"),
                                              style: .destructive,
                                              handler: { _ in
                                                  DeviceInfo.current.useRealDeviceInfo = false
                                                  self.dispatchValueUpdate()
                                              }))
                alert.addAction(UIAlertAction(title: NSLocalizedString("CANCEL", comment: "Cancel"),
                                              style: .cancel, handler: { _ in
                                                  self.dispatchValueUpdate()
                                              }))
                self.parentViewController?.present(alert, animated: true, completion: nil)
            } else {
                DeviceInfo.current.useRealDeviceInfo = true
                self.dispatchValueUpdate()
            }
        }
        let userAgentControl = SettingElement(iconSystemNamed: "grid.circle.fill",
                                              text: NSLocalizedString("USER_AGENT", comment: "User Agent"),
                                              dataType: .submenuWithAction) {
            var ret = InterfaceBridge.mainUserAgent
            if ret.count < 1 { ret = "_" }
            return ret
        } withAction: { _, _ in

            let alert = UIAlertController(title: NSLocalizedString("USER_AGENT", comment: "User Agent"),
                                          message: "",
                                          preferredStyle: .alert)
            alert.addTextField { field in
                field.text = InterfaceBridge.mainUserAgent
                if field.text?.count ?? 0 < 1 {
                    field.text = "Saily/2.0 Cydia/1.1.32"
                }
            }
            alert.addAction(UIAlertAction(title: NSLocalizedString("CANCEL", comment: "Cancel"),
                                          style: .cancel, handler: { _ in
                                              self.dispatchValueUpdate()
                                          }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("CONFIRM", comment: "Confirm"), style: .default, handler: { [weak alert, weak self] _ in
                if let text = alert?.textFields?[0].text {
                    InterfaceBridge.mainUserAgent = text
                }
                self?.dispatchValueUpdate()
            }))
            self.parentViewController?.present(alert, animated: true, completion: nil)
        }

        addSubview(groupEffect0)
        addSubview(deviceInfo)
        addSubview(systemVersion)
        addSubview(udid)
        addSubview(enableRandomDeviceInfo)
        addSubview(userAgentControl)
        deviceInfo.snp.makeConstraints { x in
            makeElement(constraint: x, widthAnchor: safeAnchor, topAnchor: anchor)
        }
        anchor = deviceInfo
        systemVersion.snp.makeConstraints { x in
            makeElement(constraint: x, widthAnchor: safeAnchor, topAnchor: anchor)
        }
        anchor = systemVersion
        udid.snp.makeConstraints { x in
            makeElement(constraint: x, widthAnchor: safeAnchor, topAnchor: anchor)
        }
        anchor = udid
        enableRandomDeviceInfo.snp.makeConstraints { x in
            makeElement(constraint: x, widthAnchor: safeAnchor, topAnchor: anchor)
        }
        anchor = enableRandomDeviceInfo
        userAgentControl.snp.makeConstraints { x in
            makeElement(constraint: x, widthAnchor: safeAnchor, topAnchor: anchor)
        }
        anchor = userAgentControl
        groupEffect0.snp.makeConstraints { x in
            x.left.equalTo(safeAnchor.snp.left)
            x.right.equalTo(safeAnchor.snp.right)
            x.top.equalTo(deviceInfo.snp.top).offset(-12)
            x.bottom.equalTo(anchor.snp.bottom).offset(16)
        }
        anchor = groupEffect0
    }
}
