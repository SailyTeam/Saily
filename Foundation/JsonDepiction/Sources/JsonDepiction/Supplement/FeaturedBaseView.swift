//
//  FeaturedBaseView.swift
//  Sileo
//
//  Created by CoolStar on 7/6/19.
//  Copyright © 2019 CoolStar. All rights reserved.
//
//  Make sure to also update DepictionBaseView.swift

import UIKit

internal protocol FeaturedViewDelegate: DepictionViewDelegate {}

internal class FeaturedBaseView: DepictionBaseView {
    @objc override class func view(dictionary: [String: Any], viewController: UIViewController, tintColor: UIColor?, isActionable: Bool) -> DepictionBaseView? {
        guard let className = dictionary["class"] as? String else {
            return nil
        }

        guard let rawclass = Bundle.main.classNamed("JsonDepiction.\(className)") as? DepictionBaseView.Type else {
            return nil
        }

        var tintColor: UIColor = tintColor ?? .systemOrange
        if let tintColorStr = dictionary["tintColor"] as? String {
            tintColor = UIColor(css: tintColorStr) ?? .systemOrange
        }

        return rawclass.init(dictionary: dictionary, viewController: viewController, tintColor: tintColor, isActionable: isActionable)
    }

    public required init?(dictionary: [String: Any], viewController: UIViewController, tintColor: UIColor, isActionable: Bool) {
        super.init(dictionary: dictionary, viewController: viewController, tintColor: tintColor, isActionable: isActionable)
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
