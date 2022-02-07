//
//  SettingElement.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/28.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import DropDown
import MorphingLabel
import UIKit

enum SettingElementDataType: String {
    case none
    case submenuWithAction
    case switcher
    case dropDownWithString
}

class SettingElement: UIView {
    let iconView = UIImageView()
    let label = UILabel()
    let switcher = UISwitch()
    let buttonImage = UIImageView()
    let button = UIButton()
    let dropDownHit = LTMorphingLabel()
    let dropDownAnchor = UIView()

    private let type: SettingElementDataType
    private let dataProvider: (() -> String)?
    private let actionCall: ((_ switcherValueIfAvailable: Bool?, _ dropDownAnchor: UIView) -> Void)?

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    required init(iconSystemNamed: String,
                  text: String,
                  dataType: SettingElementDataType,
                  initData: (() -> (String))?,
                  withAction: ((_ switcherValueIfAvailable: Bool?, _ dropDownAnchor: UIView) -> Void)?)
    {
        type = dataType
        dataProvider = initData
        actionCall = withAction

        super.init(frame: CGRect())

        addSubview(iconView)
        addSubview(label)
        addSubview(switcher)
        addSubview(buttonImage)
        addSubview(button)
        addSubview(dropDownHit)
        addSubview(dropDownAnchor)

        iconView.contentMode = .scaleAspectFit
        iconView.image = UIImage(systemName: iconSystemNamed)
        iconView.snp.makeConstraints { x in
            x.centerX.equalTo(self.snp.left).offset(4 + 20)
            x.centerY.equalTo(self.snp.centerY)
            x.top.equalToSuperview().offset(0)
        }

        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.text = text
        label.numberOfLines = 1
        label.snp.makeConstraints { x in
            x.left.equalTo(self.iconView.snp.centerX).offset(12 + 12)
            x.centerY.equalTo(self.snp.centerY)
            x.right.equalTo(self.switcher.snp.left).offset(-8)
        }

        switcher.addTarget(self, action: #selector(buttonAnimate), for: .valueChanged)
        switcher.snp.makeConstraints { x in
            x.centerY.equalTo(self.snp.centerY)
            x.right.equalTo(self.snp.right).offset(-12)
        }

        buttonImage.image = .fluent(.arrowRightCircle24Filled)
        buttonImage.snp.makeConstraints { x in
            x.centerY.equalTo(self.snp.centerY)
            x.right.equalTo(self.switcher.snp.right)
            x.width.equalTo(20)
            x.height.equalTo(20)
        }

        button.addTarget(self, action: #selector(buttonAnimate), for: .touchUpInside)
        button.snp.makeConstraints { x in
            x.center.equalTo(self.buttonImage)
            x.width.equalTo(30)
            x.height.equalTo(30)
        }

        dropDownHit.morphingEffect = .evaporate
        dropDownHit.font = UIFont.roundedFont(ofSize: 18, weight: .bold).monospacedDigitFont
        dropDownHit.textColor = .gray
        dropDownHit.textAlignment = .right
        dropDownHit.snp.makeConstraints { x in
            x.centerY.equalTo(self.snp.centerY)
            x.right.equalTo(self.snp.right).offset(-12)
            x.left.equalTo(label.snp.right).offset(8)
        }

        dropDownAnchor.snp.makeConstraints { x in
            x.top.equalTo(label.snp.bottom).offset(8)
            x.right.equalTo(self.snp.right).offset(-12)
            x.width.equalTo(250)
            x.height.equalTo(2)
        }

        switch dataType {
        case .none:
            switcher.isHidden = true
            button.isHidden = true
            buttonImage.isHidden = true
            dropDownHit.isHidden = true
            dropDownAnchor.isHidden = true
        case .switcher:
            button.isHidden = true
            buttonImage.isHidden = true
            dropDownHit.isHidden = true
            dropDownAnchor.isHidden = true
        case .submenuWithAction:
            switcher.isHidden = true
            dropDownHit.isHidden = true
            dropDownAnchor.isHidden = true
        case .dropDownWithString:
            switcher.isHidden = true
            buttonImage.isHidden = true
            button.snp.remakeConstraints { x in
                x.centerY.equalTo(self.snp.centerY)
                x.right.equalTo(self)
                x.left.equalTo(label.snp.right).offset(8)
            }
        }

        updateValues()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateValues),
                                               name: .SettingReload,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    func updateValues() {
        bringSubviewToFront(button)
        switch type {
        case .switcher:
            bringSubviewToFront(switcher)
            if let delegate = dataProvider {
                let ret = delegate()
                switcher.setOn(ret == "YES" ? true : false, animated: true)
            }
        case .dropDownWithString:
            if let delegate = dataProvider {
                dropDownHit.text = delegate()
            }
        default:
            break
        }
    }

    @objc
    func buttonAnimate() {
        if type == .submenuWithAction {
            buttonImage.shineAnimation()
        }
        if let withAction = actionCall {
            if type == .switcher {
                withAction(switcher.isOn, dropDownAnchor)
            } else {
                dropDownHit.puddingAnimate()
                withAction(nil, dropDownAnchor)
            }
        }
    }

    func setLabelText(str: String) {
        label.text = str
    }

    func setSwitcherUnavailable() {
        switcher.alpha = 0.5
        switcher.isUserInteractionEnabled = false
    }
}
