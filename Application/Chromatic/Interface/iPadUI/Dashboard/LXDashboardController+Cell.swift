//
//  LXDashboardController+Cell.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/9/14.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import UIKit

class LXDashboardMoreCell: UICollectionViewCell {
    override init(frame _: CGRect) {
        super.init(frame: CGRect())
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .thin)
        imageView.image = UIImage(systemName: "ellipsis", withConfiguration: config)
        imageView.tintColor = .gray.withAlphaComponent(0.5)
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        imageView.snp.makeConstraints { x in
            x.center.equalToSuperview()
            x.width.equalTo(40)
            x.height.equalTo(40)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class LXDashboardSupplementHeaderCell: UICollectionReusableView {
    let label = UILabel()
    let button = UIButton()
    var overrideButtonAction: (() -> Void)?

    var representSection: LXDashboardController.DataSection?
    var horizontalPadding: CGFloat = 2 {
        didSet {
            updateLayout()
        }
    }

    override init(frame _: CGRect) {
        super.init(frame: CGRect())
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        addSubview(label)
        button.setImage(.fluent(.arrowRightCircle24Filled), for: .normal)
        button.addTarget(self, action: #selector(presentFullPackage), for: .touchUpInside)
        addSubview(button)
        updateLayout()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    func updateLayout() {
        label.snp.makeConstraints { x in
            x.leading.equalToSuperview().offset(horizontalPadding)
            x.trailing.equalTo(button.snp.leading).offset(-5)
//            x.centerY.equalToSuperview()
            x.bottom.equalToSuperview().offset(-15)
        }
        button.snp.makeConstraints { x in
            x.centerY.equalTo(label)
            x.trailing.equalToSuperview().offset(-horizontalPadding)
            x.width.equalTo(33)
            x.height.equalTo(33)
        }
    }

    func prepareNewValue() {
        representSection = nil
        overrideButtonAction = nil
        label.text = ""
    }

    func loadSection(data: LXDashboardController.DataSection) {
        representSection = data
        label.text = data.title
    }

    @objc
    func presentFullPackage() {
        button.shineAnimation()
        if let override = overrideButtonAction {
            override()
            return
        }
        let target = PackageCollectionController()
        target.title = representSection?.title
        target.dataSource = representSection?.package ?? []
        parentViewController?.present(next: target)
    }
}
