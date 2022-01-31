//
//  AppDelegate.swift
//  Chromatic
//
//  Created by Lakr Aream on 2020/4/17.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import Bugsnag
import Dog
import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    // possible fix for some tweak crashing on something isn't my problem actually
    // -[chromatic.AppDelegate window]: unrecognized selector sent to instance
    var window: UIWindow?

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        #if !DEBUG
            Bugsnag.start()
            if let userID = Bugsnag.user().id {
                Dog.shared.join("Bugsnag", "user id: \(userID)")
            } else {
                Dog.shared.join("Bugsnag", "user id not available")
            }
        #endif

        if applicationShouldEnterRecovery {
            return true
        }

        // for pop up notifications
        prepareNotifications()

        return true
    }

    func applicationWillTerminate(_: UIApplication) {
        InterfaceBridge.removeRecoveryFlag(with: #function, userRequested: false)
    }

    // MARK: - UISceneSession Lifecycle

    func application(_: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options _: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_: UIApplication, didDiscardSceneSessions _: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

extension UIApplication {
    @discardableResult func closeSceneFor(view: UIView) -> Bool {
        if #available(iOS 13.0, *) {
            if let sceneSession = view.window?.windowScene?.session {
                let options = UIWindowSceneDestructionRequestOptions()
                options.windowDismissalAnimation = .standard
                requestSceneSessionDestruction(sceneSession, options: options, errorHandler: nil)
                return true
            }
        }
        return false
    }

    func closeAnyOtherSceneFor(view: UIView) {
        if #available(iOS 13.0, *) {
            if let current = view.window?.windowScene?.session {
                UIApplication
                    .shared
                    .connectedScenes
                    .map(\.session)
                    .filter { $0 != current }
                    .forEach {
                        let options = UIWindowSceneDestructionRequestOptions()
                        options.windowDismissalAnimation = .standard
                        requestSceneSessionDestruction($0, options: options, errorHandler: nil)
                    }
            }
        }
    }
}
