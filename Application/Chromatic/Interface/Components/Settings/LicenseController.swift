//
//  LicenseController.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/30.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import UIKit

class LicenseController: UIViewController {
    let padding: CGFloat = 15
    let textView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("LICENSE", comment: "License")
        navigationItem.largeTitleDisplayMode = .never
        preferredContentSize = preferredPopOverSize
        view.backgroundColor = .systemBackground

        if let url = Bundle.main.url(forResource: "ScannedLicense", withExtension: nil),
           let str = try? String(contentsOf: url)
        {
            textView.text = "\n\n\n\n\n\n\n\(str)"
        } else if let url = Bundle.main.url(forResource: "Bundle", withExtension: nil),
                  let str = try? String(contentsOf: url.appendingPathComponent("ScannedLicense"))
        {
            textView.text = "\n\n\n\n\n\n\n\(str)"
        } else {
            textView.text = NSLocalizedString("UNAVAILABLE", comment: "Unavailable")
        }

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
            bigTitle.text = NSLocalizedString("LICENSE", comment: "License")
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

        hideKeyboardWhenTappedAround()
    }
}
