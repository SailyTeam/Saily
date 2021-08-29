//
//  RepoAddSectionInput.swift
//  Chromatic
//
//  Created by Lakr Aream on 2020/4/19.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import SnapKit
import UIKit

private class RepoAddSectionInputButton: UIButton {
    var attach = Int()

    init() {
        super.init(frame: CGRect())
        titleLabel?.numberOfLines = 1
        titleLabel?.lineBreakMode = .byClipping
        titleLabel?.minimumScaleFactor = 0.5
        titleLabel?.adjustsFontSizeToFitWidth = true
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }
}

class RepoAddSectionInput: UIView {
    private var buttonGroup = [RepoAddSectionInputButton]()
    private var items = [String]()
    private var selected = [Int: Bool]()

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    required init(defaultVal: [String] = []) {
        super.init(frame: CGRect())

        items = defaultVal

        var anchor = UIView()
        addSubview(anchor)
        anchor.snp.makeConstraints { x in
            x.top.equalTo(self.snp.top)
            x.left.equalTo(self.snp.left)
            x.right.equalTo(self.snp.right)
            x.height.equalTo(1)
        }
        let gap = 0
        for (index, item) in defaultVal.enumerated() {
            let new = RepoAddSectionInputButton()
            new.attach = index
            new.setTitle("  " + item, for: .normal)
            new.setTitleColor(UIColor(named: "BUTTON_NORMAL"), for: .normal)
            new.contentHorizontalAlignment = .left
            new.titleLabel?.font = .monospacedSystemFont(ofSize: 12, weight: .bold)
            new.addTarget(self, action: #selector(select(attach:)), for: .touchUpInside)
            addSubview(new)
            new.snp.makeConstraints { x in
                x.left.equalTo(self.snp.left).offset(gap)
                x.right.equalTo(self.snp.right).offset(-gap)
                x.height.equalTo(22)
                x.top.equalTo(anchor.snp.bottom)
            }
            anchor = new
            selected[index] = false
            buttonGroup.append(new)
        }
    }

    @objc
    private func select(attach: RepoAddSectionInputButton) {
        if items.count <= attach.attach || attach.attach < 0 {
            return
        }
        let target = items[attach.attach]
        if attach.titleLabel?.text?.hasPrefix("  ") ?? false {
            attach.setTitle("* " + target, for: .normal)
            selected[attach.attach] = true
        } else {
            attach.setTitle("  " + target, for: .normal)
            selected[attach.attach] = false
        }
    }

    func selectSwitch() {
        for button in buttonGroup {
            select(attach: button)
        }
    }

    func obtainSelected() -> [String] {
        var ret = [String]()
        for (index, item) in items.enumerated() where selected[index] ?? false {
            ret.append(item)
        }
        return ret
    }
}
