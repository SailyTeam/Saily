//
//  RepoAddViewController.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/19.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit
import SnapKit
import JGProgressHUD

class RepoAddViewController: UIViewController {
    
    private var APTRepos: [String] = []
    private var ClipRepos: [String] = []
    private var recordRepos: [String] = []
    
    public let container = UIScrollView()
    
    private let tit = UILabel()
    private let titDes = UITextView()
    private let apt = UILabel()
    private let aptDes = UITextView()
    private var aptContext: RepoAddSectionInput?
    private let aptSelectAll = UIButton()
    private let clip = UILabel()
    private let clipDes = UITextView()
    private var clipContext: RepoAddSectionInput?
    private let clipSelectAll = UIButton()
    private let record = UILabel()
    private let recordDes = UITextView()
    private var recordContext: RepoAddSectionInput?
    private let recordSelectAll = UIButton()
    private let input = UILabel()
    private let inputDes = UITextView()
    
    public let inputContext = UITextView()
    
    private let layoutEnd = UIView()

    private var instructionArrow = UILabel()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("[ARC] RepoAddViewController has been deinited")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(named: "G-ViewController-Background")
        let size = CGSize(width: 600, height: 600)
        preferredContentSize = size
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        let alread = RepoManager.shared.repos
        
        do {
            // Cydia
            let cydiaRecord = try? FileManager.default.contentsOfDirectory(atPath: "/etc/apt/sources.list.d/")
            for item in cydiaRecord ?? [] {
                if let read = try? String(contentsOfFile: "/etc/apt/sources.list.d/" + item) {
                    for line in read.components(separatedBy: "\n") {
                        for each in line.components(separatedBy: " ") where each.hasPrefix("http") {
                            if let url = URL(string: each) {
                                var found = false
                                for search in alread where search.url.urlString == url.urlString {
                                    found = true
                                }
                                if !found {
                                    APTRepos.append(url.urlString)
                                }
                            }
                        }
                    }
                }
            }
            // Sileo
            let sileoRecord = try? FileManager.default.contentsOfDirectory(atPath: "/etc/apt/sileo.list.d/")
            for item in sileoRecord ?? [] {
                if let read = try? String(contentsOfFile: "/etc/apt/sileo.list.d/" + item) {
                    for line in read.components(separatedBy: "\n") {
                        if let tryRead = line.components(separatedBy: " ").last {
                            if tryRead.hasPrefix("https://") || tryRead.hasPrefix("http://"),
                                let url = URL(string: tryRead) {
                                var found = false
                                for search in alread where search.url.urlString == url.urlString {
                                    found = true
                                }
                                if !found {
                                    APTRepos.append(url.urlString)
                                }
                            }
                        }
                    }
                }
            }
            
            if APTRepos.count > 0 {
                Tools.rprint("Fond APT repos")
                for item in APTRepos {
                    Tools.rprint("  -> " + item)
                }
            }
            aptContext = RepoAddSectionInput(defaultVal: APTRepos)
        } /* catch {
            Tools.rprint("RepoAddViewController Failed to load APT repos from record")
        } */
        
        do {
            let read = String.clipBoardContext
            for line in read.components(separatedBy: "\n") {
                for str in line.components(separatedBy: " ") {
                    if (str.hasPrefix("http://") || str.hasPrefix("https://")), let url = URL(string: str) {
                        var found = false
                        for search in alread where search.url.urlString == url.urlString {
                            found = true
                        }
                        if !found && !APTRepos.contains(str) {
                            ClipRepos.append(str)
                        }
                    }
                }
            }
            if ClipRepos.count > 0 {
                Tools.rprint("Fond APT repos in clipboard")
                for item in ClipRepos {
                    Tools.rprint("  -> " + item)
                }
            }
            clipContext = RepoAddSectionInput(defaultVal: ClipRepos)
        }
        
