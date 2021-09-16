//
//  ExpandedWebView.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/9/16.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import UIKit
import WebKit

class ExpandedWebView: UIView, WKUIDelegate, WKNavigationDelegate {
    let webKitView = WKWebView()
    var onHeightUpdate: ((CGFloat) -> Void)?
    var timer: Timer?
    var heightCache: CGFloat?
    let progressView = UIProgressView()

    private var observation: NSKeyValueObservation?

    init() {
        super.init(frame: CGRect())
        debugPrint(self)
        webKitView.scrollView.isScrollEnabled = false
        webKitView.uiDelegate = self
        webKitView.navigationDelegate = self
        addSubview(webKitView)
        webKitView.snp.makeConstraints { x in
            x.edges.equalToSuperview()
        }
        addSubview(progressView)
        progressView.tintColor = .systemYellow
        progressView.snp.makeConstraints { x in
            x.left.equalToSuperview()
            x.top.equalToSuperview()
            x.right.equalToSuperview()
            x.height.equalTo(2)
        }
        let heightWatcher = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self
                .webKitView
                .evaluateJavaScript("document.body.scrollHeight") { height, _ in
                    guard var height = height as? CGFloat else { return }
                    if height > 5000 { height = 5000 }
                    if self.heightCache != height {
                        self.heightCache = height
                        debugPrint("\(#file) \(#function) onHeightUpdate: \(height)")
                        self.onHeightUpdate?(height)
                    }
                }
        }
        RunLoop.main.add(heightWatcher, forMode: .common)
        timer = heightWatcher

        observation = webKitView.observe(\WKWebView.estimatedProgress, options: .new) { [weak self] _, change in
            debugPrint("\(#file) \(#function) estimatedProgress: \(change)")
            guard let self = self else { return }
            UIView.animate(withDuration: 0.2) {
                let progress = Float(change.newValue ?? 0)
                self.progressView.setProgress(progress, animated: true)
            }
        }

        setWebViewAlphaIfNeeded()
    }

    deinit {
        debugPrint("\(self) deinit")
        timer?.invalidate()
        timer = nil
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    func load(url: URL) {
        webKitView.load(URLRequest(url: url))
    }

    func webView(_: WKWebView, didFinish _: WKNavigation!) {
        restoreWebViewAlpha()
    }

    func setWebViewAlphaIfNeeded() {
        if traitCollection.userInterfaceStyle == .dark {
            webKitView.alpha = 0.2
        }
    }

    func restoreWebViewAlpha() {
        if webKitView.alpha != 1 {
            if traitCollection.userInterfaceStyle == .dark {
                webKitView.evaluateJavaScript(darkModeJavascript, completionHandler: nil)
            }
            UIView.animate(withDuration: 0.5) {
                self.webKitView.alpha = 1
            }
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setWebViewAlphaIfNeeded()
        webKitView.reload()
    }
}
