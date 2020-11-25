//
//  PackageViewController.swift
//  Protein
//
//  Created by Lakr Aream on 2020/5/3.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit
import JGProgressHUD
import WebKit
import Down

class PackageViewController: UIViewControllerWithCustomizedNavBar {

    public var PackageObject: PackageStruct? = nil {
        didSet {
            DispatchQueue.main.async {
                self.reloadDataAndPrepareForBootstrap()
                self.BootStrapView()
            }
        }
    }
    
    private let leftAndRightInsert: CGFloat = 22
    
    let container: UIScrollView = UIScrollView()
    var containerSizeRecord: CGRect = CGRect()
    let placeHolder: UIImageView = UIImageView(image: UIImage(named: "PKGVC.PlaceHolder"))
    var PackageThemeColor: UIColor? = nil
    let PackageBannerImage: UIImageView = UIImageView()
    let PackageSection: PackageViewControllerSectionView = PackageViewControllerSectionView(insert: 18)
    
    private let WebViewDelegate = PackageViewControllerWebViewScroolViewDelegate()
    
    private var PackageDepictionContainer: UIView? = nil {
        willSet {
            PackageDepictionContainer?.removeFromSuperview()
            PackageDepictionLayoutToken = ""
        }
        didSet {
            if let target = PackageDepictionContainer {
                container.addSubview(target)
            }
            PackageDepictionLayoutTokenChecker = UUID().uuidString
        }
    }
    
    private var PackageDepictionLayoutToken: String = ""
    public  var PackageDepictionLayoutTokenChecker: String = UUID().uuidString
    public  var PackageDepictionContainerPreferredFloatingPanelVisible: Bool = false
    public  var PackageDepictionContainerPreferredWidth: CGFloat = 0
    public  var PackageDepictionContainerPreferredHeight: CGFloat = 0
    public  var preferredBannerImageHeight: CGFloat = 0
    public  var preferredBannerImageHeightUseable: Bool = false
    public  var preferredGoBackButtonStyleLight: Bool? = nil
    
    private var presentedUnderVisibleNavigationBar: Bool = false
    private var simpleNavBarLocationPoster = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        defer {
            setupNavigationBar()
            makeSimpleNavBarButtonBlue()
            view.addSubview(simpleNavBarLocationPoster)
            simpleNavBarLocationPoster.isUserInteractionEnabled = false
            simpleNavBarLocationPoster.snp.makeConstraints { (x) in
                x.left.equalToSuperview()
                x.right.equalToSuperview()
                x.top.equalTo(self.view.snp.top)
                x.bottom.equalTo(self.SimpleNavBar.snp.bottom)
            }
            makeSimpleNavBarButtonBlue()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                if self.preferredBannerImageHeightUseable {
                    self.PackageBannerImage.snp.updateConstraints { (x) in
                        x.bottom.equalTo(self.container.snp.top).offset(self.SimpleNavBar.frame.maxY)
                    }
                }
            }
        }
        
        if let navhidden = navigationController?.isNavigationBarHidden {
            if !navhidden {
                presentedUnderVisibleNavigationBar = true
                navigationController?.setNavigationBarHidden(true, animated: true)
            }
        }
        
        view.addSubview(container)
        container.addSubview(PackageBannerImage)
        container.addSubview(PackageSection)
        container.showsVerticalScrollIndicator = false
        container.showsHorizontalScrollIndicator = false
        container.alwaysBounceVertical = true
