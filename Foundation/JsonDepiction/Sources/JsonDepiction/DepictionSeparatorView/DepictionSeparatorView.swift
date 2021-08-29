//
//  DepictionSeparatorView.swift
//  Sileo
//
//  Created by CoolStar on 7/6/19.
//  Copyright © 2019 CoolStar. All rights reserved.
//
// Make sure to also update FeaturedSeparatorView.swift

import UIKit

class DepictionSeparatorView: DepictionBaseView {
    private var separatorView: UIView?

    required init?(dictionary: [String: Any], viewController: UIViewController, tintColor: UIColor, isActionable: Bool) {
        separatorView = UIView(frame: .zero)

        super.init(dictionary: dictionary, viewController: viewController, tintColor: tintColor, isActionable: isActionable)
        separatorView?.backgroundColor = .sileoSeparatorColor
        addSubview(separatorView!)
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func updateSileoColors() {
        separatorView?.backgroundColor = .sileoSeparatorColor
    }

    override func depictionHeight(width _: CGFloat) -> CGFloat {
        3
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        separatorView?.frame = CGRect(x: 16, y: 1, width: bounds.width - 32, height: 1)
    }
}
