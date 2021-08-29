//
//  PackageAction.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/22.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import Dog
import Foundation

extension TaskManager {
    struct PackageAction: Identifiable {
        enum Action: String, CaseIterable {
            case install
            case remove
        }

        let id = UUID()
        let action: Action
        let represent: Package
        let isUserRequired: Bool

        internal init?(action: TaskManager.PackageAction.Action,
                       represent package: Package,
                       isUserRequired: Bool)
        {
            self.action = action
            self.isUserRequired = isUserRequired
            if package.payload.keys.count > 1 {
                #if DEBUG
                    Dog.shared.join("DEBUG",
                                    "trim package to only one version in payload is recommend",
                                    level: .info)
                #endif
                guard let version = package.latestVersion,
                      let package = PackageCenter
                      .default
                      .trim(package: package, toVersion: version)
                else {
                    Dog.shared.join("PackageAction",
                                    "package action received ambiguous/broken package, cancel action",
                                    level: .error)
                    return nil
                }
                represent = package
            } else {
                represent = package
            }
        }
    }
}
