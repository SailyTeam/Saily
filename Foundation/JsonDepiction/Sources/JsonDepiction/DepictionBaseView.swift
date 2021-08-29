//
//  DepictionBaseView.swift
//  Sileo
//
//  Created by CoolStar on 7/6/19.
//  Copyright © 2019 CoolStar. All rights reserved.
//
//  Make sure to also update FeaturedBaseView.swift

import UIKit

// swiftlint:disable:next class_delegate_protocol
public protocol DepictionViewDelegate: NSObject {
    func subviewHeightChanged()
}

internal protocol DepictionViewProtocol: DepictionViewDelegate {
    func depictionHeight(width: CGFloat) -> CGFloat
}

public class DepictionBaseView: UIView, DepictionViewProtocol {
    internal var parentViewController: UIViewController?
    public weak var delegate: DepictionViewDelegate?
    internal var defaultTintColor: UIColor?
    private(set) var isActionable: Bool
    public var isHighlighted: Bool = false

    public class func view(dictionary: [String: Any], viewController: UIViewController, tintColor: UIColor?, isActionable: Bool) -> DepictionBaseView? {
        guard var className = dictionary["class"] as? String else {
            return nil
        }

        if className == "DepictionMarkdownView" {
            if let rawFormat = dictionary["useRawFormat"] as? Bool,
               rawFormat == true
            {
                className = "DepictionMarkdownViewSlow"
            }
        }

        guard let rawclass = Bundle.main.classNamed("JsonDepiction.\(className)") as? DepictionBaseView.Type else {
            return nil
        }

        guard (rawclass as? FeaturedBaseView.Type) == nil else {
            return nil
        }

        var tintColor: UIColor = tintColor ?? .systemOrange
        if let tintColorStr = dictionary["tintColor"] as? String {
            tintColor = UIColor(css: tintColorStr) ?? .systemOrange
        }

        return rawclass.init(dictionary: dictionary, viewController: viewController, tintColor: tintColor, isActionable: isActionable)
    }

    public required init?(dictionary _: [String: Any], viewController: UIViewController, tintColor: UIColor, isActionable: Bool) {
        parentViewController = viewController

        defaultTintColor = tintColor
        self.isActionable = isActionable
        super.init(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        self.tintColor = tintColor
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func subviewHeightChanged() {
        if let superDepictionView = superview as? DepictionViewDelegate {
            superDepictionView.subviewHeightChanged()
        }
        if let delegate = delegate {
            delegate.subviewHeightChanged()
        }
    }

    public func depictionHeight(width _: CGFloat) -> CGFloat {
        0
    }
}
