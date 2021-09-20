//
//  IBBase.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/29.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import Dog
import PropertyWrapper
import UIKit

enum InterfaceBridge {
    @UserDefaultsWrapper(key: "wiki.qaq.chromatic.collectedPackages", defaultValue: Data())
    private static var _collectedPackages: Data
    static var collectedPackages: [Package] {
        get {
            (try? JSONDecoder().decode([Package].self, from: _collectedPackages)) ?? []
        }
        set {
            _collectedPackages = (try? JSONEncoder().encode(newValue)) ?? Data()
            NotificationCenter.default.post(name: .PackageCollectionChanged, object: nil)
        }
    }

    @UserDefaultsWrapper(key: "wiki.qaq.chromatic.enableShareSheet", defaultValue: false)
    public static var enableShareSheet: Bool

    public static func removeRecoveryFlag(with reason: String, userRequested: Bool) {
        if !applicationShouldEnterRecovery || userRequested {
            debugPrint("\(#function) \(reason)")
            try? FileManager.default.removeItem(at: applicationRecoveryFlag)
        } else {
            debugPrint("app in recovery mode")
        }
    }
}
