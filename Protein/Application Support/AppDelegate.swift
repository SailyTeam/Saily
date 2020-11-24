//
//  AppDelegate.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/17.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        var failCount = 0
        while getuid() != 0 && failCount < 100 {
            setuid(0)
            usleep(23)
            failCount += 1
        }
        failCount = 0
        while getgid() != 0 && failCount < 100 {
            setgid(0)
            usleep(23)
            failCount += 1
        }
        Tools.rprint("*UID: \(getuid()) GID:\(getuid())")
        usleep(233); // wait for user doc path to be set to root
        
        ConfigManager.environmentSetupFinished = true
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {

    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        RepoManager.shared.database.close()
        PackageManager.shared.database.close()
    }

}

