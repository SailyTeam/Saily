//
//  PKGVC+Section.swift
//  Protein
//
//  Created by Lakr Aream on 2020/5/31.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit
import Down
import DropDown
import JGProgressHUD

class PackageViewControllerSectionView: UIView {
    
    private var 📦: PackageStruct? = nil
    private var icon: UIImageView = UIImageView()
    private var name: UILabel = UILabel()
    private var auth: UILabel = UILabel()
    
    private var button = UIButton()
    private var dropDownAnchor = UIView()
    private var packageStatusCache: PackageManager.packageStatus?
    
    required init?(coder: NSCoder) {
        fatalError("[PackageViewControllerSectionView] coder init not available")
    }
    
    required init(insert: CGFloat = 18) {
        super.init(frame: CGRect())
        
        addSubview(icon)
        addSubview(name)
        addSubview(auth)
        addSubview(button)
        addSubview(dropDownAnchor)
        
        icon.clipsToBounds = true
        icon.layer.cornerRadius = 8
        name.textColor = UIColor(named: "G-TextTitle")
        name.font = .boldSystemFont(ofSize: 22)
        auth.textColor = UIColor(named: "G-TextSubTitle")
        auth.font = .boldSystemFont(ofSize: 14)
        
        icon.snp.makeConstraints { (x) in
            x.centerY.equalToSuperview()
            x.left.equalToSuperview().offset(insert)
            x.width.equalTo(icon.snp.height)
            x.top.equalToSuperview().offset(insert)
        }
        name.snp.makeConstraints { (x) in
            x.left.equalTo(icon.snp.right).offset(8)
            x.bottom.equalTo(icon.snp.centerY).offset(4)
            x.right.equalTo(self.button.snp.left).offset(-8)
        }
        auth.snp.makeConstraints { (x) in
            x.left.equalTo(icon.snp.right).offset(8)
            x.top.equalTo(icon.snp.centerY).offset(4)
            x.right.equalTo(self.button.snp.left).offset(-8)
        }
        
        let color = UIColor(named: "DashNAV.DashboardSelectedColor")!
        button.backgroundColor = color
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.gray, for: .highlighted)
        button.layer.cornerRadius = 15
        button.addTarget(self, action: #selector(openMenu), for: .touchUpInside)
        button.snp.makeConstraints { (x) in
            x.centerY.equalToSuperview()
            x.right.equalToSuperview().offset(-20)
            x.width.equalTo(30)
            x.height.equalTo(30)
        }
        
        dropDownAnchor.snp.makeConstraints { (x) in
            x.top.equalTo(self.button.snp.bottom).offset(8)
            x.right.equalToSuperview().offset(-20)
            x.width.equalTo(233)
            x.height.equalTo(2)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .TaskSystemFinished, object: nil)
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public func setPackage(with item: PackageStruct?) {
        📦 = item
        DispatchQueue.main.async {
            self.reloadData()
        }
    }
    
    private var reloadToken = ""
    
    @objc
    public func reloadData() {
        reloadToken = UUID().uuidString
        DispatchQueue.main.async {
            if let item = self.📦 {
                item.setIconImage(withUIImageView: self.icon)
                self.name.text = item.obtainNameIfExists()
                self.auth.text = item.obtainAuthorIfExists()
                
                let stauts = PackageManager.shared.packageStatusLookup(identity: item.identity, version: item.newestVersion())
                self.packageStatusCache = stauts
                var tint = ""
                switch stauts {
                case .outdated:
                    tint = "UPDATE".localized()
                case .installed:
                    tint = "MODIFY".localized()
                default:
                    tint = "GET".localized()
                }
                if TaskManager.shared.packageIsInQueue(identity: item.identity) {
                    tint = "MODIFY".localized()
                }
                self.button.setTitle(tint, for: .normal)
                let width = tint.sizeOfString(usingFont: self.button.titleLabel!.font).width
                self.button.snp.updateConstraints { (x) in
                    x.width.equalTo(width + 22)
                }
                let get = self.reloadToken
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    if self.reloadToken == get {
                        UIView.transition(with: self.auth,
                                          duration: 0.5,
                                          options: .transitionCrossDissolve,
                                          animations: {
                                            self.auth.text = item.newestVersion()
                        }, completion: nil)
                    }
                }
            } else {
                self.icon.image = nil
                self.name.text = nil
                self.auth.text = nil
                let tint = "Unavailable".localized()
                self.packageStatusCache = nil
                self.button.setTitle(tint, for: .normal)
                let width = tint.sizeOfString(usingFont: self.button.titleLabel!.font).width
                self.button.snp.updateConstraints { (x) in
                    x.width.equalTo(width + 22)
                }
            }
        }
    }
    
