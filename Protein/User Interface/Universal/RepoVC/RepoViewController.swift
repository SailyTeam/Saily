//
//  RepoViewController.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/19.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit
import JGProgressHUD

class RepoViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    private var repo: RepoStruct?
    
    private let container = UIScrollView()
    private let headIcon = UIImageView()
    private let lbName = UILabel()
    private let lbUrl = UILabel()
    private let sep1 = UIView()
    private let sep2 = UIView()
    private let sep3 = UIView()
    private let desTxv = UITextView()
    private let featuredJsonLoadFoo = UIActivityIndicatorView()
    private let featuredPlaceHolder = UIScrollView()
    private let iconQR = UIImageView()
    private let lbEnd = UILabel()
    
    private var sectionDetailsSortedKeys = [String]()
    private var sectionDetails = [String : [PackageStruct]]()
    private var collectionView: UICollectionView? = nil
    
    init(withRepo: RepoStruct) {
        super.init(nibName: nil, bundle: nil)
        repo = withRepo
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("[ARC] RepoViewController has been deinited")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        preferredContentSize = CGSize(width: 700, height: 555)
        
        view.backgroundColor = UIColor(named: "G-ViewController-Background")
        
        guard let repo = repo else {
            fatalError("RepoViewController requires init(withRepo: RepoStruct)")
        }
        
        Tools.rprint("-------")
        Tools.rprint("     * " + repo.obtainPossibleName())
        Tools.rprint("     * " + String(repo.metaPackage.count) + " package(s) available")
        Tools.rprint(repo.metaRelease.description)
        Tools.rprint("-------")
        
        sectionDetails = repo.obtainSectionDetails()
        for item in sectionDetails.sorted(by: { (a, b) -> Bool in
            return a.key.lowercased() < b.key.lowercased() ? true : false
        }) {
            sectionDetailsSortedKeys.append(item.key)
        }
        
        view.addSubview(container)
        container.clipsToBounds = false
        container.showsVerticalScrollIndicator = false
        container.showsHorizontalScrollIndicator = false
        container.alwaysBounceVertical = true
        container.snp.makeConstraints { (x) in
            x.left.equalToSuperview()
            x.right.equalToSuperview()
            x.bottom.equalToSuperview()
            x.top.equalToSuperview().offset(23)
        }
        
        var anchor = UIView()
        let safeAnchor = anchor
        container.addSubview(anchor)
        anchor.snp.makeConstraints { (x) in
            x.left.equalTo(self.view.snp.left).offset(28)
            x.right.equalTo(self.view.snp.right).offset(-28)
            x.height.equalTo(20)
            x.top.equalTo(container.snp.top)
        }
        
        headIcon.sd_setImage(with: URL(string: repo.url.urlString + "/CydiaIcon@3x.png"),
                             placeholderImage: UIImage(data: repo.icon),
                             options: .highPriority) { (img, err, _, _) in
            if img == nil /*|| err != nil*/ {
                self.headIcon.sd_setImage(with: URL(string: repo.obtainIconLink()),
                                     placeholderImage: UIImage(data: repo.icon),
                                     options: .highPriority, context: nil)
            }
        }
        
        headIcon.layer.cornerRadius = 14
        headIcon.clipsToBounds = true
        headIcon.contentMode = .scaleAspectFill
        container.addSubview(headIcon)
        headIcon.snp.makeConstraints { (x) in
            x.left.equalTo(safeAnchor.snp.left)
            x.height.equalTo(80)
            x.width.equalTo(80)
            x.top.equalTo(anchor.snp.top).offset(28)
        }
        
        container.addSubview(lbName)
        container.addSubview(lbUrl)
        lbName.text = repo.obtainPossibleName()
        lbName.textColor = UIColor(named: "G-TextTitle")
        lbName.font = UIFont.roundedFont(ofSize: 22, weight: .semibold)
        
        lbName.textAlignment = .left
        lbName.alpha = 0.888
        lbName.snp.makeConstraints { (x) in
            x.left.equalTo(headIcon.snp.right).offset(18)
            x.bottom.equalTo(lbUrl.snp.top).offset(-4)
            x.right.equalTo(safeAnchor.snp.right)
        }
        lbUrl.text = repo.url.urlString
        lbUrl.textColor = UIColor(named: "G-TextSubTitle")
        lbUrl.font = .systemFont(ofSize: 16)
        lbUrl.textAlignment = .left
        lbUrl.alpha = 0.888
        lbUrl.snp.makeConstraints { (x) in
            x.left.equalTo(headIcon.snp.right).offset(18)
            x.bottom.equalTo(headIcon.snp.bottom)
            x.right.equalTo(safeAnchor.snp.right)
            x.height.equalTo(18)
        }
        
        anchor = headIcon
        
        sep1.backgroundColor = .gray
        sep1.alpha = 0.233
        container.addSubview(sep1)
        sep1.snp.makeConstraints { (x) in
            x.left.equalTo(safeAnchor.snp.left)
            x.right.equalTo(safeAnchor.snp.right)
            x.height.equalTo(1)
            x.top.equalTo(anchor.snp.bottom).offset(18)
        }
        
        anchor = sep1
        desTxv.text = repo.obtainDescription()
        desTxv.isUserInteractionEnabled = false
        desTxv.textColor = UIColor(named: "G-TextSubTitle")
        desTxv.backgroundColor = .clear
        desTxv.font = .systemFont(ofSize: 14, weight: .medium)
        container.addSubview(desTxv)
        desTxv.snp.makeConstraints { (x) in
            x.left.equalTo(safeAnchor.snp.left)
            x.right.equalTo(safeAnchor.snp.right)
            x.height.equalTo(28)
            x.top.equalTo(anchor.snp.bottom).offset(8)
        }
        desTxv.alpha = 0
        
        anchor = desTxv
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UIView.animate(withDuration: 0.5) {
                self.desTxv.alpha = 1
            }
            self.layoutTextViews()
        }
        
        sep2.backgroundColor = .gray
        sep2.alpha = 0.233
        container.addSubview(sep2)
        sep2.snp.makeConstraints { (x) in
            x.left.equalTo(safeAnchor.snp.left)
            x.right.equalTo(safeAnchor.snp.right)
            x.height.equalTo(1)
            x.top.equalTo(anchor.snp.bottom).offset(10)
        }
        
        featuredPlaceHolder.clipsToBounds = true
        featuredPlaceHolder.alwaysBounceHorizontal = true
        featuredPlaceHolder.showsVerticalScrollIndicator = false
        featuredPlaceHolder.showsHorizontalScrollIndicator = false
        featuredPlaceHolder.decelerationRate = .fast
        container.addSubview(featuredPlaceHolder)
        featuredPlaceHolder.snp.makeConstraints { (x) in
            x.left.equalTo(safeAnchor.snp.left)
            x.right.equalTo(safeAnchor.snp.right)
            x.height.equalTo(100)
            x.top.equalTo(anchor.snp.bottom).offset(10)
        }
        
        featuredJsonLoadFoo.startAnimating()
        featuredPlaceHolder.addSubview(featuredJsonLoadFoo)
        featuredJsonLoadFoo.snp.makeConstraints { (x) in
            x.center.equalToSuperview()
        }
        
        anchor = featuredPlaceHolder
        
        let flowLayout = AlignedCollectionViewFlowLayout(horizontalAlignment: .left, verticalAlignment: .center)
        collectionView = UICollectionView(frame: CGRect(), collectionViewLayout: flowLayout)
        collectionView?.register(SimpleLabelSectionCell.self, forCellWithReuseIdentifier: "wiki.qaq.Protein.SimpleLabelSectionCell")
        
        container.addSubview(collectionView!)
        collectionView!.delegate = self
        collectionView!.dataSource = self
        collectionView?.backgroundColor = nil
        collectionView!.snp.makeConstraints { (x) in
        x.top.equalTo(anchor.snp.bottom).offset(10)
            x.left.equalTo(safeAnchor.snp.left)
            x.right.equalTo(safeAnchor.snp.right)
            x.height.equalTo(0)
        }
        anchor = collectionView!
        
        sep3.backgroundColor = .gray
        sep3.alpha = 0.233
        container.addSubview(sep3)
        sep3.snp.makeConstraints { (x) in
            x.left.equalTo(safeAnchor.snp.left)
            x.right.equalTo(safeAnchor.snp.right)
            x.height.equalTo(1)
            x.top.equalTo(anchor.snp.bottom).offset(10)
        }
        anchor = sep3
        
        if let qrimg = repo.url.urlString.getQRCodeImage() {
            iconQR.image = qrimg
            container.addSubview(iconQR)
            iconQR.snp.makeConstraints { (x) in
                x.height.equalTo(60)
                x.width.equalTo(60)
                x.right.equalTo(anchor.snp.right)
                x.top.equalTo(anchor).offset(15)
            }
            anchor = iconQR
        }
        
        let date = Date(timeIntervalSince1970: repo.lastUpdatePackage)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let result = formatter.string(from: date)
        lbEnd.text = "RepoViewController_RepoLastUpdated".localized() + result
        lbEnd.textAlignment = .right
        lbEnd.textColor = UIColor(named: "G-TextSubTitle")
        lbEnd.font = .systemFont(ofSize: 10, weight: .semibold)
        container.addSubview(lbEnd)
        lbEnd.snp.makeConstraints { (x) in
            x.right.equalTo(safeAnchor.snp.right)
            x.top.equalTo(anchor.snp.bottom).offset(10)
        }
    
        DispatchQueue.global(qos: .background).async {
            self.loadFeaturedIfNeeded()
        }
        
        let imgv = UIImageView()
        let closeButton = UIButton()
        imgv.image = UIImage(named: "LicenseViewController.Close")
        imgv.contentMode = .scaleAspectFit
        view.addSubview(imgv)
        view.addSubview(closeButton)
        imgv.snp.makeConstraints { (x) in
            x.top.equalTo(self.view.snp.top).offset(40)
            x.right.equalTo(safeAnchor.snp.right)
            x.width.equalTo(20)
            x.height.equalTo(20)
        }
        closeButton.snp.makeConstraints { (x) in
            x.center.equalTo(imgv.snp.center)
            x.width.equalTo(50)
            x.height.equalTo(50)
        }
        closeButton.addTarget(self, action: #selector(closeViewController(sender:)), for: .touchUpInside)
    
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.layoutCollectionView()
        }
        
    }
    
    @objc private
    func closeViewController(sender: UIView) {
        sender.puddingAnimate()
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLayoutSubviews() {
        layoutTextViews()
        layoutCollectionView()
    }
    
    func layoutTextViews() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
            self.desTxv.sizeToFit()
            let f1 = self.desTxv.contentSize.height
            self.desTxv.snp.updateConstraints { (x) in
                x.height.equalTo(f1)
            }
            self.desTxv.layoutIfNeeded()
        }) { (_) in
            self.container.contentSize.height = self.lbEnd.frame.maxY + 50
        }

    }
    
    func loadFeaturedIfNeeded() {
        
        var json: [String : Any]?
        
        let masterSem = DispatchSemaphore(value: 0)
        do {
            DispatchQueue.global(qos: .background).async {
                let sem = DispatchSemaphore(value: 0)
                if let featured = URL(string: self.repo!.url.urlString + "/featured.json") {
                    let request = Tools.createCydiaRequest(url: featured, slient: false,
                                                           timeout: ConfigManager.shared.Networking.maxWaitTimeToDownloadRepo,
                                                           messRequest: ConfigManager.shared.CydiaConfig.mess)
                    let config = URLSessionConfiguration.default
                    let session = URLSession(configuration: config)
                    let task = session.dataTask(with: request) { (data, resp, err) in
                        if let data = data, err == nil {
                            if let j = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String : Any]  {
                                json = j
                            }
                        }
                        sem.signal()
                    }
                    task.resume()
                    sem.wait()
                }
                masterSem.signal()
            }
        }
        do {
            DispatchQueue.global(qos: .background).async {
                let sem2 = DispatchSemaphore(value: 0)
                // Sileo Capable Layout
                if json == nil,
                    let featured = URL(string: self.repo!.url.urlString + "/sileo-featured.json") {
                    let request = Tools.createCydiaRequest(url: featured, slient: false,
                                                           timeout: ConfigManager.shared.Networking.maxWaitTimeToDownloadRepo,
                                                           messRequest: ConfigManager.shared.CydiaConfig.mess)
                    let config = URLSessionConfiguration.default
                    let session = URLSession(configuration: config)
                    let task = session.dataTask(with: request) { (data, resp, err) in
                        if let data = data, err == nil {
                            if let j = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String : Any] {
                                json = j
                            }
                        }
                        sem2.signal()
                    }
                    task.resume()
                    sem2.wait()
                }
                masterSem.signal()
            }
        }
        
        let _ = masterSem.wait(timeout: .now() + Double(ConfigManager.shared.Networking.maxWaitTimeToDownloadRepo))
        
        if let json = json,
            json["class"] as? String == "FeaturedBannersView",
            let banners = json["banners"] as? [[String : Any]] {
            
            DispatchQueue.main.async {
                
                self.featuredPlaceHolder.clipsToBounds = false
                
                let itemSize: CGSize = NSCoder.cgSize(for: json["itemSize"] as? String ?? "")
                let radius = json["itemCornerRadius"] as? Double ?? 12

                var anchor = UIView()
                self.featuredPlaceHolder.addSubview(anchor)
                anchor.snp.makeConstraints { (x) in
                    x.centerY.equalToSuperview()
                    x.left.equalToSuperview().offset(-1 - 18)
                    x.height.equalTo(itemSize.height)
                    x.width.equalTo(1)
                }
                var count = 0
                inner: for banner in banners {
                    guard let url = URL(string: banner["url"] as? String ?? "") else {
                        continue inner
                    }
                    guard let package = banner["package"] as? String else {
                        continue inner
                    }
                    guard let title = banner["title"] as? String else {
                        continue inner
                    }
                    let builder = FeaturedButton(withImageUrl: url,
                                                 andPackageIdentity: package,
                                                 andTitle: title,
                                                 andRadius: CGFloat(radius),
                                                 withAPackage: self.repo!.metaPackage[package.lowercased()])
                    self.featuredPlaceHolder.addSubview(builder)
                    builder.snp.makeConstraints { (x) in
                        x.top.equalTo(anchor.snp.top)
                        x.left.equalTo(anchor.snp.right).offset(18)
                        x.bottom.equalTo(anchor.snp.bottom)
                        x.width.equalTo(itemSize.width)
                    }
                    anchor = builder
                    count += 1
                }
                
                self.featuredPlaceHolder.contentSize = CGSize(width: count * (Int(itemSize.width) + 18) + 40, height: 0)
                
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
                    self.featuredJsonLoadFoo.stopAnimating()
                    self.featuredPlaceHolder.snp.updateConstraints { (x) in
                        x.height.equalTo(itemSize.height + 40)
                    }
                    self.featuredPlaceHolder.layoutIfNeeded()
                }) { (_) in
                    self.featuredJsonLoadFoo.isHidden = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        self.container.contentSize.height = self.lbEnd.frame.maxY + 50
                    }
                }
                
            }
            
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
                    self.sep2.alpha = 0
                    self.featuredJsonLoadFoo.stopAnimating()
                    self.featuredPlaceHolder.snp.updateConstraints { (x) in
                        x.height.equalTo(0)
                    }
                    self.featuredPlaceHolder.layoutIfNeeded()
                }) { (_) in
                    self.sep2.isHidden = true
                    self.featuredPlaceHolder.isHidden = true
                }
            }
        }
        
    }
    
    func layoutCollectionView() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
            self.collectionView?.snp.updateConstraints({ (x) in
                x.height.equalTo(self.collectionView?.collectionViewLayout.collectionViewContentSize ?? 0)
            })
            self.collectionView?.layoutIfNeeded()
        }, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sectionDetailsSortedKeys.count + 1
    }
    
    func textForCellAt(row: Int) -> String {
        if row >= sectionDetailsSortedKeys.count {
            return "All (" + String(repo?.metaPackage.count ?? 0) + ")"
        }
        var currentString = sectionDetailsSortedKeys[row]
        if let counted = sectionDetails[sectionDetailsSortedKeys[row]]?.count {
            currentString += " (" + String(counted) + ")"
        }
        return currentString
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "wiki.qaq.Protein.SimpleLabelSectionCell", for: indexPath) as! SimpleLabelSectionCell
        cell.setText(textForCellAt(row: indexPath.row))
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let currentString = textForCellAt(row: indexPath.row)
        let font = SimpleLabelSectionCell.sharedFont
        let size = currentString.sizeOfString(usingFont: font)
        return CGSize(width: size.width + 30, height: 26)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var packageList = [PackageStruct]()
        if indexPath.row >= sectionDetailsSortedKeys.count {
            if let list = repo?.metaPackage {
                for item in list.values {
                    packageList.append(item)
                }
            }
        } else {
            if let list = sectionDetails[sectionDetailsSortedKeys[indexPath.row]] {
                for item in list {
                    packageList.append(item)
                }
            }
        }
        
        if packageList.count == 1 {
            let pop = PackageViewController()
            pop.modalPresentationStyle = .formSheet;
            pop.modalTransitionStyle = .coverVertical;
            pop.PackageObject = packageList.first!
            pop.preferredContentSize = self.preferredContentSize
            self.present(pop, animated: true) { }
            return
        }
        
        let pop = PackageCollectionViewController()
        pop.modalPresentationStyle = .formSheet;
        pop.modalTransitionStyle = .coverVertical;
        pop.setPackages(withSortedArray: packageList)
        var hud: JGProgressHUD?
        if self.traitCollection.userInterfaceStyle == .dark {
            hud = .init(style: .dark)
        } else {
            hud = .init(style: .light)
        }
        hud?.textLabel.text = "WaitingForDataBase".localized()
        hud?.show(in: view)
        DispatchQueue.main.async {
            self.present(pop, animated: true) {
                hud?.dismiss()
            }
        }
        
    }
    
}

