//
//  AppIndicator.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/10.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import Dog
import Foundation
import SPIndicator

extension AppDelegate {
    func prepareNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(popIndicator(withNotification:)),
                                               name: RepositoryCenter.metadataUpdate,
                                               object: nil)
    }

    @objc func popIndicator(withNotification: Notification) {
        switch withNotification.name {
        case RepositoryCenter.metadataUpdate:
            guard let object = withNotification.object as? RepositoryCenter.UpdateNotification else {
                Dog.shared.join(self, "broken notification payload received \(withNotification.name)", level: .error)
                return
            }
            if object.complete,
               let repo = RepositoryCenter.default.obtainImmutableRepository(withUrl: object.representedRepo)
            {
                if !object.success {
                    SPIndicator.present(title: "Error Occurred",
                                        message: repo.nickName,
                                        preset: .error,
                                        haptic: .error,
                                        from: .top,
                                        completion: nil)
                }
            }
            if object.queueLeft < 1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // prevent hides another
                    SPIndicator.present(title: "Update Tasks Completed",
                                        message: "", // dont remove this
                                        preset: .done,
                                        haptic: .success,
                                        from: .top,
                                        completion: nil)
                }
            }
        default:
            Dog.shared.join(self, "unknown notification received \(withNotification.name)", level: .error)
        }
    }
}
