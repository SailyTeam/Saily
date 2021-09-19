//
//  RamLogController.swift
//  Chromatic
//
//  Created by Lakr Aream on 2020/4/25.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import Dog
import SPIndicator
import UIKit

class RamLogController: UIViewController {
    var timer: Timer?
    let padding: CGFloat = 15
    let textView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("DIAGNOSTIC", comment: "Diagnostic")
        navigationItem.largeTitleDisplayMode = .never
        preferredContentSize = preferredPopOverSize
        view.backgroundColor = .systemBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: .fluent(.shareIos24Filled),
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(openShareView))

        textView.textColor = UIColor(named: "TEXT_SUBTITLE")
        textView.backgroundColor = .clear
        textView.clipsToBounds = false

        textView.font = .monospacedSystemFont(ofSize: 8, weight: .bold)
        preferredContentSize = preferredPopOverSize

        textView.isEditable = false
        view.addSubview(textView)
        textView.snp.makeConstraints { x in
            x.top.equalTo(view.snp.top).offset(28)
            x.bottom.equalTo(view.snp.bottom).offset(-28)
            x.left.equalTo(view.snp.left)
            x.right.equalTo(view.snp.right)
        }

        if navigationController == nil {
            let bigTitle = UILabel()
            bigTitle.text = NSLocalizedString("DIAGNOSTIC", comment: "Diagnostic")
            bigTitle.font = .systemFont(ofSize: 28, weight: .bold)
            view.addSubview(bigTitle)
            bigTitle.snp.makeConstraints { x in
                x.leading.equalToSuperview().offset(padding)
                x.trailing.equalToSuperview().offset(-padding)
                x.top.equalToSuperview().offset(20)
                x.height.equalTo(40)
            }
            textView.clipsToBounds = true
            textView.snp.remakeConstraints { x in
                x.top.equalTo(bigTitle.snp.bottom)
                x.bottom.equalTo(view.snp.bottom).offset(-28)
                x.left.equalTo(view.snp.left)
                x.right.equalTo(view.snp.right)
            }
        }

        let imgv = UIImageView()
        let closeButton = UIButton()
        imgv.image = UIImage.fluent(.dismissCircle24Filled)
        imgv.tintColor = UIColor(named: "BUTTON_NORMAL")
        imgv.contentMode = .scaleAspectFit
        view.addSubview(imgv)
        view.addSubview(closeButton)
        imgv.snp.makeConstraints { x in
            x.bottom.equalTo(view.snp.bottom).offset(-30)
            x.right.equalTo(view.snp.right).offset(-30)
            x.width.equalTo(30)
            x.height.equalTo(30)
        }
        closeButton.snp.makeConstraints { x in
            x.center.equalTo(imgv.snp.center)
            x.width.equalTo(50)
            x.height.equalTo(50)
        }
        closeButton.addTarget(self, action: #selector(closeViewController(sender:)), for: .touchUpInside)
        hideKeyboardWhenTappedAround()

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] _ in
            guard let self = self else { return }
            let read = Dog.shared.obtainCurrentLogContent()
            if read != self.textView.text {
                self.textView.text = read
                let bottom = NSMakeRange(self.textView.text.count - 1, 1)
                self.textView.scrollRangeToVisible(bottom)
            }
        })
        timer?.fire()

        if navigationController != nil {
            closeButton.isHidden = true
            imgv.isHidden = true
        }
    }

    deinit {
        timer?.invalidate()
        timer = nil
    }

    @objc
    func closeViewController(sender: UIButton) {
        sender.puddingAnimate()
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }

    @objc
    func openShareView() {
        if InterfaceBridge.enableShareSheet {
            let activityViewController = UIActivityViewController(activityItems: [textView.text ?? ""],
                                                                  applicationActivities: nil)
            activityViewController
                .popoverPresentationController?
                .sourceView = textView
            present(activityViewController, animated: true, completion: nil)
        } else {
            UIPasteboard.general.string = textView.text
            SPIndicator.present(title: NSLocalizedString("COPIED", comment: "Cpoied"),
                                message: nil,
                                preset: .done,
                                haptic: .success,
                                from: .top,
                                completion: nil)
        }
    }
}
