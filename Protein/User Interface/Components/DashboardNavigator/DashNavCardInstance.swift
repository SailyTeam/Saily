//
//  DashNavCardInstance.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/19.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit
import LTMorphingLabel

class DashNavCardInstance: UIView {
    
    private var icon = UIImageView()
    private var title = UILabel()
    private var button = UIButton()
    
    var badgeText: String? {
        set {
            badgeLabel.text = newValue
        }
        get {
            badgeLabel.text
        }
    }
    private var badgeLabel = LTMorphingLabel()
    
    private var cardClosure: () -> () = {}
    
    private var selectIconName: String
    private var unselectIconName: String
    private var selectTitleColor: UIColor
    private var unselectTitleColor: UIColor
    private var selectBackgroundColor: UIColor
    private var unselectBackgroundColor: UIColor
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    required init(text: String,
                  selectIconName sin: String,
                  selectTitleColor stc: UIColor = UIColor(named: "DashNAV.DefaultTitleSelectedColor")!,
                  selectBackgroundColor sbc: UIColor,
                  unselectIconName usin: String,
                  unselectTitleColor ustc: UIColor = .gray,
                  unselectBackgroundColor usbc: UIColor = UIColor(named: "DashNAV.DashNavCardDefaultFill")!,
                  defaultSelected: Bool = false) {
        
        selectIconName = sin
        unselectIconName = usin
        selectTitleColor = stc
        unselectTitleColor = ustc
        selectBackgroundColor = sbc
        unselectBackgroundColor = usbc
        
        super.init(frame: CGRect())
        
        addSubview(icon)
        addSubview(title)
        addSubview(button)
        addSubview(badgeLabel)
        
        layer.cornerRadius = 12
        dropShadow()
        icon.contentMode = .scaleAspectFit
        
        if defaultSelected {
            select()
        } else {
            deselecte()
        }
        
        title.text = text
        title.font = .systemFont(ofSize: 18, weight: .bold)
        title.textAlignment = .left
        
        badgeLabel.textAlignment = .right
        badgeLabel.font = UIFont.roundedFont(ofSize: 12, weight: .bold).monospacedDigitFont
        badgeLabel.morphingEffect = .evaporate
        
        title.snp.makeConstraints { (x) in
            x.left.equalTo(self.snp.left).offset(16)
            x.height.equalTo(28)
            x.right.equalTo(self.snp.right).offset(-8)
            x.bottom.equalTo(self.snp.bottom).offset(-8)
        }
        badgeLabel.snp.makeConstraints { (x) in
//            x.left.equalTo(self.snp.left).offset(16)
//            x.height.equalTo(28)
            x.right.equalTo(self.snp.right).offset(-10)
            x.width.equalTo(60)
            x.centerY.equalTo(title.snp.centerY).offset(2)
        }
        
        icon.snp.makeConstraints { (x) in
            x.left.equalTo(self.snp.left).offset(18)
            x.bottom.equalTo(title.snp.top).offset(-10)
            x.width.equalTo(28)
            x.height.equalTo(28)
        }
        button.snp.makeConstraints { (x) in
            x.edges.equalTo(self.snp.edges)
        }
        
        button.addTarget(self, action: #selector(touched), for: .touchUpInside)
        
    }
    
    @objc
    func touched() {
        DispatchQueue.main.async {
            self.cardClosure()
        }
    }
    
    func setTouchEvent(_ hi: @escaping () -> ()) {
        cardClosure = hi
    }
    
    func select() {
        icon.image = UIImage(named: selectIconName)
        title.textColor = selectTitleColor
        badgeLabel.textColor = title.textColor
        backgroundColor = selectBackgroundColor
        self.puddingAnimate()
    }
    
    func deselecte() {
        icon.image = UIImage(named: unselectIconName)
        title.textColor = unselectTitleColor
        badgeLabel.textColor = title.textColor
        backgroundColor = unselectBackgroundColor
    }
    
    static func ==(v1: DashNavCardInstance, v2: DashNavCardInstance) -> Bool {
        return v1.title == v2.title
    }
    
}
