//
//  ExpandedWebView.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/9/16.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import SafariServices
import UIKit
import WebKit

private let kMaxPageHeight: CGFloat = 7500

class ExpandedWebView: UIView, WKUIDelegate, WKNavigationDelegate {
    let webKitView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        config.allowsAirPlayForMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = .audio
        config.applicationNameForUserAgent = InterfaceBridge.mainUserAgent

        let scaleInjector = """
        var meta = document.createElement('meta');
        meta.name = 'viewport';
        meta.content = 'initial-scale=1, maximum-scale=1, user-scalable=0';
        var head = document.getElementsByTagName('head')[0];
        head.appendChild(meta);
        """
        let userScript = WKUserScript(
            source: scaleInjector,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(userScript)

        let view = WKWebView(frame: CGRect(), configuration: config)
        return view
    }()

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
            self.updateHeightIfNeeded()
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
        var request = URLRequest(url: url)
        for (key, value) in RepositoryCenter.default.networkingHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        webKitView.load(request)
    }

    func webView(_: WKWebView, didFinish _: WKNavigation!) {
        restoreWebViewAlpha()
    }

    func updateHeightIfNeeded() {
        /// https://stackoverflow.com/questions/41179264/how-to-find-the-height-of-the-entire-webpage
        let queryHeight = """
        var pageHeight = 0;
        function findHighestNode(nodesList) {
            for (var i = nodesList.length - 1; i >= 0; i--) {
                if (nodesList[i].scrollHeight && nodesList[i].clientHeight) {
                    var elHeight = Math.max(nodesList[i].scrollHeight, nodesList[i].clientHeight);
                    pageHeight = Math.max(elHeight, pageHeight);
                }
                if (nodesList[i].childNodes.length) findHighestNode(nodesList[i].childNodes);
            }
        }
        findHighestNode(document.documentElement.childNodes);
        pageHeight;
        """
        webKitView.evaluateJavaScript(queryHeight) { height, _ in
            guard var height = height as? CGFloat else { return }
            if height > kMaxPageHeight { height = kMaxPageHeight }
            if self.heightCache != height {
                self.heightCache = height
                debugPrint("\(#file) \(#function) onHeightUpdate: \(height)")
                self.onHeightUpdate?(height)
            }
        }
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

    func webView(_: WKWebView, createWebViewWith _: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures _: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil,
           let url = navigationAction.request.url
        {
            if url.scheme == "http" || url.scheme == "https" {
                let target = SFSafariViewController(url: url)
                window?
                    .topMostViewController?
                    .present(target, animated: true, completion: nil)
            } else {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        return nil
    }
}
