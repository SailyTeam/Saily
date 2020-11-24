//
//  MasterView.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/19.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit

class MasterViewX: UISplitViewController, UISplitViewControllerDelegate {    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        preferredDisplayMode = .allVisible
        applySplitWidth()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        applySplitWidth()
        if let mine = (viewControllers.first as? UINavigationController)?.viewControllers.first as? SplitBoardingDash {
            mine.setDetailViewController()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    func applySplitWidth() {
  
        preferredPrimaryColumnWidthFraction = 0.36
        maximumPrimaryColumnWidth = 360;
        minimumPrimaryColumnWidth = 360;
        
    }
    
}
