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
        guard let scene = (scene as? UIWindowScene) else { return }
        
        let urlContexts = connectionOptions.urlContexts
        DispatchQueue.global(qos: .background).async {
            self.scene(scene, openURLContexts: urlContexts)
        }
        
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
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        Tools.rprint(URLContexts.debugDescription)
        
        var packageList: [String] = []
        for item in URLContexts {
            let firstItem = item.url
            if firstItem.absoluteString.lowercased().hasPrefix("file://") &&
                firstItem.absoluteString.lowercased().hasSuffix(".deb") {
                let targetLocation = ConfigManager.shared.documentURL.appendingPathComponent("Imported")
                try? FileManager.default.createDirectory(at: targetLocation, withIntermediateDirectories: true,attributes: nil)
                let dest = targetLocation.appendingPathComponent(firstItem.lastPathComponent)
                try? FileManager.default.copyItem(at: firstItem, to: dest)
                Tools.rprint("* File copied from:\n " + firstItem.fileString + "\n                to:\n " + dest.fileString)
                packageList.append(dest.fileString)
            }
        }
        
        if packageList.count > 0 {
            DispatchQueue.global(qos: .background).async {
                while !StartUpVC.booted {
                    sleep(1)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let rootVC = ((scene as? UIWindowScene)?.delegate as? UIWindowSceneDelegate)?.window??.rootViewController {
                        let pop = ImportInstallViewController()
                        pop.modalPresentationStyle = .formSheet
                        pop.modalTransitionStyle = .coverVertical
                        pop.setPresentSource(vc: rootVC)
                        pop.loadPackages(withLocation: packageList)
                        rootVC.present(pop, animated: true, completion: nil)
                    }
                }
            }
        }
    }

}

