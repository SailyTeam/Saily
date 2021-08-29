//
//  PackageDiagnosticController.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/21.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import UIKit

class PackageDiagnosticController: UIViewController {
    let padding: CGFloat = 15

    let container = UIScrollView()
    let textView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        preferredContentSize = preferredPopOverSize

        title = NSLocalizedString("DIAGNOSTIC", comment: "Diagnostic")

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: .fluent(.shareIos24Filled),
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(openShareView))
        container.alwaysBounceVertical = true
        view.addSubview(container)
        container.snp.makeConstraints { x in
            x.edges.equalToSuperview()
        }

        textView.textColor = UIColor(named: "TEXT_SUBTITLE")
        textView.backgroundColor = .clear
        textView.clipsToBounds = false

        textView.font = .monospacedSystemFont(ofSize: 8, weight: .bold)
        preferredContentSize = preferredPopOverSize

        textView.isEditable = false
        textView.isScrollEnabled = false
        container.addSubview(textView)
        textView.snp.makeConstraints { x in
            x.top.equalToSuperview()
            x.height.equalTo(1000)
            x.left.equalTo(view.snp.left)
            x.right.equalTo(view.snp.right)
        }

        if navigationController == nil {
            let bigTitle = UILabel()
            bigTitle.text = NSLocalizedString("DIAGNOSTIC", comment: "Diagnostic")
            bigTitle.font = .systemFont(ofSize: 28, weight: .bold)
            container.addSubview(bigTitle)
            bigTitle.snp.makeConstraints { x in
                x.leading.equalToSuperview().offset(padding)
                x.trailing.equalToSuperview().offset(-padding)
                x.top.equalToSuperview().offset(20)
                x.height.equalTo(40)
            }
            textView.clipsToBounds = true
            textView.snp.remakeConstraints { x in
                x.top.equalTo(bigTitle.snp.bottom)
                x.top.equalTo(bigTitle.snp.bottom).offset(10)
                x.height.equalTo(1000)
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

        var text = NSLocalizedString("OPERATION_CANNOT_BE_COMPLETE_WITH_FOLLOWING_REASONS",
                                     comment: "Operation can not be complete with following reasons.")
        let report = PackageActionReport.shared.allAvailable()
        text += "\n\n" + report

        textView.text = text

        if navigationController != nil {
            closeButton.isHidden = true
            imgv.isHidden = true
        }
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
            self.adjustSizes()
        }, completion: { _ in
            self.textView.sizeToFit()
            let f1 = self.textView.contentSize.height
            self.container.contentSize = CGSize(width: 10, height: f1 + 100)
        })
    }

    func adjustSizes() {
        textView.sizeToFit()
        let f1 = textView.contentSize.height
        textView.snp.updateConstraints { x in
            x.height.equalTo(f1 + 100)
        }
        view.layoutIfNeeded()
    }

    @objc
    func openShareView() {
        let activityViewController = UIActivityViewController(activityItems: [textView.text ?? ""],
                                                              applicationActivities: nil)
        activityViewController
            .popoverPresentationController?
            .sourceView = container
        present(activityViewController, animated: true, completion: nil)
    }
}
