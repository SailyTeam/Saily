//
//  RepoAddViewController.swift
//  Chromatic
//
//  Created by Lakr Aream on 2020/4/19.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import AptRepository
import Dog
import SnapKit
import UIKit

class RepoAddViewController: UIViewController {
    var loaclRecordImport: [String] = []
    var pasteboardImport: [String] = []
    var historyImport: [String] = []

    let container = UIScrollView()

    var parseText: String {
        set {
            userInputValues.text = newValue
        }
        get {
            userInputValues.text
        }
    }

    let titleLabel = UILabel()
    let titleDescription = UITextView()
    let localRecord = UILabel()
    let localRecordDescription = UITextView()
    var localRecordInput: RepoAddSectionInput?
    let localRecordSelectionSwitcher = UIButton()
    let pasteboardRecord = UILabel()
    let pasteboardRecordDescription = UITextView()
    var pasteboardInput: RepoAddSectionInput?
    let pasteboardSelectionSwitcher = UIButton()
    let historyRecord = UILabel()
    let historyRecordDescription = UITextView()
    var historyRecordInput: RepoAddSectionInput?
    let historyRecordSelectionSwitcher = UIButton()
    let userInput = UILabel()
    let userInputDescription = UITextView()
    let userInputValues = UITextView()
    let layoutEnding = UIView()

    deinit {
        NotificationCenter.default.removeObserver(self)
        print("[ARC] RepoAddViewController has been deinited")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        preferredContentSize = preferredPopOverSize

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        var alreadyExists = RepositoryCenter
            .default
            .obtainRepositoryUrls()
        for item in alreadyExists {
            if let extended = URL(string: item.absoluteString + "/") {
                alreadyExists.append(extended)
            }
        }

        do {
            // Cydia
            let cydiaRecord = try? FileManager
                .default
                .contentsOfDirectory(atPath: "/etc/apt/sources.list.d/")
            for item in cydiaRecord ?? [] {
                if let read = try? String(contentsOfFile: "/etc/apt/sources.list.d/" + item) {
                    for line in read.components(separatedBy: "\n") {
                        for each in line.components(separatedBy: " ") where each.hasPrefix("http") {
                            if let url = URL(string: each), !alreadyExists.contains(url) {
                                loaclRecordImport.append(url.absoluteString)
                            }
                        }
                    }
                }
            }
            // Sileo
            let sileoSearchPath = "/etc/apt/sileo.list.d/"
            let sileoRecord = try? FileManager
                .default
                .contentsOfDirectory(atPath: sileoSearchPath)
            for item in sileoRecord ?? [] {
                if let read = try? String(contentsOfFile: sileoSearchPath + item) {
                    for line in read.components(separatedBy: "\n") {
                        for each in line.components(separatedBy: " ") where each.hasPrefix("http") {
                            if let url = URL(string: each), !alreadyExists.contains(url) {
                                loaclRecordImport.append(url.absoluteString)
                            }
                        }
                    }
                }
            }

            if loaclRecordImport.count > 0 {
                Dog.shared.join(self, "found \(loaclRecordImport.count) importable repositories")
            }
            localRecordInput = RepoAddSectionInput(defaultVal: loaclRecordImport.sorted())
        }

        do {
            let read = UIPasteboard.general.string ?? ""
            for line in read.components(separatedBy: "\n") {
                for str in line.components(separatedBy: " ") {
                    if str.hasPrefix("http://") || str.hasPrefix("https://"),
                       let url = URL(string: str),
                       !alreadyExists.contains(url)
                    {
                        pasteboardImport.append(str)
                    }
                }
            }
            if pasteboardImport.count > 0 {
                Dog.shared.join(self, "found \(pasteboardImport.count) importable repositories in pasteboard")
            }
            pasteboardInput = RepoAddSectionInput(defaultVal: pasteboardImport.sorted())
        }

        do {
            let exists = alreadyExists
                .map(\.absoluteString)
            historyImport = RepositoryCenter
                .default
                .historyRecords
                .filter { !loaclRecordImport.contains($0) }
                .filter { !pasteboardImport.contains($0) }
                .filter { !exists.contains($0) }
                .sorted()

            if historyImport.count > 0 {
                Dog.shared.join(self, "found \(pasteboardImport.count) importable repositories in history")
            }
            historyRecordInput = RepoAddSectionInput(defaultVal: historyImport)
        }

        hideKeyboardWhenTappedAround()

        layoutViews()
    }

