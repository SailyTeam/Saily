//
//  PackageCell.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/18.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import Digger
import FluentIcon
import SDWebImage
import UIKit

protocol PackageCellFunction {
    var horizontalPadding: CGFloat { set get }

    func prepareForNewValue()
    func loadValue(package: Package)
    func overrideIndicator(with icon: UIImage, and color: UIColor)
    func overrideDescribe(with text: String)
    func listenOnDownloadInfo()
}

class PackageCell: UIView, PackageCellFunction {
    var horizontalPadding: CGFloat = 0 {
        didSet {
            updatePadding()
        }
    }

    let contentView = UIView()

    let avatar = UIImageView()
    let indicator = UIImageView()
    let title = UILabel()
    let subtitle = UILabel()
    let describe = UILabel()
    let progressView = UIProgressView()

    var represent: Package?
    var currentToken = UUID()

    init() {
        super.init(frame: CGRect())

        let dragInteraction = UIDragInteraction(delegate: self)
        addInteraction(dragInteraction)

        addSubview(contentView)
        contentView.snp.makeConstraints { x in
            x.edges.equalToSuperview()
        }

        contentView.addSubview(avatar)
        contentView.addSubview(indicator)
        contentView.addSubview(title)
        contentView.addSubview(subtitle)
        contentView.addSubview(describe)
        contentView.addSubview(progressView)

        backgroundColor = .clear
        contentView.backgroundColor = .clear

        avatar.layer.cornerRadius = 8
        avatar.clipsToBounds = true
        avatar.contentMode = .scaleAspectFit
        avatar.snp.makeConstraints { x in
            x.centerY.equalTo(contentView.snp.centerY)
            x.leading.equalTo(contentView.snp.leading).offset(4 + horizontalPadding)
            x.height.equalTo(33)
            x.width.equalTo(33)
        }

        indicator.backgroundColor = .clear
        indicator.layer.cornerRadius = 8
        indicator.clipsToBounds = true
        indicator.snp.makeConstraints { x in
            x.centerX.equalTo(avatar.snp.right).offset(-4)
            x.centerY.equalTo(avatar.snp.bottom).offset(-4)
            x.height.equalTo(16)
            x.width.equalTo(16)
        }

        title.font = .boldSystemFont(ofSize: 16)
        title.textColor = UIColor(named: "RepoTableViewCell.Text")
        title.snp.makeConstraints { x in
            x.leading.equalTo(avatar.snp.trailing).offset(8)
            x.trailing.equalToSuperview().offset(-10 - horizontalPadding)
            x.height.equalTo(20)
            x.bottom.equalTo(subtitle.snp.top).offset(0)
        }

        subtitle.font = .boldSystemFont(ofSize: 10)
        subtitle.lineBreakMode = .byTruncatingTail
        subtitle.textColor = UIColor(named: "RepoTableViewCell.SubText")
        subtitle.snp.makeConstraints { x in
            x.centerY.equalTo(avatar.snp.centerY).offset(4)
            x.leading.equalTo(avatar.snp.trailing).offset(8)
            x.trailing.equalTo(title)
            x.height.equalTo(12)
        }

        describe.font = .boldSystemFont(ofSize: 8)
        describe.lineBreakMode = .byTruncatingTail
        describe.textColor = UIColor(named: "RepoTableViewCell.SubText")
        describe.numberOfLines = 1
        describe.snp.makeConstraints { x in
            x.leading.equalTo(avatar.snp.trailing).offset(8)
            x.trailing.equalTo(title)
            x.top.equalTo(subtitle.snp.bottom).offset(0)
            x.height.equalTo(12)
        }

        progressView.layer.cornerRadius = 1
        progressView.tintColor = .systemYellow
        progressView.snp.makeConstraints { x in
            x.leading.equalTo(title)
            x.trailing.equalTo(title)
            x.bottom.equalToSuperview()
            x.height.equalTo(2)
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateIndicator),
                                               name: .TaskContainerChanged,
                                               object: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func prepareForNewValue() {
        represent = nil // ***
        NotificationCenter.default.removeObserver(self, name: .DownloadProgress, object: nil)
        avatar.image = nil
        title.text = ""
        title.textColor = UIColor(named: "RepoTableViewCell.Text")
        subtitle.text = ""
        subtitle.textColor = UIColor(named: "RepoTableViewCell.SubText")
        describe.text = ""
        describe.textColor = UIColor(named: "RepoTableViewCell.SubText")
        progressView.tintColor = .systemYellow
        progressView.isHidden = true
        progressView.setProgress(0, animated: false)
        describe.font = .boldSystemFont(ofSize: 10)
        clearIndicator()
        represent = nil // ***
    }

    func clearIndicator() {
        indicator.image = nil
        indicator.backgroundColor = .clear
    }

    func updatePadding() {
        avatar.snp.updateConstraints { x in
            x.leading.equalTo(contentView.snp.leading).offset(4 + horizontalPadding)
        }
        title.snp.updateConstraints { x in
            x.trailing.equalToSuperview().offset(-10 - horizontalPadding)
        }
        contentView.layoutSubviews()
    }

    func loadValue(package: Package) {
        let token = UUID()
        currentToken = token
        represent = package

        avatar.image = UIImage(named: "PackageDefaultIcon")
        if let url = PackageCenter.default.avatarUrl(with: package) {
            SDWebImageManager
                .shared
                .loadImage(with: url,
                           options: .highPriority,
                           progress: nil) { [weak self] image, _, _, _, _, _ in
                    if let image = image, self?.currentToken == token {
                        self?.avatar.image = image
                    }
                }
        }

        if package.latestMetadata?["tag"]?.contains("cydia::commercial") ?? false {
            title.textColor = .systemPink
        } else {
            title.textColor = .label
        }
        title.text = PackageCenter.default.name(of: package)

        subtitle.text = package.latestVersion
        describe.text = PackageCenter.default.description(of: package)

        updateIndicator()
        updateDownloadProgress()
    }

    @objc
    func updateIndicator() {
        clearIndicator()
        if let represent = represent {
            // if is in queue
            if TaskManager.shared.isQueueContains(package: represent.identity) {
                let actions = TaskManager.shared.copyEveryActions()
                indicator.backgroundColor = .white
                for item in actions where
                    item.represent.identity == represent.identity
                {
                    switch item.action {
                    case .install:
                        let compare = Package
                            .compareVersion(item.represent.latestVersion ?? "",
                                            b: represent.latestVersion ?? "")
                        switch compare {
                        case .aIsEqualToB:
                            indicator.tintColor = .systemIndigo
                            indicator.image = .fluent(.arrowRightCircle24Filled)
                        case .aIsSmallerThenB:
                            indicator.tintColor = .systemBlue
                            indicator.image = .fluent(.arrowUpCircle24Filled)
                        case .aIsBiggerThenB:
                            indicator.tintColor = .systemGray2
                            indicator.image = .fluent(.arrowUpCircle24Filled)
                                .sd_flippedImage(withHorizontal: false, vertical: true)
                        default: break
                        }
                    case .remove:
                        indicator.tintColor = .systemRed
                        indicator.image = .fluent(.dismissCircle24Filled)
                    }
                    return
                }
                indicator.tintColor = .black
                indicator.image = .fluent(.questionCircle24Filled)
                return
            }

            if let installInfo = PackageCenter
                .default
                .obtainPackageInstallationInfo(with: represent.identity)
            {
                indicator.backgroundColor = .white
                let installedVersion = installInfo.version
                // compare to current version
                if let currentCellVersion = represent.latestVersion {
                    // we must have it right?
                    let compare = Package.compareVersion(currentCellVersion, b: installedVersion)
                    switch compare {
                    case .aIsBiggerThenB:
                        indicator.tintColor = .systemBlue
                        indicator.image = .fluent(.arrowUpCircle24Filled)
                    case .aIsEqualToB:
                        indicator.tintColor = .systemGreen
                        indicator.image = .fluent(.checkmarkCircle24Filled)
                    case .aIsSmallerThenB:
                        indicator.tintColor = .systemGray2
                        indicator.image = .fluent(.arrowUpCircle24Filled)
                            .sd_flippedImage(withHorizontal: false, vertical: true)
                    case .invalidParameter:
                        indicator.tintColor = .systemRed
                        indicator.image = .fluent(.errorCircle24Filled)
                    }
                }
            }
        }
    }

    func overrideIndicator(with icon: UIImage, and color: UIColor) {
        indicator.tintColor = color
        indicator.image = icon
    }

    func overrideDescribe(with text: String) {
        describe.text = text
    }

    func listenOnDownloadInfo() {
        progressView.isHidden = false
        progressView.alpha = 0.5
        describe.font = .monospacedSystemFont(ofSize: 10, weight: .semibold)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(downloadProgressUpdate(notification:)),
                                               name: .DownloadProgress,
                                               object: nil)
        updateDownloadProgress()
    }

