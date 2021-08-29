//
//  SettingView.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/28.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import DropDown
import MorphingLabel
import UIKit

class SettingView: UIScrollView {
    var padding: CGFloat = 20
    private let safeAnchor = UIView()
    private let frameBuilder = UIView()

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    required init() {
        super.init(frame: CGRect())

        alwaysBounceVertical = true

        addSubview(safeAnchor)
        safeAnchor.snp.makeConstraints { x in
            x.centerX.equalToSuperview()
            x.width.equalToSuperview().offset(-padding * 2)
            x.top.equalToSuperview()
            x.height.equalTo(0)
        }
        var anchor = safeAnchor

        setupDeviceInfoSection(anchor: &anchor, safeAnchor: safeAnchor)
        setupRepo(anchor: &anchor, safeAnchor: safeAnchor)
        setupPackages(anchor: &anchor, safeAnchor: safeAnchor)
        setupApplicationView(anchor: &anchor, safeAnchor: safeAnchor)

        // MARK: - LICENSE

        let licenseButton = UIButton()
        licenseButton.titleLabel?.font = .roundedFont(ofSize: 12, weight: .semibold)
        licenseButton.setTitle(NSLocalizedString("LICENSE_INFO", comment: "License Info"), for: .normal)
        licenseButton.setTitleColor(.systemBlue, for: .normal)
        licenseButton.addTarget(self, action: #selector(openLicense), for: .touchUpInside)
        addSubview(licenseButton)
        licenseButton.snp.makeConstraints { x in
            x.leading.equalTo(safeAnchor)
            x.top.equalTo(anchor.snp.bottom).offset(20)
            x.height.equalTo(20)
        }
        anchor = licenseButton

        // MARK: - BUNDLE INFO

        do {
            let label = UILabel()
            label.font = .roundedFont(ofSize: 8, weight: .thin)
            label.textColor = .systemGray
            label.numberOfLines = 4
            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            label.text =
                """
                \(Bundle.main.bundleIdentifier ?? "unknown bundle") - \(appVersion ?? "unknown bundle version")
                [\(Bundle.main.bundleURL.path)]
                [\(documentsDirectory.path)]
                """
            addSubview(label)
            label.snp.makeConstraints { x in
                x.leading.equalTo(safeAnchor)
                x.trailing.equalTo(safeAnchor)
                x.top.equalTo(anchor.snp.bottom)
                x.height.equalTo(50)
            }
        }

        // MARK: - MANAGER

        frameBuilder.isUserInteractionEnabled = false
        frameBuilder.isHidden = true
        addSubview(frameBuilder)
        frameBuilder.snp.makeConstraints { x in
            x.top.equalTo(safeAnchor)
            x.bottom.equalTo(anchor)
            x.left.equalTo(self)
            x.right.equalTo(self)
        }
    }

    func updateContentSize() {
        DispatchQueue.main.async { [self] in
            debugPrint("\(#file) #\(#function) \(#line) \(frameBuilder.frame.height)")
            contentSize = CGSize(width: 10, height: frameBuilder.frame.height + 100)
        }
    }

    func dropDownConfirm(anchor: UIView, text: String, confirm: @escaping () -> Void) {
        let dropDown = DropDown()
        let actionSource = [text, NSLocalizedString("CANCEL", comment: "Cancel")]
        dropDown.dataSource = actionSource.map { "⁠\u{200b}   " + $0 + "⁠   \u{200b}" }
        dropDown.anchorView = anchor
        dropDown.selectionAction = { (index: Int, _: String) in
            if index == 0 {
                confirm()
            }
        }
        dropDown.show(onTopOf: window)
    }

    func dispatchValueUpdate() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .SettingReload, object: nil)
        }
    }

    @objc
    func openLicense() {
        let target = LicenseController()
        parentViewController?.present(next: target)
    }
}
