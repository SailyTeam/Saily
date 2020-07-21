//
//  InstallAgentLogView.swift
//  Protein
//
//  Created by Lakr Aream on 2020/7/16.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit
import DropDown
import JGProgressHUD

class InstallAgentLogView: UIViewController {
    
    var watchFile: String? {
        didSet {
            print("[InstallAgentLogView] watchFile at: " + (watchFile ?? " nowhere"))
        }
    }
    var watchSignal: String? {
        didSet {
            print("[InstallAgentLogView] watchSignal at: " + (watchSignal ?? " nowhere"))
        }
    }
    let textView = UITextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        TaskManager.shared.inSystemTask = true
        
        view.backgroundColor = UIColor(named: "G-ViewController-Background")
        let size = CGSize(width: 600, height: 600)
        preferredContentSize = size
        hideKeyboardWhenTappedAround()
        view.insetsLayoutMarginsFromSafeArea = false
        isModalInPresentation = true
        
        let titleLab = UILabel()
        titleLab.text = "Console".localized()
        titleLab.textAlignment = .center
        titleLab.textColor = UIColor(named: "G-TextTitle")
        titleLab.font = .systemFont(ofSize: 30, weight: .heavy)
        view.addSubview(titleLab)
        titleLab.snp.makeConstraints { (x) in
            x.top.equalToSuperview().offset(50)
            x.left.equalToSuperview().offset(30)
            x.width.equalTo(123)
            x.height.equalTo(40)
        }
        
        textView.clipsToBounds = true
        textView.textColor = UIColor(named: "G-TextSubTitle")
        textView.backgroundColor = .clear
        
        #if targetEnvironment(macCatalyst)
            textView.font = .monospacedSystemFont(ofSize: 20, weight: .bold)
            preferredContentSize = CGSize(width: 700, height: 555)
        #else
            textView.font = .monospacedSystemFont(ofSize: 10, weight: .bold)
            preferredContentSize = CGSize(width: 700, height: 555)
        #endif
        
        view.addSubview(textView)
        textView.snp.makeConstraints { (x) in
            x.top.equalTo(titleLab.snp.bottom).offset(25)
            x.bottom.equalTo(self.view.snp.bottom).offset(-25)
            x.left.equalTo(self.view.snp.left).offset(25)
            x.right.equalTo(self.view.snp.right).offset(-25)
        }
        
        looper()
        
    }
    
    private var privTextLenth = 0
    private var count = 0
    func looper() {
        count += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let str = self.watchFile, let raw = try? String(contentsOfFile: str) {
                self.textView.text = raw
                if self.privTextLenth != raw.count {
                    self.privTextLenth = raw.count
                    let bottom = NSMakeRange(self.textView.text.count - 1, 0)
                    self.textView.scrollRangeToVisible(bottom)
                }
            }
            if let signale = self.watchSignal, FileManager.default.fileExists(atPath: signale) || self.count > 60 * 10 {
                self.addCloseButton()
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.looper()
            }
        }
    }
    
    private let dropdownAnchor = UIView()
    func addCloseButton() {
        let imgv = UIImageView()
        let closeButton = UIButton()
        imgv.image = UIImage(named: "exit")
        imgv.contentMode = .scaleAspectFit
        view.addSubview(imgv)
        view.addSubview(closeButton)
        imgv.snp.makeConstraints { (x) in
            x.bottom.equalTo(self.view.snp.bottom).offset(-25 - 21)
            x.right.equalTo(self.view.snp.right).offset(-25 - 21)
            x.width.equalTo(42)
            x.height.equalTo(42)
        }
        closeButton.snp.makeConstraints { (x) in
            x.center.equalTo(imgv.snp.center)
            x.width.equalTo(60)
            x.height.equalTo(60)
        }
        closeButton.addTarget(self, action: #selector(closeViewController(sender:)), for: .touchUpInside)
        view.addSubview(dropdownAnchor)
        dropdownAnchor.snp.makeConstraints { (x) in
            x.bottom.equalTo(self.view.snp.bottom).offset(-25 - 21 + 8)
            x.right.equalTo(self.view.snp.right).offset(-25 - 21)
            x.width.equalTo(250)
            x.height.equalTo(2)
        }
    }
    
    @objc
    func closeViewController(sender: UIButton) {
        sender.shineAnimation()
        
        let dropDown = DropDown(anchorView: dropdownAnchor)
        var actions = ["ReloadSpringBoard", "RebuildUIcache"]
        if FileManager.default.fileExists(atPath: "/.installed_unc0ver") {
            actions.append("RebootUserSpace")
        }
        actions.append("Done")
        dropDown.dataSource = actions.map({ (str) -> String in
            return "   " + str.localized()
        })
        dropDown.selectionAction = { [unowned self] (index, _) in
            let act = actions[index]
            if act == "Done" {
                var hud: JGProgressHUD?
                if self.traitCollection.userInterfaceStyle == .dark {
                    hud = .init(style: .dark)
                } else {
                    hud = .init(style: .light)
                }
                hud?.show(in: self.view)
                DispatchQueue.global(qos: .background).async {
                    PackageManager.shared.updateInstalledFromDpkgStatus()
                    PackageManager.shared.updateUpdateCandidate()
                    NotificationCenter.default.post(name: .TaskSystemFinished, object: nil)
                    TaskManager.shared.inSystemTask = false
                    TaskManager.shared.cancelAllTasks()
                    DispatchQueue.main.async {
                        hud?.dismiss()
                        self.dismiss(animated: true, completion: nil)
                        NotificationCenter.default.post(name: .TaskSystemFinished, object: nil)
                        AppleCardColorProvider.shared.addColor(withCount: 2)
                    }
                }
                return
            }
            if act == "ReloadSpringBoard" {
                AppleCardColorProvider.shared.addColor(withCount: 2)
                print(Tools.spawnCommandSycn("killall -9 backboardd"))
                return
            }
            if act == "RebootUserSpace" {
                AppleCardColorProvider.shared.addColor(withCount: 2)
                print(Tools.spawnCommandSycn("launchctl reboot userspace"))
                return
            }
            if act == "RebuildUIcache" {
                let dir = ConfigManager.shared.documentString + "/SystemEvents/"
                let signalFile = dir + UUID().uuidString
                print("[System] Signal to " + signalFile)
                try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
                var hud: JGProgressHUD?
                if let view = self.view {
                    if self.traitCollection.userInterfaceStyle == .dark {
                        hud = .init(style: .dark)
                    } else {
                        hud = .init(style: .light)
                    }
                    hud?.show(in: view)
                }
                DispatchQueue.global(qos: .background).async {
                    print(Tools.spawnCommandSycn("uicache -a && echo done >> " + signalFile))
                }
                DispatchQueue.global(qos: .background).async {
                    var count = 0
                    while count < 120 {
                        sleep(1)
                        if let str = try? String(contentsOfFile: signalFile),
                            str.hasPrefix("done") {
                            break
                        }
                        count += 1
                    }
                    hud?.dismiss()
                    try? FileManager.default.removeItem(atPath: signalFile)
                }
                return
            }
        }
        dropDown.show()
        
        return
    }
    
    
}
