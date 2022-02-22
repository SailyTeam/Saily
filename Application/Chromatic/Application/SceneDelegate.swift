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

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }

        // created from user activity
        if let userActivity = options.userActivities.first ?? session.stateRestorationActivity {
            if !configure(window: window, with: userActivity) {
                debugPrint("failed to restore from \(userActivity)")
            }
            return
        }

        // if not, check for url schemes
        let urlContexts = options.urlContexts
        DispatchQueue.main.async {
            self.scene(scene, openURLContexts: urlContexts)
        }
    }

    func configure(window: UIWindow?, with activity: NSUserActivity) -> Bool {
        var configured = false
        if activity.title == cUserActivityDropPackage {
            if let data = activity.userInfo?["attach"] as? Data,
               let package = Package.propertyListDecoded(with: data)
            {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    let packageConteroller = PackageController(package: package)
                    window?
                        .topMostViewController?
                        .present(next: packageConteroller)
                }
                configured = true
            }
        }
        return configured
    }

    func sceneDidDisconnect(_: UIScene) {}

    func sceneDidBecomeActive(_: UIScene) {
        if applicationShouldEnterRecovery {
            return
        }
        Dog.shared.join(self, "sceneDidBecomeActive", level: .info)
        reloadThrottle.throttle {
            PackageCenter.default.realodLocalPackages()
        }
    }

    func sceneWillResignActive(_: UIScene) {}

    func sceneWillEnterForeground(_: UIScene) {}

    func sceneDidEnterBackground(_ scene: UIScene) {
        debugPrint(scene)
        InterfaceBridge.removeRecoveryFlag(with: #function, userRequested: false)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if applicationShouldEnterRecovery {
            return
        }
        for item in URLContexts {
            let itemUrl = item.url
            if itemUrl.absoluteString.hasPrefix("file://"),
               itemUrl.absoluteString.hasSuffix(".deb")
            {
                openQuickInstall(scene: scene, url: itemUrl)
                continue
            }

            if itemUrl.absoluteString.hasPrefix("apt-repo://") {
                var str = itemUrl.absoluteString
                str.removeFirst("apt-repo://".count)
                // workaround for url scheme removing : from context
                // eg: apt-repo://https://example.com -> apt-repo://https//example.com
                // just put it back, it's usually happening when Safari make magic
                str = str.replacingOccurrences(of: "http//", with: "http://")
                str = str.replacingOccurrences(of: "https//", with: "https://")
                guard let url = URL(string: str) else {
                    continue
                }
                Dog.shared.join(self, "scheme calling apt-repo add for value \(url.absoluteString)")
                openQuickAddRepo(scene: scene, url: url)
                continue
            }
        }
    }

    func openQuickAddRepo(scene: UIScene, url: URL) {
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
                let target = RepoAddViewController()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    target.userInputValues.text = url.absoluteString
                }
                presenter.present(next: target)
            }
        }
    }

    func openQuickInstall(scene: UIScene, url: URL) {
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
                target.patternLocation = url
                presenter.present(next: target)
            }
        }
    }
}
