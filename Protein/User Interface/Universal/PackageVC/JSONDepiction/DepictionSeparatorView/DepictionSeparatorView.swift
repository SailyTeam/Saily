//
//  DepictionSeparatorView.swift
//  Sileo
//
//  Created by CoolStar on 7/6/19.
//  Copyright © 2019 CoolStar. All rights reserved.
//
// Make sure to also update FeaturedSeparatorView.swift

import UIKit

@objc(DepictionSeparatorView)
class DepictionSeparatorView: DepictionBaseView {
    private var separatorView: UIView?

    required init?(dictionary: [String: Any], viewController: UIViewController, tintColor: UIColor) {
        separatorView = UIView(frame: .zero)

        super.init(dictionary: dictionary, viewController: viewController, tintColor: tintColor)
        separatorView?.backgroundColor = SEColors.separatorColor
        addSubview(separatorView!)
        
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func updateSileoColors() {
        separatorView?.backgroundColor = SEColors.separatorColor
    }
    
    override func depictionHeight(width: CGFloat) -> CGFloat {
        3
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        separatorView?.frame = CGRect(x: 16, y: 1, width: self.bounds.width - 32, height: 1)
    }
}
