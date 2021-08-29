//
//  RecentUpdateView.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/29.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import SPIndicator
import UIKit

class RecentUpdateView: UIView {
    let contentView = UIView()
    let label = UILabel()
    let arrow = UIImageView()
    let indicator = UIImageView()
    let imageView = UIImageView()
    let button = UIButton()

    init() {
        super.init(frame: CGRect())

        addSubview(contentView)
        contentView.addSubview(imageView)
        contentView.addSubview(label)
        contentView.addSubview(indicator)
        addSubview(button)

        contentView.backgroundColor = UIColor(named: "CARD_BACKGROUND")
        contentView.layer.cornerRadius = 12
        contentView.snp.makeConstraints { x in
            x.edges.equalToSuperview()
        }

        imageView.image = UIImage(systemName: "sparkles")
        imageView.tintColor = .orange
        imageView.snp.makeConstraints { x in
            x.centerY.equalToSuperview()
            x.width.equalTo(30)
            x.height.equalTo(30)
            x.leading.equalToSuperview().offset(12)
        }

        label.font = .roundedFont(ofSize: 16, weight: .semibold)
        label.snp.makeConstraints { x in
            x.centerY.equalToSuperview()
            x.leading.equalTo(imageView.snp.trailing).offset(8)
            x.trailing.equalTo(indicator.snp.leading).offset(-8)
        }

        indicator.layer.cornerRadius = 8
        indicator.backgroundColor = .white
        indicator.tintColor = .systemGreen
        indicator.snp.makeConstraints { x in
            x.trailing.equalToSuperview().offset(-12)
            x.centerY.equalToSuperview()
            x.width.equalTo(16)
            x.height.equalTo(16)
        }

        button.snp.makeConstraints { x in
            x.edges.equalToSuperview()
        }
        button.addTarget(self, action: #selector(touched), for: .touchUpInside)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reloadData),
                                               name: PackageCenter.packageRecordChanged,
                                               object: nil)
        reloadData()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    func reloadData() {
        DispatchQueue.main.async { [self] in
            let list = PackageCenter
                .default
                .obtainRecentUpdatedList()
            if list.count == 0 {
                label.text = NSLocalizedString("NOTHING_UPDATED", comment: "Nothing Updated")
                indicator.image = .fluent(.checkmarkCircle24Filled)
            } else {
                label.text = NSLocalizedString("RECENT_UPDATE", comment: "Recent Update")
                indicator.image = .fluent(.arrowRightCircle24Filled)
            }
        }
    }

    @objc
    func touched() {
        contentView.puddingAnimate()
        var list = PackageCenter
            .default
            .obtainRecentUpdatedList()
        guard list.count > 0 else {
            SPIndicator.present(title: NSLocalizedString("NOTHING_UPDATED", comment: "Nothing Updated"),
                                message: "",
                                preset: .done,
                                haptic: .success,
                                from: .top,
                                completion: nil)
            return
        }
        for (key, value) in list {
            list[key] = value.sorted(by: \.0)
        }
        let target = RecentUpdateController()
        target.updateDataSource = list
        parentViewController?.present(next: target)
    }
}
