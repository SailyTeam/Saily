//
//  UIWindow.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/8.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import UIKit

extension UIWindow {
    var topMostViewController: UIViewController? {
        var result: UIViewController? = rootViewController
        while true {
            if let next = result?.presentedViewController {
                result = next
                continue
            }
            if let tabbar = result as? UITabBarController,
               let next = tabbar.selectedViewController
            {
                result = next
                continue
            }
            if let split = result as? UISplitViewController,
               let next = split.viewControllers.last
            {
                result = next
                continue
            }
            if let navigator = result as? UINavigationController,
               let next = navigator.viewControllers.last
            {
                result = next
                continue
            }
            break
        }
        return result
    }
}
