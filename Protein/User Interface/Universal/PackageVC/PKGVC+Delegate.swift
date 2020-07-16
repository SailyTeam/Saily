//
//  PKGVC+Delegate.swift
//  Protein
//
//  Created by Lakr Aream on 2020/5/31.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit

extension PackageViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // image height - nav bar height
        if scrollView.contentOffset.y <= preferredBannerImageHeight - 80 {
            if preferredGoBackButtonStyleLight == true {
                makeSimpleNavBarButtonLight()
            } else if preferredGoBackButtonStyleLight == false {
                makeSimpleNavBarButtonDark()
            } else {
                if traitCollection.userInterfaceStyle == .dark {
                    makeSimpleNavBarButtonLight()
                } else {
                    makeSimpleNavBarButtonDark()
                }
            }
            UIView.animate(withDuration: 0.5) {
                self.makeSimpleNavBarBackgorundTransparency()
            }
        } else {
            if traitCollection.userInterfaceStyle == .dark {
                makeSimpleNavBarButtonLight()
            } else {
                makeSimpleNavBarButtonDark()
            }
            UIView.animate(withDuration: 0.5) {
                self.makeSimpleNavBarBackgorundGreatAgain()
            }
        }
    }
    
}

extension PackageViewController: DepictionViewDelegate {
    
    func subviewHeightChanged() {
        PackageDepictionLayoutTokenChecker = UUID().uuidString
        updateLayoutsIfNeeded()
    }
    
}
