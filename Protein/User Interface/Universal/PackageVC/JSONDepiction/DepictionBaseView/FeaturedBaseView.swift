//
//  FeaturedBaseView.swift
//  ND
//
//  Created by Lakr Aream on 2020/5/30.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit

@objc protocol FeaturedViewDelegate: DepictionViewDelegate {
}

@objc(FeaturedBaseView)
open class FeaturedBaseView: DepictionBaseView {
    @objc override class func view(dictionary: [String: Any], viewController: UIViewController, tintColor: UIColor?) -> DepictionBaseView? {
        guard let className = dictionary["class"] as? String else {
            return nil
        }
        
        guard let rawclass = NSClassFromString(className) as? DepictionBaseView.Type else {
            return nil
        }
        
        var tintColor: UIColor = tintColor ?? UINavigationBar.appearance().tintColor ?? UIColor.white
        if let tintColorStr = dictionary["tintColor"] as? String {
            tintColor = UIColor(css: tintColorStr) ?? UINavigationBar.appearance().tintColor ?? UIColor.white
        }
        
        return rawclass.init(dictionary: dictionary, viewController: viewController, tintColor: tintColor)
    }
    
    required public init?(dictionary: [String: Any], viewController: UIViewController, tintColor: UIColor) {
        super.init(dictionary: dictionary, viewController: viewController, tintColor: tintColor)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
