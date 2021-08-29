//
//  LXTaskPlaceholder.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/29.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import UIKit

class LXTaskPlaceholder: UIView {
    private struct Guider {
        let icon: UIImage
        let text: String
    }

    private let payloads: [Guider] = [
        .init(icon: UIImage.fluent(.cloudDownload24Filled),
              text: NSLocalizedString("DOWNLOAD_CAN_RESUME_ANY_TIME",
                                      comment: "Your download can be resumed any time.")),
        .init(icon: UIImage.fluent(.attachArrowRight24Filled),
              text: NSLocalizedString("ADDITIONAL_OPERATIONS_ARE_APPOINTED_BY_PACKAGE_VENDER",
                                      comment: "Additional operations are appointed by package vender.")),
        .init(icon: UIImage.fluent(.documentSearch24Filled),
              text: NSLocalizedString("DOWNLOADED_FILE_CAN_BE_FOUND_IN_SETTING",
                                      comment: "Downloaded file can be found in setting.")),
        .init(icon: UIImage.fluent(.checkmarkLock24Filled),
              text: NSLocalizedString("FILE_ARE_HASH_VERIFIED_BEFORE_PROCESSING",
                                      comment: "Files are hash verified before processing.")),
    ]

    init() {
        super.init(frame: CGRect())

        var anchor = UIView()
        addSubview(anchor)
        anchor.snp.makeConstraints { x in
            x.leading.equalToSuperview()
            x.trailing.equalToSuperview()
            x.top.equalToSuperview()
            x.height.equalTo(0)
        }

        payloads.forEach { guid in

            let text = UILabel(text: guid.text)
            let image = UIImageView(image: guid.icon)
            addSubview(image)

            text.numberOfLines = 5
            text.font = .systemFont(ofSize: 16, weight: .semibold)
            text.textColor = .systemOrange
            addSubview(text)
            text.snp.makeConstraints { x in
                x.trailing.equalToSuperview()
                x.leading.equalTo(image.snp.trailing).offset(12)
                x.top.equalTo(anchor.snp.bottom).offset(15)
                x.height.equalTo(50)
            }

            image.contentMode = .scaleAspectFit
            image.tintColor = .systemOrange
            image.snp.makeConstraints { x in
                x.leading.equalToSuperview()
                x.width.equalTo(30)
                x.height.equalTo(30)
                x.centerY.equalTo(text.snp.centerY)
            }

            anchor = text
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }
}
