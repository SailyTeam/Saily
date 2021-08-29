//
//  SceneDelegate.swift
//  Chromatic
//
//  Created by Lakr Aream on 2020/4/17.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import AptRepository
import Dog
import SwiftThrottle
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    let reloadThrottle = Throttle(minimumDelay: 0.5, queue: .global())

    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
        let urlContexts = options.urlContexts
        DispatchQueue.main.async {
            self.scene(scene, openURLContexts: urlContexts)
        }
    }

    func sceneDidDisconnect(_: UIScene) {}

    func sceneDidBecomeActive(_: UIScene) {
        Dog.shared.join(self, "sceneDidBecomeActive", level: .info)
        reloadThrottle.throttle {
            PackageCenter.default.realodLocalPackages()
        }
    }

    func sceneWillResignActive(_: UIScene) {}

    func sceneWillEnterForeground(_: UIScene) {}

    func sceneDidEnterBackground(_: UIScene) {}

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        for item in URLContexts {
            let firstItem = item.url
            if firstItem.absoluteString.lowercased().hasPrefix("file://"),
               firstItem.absoluteString.lowercased().hasSuffix(".deb")
            {
                while !SetupViewController.setupCompleted { sleep(1) }
                DispatchQueue.main.async {
                    if let presenter =
                        (
                            (scene as? UIWindowScene)?
                                .delegate as? UIWindowSceneDelegate
                        )?
                        .window??
                        .topMostViewController
                    {
                        let target = DirectInstallController()
                        target.patternLocation = firstItem
                        presenter.present(next: target)
                    }
                }
            }
        }
    }
}
