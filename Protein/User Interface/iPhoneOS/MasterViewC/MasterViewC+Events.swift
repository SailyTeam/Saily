//
//  MasterView+Events.swift
//  Protein
//
//  Created by Lakr Aream on 11/18/20.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit
import JGProgressHUD
import DropDown

extension MasterView {

    func welcomeCardWhenTouchCard() {
        let alert = UIAlertController(title: "", message: "?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "SetAvatar".localized(), style: .default, handler: { (_) in
            let alert = UIAlertController(title: "SetAvatar".localized(), message: "SetAvatarHint".localized(), preferredStyle: .alert)
            alert.addTextField { (textField) in
            }
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
                var hud: JGProgressHUD?
                if self.traitCollection.userInterfaceStyle == .dark {
                    hud = .init(style: .dark)
                } else {
                    hud = .init(style: .light)
                }
                hud?.show(in: self.view)
                
                if let text = alert?.textFields?[0].text {
                    if text.hasPrefix("https://") || text.hasPrefix("http://"), let url = URL(string: text) {
                        // download avatar
                        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: Double(ConfigManager.shared.Networking.maxWaitTimeToDownloadRepo))
                        let session = URLSession(configuration: .default)
                        let task = session.dataTask(with: request) { (data, resp, err) in
                            if err != nil {
                                let alert = UIAlertController(title: "Error".localized(), message: err?.localizedDescription, preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
                                self.present(alert, animated: true, completion: nil)
                            } else if let data = data, let img = UIImage(data: data), let pngData = img.pngData() {
                                try? pngData.write(to: ConfigManager.shared.documentURL.appendingPathComponent("avatar.png"))
                                NotificationCenter.default.post(name: .AvatarUpdated, object: nil)
                            }
                            DispatchQueue.main.async {
                                hud?.dismiss()
                            }
                        }
                        task.resume()
                        return
                    }
                    if text.contains("@") {
                        let md5hash = String.md5From(data: text.data)
                        if let url = URL(string: "https://www.gravatar.com/avatar/" + md5hash + "?s=512") {
                            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: Double(ConfigManager.shared.Networking.maxWaitTimeToDownloadRepo))
                            let session = URLSession(configuration: .default)
                            let task = session.dataTask(with: request) { (data, resp, err) in
                                if err != nil {
                                    let alert = UIAlertController(title: "Error".localized(), message: err?.localizedDescription, preferredStyle: .alert)
                                    alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
                                    self.present(alert, animated: true, completion: nil)
                                } else if let data = data, let img = UIImage(data: data), let pngData = img.pngData() {
                                    try? pngData.write(to: ConfigManager.shared.documentURL.appendingPathComponent("avatar.png"))
                                    NotificationCenter.default.post(name: .AvatarUpdated, object: nil)
                                }
                                DispatchQueue.main.async {
                                    hud?.dismiss()
                                }
                            }
                            task.resume()
                            return
                        }
                    }
                }
                DispatchQueue.main.async {
                    hud?.dismiss()
                }
                return
                
                
                
            }))
            self.present(alert, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "RemoveAvatar".localized(), style: .default, handler: { (_) in
            try? FileManager.default.removeItem(at: ConfigManager.shared.documentURL.appendingPathComponent("avatar.png"))
            NotificationCenter.default.post(name: .AvatarUpdated, object: nil)
        }))
        alert.addAction(UIAlertAction(title: "Accounts".localized(), style: .default, handler: { (_) in
            self.welcomeCard.puddingAnimate()
            let pop = RepoPaymentViewController()
            pop.modalPresentationStyle = .formSheet
            pop.modalTransitionStyle = .coverVertical
            self.navigationController?.pushViewController(pop, animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: { (_) in
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc
    func searchBarTouched() {
        searchBar.puddingAnimate()
        var hud: JGProgressHUD?
        if let view = self.parent?.view {
            if self.traitCollection.userInterfaceStyle == .dark {
                hud = .init(style: .dark)
            } else {
                hud = .init(style: .light)
            }
            hud?.textLabel.text = "IndexInProgress".localized()
            hud?.show(in: view)
        }
        DispatchQueue.global(qos: .background).async {
            SearchIndexManager.shared.waitUntilIndexingFinished()
            DispatchQueue.main.async {
                hud?.dismiss()
                let vc = SearchViewController()
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func repoCardDidLayoutItsSubviews(shouldLayout: Bool = false) {
        let count = repoCard.repoCount()
        repoCardCountTitle.text = String(count)
        if !shouldLayout {
            contentLenthOfRepoCard = repoCard.suggestHeight
            return
        }
        UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
            self.repoCard.snp.updateConstraints { (x) in
                x.height.equalTo(self.repoCard.suggestHeight)
            }
            self.contentLenthOfRepoCard = self.repoCard.suggestHeight
            self.repoCard.superview?.layoutIfNeeded()
        }, completion: nil)
    }
    
}