//        container.decelerationRate = .fast
        container.delegate = self
        container.snp.makeConstraints { (x) in
            x.edges.equalTo(self.view)
        }
        
        PackageBannerImage.clipsToBounds = true
        PackageBannerImage.contentMode = .scaleAspectFill
        PackageBannerImage.snp.makeConstraints { (x) in
            x.top.lessThanOrEqualTo(self.container.snp.top)
            x.top.lessThanOrEqualTo(self.view.snp.top)
            x.left.equalTo(self.view.snp.left)
            x.right.equalTo(self.view.snp.right)
            x.height.lessThanOrEqualTo(80)
            x.height.equalTo(80)
            x.bottom.equalTo(self.container.snp.top).offset(self.SimpleNavBar.frame.maxY)
        }
        
        PackageSection.snp.makeConstraints { (x) in
            x.left.equalTo(self.view)
            x.right.equalTo(self.view)
            x.height.equalTo(88)
            x.top.equalTo(PackageBannerImage.snp.bottom)
        }
        
        let sep = UIView()
        sep.backgroundColor = .gray
        sep.alpha = 0.233
        container.addSubview(sep)
        sep.snp.makeConstraints { (x) in
            x.left.equalTo(self.view).offset(-50)
            x.right.equalTo(self.view).offset(50)
            x.height.equalTo(1)
            x.top.equalTo(PackageSection.snp.bottom)
        }
        
        placeHolder.alpha = 0.2
        let shineAnimation = CABasicAnimation(keyPath: "opacity")
        shineAnimation.duration = 0.233
        shineAnimation.repeatCount = .infinity
        shineAnimation.autoreverses = true
        shineAnimation.fromValue = 0.2
        shineAnimation.toValue = 0.233
        placeHolder.layer.add(shineAnimation, forKey: "opacity")
        
        view.addSubview(placeHolder)
        placeHolder.snp.makeConstraints { (x) in
            x.left.equalTo(self.view).offset(leftAndRightInsert)
            x.right.equalTo(self.view).offset(leftAndRightInsert)
            x.bottom.equalTo(self.view)
            x.top.equalTo(PackageSection.snp.bottom).offset(leftAndRightInsert)
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if presentedUnderVisibleNavigationBar {
            navigationController?.setNavigationBarHidden(true, animated: animated)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if presentedUnderVisibleNavigationBar {
            navigationController?.setNavigationBarHidden(false, animated: animated)
        }
    }
    
    private func reloadDataAndPrepareForBootstrap() {
        PackageSection.setPackage(with: self.PackageObject)
        PackageDepictionContainer?.removeFromSuperview()
        placeHolder.isHidden = false
        PackageBannerImage.image = nil
    }
    
    private func BootStrapView() {
        DispatchQueue.global(qos: .background).async {
            self.loadDepictionAndReturnView() { [weak self] (targetView) in
                guard let ourSelf = self else {
                    return
                }
                DispatchQueue.main.async {
                    if let targetDepictionView = targetView {
                        ourSelf.PackageDepictionContainer = targetDepictionView
                    } else {
                        let get = ourSelf.generateDepictionErrorView()
                        ourSelf.PackageDepictionContainer = get.0
                        ourSelf.PackageDepictionContainerPreferredHeight = get.1
                    }
                    ourSelf.updateLayoutsIfNeeded()
                }
            }
        }
    }
    
    public func updateLayoutsIfNeeded() {
        
        if PackageDepictionLayoutToken == PackageDepictionLayoutTokenChecker {
            return
        }
        PackageDepictionLayoutToken = PackageDepictionLayoutTokenChecker
        
//        print("[PackageViewController] Updating layouts " + String(Date().timeIntervalSince1970))
        
        guard let targetContainer = self.PackageDepictionContainer else {
            return
        }
        placeHolder.isHidden = true
        
        let after0 = calculateDepictionPreferredWidth()
        if let hi = targetContainer as? DepictionBaseView {
            hi.delegate = self
            PackageDepictionContainerPreferredHeight = hi.depictionHeight(width: after0)
        }
        
        if let web = targetContainer as? WKWebView {
            web.snp.remakeConstraints { (x) in
                x.left.equalTo(self.view.snp.left)
                x.right.equalTo(self.view.snp.right)
                x.top.equalTo(PackageSection.snp.bottom).offset(leftAndRightInsert)
                x.bottom.equalTo(self.view.snp.bottom)
            }
        } else {
            targetContainer.snp.remakeConstraints { (x) in
                x.left.equalTo(self.view)
                x.width.equalTo(self.PackageDepictionContainerPreferredWidth)
                x.height.equalTo(self.PackageDepictionContainerPreferredHeight)
                x.top.equalTo(PackageSection.snp.bottom).offset(leftAndRightInsert)
            }
        }
        
        if let img = PackageBannerImage.image {
            let height = img.size.height
            let width = img.size.width
            let ratio = width / height
            var preferredHeight = after0 / ratio
            
            let decision = view.frame.width < view.frame.height ? view.frame.width : view.frame.height
            let minHeight = decision * 0.5
            let maxHeight = decision * 1.5
            
            if preferredHeight < minHeight {
                preferredHeight = minHeight
            }
            if preferredHeight > maxHeight {
                preferredHeight = maxHeight
            }
            preferredBannerImageHeight = preferredHeight
            if img.isLight() ?? false {
                preferredGoBackButtonStyleLight = false
            } else {
                preferredGoBackButtonStyleLight = true
            }
        }
        
        if preferredBannerImageHeight < simpleNavBarLocationPoster.frame.height + simpleNavBarLocationPoster.frame.minY {
            preferredBannerImageHeight = simpleNavBarLocationPoster.frame.height + simpleNavBarLocationPoster.frame.minY
            preferredBannerImageHeightUseable = false
            PackageBannerImage.snp.remakeConstraints { (x) in
                x.top.lessThanOrEqualTo(self.container.snp.top)
                x.top.lessThanOrEqualTo(self.view.snp.top)
                x.left.equalTo(self.view.snp.left)
                x.right.equalTo(self.view.snp.right)
                x.height.lessThanOrEqualTo(80)
                x.height.equalTo(80)
                x.bottom.equalTo(self.SimpleNavBar.snp.bottom)
            }
        } else {
            preferredBannerImageHeightUseable = true
            PackageBannerImage.snp.remakeConstraints { (x) in
                x.top.lessThanOrEqualTo(self.container.snp.top)
                x.top.lessThanOrEqualTo(self.view.snp.top)
                x.left.equalTo(self.view.snp.left)
                x.right.equalTo(self.view.snp.right)
                x.height.lessThanOrEqualTo(self.preferredBannerImageHeight)
                x.height.equalTo(self.preferredBannerImageHeight)
                x.bottom.equalTo(self.container.snp.top).offset(self.preferredBannerImageHeight)
            }
        }
        
        scrollViewDidScroll(container)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.scrollViewDidScroll(self.container)
        }
        
        container.contentSize = CGSize(width: 0, height: PackageDepictionContainerPreferredHeight + preferredBannerImageHeight + 200 + SimpleNavBar.frame.maxY)
        
    }
    
    override func viewDidLayoutSubviews() {
        
        if containerSizeRecord != container.frame  {
            PackageDepictionLayoutTokenChecker = UUID().uuidString
            containerSizeRecord = container.frame
        }
        DispatchQueue.main.async {
            self.updateLayoutsIfNeeded()
        }
    }
    
    private func calculateDepictionPreferredWidth() -> CGFloat {
        self.PackageSection.setPackage(with: self.PackageObject)
        var pWidth: CGFloat = 0
        pWidth = self.PackageSection.frame.width
        
        // TODO: Side Panel
        
//        if pWidth - 500 > 300 {
//            PackageDepictionContainerPreferredWidth = 500
//            PackageDepictionContainerPreferredFloatingPanelVisible = true
//            return 500
//        }
        
        PackageDepictionContainerPreferredWidth = pWidth
        PackageDepictionContainerPreferredFloatingPanelVisible = false
        return pWidth
    }
    
}

