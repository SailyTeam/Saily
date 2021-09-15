//
//  PackageCollectionCell.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/18.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import SDWebImage
import UIKit

class ReuseTimerHeaderView: UICollectionReusableView {
    let label = UILabel()
    var horizontalPadding: CGFloat = 10 {
        didSet {
            updateSnapKitConstraints()
        }
    }

    override init(frame _: CGRect) {
        super.init(frame: CGRect())
        label.font = .roundedFont(ofSize: 12, weight: .semibold)
        label.textColor = .gray
        addSubview(label)
        updateSnapKitConstraints()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    func loadText(_ str: String) {
        label.text = str
    }

    func updateSnapKitConstraints() {
        label.snp.remakeConstraints { x in
            x.leading.equalToSuperview().offset(horizontalPadding)
            x.trailing.equalToSuperview().offset(-horizontalPadding)
            x.centerY.equalToSuperview()
            x.height.equalTo(20)
        }
    }
}

class PackageCollectionCell: UICollectionViewCell, PackageCellFunction {
    let originalCell = PackageCell()

    var horizontalPadding: CGFloat {
        get {
            originalCell.horizontalPadding
        }
        set {
            originalCell.horizontalPadding = newValue
        }
    }

    func prepareForNewValue() {
        originalCell.prepareForNewValue()
    }

    func loadValue(package: Package) {
        originalCell.loadValue(package: package)
    }

    func overrideIndicator(with icon: UIImage, and color: UIColor) {
        originalCell.overrideIndicator(with: icon, and: color)
    }

    func overrideDescribe(with text: String) {
        originalCell.overrideDescribe(with: text)
    }

    func listenOnDownloadInfo() {
        originalCell.listenOnDownloadInfo()
    }

    override init(frame _: CGRect) {
        super.init(frame: CGRect())
        addSubview(originalCell)
        originalCell.snp.makeConstraints { x in
            x.edges.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }
}
