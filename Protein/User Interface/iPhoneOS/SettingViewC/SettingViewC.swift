//
//  SettingView.swift
//  Protein
//
//  Created by Lakr Aream on 11/19/20.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit

class SettingViewController: UIViewControllerWithCustomizedNavBar, UIScrollViewDelegate {
    
    deinit {
        print("[ARC] SettingViewController has been deinited")
    }

    private let container = SettingView(addTitle: false, addHeaderSpacer: false)
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(named: "SplitDetail-G-Background")

        view.addSubview(container)
        
        setupNavigationBar()
        makeSimpleNavBarBackgorundTransparency()
        makeSimpleNavBarButtonBlue()
        
        container.snp.makeConstraints { (x) in
            x.left.equalToSuperview()
            x.right.equalToSuperview()
            x.bottom.equalToSuperview()
            x.top.equalTo(SimpleNavBar.snp.bottom).offset(0)
        }
        
        container.container.delegate = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        container.container.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
                self.container.loadContentSize()
            }, completion: nil)
        }
        
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y > 5 {
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut) {
                self.makeSimpleNavBarBackgorundGreatAgain()
            } completion: { (_) in
            }
        } else {
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut) {
                self.makeSimpleNavBarBackgorundTransparency()
            } completion: { (_) in
            }
        }
    }
    
}
