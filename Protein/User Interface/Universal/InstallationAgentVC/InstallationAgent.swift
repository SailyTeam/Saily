//
//  InstallationAgent.swift
//  Protein
//
//  Created by Lakr Aream on 2020/7/15.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit
import JGProgressHUD

class InstallationAgent: UIViewController {
    
    private var container = UIScrollView()
    
    private var titleLab = UILabel()
    private var desc  = UITextView()
    private var deleteLabel = UILabel()
    private var deleteSection: InstallAgentSection? = nil
    private var installLabel = UILabel()
    private var installSection: InstallAgentSection? = nil
    private var aptLabel = UILabel()
    private var aptDesc  = UITextView()
    private var aptButton = UIButton()
    private var aptTextResult = UITextView()
    
    private var cancelButton = UIButton()
    private var goButton = UIButton()
    
    private var lastAnchor: UIView? = nil
    
    private let capturedTasks = TaskManager.shared.generatePackageTaskReport()
    var delete = [(String, PackageStruct)]()
    var install = [(String, PackageStruct)]()
    
    private var isLocked = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(named: "G-ViewController-Background")
        let size = CGSize(width: 600, height: 600)
        preferredContentSize = size
        hideKeyboardWhenTappedAround()
        view.insetsLayoutMarginsFromSafeArea = false
        isModalInPresentation = true
        
        container.decelerationRate = .fast
        view.addSubview(container)
        container.snp.makeConstraints { (x) in
            x.edges.equalTo(self.view.snp.edges)
        }
        
        let gap = 30
        let safeAnchor = UIView()
        container.addSubview(safeAnchor)
        container.showsVerticalScrollIndicator = false
        container.showsHorizontalScrollIndicator = false
        container.decelerationRate = .fast
        safeAnchor.snp.makeConstraints { (x) in
            x.left.equalTo(self.view.snp.left).offset(gap)
            x.right.equalTo(self.view.snp.right).offset(-gap)
            x.top.equalTo(container.snp.top).offset(30)
        }
        var anchor = safeAnchor

// MARK: START
        
        do {
            titleLab.text = "InstallAgent_SubmitTitle".localized()
            titleLab.textAlignment = .center
            titleLab.textColor = UIColor(named: "G-TextTitle")
            titleLab.font = .systemFont(ofSize: 30, weight: .heavy)
            container.addSubview(titleLab)
            titleLab.snp.makeConstraints { (x) in
                x.top.equalTo(container.snp.top).offset(30)
                x.centerX.equalTo(safeAnchor)
                x.height.equalTo(60)
            }
            anchor = titleLab
            
            desc.text = "InstallAgent_SubmitTitleHint".localized()
            desc.isUserInteractionEnabled = false
            desc.textColor = UIColor(named: "G-TextSubTitle")
            desc.backgroundColor = .clear
            desc.font = .systemFont(ofSize: 14, weight: .medium)
            container.addSubview(desc)
            desc.snp.makeConstraints { (x) in
                x.left.equalTo(safeAnchor.snp.left)
                x.right.equalTo(safeAnchor.snp.right)
                x.top.equalTo(anchor.snp.bottom)
                x.height.equalTo(150)
            }
            anchor = desc
        }

// MARK: DELETE
        
        for (identity, payload) in capturedTasks where payload.0 == .pullupDelete || payload.0 == .selectDelete {
            delete.append((identity, payload.1))
        }
        delete.sort { (A, B) -> Bool in
            return A.1.obtainNameIfExists() < B.1.obtainNameIfExists() ? true : false
        }
        if delete.count > 0 {
            deleteLabel.text = "Delete".localized()
            deleteLabel.textColor = UIColor(named: "G-TextTitle")
            deleteLabel.font = .systemFont(ofSize: 20, weight: .medium)
            deleteLabel.textAlignment = .center
            deleteSection = InstallAgentSection(withPkgList: delete.map({ (payload) -> PackageStruct in
                return payload.1
            }), isDelete: true)
            container.addSubview(deleteLabel)
            container.addSubview(deleteSection!)
            deleteLabel.snp.makeConstraints { (x) in
                x.top.equalTo(anchor.snp.bottom)
                x.centerX.equalTo(safeAnchor.snp.centerX)
                x.width.equalTo(288)
                x.height.equalTo(60)
            }
            anchor = deleteLabel
            deleteSection?.snp.makeConstraints({ (x) in
                x.left.equalTo(safeAnchor.snp.left)
                x.right.equalTo(safeAnchor.snp.right)
                x.top.equalTo(anchor.snp.bottom)
                x.height.equalTo(deleteSection!.reportHeight())
            })
            anchor = deleteSection!
        }
        
// MARK: INSTALL
        