    func setButtonColor(use color: UIColor?) {
        if let color = color {
            button.backgroundColor = color
        }
    }
    
    @objc
    func openMenu() {
        button.puddingAnimate()
        let dropDown = DropDown()
        dropDown.anchorView = dropDownAnchor
        
        var source: [String] = []
        
        var inQueue = false
        var isInWishList = false
        
        var downloadAvailable = false
        
        if let item = 📦 {
            if TaskManager.shared.packageIsInQueue(identity: item.identity) {
                source.append("PackageOperation_RemoveFromQueue")
                inQueue = true
            }
            if PackageManager.shared.wishListExists(withIdentity: item.identity) {
                isInWishList = true
            }
            if item.obtainDownloadLocationFromNewestVersion() != nil {
                downloadAvailable = true
            }
        }
        if 📦?.newestMetaData()?["filename"]?.hasPrefix("local-install://") ?? false {
            source.append("PackageOperation_InstantInstall")
        } else {
            switch packageStatusCache {
            case .clear:
                if !inQueue && downloadAvailable {
                    source.append("PackageOperation_AddToInstall")
                }
                if isInWishList {
                    source.append("PackageOperation_RemoveFromWishList")
                } else {
                    source.append("PackageOperation_AddWishList")
                }
                if downloadAvailable {
                    source.append("PackageOperation_JustDownload")
                }
                source.append("PackageOperation_Share")
                source.append("PackageOperation_Advanced")
            case .installed:
                if !inQueue {
                    source.append("PackageOperation_AddToDelete")
                    if downloadAvailable {
                        source.append("PackageOperation_AddToReInstall")
                    }
                }
                if isInWishList {
                    source.append("PackageOperation_RemoveFromWishList")
                } else {
                    source.append("PackageOperation_AddWishList")
                }
                if downloadAvailable {
                    source.append("PackageOperation_JustDownload")
                }
                source.append("PackageOperation_Share")
                source.append("PackageOperation_Advanced")
            case .outdated:
                if !inQueue {
                    if downloadAvailable {
                        source.append("PackageOperation_AddToUpdate")
                    }
                    source.append("PackageOperation_AddToDelete")
                    if downloadAvailable {
                        source.append("PackageOperation_AddToReInstall")
                    }
                }
                if isInWishList {
                    source.append("PackageOperation_RemoveFromWishList")
                } else {
                    source.append("PackageOperation_AddWishList")
                }
                if downloadAvailable {
                    source.append("PackageOperation_JustDownload")
                }
                source.append("PackageOperation_Share")
                source.append("PackageOperation_Advanced")
            case .broken:
                print("case .broken")
                // todo
                source.append("PackageOperation_NotAvailable")
            default:
                source.append("PackageOperation_NotAvailable")

                let alert = UIAlertController(title: "Error".localized(),
                                              message: "PackageOperation_NotAvailableAlertHint".localized(),
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                self.obtainParentViewController?.present(alert, animated: true, completion: nil)
                return
            }
        }
        source.append("Cancel")
        
        let rawOperationList = source
        let text = source.map { (str) -> String in
            return "   " + str.localized()
        }
        dropDown.dataSource = text
        dropDown.direction = .bottom
        dropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            let operationString = rawOperationList[index]
            if let item = self.📦 {
                switch operationString {
                case "PackageOperation_InstantInstall":
                    let alert = UIAlertController(title: "Warning".localized(), message: "PackageOperation_InstantInstallHint".localized(), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Confirm".localized(), style: .destructive, handler: { (_) in
                        if let location = self.📦?.newestMetaData()?["filename"] {
                            let realLocation = location.dropFirst("local-install://".count)
                            print("[PackageManager] Instant install: " + realLocation)
                            var script = ""
                            script += "echo Unlocking system...\n"
                            script += "rm -f /var/lib/apt/lists/lock\n"
                            script += "rm -f /var/cache/apt/archives/lock\n"
                            script += "rm -f /var/lib/dpkg/lock*\n"
                            if self.📦?.identity.lowercased() == "wiki.qaq.Protein".lowercased() {
                                FileManager.default.createFile(atPath: "/private/var/root/Documents/wiki.qaq.protein.update.reopen", contents: nil, attributes: nil)
                                AppleCardColorProvider.shared.addColor(withCount: 2)
                            }
                            script += "echo ****INSTALL****\n"
                            script += "apt install --assume-yes --reinstall " + realLocation
                            script += "\n"
                            script += "echo ***DONE***\n"
                            let ret = Tools.spawnCommandAndWriteToFileReturnFileLocationAndSignalFileLocation(script)
                            let pop = InstallAgentLogView()
                            pop.watchFile = ret.0
                            pop.watchSignal = ret.1
                            pop.modalPresentationStyle = .formSheet;
                            pop.modalTransitionStyle = .coverVertical;
                            let window = self.window
                            self.obtainParentViewController?.dismiss(animated: true, completion: {
                                DispatchQueue.main.async {
                                    window?.topMostViewController?.present(pop, animated: true, completion: nil)
                                }
                            })
                        }
                    }))
                    alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
                    self.obtainParentViewController?.present(alert, animated: true, completion: nil)
                case "PackageOperation_NotAvailable":
                    print("Huso? case PackageOperation_NotAvailable should be block above")
                case "PackageOperation_AddWishList":
                    PackageManager.shared.wishListAppend(pkg: item)
                case "PackageOperation_RemoveFromWishList":
                    PackageManager.shared.wishListDelete(withIdentity: item.identity)
                case "PackageOperation_AddToInstall", "PackageOperation_AddToUpdate":
                    self.installSelector(withPackage: item)
                case "PackageOperation_AddToReInstall":
                    self.reInstallSelector(withPackage: item)
                case "PackageOperation_RemoveFromQueue":
                    let ret = TaskManager.shared.removeQueuedPackage(withIdentity: [item.identity])
                    if !ret.didSuccess {
                        let alert = UIAlertController(title: "Error".localized(),
                                                      message: "PackageOperation_OperationInvalid".localized(),
                                                      preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
                        self.obtainParentViewController?.present(alert, animated: true, completion: nil)
                    }
                case "PackageOperation_AddToDelete":
                    let ret = TaskManager.shared.addDelete(with: item)
                    if !ret.0.didSuccess {
                        print(ret)
                        let diag = PackageDiagViewController()
                        diag.loadData(withPackage: item, andResolveObject: ret.0.resolveObject)
                        diag.modalPresentationStyle = .formSheet;
                        diag.modalTransitionStyle = .coverVertical;
                        self.obtainParentViewController?.present(diag, animated: true, completion: nil)
                    }
                case "PackageOperation_Share":
                    var shareStr = item.obtainNameIfExists() + ": " + item.newestVersion()
                    if let desc = item.obtainDescriptionIfExistsOrNil() {
                        let downStr = Down(markdownString: desc)
                        if let atrStr = try? downStr.toAttributedString() {
                            shareStr += " - " + atrStr.string
                        } else {
                            shareStr += " - " + desc
                        }
                    }
                    shareStr.share(fromView: self.obtainParentViewController?.view)
                case "PackageOperation_JustDownload":
                    self.justDownloadSelector(withPackage: item)
                case "PackageOperation_Advanced":
                    let alert = UIAlertController(title: "Error".localized(), message: "Advanced package operation submenu is not supported in this beta", preferredStyle:  .alert)
                    alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
                    self.obtainParentViewController?.present(alert, animated: true, completion: nil)
                case "Cancel":
                    break
                default:
                    print("[Package] Operation not understood: " + operationString)
                }
                self.packageStatusCache = PackageManager.shared.packageStatusLookup(identity: item.identity, version: item.newestVersion())
            } else {
                let alert = UIAlertController(title: "Error".localized(),
                                              message: "PackageOperation_NotAvailableAlertHint".localized(),
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
                self.obtainParentViewController?.present(alert, animated: true, completion: nil)
            }
        }
        dropDown.show(onTopOf: self.window)
    }
    
