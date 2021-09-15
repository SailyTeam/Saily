//
//  BlockUpdateController.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/9/14.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import UIKit

class BlockUpdateController: PackageCollectionController {
    override func viewDidLoad() {
        title = NSLocalizedString("BLOCK_UPDATE", comment: "Block Update")
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: .fluent(.delete24Filled),
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(clearBlock))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadBlockedItem()
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
                                          PackageCenter.default.blockedUpdateTable = []
                                          self.reloadBlockedItem()
                                          if let navigator = self.navigationController {
                                              navigator.popViewController()
                                          } else {
                                              self.dismiss(animated: true, completion: nil)
                                          }
                                      }))
        present(alert, animated: true, completion: nil)
    }

    func reloadBlockedItem() {
        var builder = [Package]()
        let blocker = PackageCenter
            .default
            .blockedUpdateTable
        for blockItem in blocker {
            let summary = PackageCenter
                .default
                .obtainPackageSummary(with: blockItem)
            if let candidate = PackageCenter
                .default
                .newestPackage(of: [Package](summary.values))
            {
                builder.append(candidate)
            } else if let installed = PackageCenter
                .default
                .obtainPackageInstallationInfo(with: blockItem)?
                .representObject
            {
                builder.append(installed)
            } else {
                builder.append(Package(identity: blockItem,
                                       payload: ["99.0": [
                                           "package": blockItem,
                                           "version": "99.0",
                                           "description": "This package in your update blocking list is not found.",
                                       ]]))
            }
        }
        dataSource = builder.sorted(by: { a, b in
            PackageCenter.default.name(of: a)
                < PackageCenter.default.name(of: b)
        })
        collectionView.reloadData()
        updateGuiderOpacity()
    }
}