extension PackageViewController {
    
    private func loadDepictionAndReturnView(whenFinish: @escaping (UIView?) -> ()) {
        
        guard let targetObject = PackageObject, let targetMeta = targetObject.newestMetaData() else {
            whenFinish(nil)
            return
        }
        
        var nativeDepictionLookup: String? = nil
        if let lookup = targetMeta["nativedepiction"] {
            nativeDepictionLookup = lookup
        }
        if let lookup = targetMeta["sileodepiction"] {
            nativeDepictionLookup = lookup
        }
        build0: if let nativeDepiction = nativeDepictionLookup, let url = URL(string: nativeDepiction) {
            let sem = DispatchSemaphore(value: 0)
            var _json: [String : Any]? = nil
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: TimeInterval(ConfigManager.shared.Networking.maxWaitTimeToDownloadRepo))
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config)
            let task = session.dataTask(with: request) { (read, resp, err) in
                defer { sem.signal() }
                if err == nil, let data = read,
                    let jsonDecoded = try? JSONSerialization.jsonObject(with: data) as? [String : Any] {
                    _json = jsonDecoded
                }
            }
            task.resume()
            let _ = sem.wait(timeout: .now() + Double(ConfigManager.shared.Networking.maxWaitTimeToDownloadRepo))
            guard let json = _json else {
                break build0
            }
            let generateViewSem = DispatchSemaphore(value: 0)
            var buildedView: UIView? = nil
            DispatchQueue.global(qos: .background).async { [weak self] in
                guard let ourSelf = self else {
                    generateViewSem.signal()
                    return
                }
                DispatchQueue.main.async {
                    defer { generateViewSem.signal() }
                    ourSelf.PackageThemeColor = UIColor(css: (json["tintColor"] as? String) ?? "") ?? UIColor(named: "G-Theme")!
                    ourSelf.PackageSection.setButtonColor(use: ourSelf.PackageThemeColor)
                    if let urlStr = json["headerImage"] as? String, let urlBanner = URL(string: urlStr) {
                        ourSelf.PackageBannerImage.sd_setImage(with: urlBanner) { [weak self] (_, _, _, _) in
                            self?.PackageDepictionLayoutTokenChecker = UUID().uuidString
                            self?.updateLayoutsIfNeeded()
                        }
                    }
                    if let json = _json, let depictionTargetView = DepictionBaseView.view(dictionary: json, viewController: UIViewController(), tintColor: ourSelf.PackageThemeColor!) {
                        buildedView = depictionTargetView
                    }
                }
            }
            generateViewSem.wait()
            if let returnTarget = buildedView as? DepictionBaseView {
                DispatchQueue.main.async { [weak self] in
                    if self != nil {
                        whenFinish(returnTarget)
                    }
                }
                return
            }
        }
        
        build1: if targetMeta["prefer-native"] == "Yes" {
            
            if let banner = targetMeta["header"], let url = URL(string: banner) {
                PackageBannerImage.sd_setImage(with: url) { [weak self] (_, _, _, _) in
                    self?.PackageDepictionLayoutTokenChecker = UUID().uuidString
                    self?.updateLayoutsIfNeeded()
                }
            }
            
            var targetJsonData: [String : Any] = [:]
            targetJsonData["minVersion"] = "0.1"
            targetJsonData["class"] = "DepictionTabView"
            
            var tabRoot: [String : Any] = ["tabname" : "BuiltInDepiction_Description".localized(), "class" : "DepictionStackView"]
            var tabViewsArray: [[String : Any]] = []
            
            var priviewTitle = [String : Any]()
            priviewTitle["title"] = "BuiltInDepiction_Preview".localized()
            priviewTitle["useBoldText"] = "true"
            priviewTitle["useBottomMargin"] = "false"
            priviewTitle["class"] = "DepictionHeaderView"
            tabViewsArray.append(priviewTitle)
            
            var screenshots = [String : Any]()
            screenshots["itemCornerRadius"] = CGFloat(12)
            screenshots["itemSize"] = "{160, 346}"
            var screenshotArray: [[String : String]] = []
            for item in targetMeta["previews"]?.components(separatedBy: ",") ?? [] {
                var get = item
                get.removeSpaces()
                let scitem = ["accessibilityText" : "Screenshot".localized(), "url" : get]
                screenshotArray.append(scitem)
            }
            screenshots["screenshots"] = screenshotArray
            screenshots["class"] = "DepictionScreenshotsView"
            tabViewsArray.append(screenshots)

            tabViewsArray.append(["class" : "DepictionSeparatorView"])
            
            if let descMarkDown = targetMeta["description"] {
                var newmd: [String : Any] = [:]
                newmd["class"] = "DepictionMarkdownView"
                newmd["useSpacing"] = "true"
                newmd["markdown"] = descMarkDown
                tabViewsArray.append(newmd)
                tabViewsArray.append(["class" : "DepictionSeparatorView"])
            }
            
            if let changeLogStr = targetMeta["changelog"] {
                var priviewTitle1 = [String : Any]()
                priviewTitle1["title"] = "BuiltInDepiction_whatsNew".localized()
                priviewTitle1["useBoldText"] = "true"
                priviewTitle1["useBottomMargin"] = "false"
                priviewTitle1["class"] = "DepictionHeaderView"
                tabViewsArray.append(priviewTitle1)
                var newmd: [String : Any] = [:]
                newmd["class"] = "DepictionMarkdownView"
                newmd["useSpacing"] = "true"
                newmd["markdown"] = changeLogStr
                tabViewsArray.append(newmd)
                tabViewsArray.append(["class" : "DepictionSeparatorView"])
            }
            
            var metaLabel = [String : Any]()
            metaLabel["title"] = "BuiltInDepiction_metaTitle".localized()
            metaLabel["useBoldText"] = "true"
            metaLabel["useBottomMargin"] = "false"
            metaLabel["class"] = "DepictionHeaderView"
            tabViewsArray.append(metaLabel)

            var version = [String : Any]()
            version["title"] = "Version".localized()
            version["text"] = targetMeta["version"]
            version["class"] = "DepictionTableTextView"
            tabViewsArray.append(version)
            
            var tintLabel = [String : Any]()
            tintLabel["text"] = " "
            tintLabel["title"] = "BuiltInDepiction_Converted".localized()
            tintLabel["class"] = "DepictionTableTextView"
            tabViewsArray.append(tintLabel)
            
            tabRoot["views"] = tabViewsArray
            targetJsonData["tabs"] = [tabRoot]
            
            let generateViewSem = DispatchSemaphore(value: 0)
            var buildedView: UIView? = nil
            DispatchQueue.global(qos: .background).async { [weak self] in
                guard let ourSelf = self else {
                    generateViewSem.signal()
                    return
                }
                DispatchQueue.main.async {
                    defer { generateViewSem.signal() }
                    ourSelf.PackageThemeColor = UIColor(named: "G-Theme")!
                    ourSelf.PackageSection.setButtonColor(use: UIColor(named: "G-Theme"))
                    if let depictionTargetView = DepictionBaseView.view(dictionary: targetJsonData, viewController: UIViewController(), tintColor: ourSelf.PackageThemeColor!) {
                        buildedView = depictionTargetView
                    }
                }
            }
            generateViewSem.wait()
            if let returnTarget = buildedView as? DepictionBaseView {
                DispatchQueue.main.async { [weak self] in
                    if self != nil {
                        whenFinish(returnTarget)
                    }
                }
                return
            }
        }
        
        build2: if let web = targetMeta["depiction"], let url = URL(string: web) {
            let sem = DispatchSemaphore(value: 0)
            var getHtml: String? = nil
            let request = Tools.createCydiaRequest(url: url, slient: false, timeout: ConfigManager.shared.Networking.maxWaitTimeToDownloadRepo, messRequest: true)
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config)
            let task = session.dataTask(with: request) { (read, resp, err) in
                defer { sem.signal() }
                if err == nil, let data = read, let str = String(data: data, encoding: .utf8) {
                    getHtml = str
                }
            }
            task.resume()
            _ = sem.wait(timeout: .now() + 10)
            
            if let html = getHtml {
                DispatchQueue.main.async {
                    let webView = WKWebView()
                    webView.scrollView.delegate = self.WebViewDelegate
                    webView.load(html.data, mimeType: "text/html", characterEncodingName: "UTF-8", baseURL: url)
                    self.container.isScrollEnabled = false
                    if self.traitCollection.userInterfaceStyle == .dark {
                        webView.alpha = 0.2
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        whenFinish(webView)
                        if self.traitCollection.userInterfaceStyle == .dark {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                webView.evaluateJavaScript(Tools.darkModeJS, completionHandler: nil)
                                UIView.animate(withDuration: 0.5) {
                                    webView.alpha = 1
                                }
                            }
                        }
                    }
                }
                return
            }
        }
        
        whenFinish(nil)
        Tools.rprint("[]")
        
    }
    
    private func generateDepictionErrorView() -> (UIView, CGFloat) {
        let retView = UIView()
//
//        let errorMDLocation = Bundle.main.path(forResource: "PKGVC+Error", ofType: "md")!
//        let str = try! String(contentsOfFile: errorMDLocation)
//
//        if let down = try? DownView(frame: CGRect(), markdownString: str) {
//            retView.addSubview(down)
//            down.clipsToBounds = false
//            down.snp.makeConstraints { (x) in
//                x.left.equalToSuperview()
//                x.right.equalToSuperview()
//                x.top.equalToSuperview()
//                x.bottom.equalToSuperview()
//            }
//        }
        
        let label = UILabel()
        label.text = "PackageDepictionError".localized()
        label.textColor = UIColor(named: "G-TextTitle")
        label.font = .systemFont(ofSize: 22, weight: .semibold)
        retView.addSubview(label)
        label.snp.makeConstraints { (x) in
            x.center.equalToSuperview()
        }
        
        retView.clipsToBounds = false
        
        return (retView, 280) // ⚠️ -[UIView init] must be used from main thread only
    }
    
}

class PackageViewControllerWebViewScroolViewDelegate: NSObject, UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x > 0 {
            scrollView.contentOffset = CGPoint(x: 0, y: scrollView.contentOffset.y)
        }
    }
    
}