    func installSelector(withPackage item: PackageStruct) {
        if item.isPaid() {
            if ConfigManager.shared.CydiaConfig.mess {
                let alert = UIAlertController(title: "Error".localized(), message: "RandomDeviceInfoMustBeTurnOff".localized(), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
                self.obtainParentViewController?.present(alert, animated: true, completion: nil)
                return
            }
            if let url = item.fromRepoUrlRef,
                let endPoint = RepoPaymentManager.shared.queryEndpointAndSaveToRam(urlAsKey: url) {
                if RepoPaymentManager.shared.obtainUserSignInfomation(forRepoUrlAsKey: url) != nil {
                    let hud: JGProgressHUD
                    if self.traitCollection.userInterfaceStyle == .dark {
                        hud = .init(style: .dark)
                    } else {
                        hud = .init(style: .light)
                    }
                    hud.show(in: self.obtainParentViewController?.view ?? UIView())
                    DispatchQueue.global(qos: .background).async {
                        RepoPaymentManager.shared.obtainPackageInfo(withUrlAsKey: url, withPkgIdentity: item.identity) { (paymentMetaInfo) in
                            defer {
                                DispatchQueue.main.async {
                                    hud.dismiss()
                                }
                            }
                            if let meta = paymentMetaInfo, meta.available == true {
                                if meta.purchased ?? false {
                                    // go download, overwrite download link
                                    if let target = RepoPaymentManager.shared.queryDownloadLink(withPackage: item) {
                                        let version = item.newestVersion()
                                        var newMeta = item.newestMetaData() ?? [:]
                                        newMeta["filename"] = target
                                        let newPkg = PackageStruct(identity: item.identity, versions: [version : newMeta], fromRepoUrlRef: item.fromRepoUrlRef)
                                        let ret = TaskManager.shared.addInstall(with: newPkg)
                                        if !ret.didSuccess {
                                            DispatchQueue.main.async {
                                                let diag = PackageDiagViewController()
                                                diag.loadData(withPackage: item, andResolveObject: ret.resolveObject)
                                                diag.modalPresentationStyle = .formSheet;
                                                diag.modalTransitionStyle = .coverVertical;
                                                self.obtainParentViewController?.present(diag, animated: true, completion: nil)
                                            }
                                        }
                                        DispatchQueue.main.async {
                                            self.reloadData()
                                        }
                                    } else {
                                        DispatchQueue.main.async {
                                            let alert = UIAlertController(title: "Error".localized(),
                                                                          message: "PackageOperation_PaymentInvalid".localized(),
                                                                          preferredStyle: .alert)
                                            alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
                                            self.obtainParentViewController?.present(alert, animated: true, completion: nil)
                                        }
                                    }
                                } else {
                                    // go 💰
                                    DispatchQueue.main.async {
                                        let alert = UIAlertController(title: meta.price ?? "💰",
                                                                      message: "PackageOperation_PurchaseHint".localized(),
                                                                      preferredStyle: .alert)
                                        alert.addAction(UIAlertAction(title: "Continue".localized(), style: .default, handler: { (_) in
                                            let hud: JGProgressHUD
                                            if self.traitCollection.userInterfaceStyle == .dark {
                                                hud = .init(style: .dark)
                                            } else {
                                                hud = .init(style: .light)
                                            }
                                            hud.show(in: self.obtainParentViewController?.view ?? UIView())
                                            let window = self.window ?? UIWindow()
                                            DispatchQueue.global(qos: .background).async {
                                                defer {
                                                    DispatchQueue.main.async {
                                                        hud.dismiss()
                                                    }
                                                }
                                                let ret = RepoPaymentManager.shared.initPurchase(withUrlAsKey: url, withPkgIdentity: item.identity, withWindow: window)
                                                if ret == .fails {
                                                    let alert = UIAlertController(title: "Error".localized(),
                                                                                  message: "PackageOperation_PaymentInvalid".localized(),
                                                                                  preferredStyle: .alert)
                                                    alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
                                                    self.obtainParentViewController?.present(alert, animated: true, completion: nil)
                                                }
                                                if ret == .succeed {
                                                    let alert = UIAlertController(title: "Done".localized(),
                                                                                  message: "PackageOperation_PaymentSuccess".localized(),
                                                                                  preferredStyle: .alert)
                                                    alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
                                                    self.obtainParentViewController?.present(alert, animated: true, completion: nil)
                                                }
                                            }
                                        }))
                                        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .default, handler: nil))
                                        self.obtainParentViewController?.present(alert, animated: true, completion: nil)
                                    }
                                }
                            } else {
                                DispatchQueue.main.async {
                                    let alert = UIAlertController(title: "Error".localized(),
                                                                  message: "PackageOperation_PaymentInvalid".localized(),
                                                                  preferredStyle: .alert)
                                    alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
                                    self.obtainParentViewController?.present(alert, animated: true, completion: nil)
                                }
                            }
                        }
                    }
                } else {
                    let alert = UIAlertController(title: "Error".localized(),
                                                  message: "PackageOperation_RequiredLogin".localized(),
                                                  preferredStyle: .alert)
                    if let window = self.window {
                        alert.addAction(UIAlertAction(title: "Continue".localized(), style: .default, handler: { (_) in
                            RepoPaymentManager.shared.startUserAuthenticate(inWindow: window, inAlertContainer: self.obtainParentViewController, andRepoUrlAsKey: url, withEndpoint: endPoint) {
                            }
                        }))
                    }
                    alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
                    self.obtainParentViewController?.present(alert, animated: true, completion: nil)
                }
            } else {
                let alert = UIAlertController(title: "Error".localized(),
                                              message: "PackageOperation_PaymentInvalid".localized(),
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
                self.obtainParentViewController?.present(alert, animated: true, completion: nil)
            }
        } else {
            let ret = TaskManager.shared.addInstall(with: item)
            if !ret.didSuccess {
                let diag = PackageDiagViewController()
                diag.loadData(withPackage: item, andResolveObject: ret.resolveObject)
                diag.modalPresentationStyle = .formSheet;
                diag.modalTransitionStyle = .coverVertical;
                self.obtainParentViewController?.present(diag, animated: true, completion: nil)
            }
            self.reloadData()
        }
    }
    
