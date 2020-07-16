//
//  SceneDelegate.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/17.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        
        // Update Repo Update String When Reopen
        NotificationCenter.default.post(name: .RepoManagerUpdatedAllMeta, object: nil)
    
    }

    func sceneWillResignActive(_ scene: UIScene) {
        
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        #if targetEnvironment(macCatalyst)
        if let windowScene = scene as? UIWindowScene {
            unlockUISceneSizeRestrictions(windowScene)
        }
        #endif
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        
    }


}

