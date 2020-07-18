//
//  LicenseViewController.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/19.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit
import Down

class LicenseViewController: UIViewControllerWithCustomizedNavBar {
    
    private let textView: UITextView = UITextView()
    private let container = UIScrollView()
    private var attrStr: NSAttributedString = NSAttributedString()
    
    override func viewDidLoad() {
        
        defer {
            setupNavigationBar()
            container.snp.makeConstraints { (x) in
                x.left.equalToSuperview()
                x.right.equalToSuperview()
                x.top.equalTo(self.SimpleNavBar.snp.bottom)
                x.bottom.equalToSuperview()
            }
            textView.snp.makeConstraints { (x) in
                x.left.equalTo(self.view.snp.left).offset(12)
                x.right.equalTo(self.view.snp.right).offset(-12)
                x.top.equalTo(self.container.snp.top).offset(12)
                x.height.equalTo(1000)
            }
            reloadContainerSize()
        }
        
        view.backgroundColor = UIColor(named: "G-ViewController-Background")
        let size = CGSize(width: 700, height: 555)
        preferredContentSize = size
        hideKeyboardWhenTappedAround()
        view.insetsLayoutMarginsFromSafeArea = false
        isModalInPresentation = true
        
        textView.isEditable = false
        
        view.addSubview(container)
        container.addSubview(textView)
        
        if let resource = Bundle.main.path(forResource: "Acknowledge", ofType: "md"),
            let read = try? String(contentsOfFile: resource) {
            let down = Down(markdownString: read)
            var config = DownStylerConfiguration()
            let colors = LicenseColorCollection()
            config.colors = colors
            config.fonts = DepictionFontCollection()
            config.colors = colors
            let styler = DownStyler(configuration: config)
            if let attributedString = try? down.toAttributedString(.default, styler: styler) {
                textView.attributedText = attributedString
                attrStr = attributedString
                textView.setNeedsDisplay()
                textView.backgroundColor = .clear
            }
            
        }
        
    }
    
    private func updateTextViewHeight() {
        let framesetter = CTFramesetterCreateWithAttributedString(attrStr)
        let targetSize = CGSize(width: self.view.frame.width - 24, height: CGFloat.greatestFiniteMagnitude)
        let fitSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, attrStr.length), nil, targetSize, nil)
        let height = fitSize.height + 20
        textView.snp.updateConstraints { (x) in
            x.height.equalTo(height)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        reloadContainerSize()
    }
    
    func reloadContainerSize() {
        DispatchQueue.main.async {
            self.updateTextViewHeight()
            DispatchQueue.main.async {
                self.container.contentSize = CGSize(width: 0, height: self.textView.frame.maxY + 40)
            }
        }
    }
    
}

fileprivate struct LicenseColorCollection: ColorCollection {

    public var heading1 = SEColors.label
    public var heading2 = SEColors.label
    public var heading3 = SEColors.label
    public var heading4 = SEColors.label
    public var heading5 = SEColors.label
    public var heading6 = SEColors.label
    public var body = SEColors.downLabel
    public var code = SEColors.downLabel
    public var link = DownColor.systemBlue
    public var quote = DownColor.darkGray
    public var quoteStripe = DownColor.darkGray
    public var thematicBreak = DownColor(white: 0.9, alpha: 1)
    public var listItemPrefix = DownColor.lightGray
    public var codeBlockBackground = DownColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1)
}