    func justDownloadSelector(withPackage item: PackageStruct) {
        if item.isPaid() {
            if ConfigManager.shared.CydiaConfig.mess {
                let alert = UIAlertController(title: "Error".localized(), message: "RandomDeviceInfoMustBeTurnOff".localized(), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
                self.obtainParentViewController?.present(alert, animated: true, completion: nil)
                return
            }
            if let url = item.fromRepoUrlRef,
                let endPoint = RepoPaymentManager.shared.queryEndpointAndSaveToRam(urlAsKey: url) {
                if RepoPaymentManager.shared.obtainUserSignInfomation(forRepoUrlAsKey: url) != nil {
                    let hud: JGProgressHUD
                    if self.traitCollection.userInterfaceStyle == .dark {
                        hud = .init(style: .dark)
                    } else {
                        hud = .init(style: .light)
                    }
                    hud.show(in: self.obtainParentViewController?.view ?? UIView())
                    DispatchQueue.global(qos: .background).async {
                        RepoPaymentManager.shared.obtainPackageInfo(withUrlAsKey: url, withPkgIdentity: item.identity) { (paymentMetaInfo) in
                            defer {
                                DispatchQueue.main.async {
                                    hud.dismiss()
                                }
                            }
                            if let meta = paymentMetaInfo, meta.available == true {
                                if meta.purchased ?? false {
                                    // go download, overwrite download link
                                    if let target = RepoPaymentManager.shared.queryDownloadLink(withPackage: item) {
                                        let version = item.newestVersion()
                                        var newMeta = item.newestMetaData() ?? [:]
                                        newMeta["filename"] = target
                                        let newPkg = PackageStruct(identity: item.identity, versions: [version : newMeta], fromRepoUrlRef: item.fromRepoUrlRef)
                                        if let url = newPkg.obtainDownloadLocationFromNewestVersion() {
                                            TaskManager.shared.downloadManager.sendToDownload(fromPackage: newPkg, fromURL: url, withFileName: url.lastPathComponent) { (progress) in
                                                NotificationCenter.default.post(name: .DownloadProgressUpdated, object: nil, userInfo: ["key" : url.urlString, "progress" : progress])
                                            }
                                            NotificationCenter.default.post(name: .TaskNumberChanged, object: nil)
                                            NotificationCenter.default.post(name: .TaskListUpdated, object: nil)
                                        }
                                    } else {
                                        DispatchQueue.main.async {
                                            let alert = UIAlertController(title: "Error".localized(),
                                                                          message: "PackageOperation_PaymentInvalid".localized(),
                                                                          preferredStyle: .alert)
                                            alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
                                            self.obtainParentViewController?.present(alert, animated: true, completion: nil)
                                        }
                                    }
                                } else {
                                    // go 💰
                                    DispatchQueue.main.async {
                                        let alert = UIAlertController(title: meta.price ?? "💰",
                                                                      message: "PackageOperation_PurchaseHint".localized(),
                                                                      preferredStyle: .alert)
                                        alert.addAction(UIAlertAction(title: "Continue".localized(), style: .default, handler: { (_) in
                                            let hud: JGProgressHUD
                                            if self.traitCollection.userInterfaceStyle == .dark {
                                                hud = .init(style: .dark)
                                            } else {
                                                hud = .init(style: .light)
                                            }
                                            hud.show(in: self.obtainParentViewController?.view ?? UIView())
                                            let window = self.window ?? UIWindow()
                                            DispatchQueue.global(qos: .background).async {
                                                defer {
                                                    DispatchQueue.main.async {
                                                        hud.dismiss()
                                                    }
                                                }
                                                let ret = RepoPaymentManager.shared.initPurchase(withUrlAsKey: url, withPkgIdentity: item.identity, withWindow: window)
                                                if ret == .fails {
                                                    let alert = UIAlertController(title: "Error".localized(),
                                                                                  message: "PackageOperation_PaymentInvalid".localized(),
                                                                                  preferredStyle: .alert)
                                                    alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
                                                    self.obtainParentViewController?.present(alert, animated: true, completion: nil)
                                                }
                                                if ret == .succeed {
                                                    let alert = UIAlertController(title: "Done".localized(),
                                                                                  message: "PackageOperation_PaymentSuccess".localized(),
                                                                                  preferredStyle: .alert)
                                                    alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
                                                    self.obtainParentViewController?.present(alert, animated: true, completion: nil)
                                                }
                                            }
                                        }))
                                        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .default, handler: nil))
                                        self.obtainParentViewController?.present(alert, animated: true, completion: nil)
                                    }
                                }
                            } else {
                                DispatchQueue.main.async {
                                    let alert = UIAlertController(title: "Error".localized(),
                                                                  message: "PackageOperation_PaymentInvalid".localized(),
                                                                  preferredStyle: .alert)
                                    alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
                                    self.obtainParentViewController?.present(alert, animated: true, completion: nil)
                                }
                            }
                        }
                    }
                } else {
                    let alert = UIAlertController(title: "Error".localized(),
                                                  message: "PackageOperation_RequiredLogin".localized(),
                                                  preferredStyle: .alert)
                    if let window = self.window {
                        alert.addAction(UIAlertAction(title: "Continue".localized(), style: .default, handler: { (_) in
                            RepoPaymentManager.shared.startUserAuthenticate(inWindow: window, inAlertContainer: self.obtainParentViewController, andRepoUrlAsKey: url, withEndpoint: endPoint) {
                            }
                        }))
                    }
                    alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
                    self.obtainParentViewController?.present(alert, animated: true, completion: nil)
                }
            } else {
                let alert = UIAlertController(title: "Error".localized(),
                                              message: "PackageOperation_PaymentInvalid".localized(),
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
                self.obtainParentViewController?.present(alert, animated: true, completion: nil)
            }
        } else {
            if let url = item.obtainDownloadLocationFromNewestVersion() {
                TaskManager.shared.downloadManager.sendToDownload(fromPackage: item, fromURL: url, withFileName: url.lastPathComponent) { (progress) in
                    NotificationCenter.default.post(name: .DownloadProgressUpdated, object: nil, userInfo: ["key" : url.urlString, "progress" : progress])
                }
                NotificationCenter.default.post(name: .TaskNumberChanged, object: nil)
                NotificationCenter.default.post(name: .TaskListUpdated, object: nil)
            } else {
                let alert = UIAlertController(title: "Error".localized(),
                                              message: "PackageDiagnosis_NoDownloadURLAvailable".localized(), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
                self.obtainParentViewController?.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func reInstallSelector(withPackage item: PackageStruct) {
        if let installedVersion = PackageManager.shared.getInstalledVersion(withIdentity: item.identity),
            let meta = item.versions[installedVersion], meta["filename"] != nil {
            let newPackage = PackageStruct(identity: item.identity, versions: [installedVersion : meta], fromRepoUrlRef: item.fromRepoUrlRef)
            self.installSelector(withPackage: newPackage)
        } else {
            let alert = UIAlertController(title: "Error".localized(),
                                          message: "PackageDiagnosis_NoDownloadURLAvailable".localized(),
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
            self.obtainParentViewController?.present(alert, animated: true, completion: nil)
        }
        self.reloadData()
    }
    
}
