//
//  RamLogViewer.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/25.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit

class RamLogViewer: UIViewController {
    
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(named: "G-ViewController-Background")
        
        // Preparing what to
        
        let textView = UITextView()
        textView.textColor = UIColor(named: "G-TextSubTitle")
        textView.backgroundColor = .clear
        textView.clipsToBounds = false
        
        #if targetEnvironment(macCatalyst)
            textView.font = .monospacedSystemFont(ofSize: 14, weight: .bold)
            preferredContentSize = CGSize(width: 700, height: 555)
        #else
            textView.font = .monospacedSystemFont(ofSize: 6, weight: .bold)
            preferredContentSize = CGSize(width: 700, height: 555)
        #endif
        
        textView.isEditable = false
        view.addSubview(textView)
        textView.snp.makeConstraints { (x) in
            x.top.equalTo(self.view.snp.top).offset(28)
            x.bottom.equalTo(self.view.snp.bottom).offset(-28)
            x.left.equalTo(self.view.snp.left)
            x.right.equalTo(self.view.snp.right)
        }
        
        let imgv = UIImageView()
        let closeButton = UIButton()
        imgv.image = UIImage(named: "LicenseViewController.Close")
        imgv.contentMode = .scaleAspectFit
        view.addSubview(imgv)
        view.addSubview(closeButton)
        imgv.snp.makeConstraints { (x) in
            x.bottom.equalTo(self.view.snp.bottom).offset(-30)
            x.right.equalTo(self.view.snp.right).offset(-30)
            x.width.equalTo(20)
            x.height.equalTo(20)
        }
        closeButton.snp.makeConstraints { (x) in
            x.center.equalTo(imgv.snp.center)
            x.width.equalTo(50)
            x.height.equalTo(50)
        }
        closeButton.addTarget(self, action: #selector(closeViewController(sender:)), for: .touchUpInside)
        hideKeyboardWhenTappedAround()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (_) in
            if Tools.ramLogs != textView.text {
                textView.text = Tools.ramLogs
                let bottom = NSMakeRange(textView.text.count - 1, 1)
                textView.scrollRangeToVisible(bottom)
            }
        })
        timer?.fire()
        
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
    
    @objc
    func closeViewController(sender: UIButton) {
        sender.puddingAnimate()
        dismiss(animated: true, completion: nil)
    }
    
}
