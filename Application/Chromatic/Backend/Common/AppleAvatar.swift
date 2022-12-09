//
//  AppleAvatar.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/23.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import Dog
import UIKit

private let allowLoadKey = "wiki.qaq.chromatic.allowAppleAvatar"

enum AppleAvatar {
    static func blockLoad() {
        UserDefaults.standard.set(false, forKey: allowLoadKey)
    }

    static func unblockLoad() {
        UserDefaults.standard.set(true, forKey: allowLoadKey)
    }

    static func prepareIconIfAvailable() {
        if let allowed = UserDefaults.standard.value(forKey: allowLoadKey) as? Bool,
           !allowed // not allow
        {
            return
        }
        let scale = Int(UIScreen.main.scale)
        let filename = scale == 1 ? "AppleAccountIcon" : "AppleAccountIcon@\(scale)x"
        let toPath = documentsDirectory.appendingPathComponent(filename).appendingPathExtension("png")

        let iconPath = URL(fileURLWithPath: "/var/mobile/Library/Caches/com.apple.Preferences/")
            .appendingPathComponent(filename)
            .appendingPathExtension("png")

        AuxiliaryExecuteWrapper.rootspawn(command: AuxiliaryExecuteWrapper.cp,
                                          args: ["-f", iconPath.path, toPath.path],
                                          timeout: 3) { str in
            Dog.shared.join(self, "exec: \(str.trimmingCharacters(in: .whitespacesAndNewlines))", level: .verbose)
        }
        AuxiliaryExecuteWrapper.rootspawn(command: AuxiliaryExecuteWrapper.chmod,
                                          args: ["777", toPath.path],
                                          timeout: 3) { _ in }
    }
}
