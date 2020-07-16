//
//  ViewController.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/17.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit

class UIEntery: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(setExceptedRootViewController),
                                               name: .UISizeChanged,
                                               object: nil)
        
        setExceptedRootViewController()
        
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        DispatchQueue.global(qos: .background).async {
            NotificationCenter.default.post(name: .UISizeChanged, object: nil)
        }
    }
    
    @objc
    func setExceptedRootViewController() {
        DispatchQueue.main.async {
            if UIDevice.preferLargerUI(currentView: self.view) {
                self.selectedIndex = 0
            } else {
                self.selectedIndex = 1
            }
        }
    }
    
}
