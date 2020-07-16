//
//  UIApplication.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/18.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit

extension UIApplication {
    
    static var mainWindow: UIWindow? {
        get {
            return UIApplication.shared.connectedScenes
                .filter({$0.activationState == .foregroundActive})
                .map({$0 as? UIWindowScene})
                .compactMap({$0})
                .first?.windows
                .filter({$0.isKeyWindow}).first
        }
    }
    
    static var isInSplitView: Bool {
        get {
            guard let win = UIApplication.shared.delegate?.window, let window = win else { return false }
            return !window.frame.equalTo(window.screen.bounds)
        }
    }
    
}
