//
//  SearchPlaceholder.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/14.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import FluentIcon
import UIKit

class SearchPlaceholder: UIView {
    private struct Guider {
        let icon: UIImage
        let text: String
    }

    private let payloads: [Guider] = [
        .init(icon: UIImage.fluent(.starLineHorizontal324Filled),
              text: NSLocalizedString("SEARCH_GUIDE_FAVORITE",
                                      comment: "Search in your favorite collection.")),
        .init(icon: UIImage.fluent(.bookGlobe24Filled),
              text: NSLocalizedString("SEARCH_GUIDE_REPO",
                                      comment: "Search for a repository with url or description.")),
        .init(icon: UIImage.fluent(.toolbox24Filled),
              text: NSLocalizedString("SEARCH_GUIDE_PACAKGE",
                                      comment: "Search for a packages with name or description.")),
        .init(icon: UIImage.fluent(.peopleSearch24Filled),
              text: NSLocalizedString("SEARCH_GUIDE_AUTHOR",
                                      comment: "Search for everything by an author with name.")),
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
            text.textColor = UIColor(named: "TEXT_SUBTITLE")
            addSubview(text)
            text.snp.makeConstraints { x in
                x.trailing.equalToSuperview()
                x.leading.equalTo(image.snp.trailing).offset(12)
                x.top.equalTo(anchor.snp.bottom).offset(15)
                x.height.equalTo(50)
            }

            image.contentMode = .scaleAspectFit
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
