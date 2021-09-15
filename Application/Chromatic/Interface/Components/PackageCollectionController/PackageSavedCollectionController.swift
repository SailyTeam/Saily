//
//  PackageSavedCollectionController.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/9/15.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import UIKit

class PackageSavedCollectionController: PackageCollectionController {
    override func viewDidLoad() {
        title = NSLocalizedString("COLLECTED_PACKAGES", comment: "Collected Packages")
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: .fluent(.delete24Filled),
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(clearBlock))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadCollectionItems()
    }

    @objc
    func clearBlock() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        let alert = UIAlertController(title: "⚠️",
                                      message: NSLocalizedString("THIS_OPERATION_CANNOT_BE_UNDONE", comment: "This operation cannot be undone."),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("CANCEL", comment: "Cancel"),
                                      style: .cancel,
                                      handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("CONFIRM", comment: "CONFIRM"),
                                      style: .destructive,
                                      handler: { _ in
                                          InterfaceBridge.collectedPackages = []
                                          self.reloadCollectionItems()
                                          if let navigator = self.navigationController {
                                              navigator.popViewController()
                                          } else {
                                              self.dismiss(animated: true, completion: nil)
                                          }
                                      }))
        present(alert, animated: true, completion: nil)
    }

    func reloadCollectionItems() {
        dataSource = InterfaceBridge
            .collectedPackages
            .sorted { a, b in
                PackageCenter.default.name(of: a)
                    < PackageCenter.default.name(of: b)
            }
        collectionView.reloadData()
        updateGuiderOpacity()
    }
}
