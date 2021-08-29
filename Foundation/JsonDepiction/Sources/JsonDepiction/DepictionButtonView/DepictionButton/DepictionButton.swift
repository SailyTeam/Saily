//
//  DepictionButton.swift
//  Sileo
//
//  Created by CoolStar on 4/20/20.
//  Copyright © 2020 CoolStar. All rights reserved.
//

import SafariServices
import UIKit

class DepictionButton: UIButton {
    var isLink: Bool = false
    var depictionView: DepictionBaseView?

    override var isHighlighted: Bool {
        didSet {
            if isLink {
                backgroundColor = .clear
                depictionView?.isHighlighted = isHighlighted
                return
            }

            if isHighlighted {
                var tintHue: CGFloat = 0
                var tintSat: CGFloat = 0
                var tintBrightness: CGFloat = 0
                tintColor.getHue(&tintHue, saturation: &tintSat, brightness: &tintBrightness, alpha: nil)

                tintBrightness *= 0.75
                backgroundColor = UIColor(hue: tintHue, saturation: tintSat, brightness: tintBrightness, alpha: 1)
            } else {
                backgroundColor = tintColor
            }
        }
    }

    static func processAction(_ action: String, parentViewController: UIViewController?, openExternal: Bool) -> Bool {
        if action.hasPrefix("http"),
           let url = URL(string: action)
        {
            if openExternal {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                let safariViewController = SFSafariViewController(url: url)
                parentViewController?.present(safariViewController, animated: true, completion: nil)
            }
        } else if action.hasPrefix("mailto"),
                  let url = URL(string: action)
        {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else if let url = URL(string: action) {
            debugPrint(url)
//            if url.isSecure(prefix: "depiction") {
//            } else if url.isSecure(prefix: "form") {
//                if let formURL = URL(string: String(action.dropFirst(5))) {
//                    let formController = DepictionFormViewController(formURL: formURL)
//                    let navController = UINavigationController(rootViewController: formController)
//                    navController.modalPresentationStyle = .formSheet
//                    parentViewController?.present(navController, animated: true, completion: nil)
//                }
//            } else {
//                var presentModally = false
//                if let controller = URLManager.viewController(url: url, isExternalOpen: true, presentModally: &presentModally) {
//                    if presentModally {
//                        parentViewController?.present(controller, animated: true, completion: nil)
//                    } else {
//                        parentViewController?.navigationController?.pushViewController(controller, animated: true)
//                    }
//                }
//            }
        }
        return false
    }
}
