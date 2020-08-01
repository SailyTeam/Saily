//
//  DownloadInfoViewController.swift
//  Protein
//
//  Created by Lakr Aream on 2020/8/1.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit

class DownloadInfoViewController: UIViewControllerWithCustomizedNavBar {
    
    private var textView = UITextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        defer {
            setupNavigationBar()

            textView.snp.makeConstraints { (x) in
                x.top.equalTo(self.SimpleNavBar.snp.bottom).offset(25)
                x.bottom.equalTo(self.view.snp.bottom).offset(-25)
                x.left.equalTo(self.view.snp.left).offset(25)
                x.right.equalTo(self.view.snp.right).offset(-25)
            }
        }
        
        view.backgroundColor = UIColor(named: "G-ViewController-Background")
        let size = CGSize(width: 600, height: 600)
        preferredContentSize = size
        hideKeyboardWhenTappedAround()
        view.insetsLayoutMarginsFromSafeArea = false
        isModalInPresentation = true
        
        textView.clipsToBounds = true
        textView.textColor = UIColor(named: "G-TextSubTitle")
        textView.backgroundColor = .clear
        textView.isEditable = false
        
        #if targetEnvironment(macCatalyst)
            textView.font = .monospacedSystemFont(ofSize: 24, weight: .bold)
            preferredContentSize = CGSize(width: 700, height: 555)
        #else
            textView.font = .monospacedSystemFont(ofSize: 14, weight: .bold)
            preferredContentSize = CGSize(width: 700, height: 555)
        #endif
        
        view.addSubview(textView)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.reloadData()
        }
        
    }
    
    func reloadData() {
        textView.text = TaskManager.shared.downloadManager.reportDownloadLogsAndRecords()
    }
    
}
