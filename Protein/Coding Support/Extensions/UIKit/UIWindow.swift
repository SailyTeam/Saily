//
//  UIWindow.swift
//  Protein
//
//  Created by Lakr Aream on 2020/7/21.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit

extension UIWindow {
    
    var topMostViewController: UIViewController? {
        var topController = rootViewController
        while let newTopController = topController?.presentedViewController {
            topController = newTopController
        }
        return topController
    }
    
}
