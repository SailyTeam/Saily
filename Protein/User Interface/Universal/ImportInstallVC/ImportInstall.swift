//
//  ImportInstall.swift
//  Protein
//
//  Created by Lakr Aream on 2020/7/18.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit

class ImportInstallViewController: UIViewControllerWithCustomizedNavBar {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        defer { setupNavigationBar() }
        
        view.backgroundColor = UIColor(named: "G-ViewController-Background")
        let size = CGSize(width: 600, height: 600)
        preferredContentSize = size
        hideKeyboardWhenTappedAround()
        view.insetsLayoutMarginsFromSafeArea = false
        isModalInPresentation = true
     
        let acti = UIActivityIndicatorView()
        acti.startAnimating()
        view.addSubview(acti)
        acti.snp.makeConstraints { (x) in
            x.center.equalToSuperview()
        }
        
    }
    
    private var fromViewController: UIViewController? = nil
    func setPresentSource(vc: UIViewController) {
        fromViewController = vc
    }
    
    func loadPackages(withLocation: [String]) {
        // todo: multiple packages from airdrop of mac
        for item in withLocation {
            guard let pkg = Tools.DEBLoadFromFile(atLocation: item) else {
                continue
            }
            guard let meta = pkg.newestMetaData() else {
                continue
            }
            var newMeta = meta
            newMeta["filename"] = "local-install://" + item
            var newPayload = [String : [String : String]]()
            newPayload[pkg.newestVersion()] = newMeta
            let rebuild = PackageStruct(identity: pkg.identity, versions: newPayload, fromRepoUrlRef: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.dismiss(animated: true) {
                    let pop = PackageViewController()
                    pop.PackageObject = rebuild
                    pop.modalPresentationStyle = .formSheet
                    pop.modalTransitionStyle = .coverVertical
                    self.fromViewController?.present(pop, animated: true, completion: nil)
                }
            }
            return
        }
        
        self.dismiss(animated: true, completion: nil)
        let window = view.window
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let alert = UIAlertController(title: "Error".localized(), message: "导入的软件包无效", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
            window?.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }
    
}
