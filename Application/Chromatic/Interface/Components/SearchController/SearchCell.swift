//
//  SearchCell.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/13.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import SDWebImage
import UIKit

class SearchCell: UITableViewCell {
    let image = UIImageView()
    let title = UILabel()
    let subtitle = UILabel()
    let describe = UILabel()

    var displayToken: UUID = .init()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .gray

        contentView.addSubview(image)
        contentView.addSubview(title)
        contentView.addSubview(subtitle)
        contentView.addSubview(describe)

        backgroundColor = .clear
        contentView.backgroundColor = .clear

        image.image = UIImage.fluent(.bookNumber24Filled)
        image.layer.cornerRadius = 8
        image.tintColor = .systemOrange
        image.clipsToBounds = true
        image.contentMode = .scaleAspectFit
        image.snp.makeConstraints { x in
            x.centerY.equalTo(contentView.snp.centerY)
            x.leading.equalTo(contentView.snp.leading).offset(12)
            x.height.equalTo(33)
            x.width.equalTo(33)
        }

        title.font = .boldSystemFont(ofSize: 16)
        title.clipsToBounds = false
        title.textColor = UIColor(named: "SearchCell.Text")
        title.snp.makeConstraints { x in
            x.leading.equalTo(image.snp.trailing).offset(8)
            x.trailing.equalToSuperview().offset(-10)
            x.height.equalTo(20)
            x.bottom.equalTo(subtitle.snp.top).offset(0)
        }

        subtitle.font = .boldSystemFont(ofSize: 10)
        subtitle.lineBreakMode = .byTruncatingTail
        subtitle.textColor = UIColor(named: "SearchCell.SubText")
        subtitle.snp.makeConstraints { x in
            x.centerY.equalTo(image.snp.centerY).offset(4)
            x.leading.equalTo(image.snp.trailing).offset(8)
            x.trailing.equalTo(contentView.snp.trailing).offset(-30)
            x.height.equalTo(14)
        }

        describe.font = .boldSystemFont(ofSize: 8)
        describe.lineBreakMode = .byTruncatingTail
        describe.textColor = UIColor(named: "SearchCell.SubText")
        describe.snp.makeConstraints { x in
            x.leading.equalTo(image.snp.trailing).offset(8)
            x.trailing.equalTo(contentView.snp.trailing)
            x.top.equalTo(subtitle.snp.bottom).offset(0)
            x.height.equalTo(12)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    func prepareNewValue() -> UUID {
        image.image = nil
        title.text = ""
        title.textColor = .label
        subtitle.text = ""
        describe.text = ""
        describe.attributedText = nil
        describe.textColor = UIColor(named: "SearchCell.SubText")
        let token = UUID()
        displayToken = token
        return token
    }

    func makeEmptyHinter() {
        image.image = UIImage.fluent(.documentNone24Regular)
        title.text = NSLocalizedString("NO_RESULT_FOUND", comment: "No Result Found")
        subtitle.text = NSLocalizedString("CHANGE_YOUR_KEYWORD_OR_REFRESH_REPO", comment: "Change your keyword or refresh the repo.")
        describe.text = "o( =•ω•= )m"
    }

    func insertValue(with result: SearchResult, token: UUID) {
        switch result.associatedValue {
        // MARK: - AUTHOR

        case let .author(name):
            title.text = name
            subtitle.text = NSLocalizedString("FOUND_AUTHOR_WITH_NAME", comment: "Found author with this search key.")
            image.image = UIImage.fluent(.peopleSearch24Regular)

        // MARK: - INSTALLED & COLLECTION

        case let .installed(package), let .collection(package):
            insertPackageValue(package, withToken: token)

        // MARK: - PACKAGE

        case let .package(identity, repository):
            guard let package = RepositoryCenter
                .default
                .obtainImmutableRepository(withUrl: repository)?
                .metaPackage[identity]
            else {
                return
            }
            insertPackageValue(package, withToken: token)

        // MARK: - REPO

        case let .repository(url):
            let repo = RepositoryCenter
                .default
                .obtainImmutableRepository(withUrl: url)
            title.text = repo?.nickName
            subtitle.text = url.absoluteString
            if let data = repo?.avatar, let img = UIImage(data: data) {
                image.image = img
            } else {
                image.image = UIImage.fluent(.bookCompass24Filled)
            }
        }

        // MARK: - SEARCH HIGHLIGHT

        let description = result
            .searchText
            .components(separatedBy: "\n")
            .filter { $0.contains(result.underKey) }
            .first
        describe.text = description
        describe.limitedLeadingHighlight(text: result.underKey, color: .systemOrange)
    }

    private func insertPackageValue(_ package: Package, withToken token: UUID) {
        if package.latestMetadata?["tag"]?.contains("cydia::commercial") ?? false {
            title.textColor = .systemPink
        }
        title.text = PackageCenter.default.name(of: package)
        let description = PackageCenter.default.description(of: package)
        if let repoUrl = package.repoRef,
           let repo = RepositoryCenter.default.obtainImmutableRepository(withUrl: repoUrl)
        {
            subtitle.text = "[\(repo.nickName)] \(description)"
        } else {
            subtitle.text = description
        }
        image.image = UIImage(named: "PackageDefaultIcon")
        if let iconUrl = PackageCenter.default.avatarUrl(with: package) {
            SDWebImageManager
                .shared
                .loadImage(with: iconUrl,
                           options: .highPriority,
                           progress: nil) { [weak self] img, _, _, _, _, _ in
                    if let img = img, self?.displayToken == token {
                        self?.image.image = img
                    }
                }
        }
    }
}
