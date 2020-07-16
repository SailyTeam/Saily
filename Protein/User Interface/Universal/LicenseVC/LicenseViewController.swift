//
//  LicenseViewController.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/19.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit
import WebKit

class LicenseViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {
    
    lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        return webView
    }()
    
    let imgv = UIImageView()
    let closeButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        preferredContentSize = CGSize(width: 700, height: 555)
        
        view.insetsLayoutMarginsFromSafeArea = false

        
        webView.alpha = 0.2
        webView.backgroundColor = .clear
        view.backgroundColor = UIColor(named: "G-ViewController-Background")
        view.addSubview(webView)
        webView.snp.makeConstraints { (x) in
            x.edges.equalTo(self.view.snp.edges)
        }
        let myURL = URL(string: DEFINE.WEB_LOCATION_LICENSE) ?? URL(string: "https://google.com")!
        let myRequest = URLRequest(url: myURL)
        webView.load(myRequest)
        
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
    }
    
    @objc
    func closeViewController(sender: UIButton) {
        sender.puddingAnimate()
        dismiss(animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("document.readyState", completionHandler: { (complete, error) in
            if complete != nil {
                if (self.traitCollection.userInterfaceStyle == .dark) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.webView.evaluateJavaScript(Tools.darkModeJS) { (anyret, err) in
                            UIView.animate(withDuration: 0.5) {
                                self.webView.alpha = 1
                            }
                        }
                    }
                } else {
                    UIView.animate(withDuration: 0.5) {
                        self.webView.alpha = 1
                    }
                }
            }
        })
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
//        var isDarkMode: Bool {
//            if #available(iOS 13.0, *) {
//                return self.traitCollection.userInterfaceStyle == .dark
//            }
//            else {
//                return false
//            }
//        }
//        if isDarkMode {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                self.webView.evaluateJavaScript(Tools.darkModeJS_JustToggle) { (anyret, err) in
//                    UIView.animate(withDuration: 0.5) {
//                        self.webView.alpha = 1
//                    }
//                }
//            }
//        } else {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                self.webView.evaluateJavaScript(Tools.darkModeJS_JustToggle) { (anyret, err) in
//                    UIView.animate(withDuration: 0.5) {
//                        self.webView.alpha = 1
//                    }
//                }
//            }
//        }
    }
    
}
