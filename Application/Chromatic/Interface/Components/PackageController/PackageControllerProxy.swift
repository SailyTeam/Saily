//
//  PackageControllerProxy.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/19.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import SafariServices
import UIKit

class PackageControllerProxy: UIViewController {
    weak var parentController: UIViewController?

    deinit {
        debugPrint("\(self) deinit")
    }

    override func present(_ viewControllerToPresent: UIViewController,
                          animated flag: Bool,
                          completion: (() -> Void)? = nil)
    {
        if let navigator = parentController?.navigationController,
           !(viewControllerToPresent is SFSafariViewController)
        {
            if viewControllerToPresent.title?.count ?? 0 < 1 {
                viewControllerToPresent.title = NSLocalizedString("DETAILS", comment: "Details")
            }
            navigator.pushViewController(viewControllerToPresent)
        } else {
            if UIDevice.current.userInterfaceIdiom == .pad {
                viewControllerToPresent.modalTransitionStyle = .coverVertical
                viewControllerToPresent.modalPresentationStyle = .formSheet
                viewControllerToPresent.preferredContentSize = preferredPopOverSize
            }
            parentController?.present(viewControllerToPresent,
                                      animated: flag,
                                      completion: completion)
        }
    }
}
