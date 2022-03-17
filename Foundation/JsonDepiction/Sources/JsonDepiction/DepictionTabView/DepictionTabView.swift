//
//  DepictionTabView.swift
//  Sileo
//
//  Created by CoolStar on 7/6/19.
//  Copyright © 2019 CoolStar. All rights reserved.
//

import UIKit

class DepictionTabView: DepictionBaseView, DepictionTabControlContainer {
    var tabViews: [DepictionTabControl] = []
    var tabContentViews: [DepictionBaseView] = []

    var tabView: UIView?
    var tabViewSeparator: UIView?
    var tabViewHighlight: UIView?

    required init?(dictionary: [String: Any], viewController: UIViewController, tintColor: UIColor, isActionable: Bool) {
        guard let tabs = dictionary["tabs"] as? [[String: Any]] else {
            return nil
        }

        for tab in tabs {
            guard (tab["tabname"] as? String) != nil else {
                return nil
            }
            guard (tab["class"] as? String) != nil else {
                return nil
            }
        }

        super.init(dictionary: dictionary, viewController: viewController, tintColor: tintColor, isActionable: isActionable)
        tabView = UIView(frame: .zero)
        addSubview(tabView!)

        for tab in tabs {
            guard let tabName = tab["tabname"] as? String else {
                continue
            }

            let tabControl = DepictionTabControl(text: tabName)

            if let view = DepictionBaseView.view(dictionary: tab, viewController: viewController, tintColor: tintColor, isActionable: isActionable) {
                tabViews.append(tabControl)
                tabView?.addSubview(tabControl)
                tabContentViews.append(view)
            }
        }

        tabViewSeparator = UIView(frame: .zero)
        tabViewSeparator?.backgroundColor = .sileoSeparatorColor

        tabView?.addSubview(tabViewSeparator!)

        tabViewHighlight = UIView(frame: .zero)
        tabView?.addSubview(tabViewHighlight!)

        activeTab = 0
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        tabView?.frame = CGRect(origin: .zero, size: CGSize(width: bounds.width, height: 40))
        tabView?.accessibilityTraits = .tabBar

        let activeTab = tabViews[activeTab]
        activeTab.highlighted = true

        let activeTabContent = tabContentViews[self.activeTab]
        addSubview(activeTabContent)

        let tabCount = CGFloat(tabViews.count)

        var x = CGFloat(0)
        for tabControl in tabViews {
            tabControl.frame = CGRect(x: x, y: 0, width: bounds.width / tabCount, height: 40)
            x += tabControl.frame.width

            if tabControl != activeTab {
                tabControl.highlighted = false
            }
        }

        for tabContent in tabContentViews where tabContent != activeTabContent && subviews.contains(tabContent) {
            tabContent.removeFromSuperview()
        }

        let highlightWidth = activeTab.textWidth() + 6
        tabViewHighlight?.backgroundColor = tintColor

        tabViewSeparator?.frame = CGRect(x: 0, y: 39, width: bounds.width, height: 1)
        tabViewHighlight?.frame = CGRect(x: activeTab.frame.minX + (activeTab.frame.width - highlightWidth) / 2.0,
                                         y: 38.0,
                                         width: highlightWidth,
                                         height: 2)
        UIView.setAnimationsEnabled(false)
        activeTabContent.frame = CGRect(x: 0, y: 40, width: bounds.width, height: activeTabContent.depictionHeight(width: bounds.width))
        activeTabContent.layoutSubviews()
        UIView.setAnimationsEnabled(true)
    }

    func tabTapped(_ tab: DepictionTabControl) {
        UIView.animate(withDuration: 0.25) {
            self.activeTab = self.tabViews.firstIndex(of: tab) ?? 0
        }
    }

    var activeTab: Int = 0 {
        didSet {
            self.subviewHeightChanged()
        }
    }

    override func subviewHeightChanged() {
        layoutSubviews()
        super.subviewHeightChanged()
    }

    override func depictionHeight(width: CGFloat) -> CGFloat {
        var height = CGFloat(40)

        let depictionView = tabContentViews[activeTab]
        height += depictionView.depictionHeight(width: width)
        return height
    }

    @objc func updateSileoColors() {
        tabViewSeparator?.backgroundColor = .sileoSeparatorColor
    }

    override var isHighlighted: Bool {
        didSet {
            if isActionable {
                for view in tabContentViews {
                    view.isHighlighted = isHighlighted
                }
            }
        }
    }
}
