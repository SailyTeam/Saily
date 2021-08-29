//
//  TaskManager+Api.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/22.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import Foundation

extension TaskManager {
    func obtainAllDownloadProgress() -> Progress {
        let tasks = copyEveryActions()
            .filter { $0.action == .install }
            .map(\.represent)
            .map { $0.obtainDownloadLink() }
        var totalUnit: Int64 = 0
        var totoalComplete: Int64 = 0
        for item in tasks {
            if let itemProgress = CariolNetwork
                .shared
                .progressRecord(for: item)?
                .progress
            {
                totalUnit += itemProgress.totalUnitCount
                totoalComplete += itemProgress.completedUnitCount
            }
        }
        let result = Progress(totalUnitCount: totalUnit)
        result.completedUnitCount = totoalComplete
        return result
    }

    func clearActions() {
        commitResolved(resolvedActions: [])
    }
}
