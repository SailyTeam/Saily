//
//  RepoAddController+Layout.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/17.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import UIKit

extension RepoAddViewController: UITextViewDelegate {
    func layoutViews() {
        view.addSubview(container)
        container.snp.makeConstraints { x in
            x.edges.equalToSuperview()
        }

        var anchor = UIView()
        container.alwaysBounceVertical = true
        container.addSubview(anchor)
        anchor.snp.makeConstraints { x in
            x.centerX.equalToSuperview()
            x.width.equalToSuperview()
            x.trailing.equalTo(self.view.snp.trailing)
            x.height.equalTo(0)
            x.top.equalToSuperview()
        }

        var padding = 30
        if let navigator = navigationController,
           navigator.navigationBar.prefersLargeTitles
        {
            title = NSLocalizedString("ADD", comment: "Add")
            padding = 12
        } else {
            titleLabel.text = NSLocalizedString("ADD", comment: "Add")
            titleLabel.font = .systemFont(ofSize: 30, weight: .heavy)
            container.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { x in
                x.top.equalTo(container.snp.top).offset(30)
                x.leading.equalTo(self.view.snp.leading).offset(padding + 4)
                x.width.equalTo(123)
                x.height.equalTo(48)
            }
            anchor = titleLabel
        }

        titleDescription.text = NSLocalizedString("REPO_DESCRIPTION", comment: "The software source (aka repo) contains various plug-ins, applications, themes, and ringtones, which are maintained by official or unofficial organizations or individuals. You can add any software source without restrictions, but please note that we cannot confirm that the data or information they provide is safe, they may damage your system or equipment, making it impossible to recover.")
        titleDescription.isEditable = false
        titleDescription.textColor = UIColor(named: "TEXT_SUBTITLE")
        titleDescription.backgroundColor = .clear
        titleDescription.font = .systemFont(ofSize: 14, weight: .medium)
        container.addSubview(titleDescription)
        titleDescription.snp.makeConstraints { x in
            x.leading.equalTo(self.view.snp.leading).offset(padding)
            x.trailing.equalTo(self.view.snp.trailing).offset(-padding)
            x.top.equalTo(anchor.snp.bottom).offset(-4)
            x.height.equalTo(128)
        }
        anchor = titleDescription

        if loaclRecordImport.count > 0 {
            localRecord.text = NSLocalizedString("APT_RECORDS", comment: "Apt Records")
            localRecord.textColor = UIColor(named: "TEXT_TITLE")
            localRecord.font = .systemFont(ofSize: 24, weight: .medium)
            localRecordDescription.isUserInteractionEnabled = false
            localRecordDescription.textColor = UIColor(named: "TEXT_SUBTITLE")
            localRecordDescription.text = NSLocalizedString("APT_RECORDS_DESCRIPTION", comment: "Following software sources come from APT or other package managers")
            localRecordDescription.backgroundColor = .clear
            localRecordDescription.font = .systemFont(ofSize: 14, weight: .medium)
            localRecordSelectionSwitcher.setTitle(NSLocalizedString("TOGGLE", comment: "Toggle"), for: .normal)
            localRecordSelectionSwitcher.setTitleColor(UIColor(named: "BUTTON_NORMAL"), for: .normal)
            localRecordSelectionSwitcher.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
            localRecordSelectionSwitcher.contentHorizontalAlignment = .left
            localRecordSelectionSwitcher.addTarget(self, action: #selector(aptSelectSwitch(sender:)), for: .touchUpInside)
            container.addSubview(localRecord)
            container.addSubview(localRecordDescription)
            container.addSubview(localRecordInput!)
            container.addSubview(localRecordSelectionSwitcher)
            localRecord.snp.makeConstraints { x in
                x.top.equalTo(anchor.snp.bottom).offset(0)
                x.leading.equalTo(self.view.snp.leading).offset(padding + 4)
                x.width.equalTo(288)
                x.height.equalTo(48)
            }
            localRecordSelectionSwitcher.snp.makeConstraints { x in
                x.trailing.equalTo(self.view.snp.trailing).offset(-padding - 4)
                x.bottom.equalTo(self.localRecord.snp.bottom).offset(-4)
            }
            anchor = localRecord
            localRecordDescription.snp.makeConstraints { x in
                x.leading.equalTo(self.view.snp.leading).offset(padding)
                x.trailing.equalTo(self.view.snp.trailing).offset(-padding)
                x.top.equalTo(anchor.snp.bottom).offset(0)
                x.height.equalTo(28)
            }
            anchor = localRecordDescription
            localRecordInput?.snp.makeConstraints { x in
                x.leading.equalTo(self.view.snp.leading).offset(padding)
                x.trailing.equalTo(self.view.snp.trailing).offset(-padding)
                x.height.equalTo(22 * loaclRecordImport.count)
                x.top.equalTo(anchor.snp.bottom).offset(4)
            }
            anchor = localRecordInput!
        } else {
            localRecordDescription.isHidden = true
        }

        if pasteboardImport.count > 0 {
            pasteboardRecord.text = NSLocalizedString("PASTEBOARD_REPO", comment: "Pasteboard Records")
            pasteboardRecord.textColor = UIColor(named: "TEXT_TITLE")
            pasteboardRecord.font = .systemFont(ofSize: 24, weight: .medium)
            pasteboardRecordDescription.isUserInteractionEnabled = false
            pasteboardRecordDescription.textColor = UIColor(named: "TEXT_SUBTITLE")
            pasteboardRecordDescription.text = NSLocalizedString("PASTEBOARD_REPO_DESCRIPTION", comment: "We found these links in the clipboard, they may be the source of the software")
            pasteboardRecordDescription.backgroundColor = .clear
            pasteboardRecordDescription.font = .systemFont(ofSize: 14, weight: .medium)
            pasteboardSelectionSwitcher.setTitle(NSLocalizedString("TOGGLE", comment: "Toggle"), for: .normal)
            pasteboardSelectionSwitcher.setTitleColor(UIColor(named: "BUTTON_NORMAL"), for: .normal)
            pasteboardSelectionSwitcher.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
            pasteboardSelectionSwitcher.contentHorizontalAlignment = .left
            pasteboardSelectionSwitcher.addTarget(self, action: #selector(clipSelectSwitch(sender:)), for: .touchUpInside)
            container.addSubview(pasteboardRecord)
            container.addSubview(pasteboardRecordDescription)
            container.addSubview(pasteboardInput!)
            container.addSubview(pasteboardSelectionSwitcher)
            pasteboardRecord.snp.makeConstraints { x in
                x.top.equalTo(anchor.snp.bottom).offset(0)
                x.leading.equalTo(self.view.snp.leading).offset(padding + 4)
                x.width.equalTo(288)
                x.height.equalTo(48)
            }
            pasteboardSelectionSwitcher.snp.makeConstraints { x in
                x.trailing.equalTo(self.view.snp.trailing).offset(-padding - 4)
                x.bottom.equalTo(self.pasteboardRecord.snp.bottom).offset(-4)
            }
            anchor = pasteboardRecord
            pasteboardRecordDescription.snp.makeConstraints { x in
                x.leading.equalTo(self.view.snp.leading).offset(padding)
                x.trailing.equalTo(self.view.snp.trailing).offset(-padding)
                x.top.equalTo(anchor.snp.bottom).offset(0)
                x.height.equalTo(28)
            }
            anchor = pasteboardRecordDescription
            pasteboardInput?.snp.makeConstraints { x in
                x.leading.equalTo(self.view.snp.leading).offset(padding)
                x.trailing.equalTo(self.view.snp.trailing).offset(-padding)
                x.height.equalTo(22 * pasteboardImport.count)
                x.top.equalTo(anchor.snp.bottom).offset(4)
            }
            anchor = pasteboardInput!
        } else {
            pasteboardRecordDescription.isHidden = true
        }

        if historyImport.count > 0 {
            historyRecord.text = NSLocalizedString("HISTORY_RECORDS", comment: "History Records")
            historyRecord.textColor = UIColor(named: "TEXT_TITLE")
            historyRecord.font = .systemFont(ofSize: 24, weight: .medium)
            historyRecordDescription.isUserInteractionEnabled = false
            historyRecordDescription.textColor = UIColor(named: "TEXT_SUBTITLE")
            historyRecordDescription.text = NSLocalizedString("HISTORY_RECORDS_DESCRIPTION", comment: "You have added these software sources before. These records will be kept for two weeks until you manually turn off this function.")
            historyRecordDescription.backgroundColor = .clear
            historyRecordDescription.font = .systemFont(ofSize: 14, weight: .medium)
            historyRecordSelectionSwitcher.setTitle(NSLocalizedString("TOGGLE", comment: "Toggle"), for: .normal)
            historyRecordSelectionSwitcher.setTitleColor(UIColor(named: "BUTTON_NORMAL"), for: .normal)
            historyRecordSelectionSwitcher.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
            historyRecordSelectionSwitcher.contentHorizontalAlignment = .left
            historyRecordSelectionSwitcher.addTarget(self, action: #selector(recordSelectSwitch(sender:)), for: .touchUpInside)
            container.addSubview(historyRecord)
            container.addSubview(historyRecordDescription)
            container.addSubview(historyRecordInput!)
            container.addSubview(historyRecordSelectionSwitcher)
            historyRecord.snp.makeConstraints { x in
                x.top.equalTo(anchor.snp.bottom).offset(0)
                x.leading.equalTo(self.view.snp.leading).offset(padding + 4)
                x.width.equalTo(288)
                x.height.equalTo(48)
            }
            historyRecordSelectionSwitcher.snp.makeConstraints { x in
                x.trailing.equalTo(self.view.snp.trailing).offset(-padding - 4)
                x.bottom.equalTo(self.historyRecord.snp.bottom).offset(-4)
            }
            anchor = historyRecord
            historyRecordDescription.snp.makeConstraints { x in
                x.leading.equalTo(self.view.snp.leading).offset(padding)
                x.trailing.equalTo(self.view.snp.trailing).offset(-padding)
                x.top.equalTo(anchor.snp.bottom).offset(0)
                x.height.equalTo(28)
            }
            anchor = historyRecordDescription
            historyRecordInput?.snp.makeConstraints { x in
                x.leading.equalTo(self.view.snp.leading).offset(padding)
                x.trailing.equalTo(self.view.snp.trailing).offset(-padding)
                x.height.equalTo(22 * historyImport.count)
                x.top.equalTo(anchor.snp.bottom).offset(4)
            }
            anchor = historyRecordInput!
        } else {
            historyRecordDescription.isHidden = true
        }

        userInput.text = NSLocalizedString("MANUAL_INPUT", comment: "Manual Input")
        userInput.textColor = UIColor(named: "TEXT_TITLE")
        userInput.font = .systemFont(ofSize: 24, weight: .medium)
        userInputDescription.isEditable = false
        userInputDescription.textColor = UIColor(named: "TEXT_SUBTITLE")
        userInputDescription.text = NSLocalizedString("MANUAL_INPUT_DESCRIPTION", comment: "Enter the software source address manually here and use line feed to split multiple addresses")
        userInputDescription.backgroundColor = .clear
        userInputDescription.font = .systemFont(ofSize: 14, weight: .medium)
        userInputValues.backgroundColor = UIColor(named: "RepoAddViewController.InputBackgroundFill")
        userInputValues.layer.cornerRadius = 12
        userInputValues.autocorrectionType = .no
        userInputValues.textContainerInset = UIEdgeInsets(top: 20, left: 20, bottom: 18, right: 18)
        userInputValues.text = "https://"
        userInputValues.delegate = self
        userInputValues.font = .monospacedSystemFont(ofSize: 14, weight: .bold)
        userInputValues.autocapitalizationType = .none
        userInputValues.textColor = UIColor(named: "BUTTON_NORMAL")
        container.addSubview(userInput)
        container.addSubview(userInputDescription)
        container.addSubview(userInputValues)
        userInput.snp.makeConstraints { x in
            x.top.equalTo(anchor.snp.bottom).offset(0)
            x.leading.equalTo(self.view.snp.leading).offset(padding + 4)
            x.width.equalTo(288)
            x.height.equalTo(48)
        }
        anchor = userInput
        userInputDescription.snp.makeConstraints { x in
            x.leading.equalTo(self.view.snp.leading).offset(padding)
            x.trailing.equalTo(self.view.snp.trailing).offset(-padding)
            x.top.equalTo(anchor.snp.bottom).offset(0)
            x.height.equalTo(28)
        }
        anchor = userInputDescription
        userInputValues.snp.makeConstraints { x in
            x.leading.equalTo(self.view.snp.leading).offset(padding)
            x.trailing.equalTo(self.view.snp.trailing).offset(-padding)
            x.height.equalTo(150)
            x.top.equalTo(anchor.snp.bottom).offset(4)
        }
        anchor = userInputValues

        let button = UIButton()
        button.setTitle(NSLocalizedString("CONFIRM", comment: "Confirm"), for: .normal)
        button.setTitleColor(UIColor(hex: 0xFFFFFF), for: .normal)
        button.backgroundColor = UIColor(named: "BUTTON_NORMAL")
        button.layer.cornerRadius = 12
        button.titleLabel?.font = UIFont.roundedFont(ofSize: 18, weight: .semibold)
        button.addTarget(self, action: #selector(sendToConfirm(sender:)), for: .touchUpInside)
        container.addSubview(button)
        button.snp.makeConstraints { x in
            x.right.equalTo(self.view.snp.right).offset(-padding)
            x.top.equalTo(anchor.snp.bottom).offset(30)
            x.height.equalTo(60)
            x.width.equalTo(123)
        }

        let cancel = UIButton()
        cancel.setTitle(NSLocalizedString("CANCEL", comment: "Cancel"), for: .normal)
        cancel.setTitleColor(UIColor(named: "BUTTON_NORMAL"), for: .normal)
        cancel.backgroundColor = UIColor.gray.withAlphaComponent(0.1)
        cancel.layer.cornerRadius = 12
        cancel.titleLabel?.font = UIFont.roundedFont(ofSize: 18, weight: .semibold)
        cancel.addTarget(self, action: #selector(cancel(sender:)), for: .touchUpInside)
        container.addSubview(cancel)
        cancel.snp.makeConstraints { x in
            x.right.equalTo(button.snp.left).offset(-10)
            x.top.equalTo(anchor.snp.bottom).offset(30)
            x.height.equalTo(60)
            x.width.equalTo(123)
        }
        anchor = cancel

        layoutEnding.isHidden = true
        layoutEnding.isUserInteractionEnabled = false
        container.addSubview(layoutEnding)
        layoutEnding.snp.makeConstraints { x in
            x.top.equalTo(container)
            x.centerX.equalTo(view)
            x.width.equalTo(100)
            x.bottom.equalTo(anchor)
        }

        container.showsHorizontalScrollIndicator = false
        container.showsVerticalScrollIndicator = true
        adjustDescriptionsSize()
        container.contentSize = CGSize(width: 0, height: layoutEnding.frame.height + 100)
    }

    func textViewDidChange(_ textView: UITextView) {
        if let text = textView.text,
           text.hasPrefix("https://http")
        {
            textView.text = String(text.dropFirst("https://".count))
        }
    }
}
