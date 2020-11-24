//
//  RepoPaymentViewController.swift
//  Protein
//
//  Created by Lakr Aream on 2020/7/18.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit
import SnapKit
import DropDown
import JGProgressHUD

class RepoPaymentViewController: UIViewControllerWithCustomizedNavBar {
    
    private let dataSource: [(String, String)] = RepoPaymentManager.shared.reportPaidReposWithItsEndpoint()
    private let heightPerRow = 75
    
    private let tableView = UITableView()
    private let scrollView = UIScrollView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        defer {
            setupNavigationBar()
            tableView.snp.makeConstraints { (x) in
                x.left.equalTo(self.view.snp.left)
                x.right.equalTo(self.view.snp.right)
                x.top.equalTo(self.scrollView.snp.top)
                x.height.equalTo(dataSource.count * heightPerRow + 380)
            }
            scrollView.snp.makeConstraints { (x) in
                x.left.equalToSuperview()
                x.right.equalToSuperview()
                x.bottom.equalToSuperview()
                x.top.equalTo(self.SimpleNavBar.snp.bottom)
            }
            scrollView.contentSize = CGSize(width: 0, height: dataSource.count * heightPerRow + 380)
        }
        
        view.backgroundColor = UIColor(named: "G-ViewController-Background")
        let size = CGSize(width: 600, height: 600)
        preferredContentSize = size
        hideKeyboardWhenTappedAround()
        view.insetsLayoutMarginsFromSafeArea = false
        
        view.addSubview(scrollView)
        
        tableView.register(RepoPaymentCell.self, forCellReuseIdentifier: "wiki.qaq.Protein.RepoPaymentCell")
        tableView.separatorColor = .clear
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        scrollView.addSubview(tableView)
        
    }
    
}

extension RepoPaymentViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 0
        }
        if section == 2 {
            return 1
        }
        let count = dataSource.count
        return count < 1 ? 1 : count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "wiki.qaq.Protein.RepoPaymentCell", for: indexPath) as? RepoPaymentCell else {
            return RepoPaymentCell()
        }
        
        if indexPath.section == 2 {
            cell.setupDescription(withString: "Payment_GetHelp".localized())
            return cell
        }
        
        if dataSource.count < 1 {
            cell.setupDescription(withString: "NoRepoSupportsPayment".localized())
        } else {
            let payload = dataSource[indexPath.row]
            cell.setData(repoUrl: payload.0, paymentEndPoint: payload.1)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 2 {
            return 50
        }
        return CGFloat(heightPerRow)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath), indexPath.section == 2 {
            cell.puddingAnimate()
            guard let url = URL(string: DEFINE.SOURCE_CODE_LOCATION +  "/issues") else { return }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 80
        }
        return 60
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case 0:
            let container = UIView()
            container.backgroundColor = self.view.backgroundColor
            let label = UILabel()
            label.font = .systemFont(ofSize: 24, weight: .bold)
            label.text = "Account".localized()
            container.addSubview(label)
            label.snp.makeConstraints { (x) in
                x.left.equalToSuperview().offset(28)
                x.height.equalTo(60)
                x.bottom.equalToSuperview().offset(-10)
                x.right.equalToSuperview()
            }
            return container
        case 1:
            let container = UIView()
            container.backgroundColor = self.view.backgroundColor
            let label = UILabel()
            label.font = .systemFont(ofSize: 18, weight: .semibold)
            label.text = "RepoLoginTitle".localized()
            container.addSubview(label)
            label.snp.makeConstraints { (x) in
                x.left.equalToSuperview().offset(28)
                x.height.equalTo(60)
                x.centerY.equalToSuperview()
                x.right.equalToSuperview()
            }
            return container
        case 2:
            let container = UIView()
            container.backgroundColor = self.view.backgroundColor
            let label = UILabel()
            label.font = .systemFont(ofSize: 18, weight: .semibold)
            label.text = "PackageDiagnosis_Help".localized()
            container.addSubview(label)
            label.snp.makeConstraints { (x) in
                x.left.equalToSuperview().offset(28)
                x.height.equalTo(60)
                x.centerY.equalToSuperview()
                x.right.equalToSuperview()
            }
            return container
        default:
            return UIView()
        }
    }
    
}

