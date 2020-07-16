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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
//            if self.isCollapsed {
//                if let nav = self.viewControllers[0] as? UINavigationController {
//                    nav.popToRootViewController(animated: true)
//                    if let b = nav.viewControllers.first as? SplitBoardingDash {
//                        b.showShadowView()
//                    }
//                } else {
//                    self.preferredDisplayMode = .allVisible
//                }
//            } else {
//                if let nav = self.viewControllers[0] as? UINavigationController {
//                    if let b = nav.viewControllers.first as? SplitBoardingDash {
//                        b.hidesShadowView()
//                    }
//                }
//            }
//        }
    }
    
    func applySplitWidth() {
  
        preferredPrimaryColumnWidthFraction = 0.36
        maximumPrimaryColumnWidth = 360;
        minimumPrimaryColumnWidth = 360;
        
    }
    
}