        for (identity, payload) in capturedTasks where payload.0 == .pullupInstall || payload.0 == .selectInstall {
            install.append((identity, payload.1))
        }
        install.sort { (A, B) -> Bool in
            return A.1.obtainNameIfExists() < B.1.obtainNameIfExists() ? true : false
        }
        if install.count > 0 {
            installLabel.text = "Install".localized()
            installLabel.textColor = UIColor(named: "G-TextTitle")
            installLabel.font = .systemFont(ofSize: 20, weight: .medium)
            installLabel.textAlignment = .center
            installSection = InstallAgentSection(withPkgList: install.map({ (payload) -> PackageStruct in
                return payload.1
            }), isDelete: false)
            container.addSubview(installLabel)
            container.addSubview(installSection!)
            installLabel.snp.makeConstraints { (x) in
                x.top.equalTo(anchor.snp.bottom)
                x.centerX.equalTo(safeAnchor.snp.centerX)
                x.width.equalTo(288)
                x.height.equalTo(50)
            }
            anchor = installLabel
            installSection?.snp.makeConstraints({ (x) in
                x.left.equalTo(safeAnchor.snp.left)
                x.right.equalTo(safeAnchor.snp.right)
                x.top.equalTo(anchor.snp.bottom)
                x.height.equalTo(installSection!.reportHeight())
            })
            anchor = installSection!
        }

// MARK: APT
        