    func updateDownloadProgress() {
        guard let represent = represent else { return }
        let url = represent.obtainDownloadLink()
        guard let status = CariolNetwork
            .shared
            .progressRecord(for: url)
        else {
            return
        }
        setDownloadLabels(with: status, confirmationIdentity: represent.identity)
    }

    @objc
    func downloadProgressUpdate(notification: Notification) {
        guard let represent = represent,
              let info = notification.object as? CariolNetwork.DownloadNotification,
              let packageId = info.represent?.identity,
              packageId == represent.identity
        else {
            return
        }
        DispatchQueue.main.async { [self] in
            setDownloadLabels(with: info, confirmationIdentity: represent.identity)
        }
    }

    func setDownloadLabels(with info: CariolNetwork.DownloadNotification,
                           confirmationIdentity: String)
    {
        guard let represent = represent,
              represent.identity == confirmationIdentity
        else {
            return
        }
        progressView.tintColor = .systemYellow
        describe.textColor = UIColor(named: "RepoTableViewCell.SubText")
        if info.completed {
            progressView.setProgress(1, animated: false)
            if let error = info.error {
                describe.text = error.localizedDescription
                describe.textColor = .systemRed
                progressView.tintColor = .systemRed
            } else if let url = info.targetLocation {
                describe.text = url.lastPathComponent
            } else {
                describe.text = NSLocalizedString("VALIDATING...", comment: "Validating...")
            }
            return
        }
        var descriptionBuilder = String(format: "%@/s %.2f%%",
                                        CariolNetwork.shared.byteFormat(bytes: info.speedBytes),
                                        info.progress.fractionCompleted * 100)
        let totalCount = info.progress.totalUnitCount
        if let sizeStr = represent.latestMetadata?["size"],
           let size = Int(sizeStr),
           size > 0
        {
            descriptionBuilder += " [\(CariolNetwork.shared.byteFormat(bytes: size))]"
            if totalCount > 100, totalCount < size { // 100 bytes
                descriptionBuilder += " " + NSLocalizedString("RESUMED", comment: "Resumed").lowercased()
                descriptionBuilder += " ..+ \(CariolNetwork.shared.byteFormat(bytes: Int(totalCount)))"
            }
        }

        describe.text = descriptionBuilder
        UIView.animate(withDuration: 0.2) { [self] in
            progressView.setProgress(Float(info.progress.fractionCompleted), animated: true)
        }
    }
}

extension PackageCell: UIDragInteractionDelegate {
    func dragInteraction(_: UIDragInteraction, itemsForBeginning _: UIDragSession) -> [UIDragItem] {
        guard let package = represent else { return [] }

        // define
        let provider = NSItemProvider(object: captureDragImage())
        let dragItem = UIDragItem(itemProvider: provider)

        // attach user activity if available
        if let data = package.propertyListEncoded() {
            let userActivity = NSUserActivity(activityType: cUserActivityDropPackage)
            userActivity.title = cUserActivityDropPackage
            userActivity.userInfo = ["attach": data]
            provider.registerObject(userActivity, visibility: .all)
        }

        // return drag
        return [dragItem]
    }

    private func captureDragImage() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(bounds.size, isOpaque, 0.0)
        defer { UIGraphicsEndImageContext() }
        if let context = UIGraphicsGetCurrentContext() {
            layer.render(in: context)
            if let image = UIGraphicsGetImageFromCurrentImageContext() {
                return image
            }
        }
        return UIImage.fluent(.extension24Filled)
    }
}