        do {
            let get = RepoManager.shared.getHistory().map({ (url) -> String in
                return url.urlString
            })
            get.forEach { (url) in
                if ClipRepos.contains(url) || APTRepos.contains(url) {
                    return
                }
                for item in alread where item.url.urlString == url {
                    return
                }
                recordRepos.append(url)
            }
            if recordRepos.count > 0 {
                Tools.rprint("Fond APT repos in record")
                for item in recordRepos {
                    Tools.rprint("  -> " + item)
                }
            }
            recordContext = RepoAddSectionInput(defaultVal: recordRepos)
        }
     
        container.decelerationRate = .fast
        
        hideKeyboardWhenTappedAround()
        
        bootstrapViews()
        
    }
    
    func showInstructionArrow() {

        instructionArrow.text = "⬇️"
        instructionArrow.font = .systemFont(ofSize: 18, weight: .semibold)
        view.addSubview(instructionArrow)
        instructionArrow.snp.makeConstraints { (x) in
            x.top.equalTo(self.view.snp.bottom).offset(10)
            x.centerX.equalTo(self.view.snp.centerX)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
                self.instructionArrow.snp.updateConstraints { (x) in
                    x.top.equalTo(self.view.snp.bottom).offset(-50)
                }
                self.view.layoutIfNeeded()
            }) { (_) in }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
                    self.instructionArrow.snp.updateConstraints { (x) in
                        x.top.equalTo(self.view.snp.bottom).offset(10)
                    }
                    self.view.layoutIfNeeded()
                }) { (_) in
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.instructionArrow.removeFromSuperview()
            }
        }
    }
    
    
    func bootstrapViews() {
        
        view.addSubview(container)
        container.snp.makeConstraints { (x) in
            x.edges.equalTo(self.view.snp.edges)
        }
        
        let gap = 30
        var anchor = UIView()
        
        tit.text = "RepoAddViewController_TitleAdd".localized()
        tit.textColor = UIColor(named: "G-TextTitle")
        tit.font = .systemFont(ofSize: 30, weight: .heavy)
        container.addSubview(tit)
        tit.snp.makeConstraints { (x) in
            x.top.equalTo(container.snp.top).offset(30)
            x.left.equalTo(self.view.snp.left).offset(gap + 4)
            x.width.equalTo(123)
            x.height.equalTo(48)
        }
        anchor = tit
        
        titDes.text = "RepoAddViewController_RepoDescription".localized()
        titDes.isUserInteractionEnabled = false
        titDes.textColor = UIColor(named: "G-TextSubTitle")
        titDes.backgroundColor = .clear
        titDes.font = .systemFont(ofSize: 14, weight: .medium)
        container.addSubview(titDes)
        titDes.snp.makeConstraints { (x) in
            x.left.equalTo(self.view.snp.left).offset(gap)
            x.right.equalTo(self.view.snp.right).offset(-gap)
            x.top.equalTo(anchor.snp.bottom).offset(-4)
            x.height.equalTo(128)
        }
        anchor = titDes
        
        if APTRepos.count > 0 {
            apt.text = "RepoAddViewController_APTRecordTitle".localized()
            apt.textColor = UIColor(named: "G-TextTitle")
            apt.font = .systemFont(ofSize: 24, weight: .medium)
            aptDes.isUserInteractionEnabled = false
            aptDes.textColor = UIColor(named: "G-TextSubTitle")
            aptDes.text = "RepoAddViewController_APTRecordDescription".localized()
            aptDes.backgroundColor = .clear
            aptDes.font = .systemFont(ofSize: 14, weight: .medium)
            aptSelectAll.setTitle("RepoAddViewController_SelectionSwitcher".localized(), for: .normal)
            aptSelectAll.setTitleColor(UIColor(named: "G-Button-Normal"), for: .normal)
            aptSelectAll.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
            aptSelectAll.contentHorizontalAlignment = .left
            aptSelectAll.addTarget(self, action: #selector(aptSelectSwitch(sender:)), for: .touchUpInside)
            container.addSubview(apt)
            container.addSubview(aptDes)
            container.addSubview(aptContext!)
            container.addSubview(aptSelectAll)
            apt.snp.makeConstraints { (x) in
                x.top.equalTo(anchor.snp.bottom).offset(0)
                x.left.equalTo(self.view.snp.left).offset(gap + 4)
                x.width.equalTo(288)
                x.height.equalTo(48)
            }
            aptSelectAll.snp.makeConstraints { (x) in
                x.right.equalTo(self.view.snp.right).offset(-gap - 4)
                x.bottom.equalTo(self.apt.snp.bottom).offset(-4)
            }
            anchor = apt
            aptDes.snp.makeConstraints { (x) in
                x.left.equalTo(self.view.snp.left).offset(gap)
                x.right.equalTo(self.view.snp.right).offset(-gap)
                x.top.equalTo(anchor.snp.bottom).offset(0)
                x.height.equalTo(28)
            }
            anchor = aptDes
            aptContext?.snp.makeConstraints({ (x) in
                x.left.equalTo(self.view.snp.left).offset(gap)
                x.right.equalTo(self.view.snp.right).offset(-gap)
                x.height.equalTo(22 * APTRepos.count)
                x.top.equalTo(anchor.snp.bottom).offset(4)
            })
            anchor = aptContext!
        }
        
        if ClipRepos.count > 0 {
            clip.text = "RepoAddViewController_ClipBoardTitle".localized()
            clip.textColor = UIColor(named: "G-TextTitle")
            clip.font = .systemFont(ofSize: 24, weight: .medium)
            clipDes.isUserInteractionEnabled = false
            clipDes.textColor = UIColor(named: "G-TextSubTitle")
            clipDes.text = "RepoAddViewController_ClipBoardDescription".localized()
            clipDes.backgroundColor = .clear
            clipDes.font = .systemFont(ofSize: 14, weight: .medium)
            clipSelectAll.setTitle("RepoAddViewController_SelectionSwitcher".localized(), for: .normal)
            clipSelectAll.setTitleColor(UIColor(named: "G-Button-Normal"), for: .normal)
            clipSelectAll.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
            clipSelectAll.contentHorizontalAlignment = .left
            clipSelectAll.addTarget(self, action: #selector(clipSelectSwitch(sender:)), for: .touchUpInside)
            container.addSubview(clip)
            container.addSubview(clipDes)
            container.addSubview(clipContext!)
            container.addSubview(clipSelectAll)
            clip.snp.makeConstraints { (x) in
                x.top.equalTo(anchor.snp.bottom).offset(0)
                x.left.equalTo(self.view.snp.left).offset(gap + 4)
                x.width.equalTo(288)
                x.height.equalTo(48)
            }
            clipSelectAll.snp.makeConstraints { (x) in
                x.right.equalTo(self.view.snp.right).offset(-gap - 4)
                x.bottom.equalTo(self.clip.snp.bottom).offset(-4)
            }
            anchor = clip
            clipDes.snp.makeConstraints { (x) in
                x.left.equalTo(self.view.snp.left).offset(gap)
                x.right.equalTo(self.view.snp.right).offset(-gap)
                x.top.equalTo(anchor.snp.bottom).offset(0)
                x.height.equalTo(28)
            }
            anchor = clipDes
            clipContext?.snp.makeConstraints({ (x) in
                x.left.equalTo(self.view.snp.left).offset(gap)
                x.right.equalTo(self.view.snp.right).offset(-gap)
                x.height.equalTo(22 * ClipRepos.count)
                x.top.equalTo(anchor.snp.bottom).offset(4)
            })
            anchor = clipContext!
        }
        
        if recordRepos.count > 0 {
            record.text = "RepoAddViewController_HistoryTitle".localized()
            record.textColor = UIColor(named: "G-TextTitle")
            record.font = .systemFont(ofSize: 24, weight: .medium)
            recordDes.isUserInteractionEnabled = false
            recordDes.textColor = UIColor(named: "G-TextSubTitle")
            recordDes.text = "RepoAddViewController_HistoryDescription".localized()
            recordDes.backgroundColor = .clear
            recordDes.font = .systemFont(ofSize: 14, weight: .medium)
            recordSelectAll.setTitle("RepoAddViewController_SelectionSwitcher".localized(), for: .normal)
            recordSelectAll.setTitleColor(UIColor(named: "G-Button-Normal"), for: .normal)
            recordSelectAll.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
            recordSelectAll.contentHorizontalAlignment = .left
            recordSelectAll.addTarget(self, action: #selector(recordSelectSwitch(sender:)), for: .touchUpInside)
            container.addSubview(record)
            container.addSubview(recordDes)
            container.addSubview(recordContext!)
            container.addSubview(recordSelectAll)
            record.snp.makeConstraints { (x) in
                x.top.equalTo(anchor.snp.bottom).offset(0)
                x.left.equalTo(self.view.snp.left).offset(gap + 4)
                x.width.equalTo(288)
                x.height.equalTo(48)
            }
            recordSelectAll.snp.makeConstraints { (x) in
                x.right.equalTo(self.view.snp.right).offset(-gap - 4)
                x.bottom.equalTo(self.record.snp.bottom).offset(-4)
            }
            anchor = record
            recordDes.snp.makeConstraints { (x) in
                x.left.equalTo(self.view.snp.left).offset(gap)
                x.right.equalTo(self.view.snp.right).offset(-gap)
                x.top.equalTo(anchor.snp.bottom).offset(0)
                x.height.equalTo(28)
            }
            anchor = recordDes
            recordContext?.snp.makeConstraints({ (x) in
                x.left.equalTo(self.view.snp.left).offset(gap)
                x.right.equalTo(self.view.snp.right).offset(-gap)
                x.height.equalTo(22 * recordRepos.count)
                x.top.equalTo(anchor.snp.bottom).offset(4)
            })
            anchor = recordContext!
        }

        input.text = "RepoAddViewController_InputTitle".localized()
        input.textColor = UIColor(named: "G-TextTitle")
        input.font = .systemFont(ofSize: 24, weight: .medium)
        inputDes.isUserInteractionEnabled = false
        inputDes.textColor = UIColor(named: "G-TextSubTitle")
        inputDes.text = "RepoAddViewController_InputDescription".localized()
        inputDes.backgroundColor = .clear
        inputDes.font = .systemFont(ofSize: 14, weight: .medium)
        inputContext.backgroundColor = UIColor(named: "RepoAddViewController.InputBackgroundFill")
        inputContext.layer.cornerRadius = 12
        inputContext.autocorrectionType = .no
        inputContext.textContainerInset = UIEdgeInsets(top: 20, left: 20, bottom: 18, right: 18)
        inputContext.text = "https://"
        inputContext.font = .monospacedSystemFont(ofSize: 14, weight: .bold)
        inputContext.autocapitalizationType = .none
        inputContext.textColor = UIColor(named: "G-Button-Normal")
        container.addSubview(input)
        container.addSubview(inputDes)
        container.addSubview(inputContext)
        input.snp.makeConstraints { (x) in
            x.top.equalTo(anchor.snp.bottom).offset(0)
            x.left.equalTo(self.view.snp.left).offset(gap + 4)
            x.width.equalTo(288)
            x.height.equalTo(48)
        }
        anchor = input
        inputDes.snp.makeConstraints { (x) in
            x.left.equalTo(self.view.snp.left).offset(gap)
            x.right.equalTo(self.view.snp.right).offset(-gap)
            x.top.equalTo(anchor.snp.bottom).offset(0)
            x.height.equalTo(28)
        }
        anchor = inputDes
        inputContext.snp.makeConstraints({ (x) in
            x.left.equalTo(self.view.snp.left).offset(gap)
            x.right.equalTo(self.view.snp.right).offset(-gap)
            x.height.equalTo(200)
            x.top.equalTo(anchor.snp.bottom).offset(4)
        })
        anchor = inputContext
        
        let button = UIButton()
        button.setTitle("Confirm".localized(), for: .normal)
        button.setTitleColor(UIColor(hex: 0xFFFFFF), for: .normal)
        button.backgroundColor = UIColor(named: "G-Button-Normal")
        button.layer.cornerRadius = 12
        button.titleLabel?.font = UIFont.roundedFont(ofSize: 18, weight: .semibold)
        button.addTarget(self, action: #selector(sendToConfirm(sender:)), for: .touchUpInside)
        container.addSubview(button)
        button.snp.makeConstraints { (x) in
            x.right.equalTo(self.view.snp.right).offset(-gap)
            x.top.equalTo(anchor.snp.bottom).offset(30)
            x.height.equalTo(60)
            x.width.equalTo(123)
        }
        
        let cancel = UIButton()
        cancel.setTitle("Cancel".localized(), for: .normal)
        cancel.setTitleColor(UIColor(named: "G-Button-Normal"), for: .normal)
        cancel.backgroundColor = UIColor(named: "G-Background-Fill")!
        cancel.layer.cornerRadius = 12
        cancel.titleLabel?.font = UIFont.roundedFont(ofSize: 18, weight: .semibold)
        cancel.addTarget(self, action: #selector(cancel(sender:)), for: .touchUpInside)
        container.addSubview(cancel)
        cancel.snp.makeConstraints { (x) in
            x.right.equalTo(button.snp.left).offset(-10)
            x.top.equalTo(anchor.snp.bottom).offset(30)
            x.height.equalTo(60)
            x.width.equalTo(123)
        }
        anchor = cancel
        
        container.addSubview(layoutEnd)
        layoutEnd.snp.makeConstraints { (x) in
            x.top.equalTo(anchor.snp.bottom).offset(28)
            x.height.equalTo(28)
            x.centerX.equalTo(self.view)
            x.width.equalTo(233)
        }
        
//        self.view.isUserInteractionEnabled = false
        
        container.decelerationRate = .fast
        container.showsHorizontalScrollIndicator = false
        container.showsVerticalScrollIndicator = false
                
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
                self.adjustDescriptionsSize()
            }, completion: { (_) in
                self.container.contentSize = CGSize(width: 0, height: self.layoutEnd.frame.maxY)
            })
        }
        
    }
    
    func adjustDescriptionsSize() {
        titDes.sizeToFit()
        aptDes.sizeToFit()
        clipDes.sizeToFit()
        recordDes.sizeToFit()
        inputDes.sizeToFit()
        let f1 = titDes.contentSize.height
        titDes.snp.updateConstraints { (x) in
            x.height.equalTo(f1)
        }
        let f2 = aptDes.contentSize.height
        aptDes.snp.updateConstraints { (x) in
            x.height.equalTo(f2)
        }
        let f3 = clipDes.contentSize.height
        clipDes.snp.updateConstraints { (x) in
            x.height.equalTo(f3)
        }
        let f4 = recordDes.contentSize.height
        recordDes.snp.updateConstraints { (x) in
            x.height.equalTo(f4)
        }
        let f5 = inputDes.contentSize.height
        inputDes.snp.updateConstraints { (x) in
            x.height.equalTo(f5)
        }
        self.view.layoutIfNeeded()
    }
    
    private var instructionArrowAlreadyShown = false
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
                self.adjustDescriptionsSize()
            }, completion:{ (_) in
                self.container.contentSize = CGSize(width: 0, height: self.layoutEnd.frame.maxY)
                if !self.instructionArrowAlreadyShown, self.layoutEnd.frame.maxY > self.container.frame.height + 50 {
                    self.instructionArrowAlreadyShown = true
                    self.showInstructionArrow()
                }
            })
        }
    }
    
    @objc
    func sendToConfirm(sender: UIButton) {
        sender.puddingAnimate()
        
        var read = self.inputContext.text
        read?.cleanAndReplaceLineBreaker()

        let hud: JGProgressHUD
        if self.traitCollection.userInterfaceStyle == .dark {
            hud = .init(style: .dark)
        } else {
            hud = .init(style: .light)
        }
        hud.textLabel.text = "WaitingForDataBase".localized()
        hud.show(in: self.view)
        
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.5) {
            var repo2add = [String]()
            if let section = self.aptContext {
                section.obtainSelected().forEach { (str) in
                    if URL(string: str.lowercased()) != nil {
                        repo2add.append(str)
                    }
                }
            }
            if let section = self.clipContext {
                section.obtainSelected().forEach { (str) in
                    if URL(string: str.lowercased()) != nil {
                        repo2add.append(str)
                    }
                }
            }
            if let section = self.recordContext {
                section.obtainSelected().forEach { (str) in
                    if URL(string: str.lowercased()) != nil {
                        repo2add.append(str)
                    }
                }
            }
            for item in read?.split(separator: "\n") ?? [] where item != "https://" && item != "https://" {
                var trim = item.string()
                trim.removeSpaces()
                if (trim.hasPrefix("http://") || trim.hasPrefix("https://")), URL(string: trim) != nil {
                    repo2add.append(trim)
                }
            }
            repo2add = repo2add.map({ (trim) -> String in
                var trim = trim
                if trim.lowercased().hasPrefix("https://") {
                    trim = "https://" + String(trim.dropFirst("https://".count))
                }
                if trim.lowercased().hasPrefix("http://") {
                    trim = "http://" + String(trim.dropFirst("http://".count))
                }
                while trim.hasSuffix("/") {
                    trim.removeLast()
                }
                return trim
            })
            Tools.rprint(repo2add.description)
            RepoManager.shared.updateDispatchLock = true
            RepoManager.shared.appendNewRepos(withURLs: repo2add.map({ (str) -> URL in
                return URL(string: str)!
            }), andSync: false)
            RepoManager.shared.reloadReposFromDataBase()
            DispatchQueue.main.async {
                hud.dismiss()
                self.dismiss(animated: true, completion: nil)
                DispatchQueue.global(qos: .background).async {
                    RepoManager.shared.updateDispatchLock = false
                    let _ = RepoManager.shared.sendToSmartUpdateRepo()
                }
            }
        }
    }
    
    @objc
    func cancel(sender: UIButton) {
        sender.puddingAnimate()
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc
    func keyboardWillShow(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
                self.layoutEnd.snp.updateConstraints { (x) in
                    x.height.equalTo(keyboardSize.height + 50)
                }
                self.view.layoutSubviews()
            }, completion: { (_) in
                self.container.contentSize = CGSize(width: 0, height: self.layoutEnd.frame.maxY)
            })
        }
    }

    @objc
    func keyboardWillHide(notification: Notification) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
            self.layoutEnd.snp.updateConstraints { (x) in
                x.height.equalTo(28)
            }
        }, completion: { (_) in
            UIView.animate(withDuration: 0.5, delay: 0.2, usingSpringWithDamping: 1, initialSpringVelocity: 0.8,  options: .curveEaseInOut, animations: {
                self.container.contentSize = CGSize(width: 0, height: self.layoutEnd.frame.maxY)
            }, completion: { (_) in
            })
        })
    }
    
    @objc func aptSelectSwitch(sender: UIButton) {
        sender.puddingAnimate()
        if let context = self.aptContext {
            context.selectSwitch()
        }
    }
    
    @objc func clipSelectSwitch(sender: UIButton) {
        sender.puddingAnimate()
        if let context = self.clipContext {
            context.selectSwitch()
        }
    }
    
    @objc func recordSelectSwitch(sender: UIButton) {
        sender.puddingAnimate()
        if let context = self.recordContext {
            context.selectSwitch()
        }
    }
    
}
