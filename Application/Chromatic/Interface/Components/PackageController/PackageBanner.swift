//
//  PackageBanner.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/17.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import SDWebImage
import UIKit

class PackageBannerView: UIView {
    let package: Package

    var icon = UIImageView()
    var name = UILabel()
    var version = UILabel()

    let padding = 15

    var button = UIButton()
    let buttonBackground = UIView()
    let buttonAnchor = UIView()

    init(package: Package) {
        self.package = package

        super.init(frame: CGRect())

        addSubview(icon)
        addSubview(name)
        addSubview(version)
        addSubview(buttonBackground)
        addSubview(button)
        addSubview(buttonAnchor)

        icon.clipsToBounds = true
        icon.layer.cornerRadius = 8
        icon.contentMode = .scaleAspectFill
        icon.tintColor = .systemOrange
        name.textColor = UIColor(named: "TEXT_TITLE")
        name.font = .boldSystemFont(ofSize: 22)
        name.numberOfLines = 1
        name.minimumScaleFactor = 0.5
        name.adjustsFontSizeToFitWidth = true
        version.textColor = UIColor(named: "TEXT_SUBTITLE")
        version.font = .boldSystemFont(ofSize: 14)

        icon.snp.makeConstraints { x in
            x.centerY.equalToSuperview()
            x.left.equalToSuperview().offset(padding)
            x.width.equalTo(icon.snp.height)
            x.top.equalToSuperview().offset(padding)
        }
        name.snp.makeConstraints { x in
            x.left.equalTo(icon.snp.right).offset(8)
            x.bottom.equalTo(icon.snp.centerY).offset(4)
            x.right.equalTo(button.snp.left).offset(-12)
        }
        version.snp.makeConstraints { x in
            x.left.equalTo(icon.snp.right).offset(8)
            x.top.equalTo(icon.snp.centerY).offset(4)
            x.right.equalTo(button.snp.left).offset(-8)
        }

        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.minimumScaleFactor = 0.2
        button.titleLabel?.lineBreakMode = .byClipping
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.gray, for: .highlighted)
        button.addTarget(self, action: #selector(dropDownActionList), for: .touchUpInside)
        button.snp.makeConstraints { x in
            x.centerY.equalToSuperview()
            x.right.equalToSuperview().offset(-20)
            x.width.equalTo(50)
            x.height.equalTo(30)
        }
        buttonBackground.backgroundColor = .systemOrange
        buttonBackground.layer.cornerRadius = 15
        buttonBackground.snp.makeConstraints { x in
            x.top.equalTo(button)
            x.bottom.equalTo(button)
            x.leading.equalTo(button).offset(-8)
            x.trailing.equalTo(button).offset(8)
        }
        buttonAnchor.snp.makeConstraints { x in
            x.trailing.equalTo(buttonBackground)
            x.top.equalTo(buttonBackground.snp.bottom).offset(10)
            x.height.equalTo(2)
            x.width.equalTo(250)
        }

        updateValues()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateValues),
                                               name: .TaskContainerChanged,
                                               object: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    func updateValues() {
        name.text = PackageCenter.default.name(of: package)
        version.text = package.latestVersion ?? "0.0.0.???"
        icon.image = UIImage(named: "PackageDefaultIcon")
        button.setTitle(grabButtonString(), for: .normal)

        // now we need to update button size from localized string
        var width = button.intrinsicContentSize.width
        if width < 50 { width = 50 }
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 1.0,
            initialSpringVelocity: 0.8,
            options: .curveEaseInOut
        ) {
            self.button.snp.updateConstraints { make in
                make.width.equalTo(width + 10) // so min would be 60
            }
            self.button.layoutIfNeeded()
        } completion: { _ in }

        if let iconUrl = PackageCenter.default.avatarUrl(with: package) {
            SDWebImageManager
                .shared
                .loadImage(with: iconUrl,
                           options: .highPriority,
                           progress: nil) { [weak self] img, _, _, _, _, _ in
                    if let img = img {
                        self?.icon.image = img
                    }
                }
        }
    }

    func grabButtonString() -> String {
        if TaskManager.shared.isQueueContains(package: package.identity) {
            return NSLocalizedString("QUEUED", comment: "Queued").uppercased()
        }
        if PackageCenter
            .default
            .obtainPackageInstallationInfo(with: package.identity)
            == nil
        {
            if let tag = package.latestMetadata?["tag"],
               tag.contains("cydia::commercial")
            {
                return NSLocalizedString("BUY", comment: "Buy").uppercased()
            }
            return NSLocalizedString("INSTALL", comment: "Install").uppercased()
        }
        return NSLocalizedString("OPTION", comment: "Option").uppercased()
    }
}