        if ConfigManager.shared.Application.shouldShowAPTReportSection {
//            private var aptDesc  = UITextView()
//            private var aptButton = UIButton()
//            private var aptTextResult = UITextView()
            aptLabel.text = "InstallAgent_APTReportTitle".localized()
            aptLabel.textColor = UIColor(named: "G-TextTitle")
            aptLabel.font = .systemFont(ofSize: 20, weight: .medium)
            aptLabel.textAlignment = .center
            aptDesc.text = "InstallAgent_APTReportTitleHint".localized()
            aptDesc.isUserInteractionEnabled = false
            aptDesc.textColor = UIColor(named: "G-TextSubTitle")
            aptDesc.backgroundColor = .clear
            aptDesc.font = .systemFont(ofSize: 14, weight: .medium)
            aptTextResult.isUserInteractionEnabled = false
            aptTextResult.layer.cornerRadius = 12
            aptTextResult.textColor = UIColor(named: "G-TextSubTitle")
            aptTextResult.backgroundColor = UIColor(named: "G-TextSubTitle")?.withAlphaComponent(0.2)
            aptTextResult.font = .monospacedSystemFont(ofSize: 14, weight: .semibold)
            aptTextResult.textContainerInset = UIEdgeInsets(top: 20, left: 20, bottom: 18, right: 18)
            aptButton.setTitle("InstallAgent_APTGenerateReport".localized(), for: .normal)
            aptButton.addTarget(self, action: #selector(generateAPTReport), for: .touchUpInside)
            aptButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
            aptButton.setTitleColor(UIColor(named: "DashNAV.DashboardSelectedColor"), for: .normal)
            aptButton.setTitleColor(.black, for: .highlighted)
            container.addSubview(aptLabel)
            container.addSubview(aptDesc)
            container.addSubview(aptTextResult)
            container.addSubview(aptButton)
            aptLabel.snp.makeConstraints { (x) in
                x.top.equalTo(anchor.snp.bottom)
                x.centerX.equalTo(safeAnchor.snp.centerX)
                x.width.equalTo(288)
                x.height.equalTo(60)
            }
            anchor = aptLabel
            aptDesc.snp.makeConstraints { (x) in
                x.left.equalTo(safeAnchor.snp.left)
                x.right.equalTo(safeAnchor.snp.right)
                x.top.equalTo(anchor.snp.bottom)
                x.height.equalTo(30)
            }
            anchor = aptDesc
            aptTextResult.snp.makeConstraints { (x) in
                x.left.equalTo(safeAnchor.snp.left)
                x.right.equalTo(safeAnchor.snp.right)
                x.top.equalTo(anchor.snp.bottom)
                x.height.equalTo(128)
            }
            anchor = aptTextResult
            aptButton.snp.makeConstraints { (x) in
                x.center.equalTo(aptTextResult)
            }
        }
        
// MARK: END
        
        goButton.setTitle("Submit".localized(), for: .normal)
        goButton.setTitleColor(UIColor(hex: 0xFFFFFF), for: .normal)
        goButton.backgroundColor = UIColor(named: "DashNAV.TaskSelectedColor")
        goButton.layer.cornerRadius = 12
        goButton.titleLabel?.font = UIFont.roundedFont(ofSize: 18, weight: .semibold)
        goButton.addTarget(self, action: #selector(sendToConfirm(sender:)), for: .touchUpInside)
        container.addSubview(goButton)
        goButton.snp.makeConstraints { (x) in
            x.right.equalTo(self.view.snp.right).offset(-30)
            x.top.equalTo(anchor.snp.bottom).offset(30)
            x.height.equalTo(60)
            x.width.equalTo(123)
        }
        
        cancelButton.setTitle("Cancel".localized(), for: .normal)
        cancelButton.setTitleColor(UIColor(named: "G-Button-Normal"), for: .normal)
        cancelButton.backgroundColor = UIColor(named: "G-Background-Fill")!
        cancelButton.layer.cornerRadius = 12
        cancelButton.titleLabel?.font = UIFont.roundedFont(ofSize: 18, weight: .semibold)
        cancelButton.addTarget(self, action: #selector(cancel(sender:)), for: .touchUpInside)
        container.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { (x) in
            x.right.equalTo(self.goButton.snp.left).offset(-10)
            x.top.equalTo(anchor.snp.bottom).offset(30)
            x.height.equalTo(60)
            x.width.equalTo(123)
        }
        anchor = cancelButton
        
        let foo = UIView()
        container.addSubview(foo)
        foo.snp.makeConstraints { (x) in
            x.top.equalTo(cancelButton)
            x.centerY.equalTo(safeAnchor.snp.centerY)
            x.height.equalTo(128)
        }
        anchor = foo
        
        lastAnchor = anchor
        
        NotificationCenter.default.addObserver(self, selector: #selector(justDismiss), name: .TaskSystemFinished, object: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.layoutSizes()
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.layoutSizes()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .TaskSystemFinished, object: nil)
    }
    
    func layoutSizes() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
            self.adjustDescriptionsSize()
        }, completion:{ (_) in
            if let a = self.lastAnchor {
                self.container.contentSize = CGSize(width: 0, height: a.frame.maxY)
            }
        })
    }
    
    func adjustDescriptionsSize() {
        
        desc.sizeToFit()
        let f1 = desc.contentSize.height
        desc.snp.updateConstraints { (x) in
            x.height.equalTo(f1)
        }
        let f2 = aptDesc.contentSize.height
        aptDesc.snp.updateConstraints { (x) in
            x.height.equalTo(f2)
        }
        
        if aptTextResult.text.count < 10 {
            aptTextResult.snp.updateConstraints { (x) in
                x.height.equalTo(128)
            }
        } else {
            let f3 = aptTextResult.contentSize.height
            aptTextResult.snp.updateConstraints { (x) in
                x.height.equalTo(f3)
            }
        }
        
        self.view.layoutIfNeeded()

    }
    
    private var selfUpdateNotice: Bool = false
    @objc
    func sendToConfirm(sender: UIButton?) {
        sender?.puddingAnimate()
        
        isLocked = true
        defer { isLocked = false }
        
        if TaskManager.shared.inSystemTask {
            let alert = UIAlertController(title: "Warning".localized(), message: "InstallAgent_InTasksNotice".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        
        var script = ""
        script += "echo Unlocking system...\n"
        script += "rm -f /var/lib/apt/lists/lock\n"
        script += "rm -f /var/cache/apt/archives/lock\n"
        script += "rm -f /var/lib/dpkg/lock*\n"
        if delete.count > 0 {
            script += "echo ****REMOVE****\n"
            script += "apt remove --allow-remove-essential --assume-yes --purge "

            for item in delete {
                script += item.0 + " "
            }
            script += "\n"
        }
        
        if install.count > 0 {
            
            script += "echo ****INSTALL****\n"
            
            var installFileLocation = [String]()
            for item in install {
                if item.1.identity.lowercased() == "wiki.qaq.protein" && !selfUpdateNotice {
                    let alert = UIAlertController(title: "Warning".localized(), message: "InstallAgent_UpdateNotice".localized(), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Confirm".localized(), style: .destructive) { (_) in
                        self.selfUpdateNotice = true
                        self.sendToConfirm(sender: nil)
                    })
                    alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .default, handler: nil))
                    present(alert, animated: true, completion: nil)
                    FileManager.default.createFile(atPath: "/private/var/root/Documents/wiki.qaq.protein.update.reopen", contents: nil, attributes: nil)
                    return
                }
                guard let url = item.1.obtainDownloadLocationFromNewestVersion() else {
                    let alert = UIAlertController(title: "Error".localized(), message: "InstallAgent_UnknownError".localized(), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
                    present(alert, animated: true, completion: nil)
                    isLocked = false
                    return
                }
                if let fileLocation = TaskManager.shared.downloadManager.getDownloadedFileLocation(withUrlStringAsKey: url.urlString) {
                    installFileLocation.append(fileLocation)
                } else {
                    let alert = UIAlertController(title: "Error".localized(), message: "InstallAgent_UnableAquireDownloadFile".localized(), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
                    present(alert, animated: true, completion: nil)
                    isLocked = false
                    return
                }
            }
            
            script += "mv /etc/apt/sources.list.d /etc/apt/sources.list.d.locked\n"
            script += "mkdir /etc/apt/sources.list.d\n"
            script += "apt install --assume-yes --reinstall --allow-downgrades -oquiet::NoUpdate=true -oApt::Get::HideAutoRemove=true -oquiet::NoProgress=true -oquiet::NoStatistic=true -oAPT::Get::Show-User-Simulation-Note=False "
            for item in installFileLocation {
                script += item + " "
            }
            script += "\n"
            script += "rm -rf /etc/apt/sources.list.d\n"
            script += "mv /etc/apt/sources.list.d.locked /etc/apt/sources.list.d\n"
        }
        
        script += "echo ***DONE***\n"
        
        let ret = Tools.spawnCommandAndWriteToFileReturnFileLocationAndSignalFileLocation(script)

        let pop = InstallAgentLogView()
        pop.watchFile = ret.0
        pop.watchSignal = ret.1
        pop.modalPresentationStyle = .formSheet;
        pop.modalTransitionStyle = .coverVertical;
        self.present(pop, animated: true, completion: nil)
        
    }
    
    @objc
    func justDismiss() {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc
    func cancel(sender: UIButton) {
        sender.puddingAnimate()
        if !isLocked {
            dismiss(animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Error".localized(), message: "InstallAgent_Locked".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    @objc
    func generateAPTReport() {
        isLocked = true
        
        var script = ""
        
        if delete.count > 0 {
            script += "echo ****REMOVE****\n"
            script += "apt remove --allow-remove-essential --just-print --purge "
            for item in delete {
                script += item.0 + " "
            }
            script += "\n"
        }
        
        if install.count > 0 {
            
            script += "echo ****INSTALL****\n"
            
            var installFileLocation = [String]()
            for item in install {
                guard let url = item.1.obtainDownloadLocationFromNewestVersion() else {
                    let alert = UIAlertController(title: "Error".localized(), message: "InstallAgent_UnknownError".localized(), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
                    present(alert, animated: true, completion: nil)
                    isLocked = false
                    return
                }
                if let fileLocation = TaskManager.shared.downloadManager.getDownloadedFileLocation(withUrlStringAsKey: url.urlString) {
                    installFileLocation.append(fileLocation)
                } else {
                    let alert = UIAlertController(title: "Error".localized(), message: "InstallAgent_UnableAquireDownloadFile".localized(), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
                    present(alert, animated: true, completion: nil)
                    isLocked = false
                    return
                }
            }
            
            script += "apt install --just-print "
            for item in installFileLocation {
                script += item + " "
            }
            script += "\n"
        }
        
        let hud: JGProgressHUD
        if self.traitCollection.userInterfaceStyle == .dark {
            hud = .init(style: .dark)
        } else {
            hud = .init(style: .light)
        }
        hud.textLabel.text = "InstallAgent_APTGeneratingReport".localized()
        hud.show(in: self.view)
        
        let ret = Tools.spawnCommandAndWriteToFileReturnFileLocationAndSignalFileLocation(script)

        DispatchQueue.global(qos: .background).async {
            var count = 0
            while count < 30 {
                count += 1
                if FileManager.default.fileExists(atPath: ret.1) {
                    break
                }
                sleep(1)
            }
            if let str = try? String(contentsOfFile: ret.0) {
                DispatchQueue.main.async {
                    self.aptTextResult.text = str
                    self.aptButton.isHidden = true
                    if str.lowercased().contains("warning") || str.lowercased().contains("error") {
                        let alert = UIAlertController(title: "Warning".localized(), message: "InstallAgent_APTGeneratedReportContainWarningOrError".localized(), preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }
            DispatchQueue.main.async {
                hud.dismiss()
                self.isLocked = false
            }
        }
    }
    
}
