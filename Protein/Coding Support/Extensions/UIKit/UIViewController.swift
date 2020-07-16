//
//  UIViewControllerExtension.swift
//  Sail
//
//  Created by mac on 2019/5/11.
//  Copyright © 2019 Lakr Aream. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
}

class UIViewControllerWithCustomizedNavBar: UIViewController  {
    
    let SimpleNavBar = UIView()
    private let SimpleNavEffectView = UIVisualEffectView()
    private let goBackButton = UIButton(frame: CGRect())
    
    func setupNavigationBar(withHeight: CGFloat = 80) {
        
        view.backgroundColor = UIColor(named: "G-ViewController-Background")
        preferredContentSize = CGSize(width: 700, height: 555)
        hideKeyboardWhenTappedAround()
        view.insetsLayoutMarginsFromSafeArea = false

        let effect = UIBlurEffect(style: .systemChromeMaterial)
        SimpleNavEffectView.effect = effect
        view.addSubview(SimpleNavBar)
        SimpleNavBar.addSubview(SimpleNavEffectView)
        SimpleNavBar.addSubview(goBackButton)
        SimpleNavBar.snp.makeConstraints { (x) in
            x.top.equalTo(self.view.snp.top).offset(-233) // safe area
            x.left.equalTo(self.view.snp.left)
            x.right.equalTo(self.view.snp.right)
            x.height.equalTo(233 + withHeight)
        }
        SimpleNavEffectView.snp.makeConstraints { (x) in
            x.edges.equalToSuperview()
        }
        
        goBackButton.alpha = 0.8
        goBackButton.setTitle("Navigation_GoBack".localized(), for: .normal)
        goBackButton.titleLabel?.font = UIFont.roundedFont(ofSize: 20, weight: .black)
        goBackButton.contentHorizontalAlignment = .left
        goBackButton.contentVerticalAlignment = .bottom
        goBackButton.addTarget(self, action: #selector(dismissAction), for: .touchUpInside)
        goBackButton.setTitleColor(UIColor(named: "G-TextTitle"), for: .normal)
        goBackButton.setTitleColor(UIColor(named: "G-Button-Highlighted"), for: .highlighted)
        goBackButton.snp.makeConstraints { (x) in
            x.left.equalTo(SimpleNavBar).offset(18)
            x.bottom.equalTo(SimpleNavBar).offset(-12)
            x.width.equalTo(100)
            x.height.equalTo(60)
        }
        
        SimpleNavBar.layer.zPosition = .greatestFiniteMagnitude
        
    }
    
    func makeSimpleNavBarGreatAgain(withName: String) {
        goBackButton.setTitle(withName, for: .normal)
    }
    
    func makeSimpleNavBarBackgorundTransparency() {
        SimpleNavEffectView.alpha = 0
    }
    
    func makeSimpleNavBarBackgorundGreatAgain() {
        SimpleNavEffectView.alpha = 1
    }
    
    func makeSimpleNavBarButtonLight() {
        goBackButton.setTitleColor(.white, for: .normal)
    }
    
    func makeSimpleNavBarButtonDark() {
        goBackButton.setTitleColor(.black, for: .normal)
    }
    
    deinit {
        print("[ARC] UIViewControllerWithCustomizedNavBar has been deinited")
    }
    
    @objc private
    func dismissAction() {
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
}
