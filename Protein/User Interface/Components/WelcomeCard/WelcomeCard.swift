//
//  WelcomeCard.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/18.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit
import SnapKit
import SDWebImage

class WelcomeCard: UIView {
    
    private var backgroundView = AppleCardColorView()
    private var headIconContainer = UIView()
    private var headIconView = UIImageView()
    private var welcomeTitleLabel = UILabel()
    private var welcomeTintLabel = UILabel()
    
    private var touchHandlerIcon = UIButton()
    private var touchHandlerCard = UIButton()
    
    private var cardClosure: () -> () = {}
    private var headIconClosure: () -> () = {}
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    required init() {
        super.init(frame: CGRect())
        
        // self
        backgroundColor = .white
        clipsToBounds = true
        layer.cornerRadius = 14
        dropShadow()
        
        // card touch
        touchHandlerCard.addTarget(self, action: #selector(whenTouched), for: .touchUpInside)
        addSubview(touchHandlerCard)
        touchHandlerCard.snp.makeConstraints { (x) in
            x.edges.equalTo(self.snp.edges)
        }
        
        // headicon
        headIconContainer.backgroundColor = .gray
        headIconContainer.layer.cornerRadius = 34.5
        headIconContainer.dropShadow(ofColor: .black, opacity: 0.16)
        addSubview(headIconContainer)
        headIconContainer.snp.makeConstraints { (x) in
            x.centerX.equalTo(self.snp.centerX)
            x.bottom.equalTo(self.snp.centerY).offset(20)
            x.height.equalTo(69)
            x.width.equalTo(69)
        }
        
//        headIconView.sd_setImage(with: URL(string: DEFINE.DEVELOPMENT_ICON)!, completed: nil)
        headIconView.contentMode = .scaleAspectFill
        headIconView.layer.cornerRadius = 34.5
        headIconView.clipsToBounds = true
        headIconContainer.addSubview(headIconView)
        headIconView.snp.makeConstraints { (x) in
            x.edges.equalTo(headIconContainer)
        }
        
        // labels
        welcomeTintLabel.text = "HomeCard_Desc".localized()
        welcomeTintLabel.font = .systemFont(ofSize: 10, weight: .semibold)
        welcomeTintLabel.textAlignment = .left
        welcomeTintLabel.textColor = UIColor(named: "WelcomeCard-Title")
        welcomeTitleLabel.text = "HomeCard_Welcome".localized()
        welcomeTitleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        welcomeTitleLabel.textAlignment = .left
        welcomeTitleLabel.textColor = UIColor(named: "WelcomeCard-Title")
        addSubview(welcomeTintLabel)
        addSubview(welcomeTitleLabel)
        welcomeTintLabel.snp.makeConstraints { (x) in
            x.left.equalTo(self.snp.left).offset(18)
            x.right.equalTo(self.snp.right).offset(18)
            x.height.equalTo(22)
            x.bottom.equalTo(self.snp.bottom).offset(-12)
        }
        welcomeTitleLabel.snp.makeConstraints { (x) in
            x.left.equalTo(self.snp.left).offset(18)
            x.right.equalTo(self.snp.right).offset(18)
            x.height.equalTo(28)
            x.bottom.equalTo(welcomeTintLabel.snp.top).offset(6)
        }

        // icon touch
        touchHandlerIcon.addTarget(self, action: #selector(whenTouchedIcon), for: .touchUpInside)
        addSubview(touchHandlerIcon)
        touchHandlerIcon.snp.makeConstraints { (x) in
            x.edges.equalTo(headIconContainer.snp.edges)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateAvatar), name: .AvatarUpdated, object: nil)
        
        updateAvatar()
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc
    func updateAvatar() {
        if let img = UIImage(contentsOfFile: ConfigManager.shared.documentURL.appendingPathComponent("avatar.png").fileString) {
            headIconView.image = img
            headIconContainer.alpha = 0
            UIView.animate(withDuration: 0.6) {
                self.headIconContainer.alpha = 1
            }
        } else {
            headIconView.image = nil
            headIconContainer.alpha = 0.2
        }
    }
    
    @objc
    func whenTouched() {
        DispatchQueue.main.async {
            self.cardClosure()
        }
        self.puddingAnimate()
    }
    
    @objc
    func whenTouchedIcon() {
        DispatchQueue.main.async {
            self.headIconClosure()
        }
        headIconContainer.puddingAnimate()
    }
    
    func setTouchEvent(_ hi: @escaping () -> ()) {
        cardClosure = hi
    }
    
    func setTouchIconEvent(_ hi: @escaping () -> ()) {
        headIconClosure = hi
    }
    
    
}
