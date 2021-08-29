//
//  PackageTableCell.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/18.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import SDWebImage
import UIKit

class PackageTableCell: UITableViewCell, PackageCellFunction {
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

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubview(originalCell)
        originalCell.snp.makeConstraints { x in
            x.edges.equalToSuperview()
        }
        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }
}
