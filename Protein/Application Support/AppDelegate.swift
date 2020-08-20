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
        
        #if DEBUG
        Tools.rprint("[setuid] returns " + String(setuid(0)))
        Tools.rprint("[setgid] returns " + String(setgid(0)))
        #else
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
        #endif
        
        usleep(233); // wait for user doc path to be set to root
        ConfigManager.initAllowed = true
        
        let _ = ConfigManager.shared
        
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
        print("\n\n------ bye bye ------\n")
        let a = Date().timeIntervalSince1970
        RepoManager.shared.database.close()
        PackageManager.shared.database.close()
        print(Date().timeIntervalSince1970 - a)
    }

}

