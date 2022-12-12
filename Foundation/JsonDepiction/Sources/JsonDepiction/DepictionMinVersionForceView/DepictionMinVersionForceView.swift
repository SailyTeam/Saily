//
//  DepictionMinVersionForceView.swift
//  Sileo
//
//  Created by CoolStar on 7/6/19.
//  Copyright © 2019 CoolStar. All rights reserved.
//

import UIKit

class DepictionMinVersionForceView: DepictionBaseView {
    var containedView: DepictionBaseView?

    required init?(dictionary: [String: Any], viewController: UIViewController, tintColor: UIColor, isActionable: Bool) {
        guard let view = dictionary["view"] as? [String: Any] else {
            return nil
        }

        super.init(dictionary: dictionary, viewController: viewController, tintColor: tintColor, isActionable: isActionable)

        if let baseView = DepictionBaseView.view(dictionary: view, viewController: viewController, tintColor: tintColor, isActionable: isActionable) {
            containedView = baseView
            addSubview(baseView)
        }
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func depictionHeight(width: CGFloat) -> CGFloat {
        guard let containedView else {
            return 0
        }
        return containedView.depictionHeight(width: width)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        containedView?.frame = bounds
    }

    override var isHighlighted: Bool {
        didSet {
            if isActionable {
                containedView?.isHighlighted = isHighlighted
            }
        }
    }
}