fileprivate class RepoPaymentCell: UITableViewCell {
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private let container = UIView()
    private let icon = UIImageView()
    private let label = UILabel()
    private let desc = UILabel()
    private let textView = UITextView()
    private let active = UIActivityIndicatorView()
    
    private let button = UIButton()
    
    private var repoUrlAsKey: String? = nil
    private var endPoint: String? = nil
    private var buttonSignInText = ""
    
    private var dropDownAnchor = UIView()
    
    required override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let fixSnap = UIView()
        addSubview(fixSnap)
        fixSnap.snp.makeConstraints { (x) in
            x.edges.equalToSuperview()
        }
        contentView.addSubview(container)
        container.addSubview(icon)
        container.addSubview(label)
        container.addSubview(desc)
        container.addSubview(textView)
        container.addSubview(button)
        container.addSubview(dropDownAnchor)
        
        backgroundColor = .clear
        
        selectedBackgroundView = UIView()

        container.snp.makeConstraints { (x) in
            x.edges.equalTo(fixSnap)
        }
        icon.clipsToBounds = true
        icon.layer.cornerRadius = 12
        icon.contentMode = .scaleAspectFill
        icon.snp.makeConstraints { (x) in
            x.centerY.equalToSuperview()
            x.left.equalTo(self.container.snp.left).offset(12)
            x.width.equalTo(35)
            x.height.equalTo(35)
        }
        label.textColor = UIColor(named: "RepoTableViewCell.Text")
        label.font = .monospacedSystemFont(ofSize: 18, weight: .semibold)
        label.snp.makeConstraints { (x) in
            x.left.equalTo(icon.snp.right).offset(12)
            x.right.equalTo(button.snp.left).offset(-8)
            x.bottom.equalTo(icon.snp.centerY).offset(4)
        }
        desc.numberOfLines = 0
        desc.lineBreakMode = .byWordWrapping
        desc.textColor = UIColor(named: "RepoTableViewCell.Text")
        desc.font = .systemFont(ofSize: 12)
        desc.snp.makeConstraints { (x) in
            x.left.equalTo(icon.snp.right).offset(12)
            x.right.equalTo(self.button.snp.left).offset(-12)
            x.top.equalTo(icon.snp.centerY).offset(6)
        }
        textView.isUserInteractionEnabled = false
        textView.font = .systemFont(ofSize: 16)
        textView.isEditable = false
        textView.backgroundColor = .clear
        textView.snp.remakeConstraints { (x) in
            x.left.equalToSuperview().offset(28)
            x.right.equalToSuperview().offset(-28)
            x.centerY.equalToSuperview()
            x.height.equalTo(30)
        }
        
        button.alpha = 0
        button.isHidden = true
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        button.setTitleColor(UIColor(named: "G-TextSubTitle"), for: .normal)
        button.setTitleColor(.gray, for: .highlighted)
        button.layer.cornerRadius = 15
        button.addTarget(self, action: #selector(buttonCall), for: .touchUpInside)
        button.snp.makeConstraints { (x) in
            x.centerY.equalToSuperview()
            x.right.equalToSuperview().offset(-12)
            x.width.equalTo(60)
            x.height.equalTo(30)
        }
        
        dropDownAnchor.snp.makeConstraints { (x) in
            x.right.equalToSuperview().offset(-12)
            x.width.equalTo(233)
            x.height.equalTo(2)
            x.top.equalTo(self.button.snp.bottom).offset(8)
        }
        
    }
    
    func setData(repoUrl: String, paymentEndPoint: String) {
        label.text = repoUrl
        if label.text?.lowercased().hasPrefix("http://") ?? false {
            label.text?.removeFirst("http://".count)
        }
        if label.text?.lowercased().hasPrefix("https://") ?? false {
            label.text?.removeFirst("https://".count)
        }
        desc.text = paymentEndPoint
        active.startAnimating()
        container.addSubview(active)
        active.snp.makeConstraints { (x) in
            x.center.equalTo(self.icon)
        }
        bringSubviewToFront(contentView)
        contentView.bringSubviewToFront(container)
        container.bringSubviewToFront(button)
        repoUrlAsKey = repoUrl
        endPoint = paymentEndPoint
        DispatchQueue.global(qos: .background).async {
            if let url = URL(string: paymentEndPoint)?.appendingPathComponent("info") {
                let request = URLRequest(url: url,
                                         cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                         timeoutInterval: TimeInterval(ConfigManager.shared.Networking.maxWaitTimeToDownloadRepo))
                let config = URLSessionConfiguration.default
                let session = URLSession(configuration: config)
                let sem = DispatchSemaphore(value: 0)
                var json: [String : Any]? = nil
                let task = session.dataTask(with: request) { (data, _, err) in
                    defer { sem.signal() }
                    if err == nil, let data = data, let j = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String : Any]) {
                        json = j
                    }
                }
                task.resume()
                let _ = sem.wait(timeout: .now() + Double(ConfigManager.shared.Networking.maxWaitTimeToDownloadRepo))
                /*
                 {
                    "name": "Chariz",
                    "icon": "https://my.chariz.io/Icon.png",
                    "description": "Chariz Pay",
                    "authentication_banner": {
                       "message": "Sample sign in prompt text",
                       "button": "Sign in"
                    }
                 }
                 */
                if let json = json {
                    DispatchQueue.main.async {
                        self.active.stopAnimating()
                        if let name = json["name"] as? String {
                            self.label.text = name
                        }
                        if let raw = json["icon"] as? String, let iconUrl = URL(string: raw) {
                            self.icon.sd_setImage(with: iconUrl) { (img, _, _, _) in
                            }
                        }
                        if let payload = json["authentication_banner"] as? [String : String] {
                            if let msg = payload["message"] {
                                self.desc.text = msg
                            }
                            if let signInText = payload["button"] {
                                self.buttonSignInText = signInText
                                self.button.setTitle(self.buttonSignInText, for: .normal)
                                self.button.isHidden = false
                                UIView.animate(withDuration: 0.6) {
                                    self.button.alpha = 1
                                }
                                self.loginStatusUpdated()
                                return
                            }
                        }
                        self.buttonSignInText = "SignIn".localized()
                        self.button.setTitle(self.buttonSignInText, for: .normal)
                        self.button.isHidden = false
                        UIView.animate(withDuration: 0.6) {
                            self.button.alpha = 1
                        }
                        self.loginStatusUpdated()
                        return
                    }
                } else {
                    DispatchQueue.main.async {
                        self.buttonSignInText = "SignIn".localized()
                        self.button.setTitle(self.buttonSignInText, for: .normal)
                        self.button.isHidden = false
                        UIView.animate(withDuration: 0.6) {
                            self.button.alpha = 1
                        }
                        self.loginStatusUpdated()
                        self.active.stopAnimating()
                    }
                    return
                }
            }
        }
    }
    
    func setupDescription(withString: String) {
        textView.text = withString
    }
    
    // no more needed, casue we dont actually have a dequeueReusableCell
    
    @objc
    func buttonCall() {
        if RepoPaymentManager.shared.obtainUserSignInfomation(forRepoUrlAsKey: repoUrlAsKey) == nil {
            self.button.puddingAnimate()
            if !ConfigManager.shared.CydiaConfig.mess && ConfigManager.shared.obtainRealDeviceID() != nil,
                let url = repoUrlAsKey, let window = self.window {
                RepoPaymentManager.shared.startUserAuthenticate(inWindow: window, inAlertContainer: self.obtainParentViewController, andRepoUrlAsKey: url, withEndpoint: endPoint) {
                    self.loginStatusUpdated()
                }
            } else {
                let alert = UIAlertController(title: "Error".localized(), message: "RepoSignInBlockedHint".localized(), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
                self.obtainParentViewController?.present(alert, animated: true, completion: nil)
            }
        } else {
            let dropDown = DropDown()
            let source = ["SignOut", "ListPurchased", "Cancel"]
            dropDown.dataSource = source.map({ (str) -> String in
                return "   " + str.localized()
            })
            dropDown.selectionAction = { (index, _) in
                let str = source[index]
                switch str {
                case "SignOut":
                    RepoPaymentManager.shared.deleteSignInRecord(forRepoUrlAsKey: self.repoUrlAsKey)
                    self.loginStatusUpdated()
                case "ListPurchased":
                    let hud: JGProgressHUD
                    if self.traitCollection.userInterfaceStyle == .dark {
                        hud = .init(style: .dark)
                    } else {
                        hud = .init(style: .light)
                    }
                    hud.show(in: self.obtainParentViewController?.view ?? UIView())
                    RepoPaymentManager.shared.obtainUserInfo(withUrlAsKey: self.repoUrlAsKey) { (userInfo) in
                        var lookup = [PackageStruct]()
                        for repo in RepoManager.shared.repos where repo.url.urlString == self.repoUrlAsKey {
                            for item in userInfo?.item ?? [] {
                                if let pkg = repo.metaPackage[item] {
                                    lookup.append(pkg)
                                }
                            }
                        }
                        DispatchQueue.main.async {
                            hud.dismiss()
                            if lookup.count < 1 {
                                let alert = UIAlertController(title: "Error".localized(),
                                                              message: "NoPurchased".localized(), preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
                                self.obtainParentViewController?.present(alert, animated: true, completion: nil)
                            } else {
                                let pop = PackageCollectionViewController()
                                pop.setPackages(withSortedArray: lookup)
                                pop.modalPresentationStyle = .formSheet
                                pop.modalTransitionStyle = .coverVertical
                                pop.nothingInfo = ("NoPurchased".localized(), "⚠️", "".localized())
                                self.obtainParentViewController?.present(pop, animated: true, completion: nil)
                            }
                        }
                    }
                default:
                    break
                }
            }
            dropDown.anchorView = dropDownAnchor
            dropDown.show(onTopOf: self.window)
            
        }
    }
    
    func loginStatusUpdated() {
        if (RepoPaymentManager.shared.obtainUserSignInfomation(forRepoUrlAsKey: self.repoUrlAsKey) == nil) {
            let title = self.buttonSignInText
            let font = self.button.titleLabel?.font ?? UIFont.systemFont(ofSize: 16, weight: .semibold)
            self.button.setTitle(title, for: .normal)
            self.button.snp.updateConstraints { (x) in
                x.width.equalTo(title.sizeOfString(usingFont: font).width + 24)
            }
        } else {
            let title = "Option".localized()
            let font = self.button.titleLabel?.font ?? UIFont.systemFont(ofSize: 16, weight: .semibold)
            self.button.setTitle(title, for: .normal)
            self.button.snp.updateConstraints { (x) in
                x.width.equalTo(title.sizeOfString(usingFont: font).width + 24)
            }
        }
    }
    
}
