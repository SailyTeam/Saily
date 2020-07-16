//
//  DepictionButton.swift
//  Sileo
//
//  Created by CoolStar on 4/20/20.
//  Copyright © 2020 CoolStar. All rights reserved.
//

import UIKit
import SafariServices

class DepictionButton: UIButton {
    
    var packageMetaInfo: [String : String] = [:]
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                var tintHue: CGFloat = 0
                var tintSat: CGFloat = 0
                var tintBrightness: CGFloat = 0
                self.tintColor.getHue(&tintHue, saturation: &tintSat, brightness: &tintBrightness, alpha: nil)
                
                tintBrightness *= 0.75
                self.backgroundColor = UIColor(hue: tintHue, saturation: tintSat, brightness: tintBrightness, alpha: 1)
            } else {
                self.backgroundColor = self.tintColor
            }
        }
    }
    
    static func processAction(_ action: String, parentViewController: UIViewController?, openExternal: Bool) -> Bool {
        if action.hasPrefix("http"),
            let url = URL(string: action) {
            if openExternal {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                let safariViewController = SFSafariViewController(url: url)
                safariViewController.preferredControlTintColor = UINavigationBar.appearance().tintColor ?? UIColor.white
                parentViewController?.present(safariViewController, animated: true, completion: nil)
            }
        } else if action.hasPrefix("mailto"),
            let url = URL(string: action) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else if action == "showInstalledContents" {
            print("showInstalledContents isnt implemented")
        }
        print("unknown operation - " + action)
        return false
    }
}
