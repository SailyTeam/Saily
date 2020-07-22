//
//  SearchBar.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/20.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit
import SnapKit

protocol SearchBarDelegate {
    func focused()
    func textDidChange(input: String)
    func performSearch(input: String)
    func finishInput(withResult: String)
}

class SearchBar: UIView, UITextViewDelegate {
    
    var delegate: SearchBarDelegate?
    
    var iconView: UIImageView = UIImageView(image: UIImage(named: "SearchBar.Icon"))
    var placeholder: UILabel = UILabel()
    var textView: UITextView = UITextView()
    var coverButton: UIButton = UIButton()
    var cancelButton: UIButton = UIButton()
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    required init() {
        super.init(frame: CGRect())
        
        backgroundColor = UIColor(named: "G-Background-Fill")
        
//        dropShadow()
        layer.cornerRadius = 12
        
        let gap = 12
        
        addSubview(cancelButton)
        cancelButton.setTitle("Cancel".localized(), for: .normal)
        cancelButton.isHidden = true
        cancelButton.setTitleColor(UIColor(named: "G-Button-Normal"), for: .normal)
        cancelButton.snp.makeConstraints { (x) in
        x.centerY.equalTo(self.snp.centerY)
            x.right.equalTo(self.snp.right).offset(-gap)
            x.width.equalTo(80)
            x.height.equalTo(25)
            x.centerY.equalTo(self.snp.centerY)
        }
        
        iconView.alpha = 0.3
        iconView.contentMode = .scaleAspectFit
        addSubview(iconView)
        iconView.snp.makeConstraints { (x) in
            x.centerY.equalTo(self.snp.centerY)
            x.left.equalTo(self.snp.left).offset(gap)
            x.height.equalTo(25)
            x.width.equalTo(30)
        }
        
        placeholder.text = "SearchBar_SearchPackageOrRepo".localized()
        placeholder.textColor = UIColor(named: "SearchBar.PlaceHolder")
        placeholder.font = .monospacedSystemFont(ofSize: 18, weight: .bold)
        addSubview(placeholder)
        placeholder.snp.makeConstraints { (x) in
            x.centerY.equalTo(self.snp.centerY)
            x.left.equalTo(iconView.snp.right).offset(gap)
            x.top.equalTo(self.snp.top).offset(gap / 2)
            x.width.equalTo(233)
        }
        
        addSubview(coverButton)
        coverButton.snp.makeConstraints { (x) in
            x.centerY.equalTo(self.snp.centerY)
            x.left.equalTo(iconView.snp.right).offset(gap)
            x.top.equalTo(self.snp.top).offset(gap / 2)
            x.right.equalTo(cancelButton.snp.left).offset(-gap)
        }
        coverButton.addTarget(self, action: #selector(touched), for: .touchUpInside)
        
        addSubview(textView)
        textView.autocorrectionType = .no
        textView.delegate = self
        textView.isHidden = true
        textView.backgroundColor = .clear
        textView.returnKeyType = .search
        textView.autocapitalizationType = .none
        textView.font = .monospacedSystemFont(ofSize: 18, weight: .semibold)
        textView.isScrollEnabled = false
        textView.snp.makeConstraints { (x) in
            x.top.equalTo(self.snp.top).offset(5)
            x.left.equalTo(iconView.snp.right).offset(gap)
            x.right.equalTo(cancelButton.snp.left).offset(-gap)
            x.bottom.lessThanOrEqualTo(self.snp.bottom).offset(-5)
        }
        
        cancelButton.addTarget(self, action: #selector(finishInput), for: .touchUpInside)
        
    }
    
    deinit {
        delegate = nil
        textView.resignFirstResponder()
        self.subviews.forEach { (view) in
            view.removeFromSuperview()
        }
    }
    
    func active() {
        DispatchQueue.main.async { [weak self] in
            self?.touched(slient: true)
        }
    }
    
    func deactive() {
        finishInput()
    }
    
    @objc private
    func touched(slient: Bool = false) {
        coverButton.isHidden = true
        cancelButton.alpha = 0
        cancelButton.isHidden = false
        
        textView.becomeFirstResponder()
        textView.isHidden = false
        textView.isUserInteractionEnabled = true
        placeholder.isHidden = true
        
        UIView.animate(withDuration: 0.5) {
            self.cancelButton.alpha = 1
        }
        
        if !slient {
            delegate?.focused()
        }
    }
    
    @objc private
    func finishInput() {
        coverButton.isHidden = false
        if textView.text == "" {
            textView.isUserInteractionEnabled = false
            placeholder.isHidden = false
            UIView.animate(withDuration: 0.5, animations: {
                self.cancelButton.alpha = 0
            }) { (_) in
                self.cancelButton.isHidden = true
            }
        } else {
            textView.isUserInteractionEnabled = false
            UIView.animate(withDuration: 0.5, animations: {
                self.cancelButton.alpha = 0
            }) { (_) in
                self.cancelButton.isHidden = true
            }
        }
        Tools.rprint("SearchBar input session finished with text: " + textView.text)
        delegate?.finishInput(withResult: textView.text)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        delegate?.textDidChange(input: textView.text)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        finishInput()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
}
