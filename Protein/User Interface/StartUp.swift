//
//  StartUp.swift
//  Protein
//
//  Created by Lakr Aream on 2020/7/10.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit
import SnapKit
import DropDown
import Bugsnag

class StartUpVC: UIViewController {
    
    static var booted = false
    @Atomic static var bootInProgress = false
    
    var label = UILabel()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        view.addSubview(label)
        label.snp.makeConstraints { (x) in
            x.centerX.equalTo(self.view)
            x.centerY.equalTo(self.view).offset(20)
        }
        
        label.textColor = .gray
        label.font = .boldSystemFont(ofSize: 12)
        label.font = UIFont.roundedFont(ofSize: 12, weight: .bold).monospacedDigitFont
        
        if Bugsnag.appDidCrashLastLaunch() && !StartUpVC.booted {
            let alert = UIAlertController(title: "⚠️", message: "AllowBugReport".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: { (_) in
                self.boot()
            }))
            alert.addAction(UIAlertAction(title: "Confirm".localized(), style: .default, handler: { (_) in
                Bugsnag.start()
                DispatchQueue.global(qos: .background).async {
                    Bugsnag.notify(NSException(name: NSExceptionName(rawValue: "appDidCrashLastLaunch"), reason: nil, userInfo: nil))
                }
                self.boot()
            }))
            present(alert, animated: true, completion: nil)
        } else {
            boot()
        }
        
    }
    
    func boot() {
        DispatchQueue.global().async {
            
            if StartUpVC.bootInProgress {
                while StartUpVC.bootInProgress && !StartUpVC.booted {
                    sleep(1)
                }
            }
            
            StartUpVC.bootInProgress = true
            defer { StartUpVC.bootInProgress = false }

            let beginAt = Date().timeIntervalSince1970
            
            if !StartUpVC.booted {

                UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
                
                // network fixup
                CellularNetworkTool.fixIt()
                
                DispatchQueue.main.async {
                    self.label.text = "AppDelegate_init".localized()
                }
                Tools.rprint(ConfigManager.shared.documentURL.urlString)
                
                DispatchQueue.main.async {
                    self.label.text = "AppDelegate_loadRepoRecord".localized()
                }
                let _ = RepoManager.shared
                
                DispatchQueue.main.async {
                    self.label.text = "AppDelegate_loadPackageRecord".localized()
                }
                let _ = PackageManager.shared
                
                DispatchQueue.main.async {
                    self.label.text = "AppDelegate_startTaskManager".localized()
                }
                let _ = TaskManager.shared
                
                DispatchQueue.main.async {
                    self.label.text = ""
                }

                #if targetEnvironment(simulator)
                DispatchQueue.main.async {
                
                    print(" ")
                }
                #endif

                DropDown.startListeningToKeyboard()
                DropDown.appearance().textColor = UIColor(named: "G-TextTitle")!
                DropDown.appearance().selectedTextColor = UIColor.white
                DropDown.appearance().textFont = UIFont.systemFont(ofSize: 18, weight: .semibold)
                DropDown.appearance().backgroundColor = UIColor(named: "G-Background-Cell")!
                DropDown.appearance().selectionBackgroundColor = UIColor(hex: 0x93d5dc)!
                DropDown.appearance().layer.shadowOpacity = 0.233
                DropDown.appearance().cellHeight = 60
                DropDown.appearance().cornerRadius = 8

                StartUpVC.booted = true
            }
            
            let sem = DispatchSemaphore(value: 0)
            var vc: UIViewController? = nil
            DispatchQueue.main.async {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                vc = storyboard.instantiateViewController(withIdentifier: "UIEntery")
                vc?.modalPresentationStyle = .fullScreen
                sem.signal()
            }
            sem.wait()
            
            let endsAt = Date().timeIntervalSince1970
            let time = Double(Int((endsAt -  beginAt) * 100)) / 100
            Tools.rprint("AppDelegate_BootstrapTime".localized() + " " + String(time) + "s")
            
            if ConfigManager.shared.Application.bugReportEnabled {
                DispatchQueue.main.async {
                    Bugsnag.start()
                }
            }
            
            DispatchQueue.main.async {
                self.view.window?.rootViewController = vc
            }
            
        }
        
    }
    
}
