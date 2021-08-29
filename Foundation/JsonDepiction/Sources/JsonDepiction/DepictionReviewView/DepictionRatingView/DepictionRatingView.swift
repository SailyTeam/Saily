//
//  DepictionRatingView.swift
//  Sileo
//
//  Created by CoolStar on 7/6/19.
//  Copyright © 2019 CoolStar. All rights reserved.
//

import Cosmos
import UIKit

class DepictionRatingView: DepictionBaseView {
    private var rating: CGFloat
    private var alignment: Int

    private var ratingView: CosmosView?

    required init?(dictionary: [String: Any], viewController: UIViewController, tintColor: UIColor, isActionable: Bool) {
        guard let rawRating = dictionary["rating"] as? CGFloat else {
            return nil
        }
        rating = rawRating
        guard let rawAlignment = dictionary["alignment"] as? Int else {
            return nil
        }
        alignment = rawAlignment
        super.init(dictionary: dictionary, viewController: viewController, tintColor: tintColor, isActionable: isActionable)

        var settings = CosmosSettings()
        settings.fillMode = .precise
        settings.starSize = 19
        settings.starMargin = 1
        settings.filledColor = UIColor(white: 161.0 / 255.0, alpha: 1.0)
        settings.emptyBorderColor = UIColor(white: 161.0 / 255.0, alpha: 1.0)
        settings.filledBorderColor = UIColor(white: 161.0 / 255.0, alpha: 1.0)

        ratingView = CosmosView(settings: settings)
        ratingView?.rating = Double(rating)
        addSubview(ratingView!)
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func depictionHeight(width _: CGFloat) -> CGFloat {
        40
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        var x = CGFloat(0)
        switch alignment {
        case 1: do {
                x = (bounds.width - 100.0) / 2.0
                break
            }
        case 2: do {
                x = (bounds.width - 100.0)
                break
            }
        default: do {
                x = 0
                break
            }
        }
        ratingView?.frame = CGRect(x: x, y: bounds.height - 20.0, width: 100.0, height: 20.0)
    }
}
