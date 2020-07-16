//
//  SplitDetailSetting.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/20.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit

class SplitDetailSetting: UIViewController {
    
    deinit {
        print("[ARC] SplitDetailSetting has been deinited")
    }

    private let container = SettingView()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(named: "SplitDetail-G-Background")

        view.addSubview(container)
        container.snp.makeConstraints { (x) in
            x.edges.equalToSuperview()
        }
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
                self.container.loadContentSize()
            }, completion: nil)
        }
        
    }
    
}