fileprivate class FeaturedButton: UIView {
    
    private let image = UIImageView()
    private let gray = UIView()
    private let label = UILabel()
    private let button = UIButton()
    private let identity: String
    private let package: PackageStruct?
    
    required init(withImageUrl: URL,
                  andPackageIdentity: String,
                  andTitle: String,
                  andRadius: CGFloat,
                  withAPackage: PackageStruct?) {
        
        identity = andPackageIdentity
        package = withAPackage
        
        super.init(frame: CGRect())
        
        addSubview(gray)
        addSubview(image)
        addSubview(label)
        addSubview(button)
        
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.layer.cornerRadius = andRadius
        image.snp.makeConstraints { (x) in
            x.edges.equalToSuperview()
        }
        image.sd_setImage(with: withImageUrl) { (_, _, _, _) in
        }
        
        gray.alpha = 0.5
        gray.backgroundColor = .gray
        gray.layer.cornerRadius = andRadius
        gray.snp.makeConstraints { (x) in
            x.edges.equalTo(image)
        }
        
        label.alpha = 0
        label.text = andTitle
        label.textColor = .gray
        label.alpha = 0.5
        label.font = .systemFont(ofSize: 10, weight: .bold)
        label.textAlignment = .left
        label.snp.makeConstraints { (x) in
            x.centerX.equalToSuperview()
            x.top.equalTo(self.snp.bottom).offset(4)
        }
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.5) {
                self.label.alpha = 1
            }
        }
        
        button.snp.makeConstraints { (x) in
            x.edges.equalToSuperview()
        }
        button.addTarget(self, action: #selector(loadPackage), for: .touchUpInside)
        
    }
    
    @objc private
    func loadPackage() {
        self.puddingAnimate()
        
        if let pkg = package {
            let target = PackageViewController()
            target.PackageObject = pkg
            target.modalPresentationStyle = .formSheet;
            target.modalTransitionStyle = .coverVertical;
            if let vc = self.obtainParentViewController {
                vc.present(target, animated: true, completion: nil)
            } else if let vc = self.window?.rootViewController {
                vc.present(target, animated: true, completion: nil)
            }
        } else {
            let alert = UIAlertController(title: "⚠️", message: "RepoViewController_RepoFeaturedPackageNotFoundHint".localized(),
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
            if let vc = self.obtainParentViewController {
                vc.present(alert, animated: true, completion: nil)
            } else if let vc = self.window?.rootViewController {
                vc.present(alert, animated: true, completion: nil)
            }
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

fileprivate class SimpleLabelSectionCell: UICollectionViewCell {
    
    private var label = UILabel()
    private var container = UIView()
    
    static let sharedFont: UIFont = .systemFont(ofSize: 14, weight: .semibold)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(container)
        container.addSubview(label)
        label.snp.makeConstraints { (x) in
            x.edges.equalTo(self.container)
        }
        container.snp.makeConstraints { (x) in
            x.left.equalToSuperview()
            x.right.equalToSuperview().offset(-4)
            x.top.equalToSuperview()
            x.bottom.equalToSuperview().offset(-2)
        }
//        var color = UIColor.randomAsPudding
        var color = UIColor.gray
        color = color.withAlphaComponent(0.1)
        container.backgroundColor = color
        container.layer.cornerRadius = 4
        
        label.font = SimpleLabelSectionCell.sharedFont
        label.textColor = UIColor(named: "G-TextTitle")
        label.textAlignment = .center
        label.lineBreakMode = .byCharWrapping
        
    }
    
    func setText(_ str: String) {
        label.text = str
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