    func adjustDescriptionsSize() {
        titleDescription.sizeToFit()
        let f1 = titleDescription.contentSize.height
        titleDescription.snp.updateConstraints { x in
            x.height.equalTo(f1)
        }
        if !localRecordDescription.isHidden {
            localRecordDescription.sizeToFit()
            let f2 = localRecordDescription.contentSize.height
            localRecordDescription.snp.updateConstraints { x in
                x.height.equalTo(f2)
            }
        }
        if !pasteboardRecordDescription.isHidden {
            pasteboardRecordDescription.sizeToFit()
            let f3 = pasteboardRecordDescription.contentSize.height
            pasteboardRecordDescription.snp.updateConstraints { x in
                x.height.equalTo(f3)
            }
        }
        if !historyRecordDescription.isHidden {
            historyRecordDescription.sizeToFit()
            let f4 = historyRecordDescription.contentSize.height
            historyRecordDescription.snp.updateConstraints { x in
                x.height.equalTo(f4)
            }
        }
        userInputDescription.sizeToFit()
        let f5 = userInputDescription.contentSize.height
        userInputDescription.snp.updateConstraints { x in
            x.height.equalTo(f5)
        }
        view.layoutIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        DispatchQueue.main.async { [self] in
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: { [self] in
                adjustDescriptionsSize()
            }, completion: { [self] _ in
                let height = layoutEnding.frame.height + 150
                debugPrint("\(#file) #\(#function) \(#line) \(height)")
                container.contentSize = CGSize(width: 0, height: height)
            })
        }
    }

    @objc
    func sendToConfirm(sender: UIButton) {
        sender.puddingAnimate()
        var repositoryAddRequest: Set<URL> = []
        if let section = localRecordInput {
            section
                .obtainSelected()
                .map { clearTrailing($0) }
                .map { URL(string: $0) }
                .compactMap { $0 }
                .forEach { repositoryAddRequest.insert($0) }
        }
        if let section = pasteboardInput {
            section
                .obtainSelected()
                .map { clearTrailing($0) }
                .map { URL(string: $0) }
                .compactMap { $0 }
                .forEach { repositoryAddRequest.insert($0) }
        }
        if let section = historyRecordInput {
            section
                .obtainSelected()
                .map { clearTrailing($0) }
                .map { URL(string: $0) }
                .compactMap { $0 }
                .forEach { repositoryAddRequest.insert($0) }
        }
        userInputValues
            .text
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.hasPrefix("http") }
            .filter { !$0.hasSuffix("://") }
            .map { URL(string: $0) }
            .compactMap { $0 }
            .forEach { repositoryAddRequest.insert($0) }

        repositoryAddRequest.forEach { url in
            RepositoryCenter
                .default
                .registerRepository(withUrl: url)
        }

        cancel(sender: UIButton())
    }

    @objc
    func cancel(sender: UIButton) {
        sender.puddingAnimate()
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }

    @objc
    func keyboardWillShow(notification: Notification) {
        if let keyboardSize = (
            notification
                .userInfo?[UIResponder.keyboardFrameBeginUserInfoKey]
                as? NSValue
        )?
            .cgRectValue
        {
            UIView
                .animate(withDuration: 0.5,
                         delay: 0,
                         usingSpringWithDamping: 1,
                         initialSpringVelocity: 0.8,
                         options: .curveEaseInOut,
                         animations: {
                             self.container.contentSize = CGSize(width: 0, height: self.layoutEnding.frame.height
                                 + 150
                                 + keyboardSize.height)
                         }, completion: { _ in })
        }
    }

    @objc
    func keyboardWillHide(notification _: Notification) {
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 1,
                       initialSpringVelocity: 0.8,
                       options: .curveEaseInOut,
                       animations: {
                           self.container.contentSize = CGSize(width: 0, height: self.layoutEnding.frame.height + 150)
                       }, completion: { _ in })
    }

    @objc func aptSelectSwitch(sender: UIButton) {
        sender.puddingAnimate()
        if let context = localRecordInput {
            context.selectSwitch()
        }
    }

    @objc func clipSelectSwitch(sender: UIButton) {
        sender.puddingAnimate()
        if let context = pasteboardInput {
            context.selectSwitch()
        }
    }

    @objc func recordSelectSwitch(sender: UIButton) {
        sender.puddingAnimate()
        if let context = historyRecordInput {
            context.selectSwitch()
        }
    }
}

private func clearTrailing(_ str: String) -> String {
    var str = str
    while str.hasSuffix("/") {
        str.removeLast()
    }
    return str
}
