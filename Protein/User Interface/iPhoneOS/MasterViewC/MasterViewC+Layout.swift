//
//  MasterView+Layout.swift
//  Protein
//
//  Created by Lakr Aream on 11/18/20.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit
import SnapKit

extension MasterView {
    
    func bootstrapLayouts() {
        
        hideKeyboardWhenTappedAround()
        view.backgroundColor = UIColor(named: "SplitBoardingDash.Background")
        
        container.showsVerticalScrollIndicator = false
        container.showsHorizontalScrollIndicator = false
        container.alwaysBounceVertical = true
        view.addSubview(container)
        container.snp.makeConstraints { (x) in
            x.edges.equalTo(self.view.snp.edges)
        }
        
        var anchor = UIView()
        let safeAnchor = anchor
        
        container.addSubview(anchor)
        anchor.snp.makeConstraints { (x) in
            x.top.equalTo(container.snp.top).offset(2)
            x.height.equalTo(2)
            x.left.equalTo(self.view.snp.left).offset(20)
            x.right.equalTo(self.view.snp.right).offset(-20)
        }
        
        welcomeCard.setTouchEvent {
            self.welcomeCardWhenTouchCard()
        }
        welcomeCard.setTouchIconEvent {
            self.welcomeCardWhenTouchCard()
        }
        welcomeCard.cancelAllShadow()
        container.addSubview(welcomeCard)
        welcomeCard.snp.makeConstraints { (x) in
            x.left.equalTo(safeAnchor.snp.left)
            x.right.equalTo(safeAnchor.snp.right)
            x.top.equalTo(anchor.snp.bottom).offset(35)
            x.height.equalTo(200)
        }
        anchor = welcomeCard
        
        searchBar.isUserInteractionEnabled = false
//        searchBar.dropShadow(ofColor: .black, opacity: 0.08)
        searchBar.backgroundColor = UIColor(named: "G-ViewController-Background")
        container.addSubview(searchBar)
        searchBar.snp.makeConstraints { (x) in
            x.left.equalTo(safeAnchor.snp.left)
            x.right.equalTo(safeAnchor.snp.right)
            x.top.equalTo(anchor.snp.bottom).offset(22)
            x.height.equalTo(45)
        }
        container.addSubview(searchBarSender)
        searchBarSender.addTarget(self, action: #selector(searchBarTouched), for: .touchUpInside)
        searchBarSender.snp.makeConstraints { (x) in
            x.edges.equalTo(self.searchBar)
        }
        anchor = searchBar
        
        dashNavCard.cancelAllShadow()
        container.addSubview(dashNavCard)
        dashNavCard.snp.makeConstraints { (x) in
            x.left.equalTo(safeAnchor.snp.left)
            x.right.equalTo(safeAnchor.snp.right)
            x.top.equalTo(anchor.snp.bottom).offset(14)
            x.height.equalTo(215)
        }
        anchor = dashNavCard
        
        // Repo Cards
        
        repoCardTitle.text = "SplitView_MyRepo".localized()
        repoCardTitle.textColor = UIColor(named: "G-TextTitle")
        repoCardTitle.font = .systemFont(ofSize: 22, weight: .heavy)
        repoCardTitle.textAlignment = .left
        container.addSubview(repoCardTitle)
        repoCardTitle.snp.makeConstraints { (x) in
            x.left.equalTo(safeAnchor.snp.left).offset(-4)
            x.width.equalTo(188)
            x.height.equalTo(35)
            x.top.equalTo(anchor.snp.bottom).offset(10)
        }
        repoCardCountTitle.text = String(repoCard.repoCount())
        repoCardCountTitle.morphingEffect = .evaporate
        repoCardCountTitle.font = UIFont.roundedFont(ofSize: 22, weight: .bold).monospacedDigitFont
        repoCardCountTitle.textAlignment = .right
        container.addSubview(repoCardCountTitle)
        repoCardCountTitle.snp.makeConstraints { (x) in
            x.right.equalTo(safeAnchor.snp.right)
            x.width.equalTo(188)
            x.height.equalTo(35)
            x.top.equalTo(anchor.snp.bottom).offset(10)
        }
        anchor = repoCardTitle
        
        repoCard.afterLayoutUpdate { self.repoCardDidLayoutItsSubviews(shouldLayout: true) }
        container.addSubview(repoCard)
        repoCard.snp.makeConstraints { (x) in
            x.top.equalTo(anchor.snp.bottom).offset(8)
            x.left.equalTo(safeAnchor.snp.left)
            x.right.equalTo(safeAnchor.snp.right)
            x.height.equalTo(repoCard.suggestHeight)
        }
        repoCardDidLayoutItsSubviews(shouldLayout: false)
        anchor = repoCard
        
        downTinit.text = "Lakr Aream @ 2020.4 - Project Protein"
        downTinit.font = .systemFont(ofSize: 12, weight: .semibold)
        downTinit.textAlignment = .center
        downTinit.textColor = .gray
        container.addSubview(downTinit)
        downTinit.snp.makeConstraints { (x) in
            x.left.equalTo(safeAnchor.snp.left)
            x.right.equalTo(safeAnchor.snp.right)
            x.top.equalTo(anchor.snp.bottom).offset(8)
            x.height.equalTo(20)
        }
        
    }
    
}
