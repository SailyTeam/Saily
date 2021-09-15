//
//  DashboardController+Data.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/9/14.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import SPIndicator
import UIKit

extension DashboardController {
    @objc
    func refresh() {
        reloadDataSource()
        refreshControl.endRefreshing()
        SPIndicator.present(title: NSLocalizedString("REFRESHED", comment: "Refreshed"),
                            message: nil,
                            preset: .done,
                            haptic: .success,
                            from: .top,
                            completion: nil)
    }

    @objc
    func reloadDataSource() {
        dataSource = InterfaceBridge.dashbaordBuildDataSource(for: self)
        collectionView.reloadData()
    }
}
