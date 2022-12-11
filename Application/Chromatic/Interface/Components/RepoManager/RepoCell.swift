//
//  RepoCell.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/20.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import SnapKit
import UIKit

private let formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.formatterBehavior = .behavior10_4
    formatter.dateStyle = .medium
    formatter.timeStyle = .medium
    return formatter
}()

class RepoCell: UIView {
    var title = UILabel()
    let subtitle = UILabel()
    let describe = UILabel()
    var icon = UIImageView()
    let arrow = UIImageView(image: UIImage(named: "RepoTableViewCell.trailing"))
    let indicator = UIView()
    var repoUrl: URL?

    let contentView = UIView()

    init() {
        super.init(frame: CGRect())

        addSubview(contentView)
        contentView.snp.makeConstraints { x in
            x.edges.equalToSuperview()
        }
        contentView.addSubview(icon)
        contentView.addSubview(title)
        contentView.addSubview(subtitle)
        contentView.addSubview(describe)
        contentView.addSubview(arrow)
        contentView.addSubview(indicator)

        backgroundColor = .clear
        contentView.backgroundColor = .clear

        icon.image = UIImage(named: "RepoTableViewCell.Missing")
        icon.layer.cornerRadius = 8
        icon.clipsToBounds = true
        icon.contentMode = .scaleAspectFit
        icon.snp.remakeConstraints { x in
            x.centerY.equalTo(contentView.snp.centerY)
            x.leading.equalTo(contentView.snp.leading).offset(4)
            x.height.equalTo(33)
            x.width.equalTo(33)
        }

        indicator.backgroundColor = .clear
        indicator.layer.cornerRadius = 4
        indicator.clipsToBounds = true
        indicator.snp.makeConstraints { x in
            x.centerX.equalTo(icon.snp.right).offset(-2)
            x.centerY.equalTo(icon.snp.bottom).offset(-2)
            x.height.equalTo(8)
            x.width.equalTo(8)
        }

        title.font = .boldSystemFont(ofSize: 16)
        title.clipsToBounds = false
        title.textColor = UIColor(named: "RepoTableViewCell.Text")
        title.snp.makeConstraints { x in
            x.leading.equalTo(icon.snp.trailing).offset(8)
            x.trailing.equalTo(arrow.snp.leading).offset(-10)
            x.height.equalTo(20)
            x.bottom.equalTo(subtitle.snp.top).offset(0)
        }

        subtitle.font = .boldSystemFont(ofSize: 10)
        subtitle.lineBreakMode = .byTruncatingTail
        subtitle.textColor = UIColor(named: "RepoTableViewCell.SubText")
        subtitle.snp.makeConstraints { x in
            x.centerY.equalTo(icon.snp.centerY).offset(4)
            x.leading.equalTo(icon.snp.trailing).offset(8)
            x.trailing.equalTo(contentView.snp.trailing).offset(-30)
            x.height.equalTo(14)
        }

        describe.font = .boldSystemFont(ofSize: 8)
        describe.lineBreakMode = .byTruncatingTail
        describe.textColor = UIColor(named: "RepoTableViewCell.SubText")
        describe.snp.makeConstraints { x in
            x.leading.equalTo(icon.snp.trailing).offset(8)
            x.trailing.equalTo(contentView.snp.trailing)
            x.top.equalTo(subtitle.snp.bottom).offset(0)
            x.height.equalTo(12)
        }

        arrow.contentMode = .scaleAspectFit
        arrow.snp.makeConstraints { x in
            x.centerY.equalTo(contentView.snp.centerY)
            x.trailing.equalTo(contentView.snp.trailing).offset(-4)
            x.height.equalTo(16)
            x.width.equalTo(16)
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateRepoMetadata),
                                               name: RepositoryCenter.metadataUpdate,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateIndicator),
                                               name: .RepositoryQueueChanged,
                                               object: nil)
    }

    @objc
    func updateRepoMetadata(withNotification: Notification) {
        if let url = repoUrl,
           let updateOn = withNotification.object as? RepositoryCenter.UpdateNotification,
           url == updateOn.representedRepo
        {
            setRepository(withUrl: url)
        }
    }

    @objc
    func updateIndicator() {
        if let url = repoUrl {
            setRepository(withUrl: url)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func prepareForNewValue() {
        title.text = ""
        subtitle.text = ""
        describe.text = ""
        icon.image = nil
        repoUrl = nil
        indicator.backgroundColor = .clear
    }

    func setRepository(withUrl: URL) {
        repoUrl = withUrl
        let repo = RepositoryCenter.default.obtainImmutableRepository(withUrl: withUrl)
        title.text = repo?.nickName ?? ""
        subtitle.text = repo?.url.absoluteString ?? ""
        if let date = repo?.lastUpdatePackage, date != Date(timeIntervalSince1970: 0) {
            describe.text = formatter.string(from: date)
            describe.textColor = UIColor(named: "RepoTableViewCell.SubText")
        } else {
            describe.text = NSLocalizedString("NOT_AVAILABLE", comment: "Not Available")
            describe.textColor = .systemOrange
        }
        if let data = repo?.avatar,
           let image = UIImage(data: data)
        {
            icon.image = image
        } else {
            icon.image = UIImage.fluent(.bookCompass24Filled)
        }
        let indicatorDecision = RepositoryCenter.default.isRepositoryReadyForUse(withUrl: withUrl)
        if let decision = indicatorDecision {
            if RepositoryCenter.default.isRepositoryPreparedForUpdate(withUrl: withUrl) {
                indicator.backgroundColor = .cyan
            } else {
                if decision {
                    indicator.backgroundColor = .systemGreen
                } else {
                    indicator.backgroundColor = .systemOrange
                }
            }
        } else {
            indicator.backgroundColor = .clear
        }
    }

    func setNoRepoAvailable() {
        title.text = NSLocalizedString("NO_REPO", comment: "No Repository")
        subtitle.text = NSLocalizedString("PLEASE_ADD_REPO", comment: "Press add button above to add some")
        describe.text = "o( =•ω•= )m"
        icon.image = UIImage.fluent(.bookCompass24Filled)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }
}

class RepoCompactCell: UIView {
    var title = UILabel()
    var icon = UIImageView()

    let contentView = UIView()

    var repoUrl: URL?

    init() {
        super.init(frame: CGRect())

        addSubview(contentView)
        contentView.snp.makeConstraints { x in
            x.edges.equalToSuperview()
        }
        contentView.addSubview(icon)
        contentView.addSubview(title)

        backgroundColor = .clear
        contentView.backgroundColor = .clear

        icon.image = UIImage(named: "RepoTableViewCell.Missing")
        icon.layer.cornerRadius = 4
        icon.clipsToBounds = true
        icon.contentMode = .scaleAspectFit
        icon.snp.remakeConstraints { x in
            x.centerY.equalTo(contentView.snp.centerY)
            x.leading.equalTo(contentView.snp.leading).offset(4)
            x.height.equalTo(20)
            x.width.equalTo(20)
        }

        title.font = .boldSystemFont(ofSize: 16)
        title.clipsToBounds = false
        title.textColor = UIColor(named: "RepoTableViewCell.Text")
        title.snp.makeConstraints { x in
            x.leading.equalTo(icon.snp.trailing).offset(8)
            x.trailing.equalToSuperview()
            x.height.equalTo(20)
            x.centerY.equalTo(icon)
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateRepoMetadata),
                                               name: RepositoryCenter.metadataUpdate,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateIndicator),
                                               name: .RepositoryQueueChanged,
                                               object: nil)
    }

    @objc
    func updateRepoMetadata(withNotification: Notification) {
        if let url = repoUrl,
           let updateOn = withNotification.object as? RepositoryCenter.UpdateNotification,
           url == updateOn.representedRepo
        {
            setRepository(withUrl: url)
        }
    }

    @objc
    func updateIndicator() {
        if let url = repoUrl {
            setRepository(withUrl: url)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func prepareForNewValue() {
        title.text = ""
        icon.image = nil
        repoUrl = nil
    }

    func setRepository(withUrl: URL) {
        repoUrl = withUrl
        let repo = RepositoryCenter.default.obtainImmutableRepository(withUrl: withUrl)
        title.text = repo?.nickName ?? ""
        if let data = repo?.avatar,
           let image = UIImage(data: data)
        {
            icon.image = image
        } else {
            icon.image = UIImage.fluent(.bookCompass24Filled)
        }
    }

    func setNoRepoAvailable() {
        title.text = NSLocalizedString("NO_REPO", comment: "No Repository")
        icon.image = UIImage.fluent(.bookCompass24Filled)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }
}
