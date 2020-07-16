//
//  PackageCollectionView.swift
//  Protein
//
//  Created by Lakr Aream on 2020/5/9.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit
import SDWebImage
import JGProgressHUD

class PackageCollectionView: UIView {
    
    override var bounds: CGRect {
        didSet {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.updateContexts()
            }
        }
    }
    
    let CellID = "wiki.qaq.Protein.PackageCollectionView.Cell." + UUID().uuidString
    
    private let lineLimit: Int
    
    var suggestedHeight: CGFloat {
        get {
            let hi = self.collectionViewCalculatesCellSize()
            var count = hi.2
            if count < 1 { count = 1 }
            let itemEachLine = hi.1
            let totalLine = count / itemEachLine + (count % itemEachLine != 0 ? 1 : 0)
            let cellHeight = hi.0.height
            let height = totalLine * (Int(cellHeight) + 10)
            return CGFloat(height)
        }
    }
    var shouldHide: Bool {
        get {
            if safePackagePool.count < 1 {
                return true
            } else {
                return false
            }
        }
    }
    
    var whenPushDetailsWithPackages: () -> [PackageStruct]? = { return nil }
    var whenPushDetailsWithAnotherBlock: () -> () = { }
    var whenUpdateCollectionViewDatas: () -> [PackageStruct]? = { return nil }
    var whenSetupCells: (PackagePreviewCoCell) -> () = { (_) in }
    var notificationUpdateName: Notification.Name
    var notificationLayoutName: Notification.Name
    
    var emptyInfoElements: (String, String, String)?
    
    private var safePackagePool = [PackageStruct]()
    
    var collectionView: UICollectionView
    
    let title = UILabel()
    let bottomAnchorView = UIView()
    let nextButtonImage = UIImageView(image: UIImage(named: "PackageCollectionView.Next"))
    let nextButtonCore = UIButton()
    
    init(titleText: String = "", maxLineLimit: Int = 4, shouldShowButton: Bool = true,
         notifyUpdateName: Notification.Name,
         notifyLayoutName: Notification.Name, withInitPackagePool: [PackageStruct]? = nil) {
        
        lineLimit = maxLineLimit
        notificationUpdateName = notifyUpdateName
        notificationLayoutName = notifyLayoutName
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        flowLayout.scrollDirection = UICollectionView.ScrollDirection.vertical
        flowLayout.minimumInteritemSpacing = 0.0
        collectionView = UICollectionView(frame: CGRect(), collectionViewLayout: flowLayout)
        
        super.init(frame: CGRect())
        
        if let initPkgs = withInitPackagePool {
            safePackagePool = initPkgs
        }
        
        if !shouldShowButton {
            nextButtonCore.isHidden = true
            nextButtonImage.isHidden = true
        }
        
        title.text = titleText
        title.textColor = UIColor(named: "G-TextTitle")
        title.font = .systemFont(ofSize: 26, weight: .bold)
        title.textAlignment = .left
        addSubview(title)
        title.snp.makeConstraints { (x) in
            x.left.equalTo(self.snp.left).offset(8)
            x.top.equalTo(self.snp.top)
            x.right.equalTo(self.snp.right)
            x.height.equalTo(40)
        }
        
        collectionView.delegate = self
        collectionView.alpha = 0
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.clipsToBounds = false
        collectionView.register(PackagePreviewCoCell.self, forCellWithReuseIdentifier: CellID)
        collectionView.isScrollEnabled = false
        addSubview(collectionView)
        collectionView.snp.makeConstraints { (x) in
            x.left.equalTo(self.snp.left)
            x.top.equalTo(title.snp.bottom).offset(12)
            x.right.equalTo(self.snp.right)
            x.height.equalTo(400)
        }
        
        addSubview(bottomAnchorView)
        bottomAnchorView.snp.makeConstraints { (x) in
            x.left.equalTo(self.snp.left)
            x.top.equalTo(collectionView.snp.bottom)
            x.right.equalTo(self.snp.right)
            x.height.equalTo(8)
        }
        
        nextButtonImage.contentMode = .scaleAspectFit
        addSubview(nextButtonImage)
        addSubview(nextButtonCore)
        nextButtonImage.snp.makeConstraints { (x) in
            x.bottom.equalTo(title.snp.bottom)
            x.right.equalTo(self.snp.right).offset(-8)
            x.width.equalTo(22)
            x.height.equalTo(22)
        }
        nextButtonCore.snp.makeConstraints { (x) in
            x.center.equalTo(nextButtonImage.snp.center)
            x.width.equalTo(30)
            x.height.equalTo(30)
        }
        nextButtonCore.addTarget(self, action: #selector(pushToAllDetails), for: .touchUpInside)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateContexts), name: notifyUpdateName, object: nil)
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
                self.collectionView.snp.updateConstraints { (x) in
                    x.height.equalTo(self.suggestedHeight)
                }
                self.collectionView.layoutIfNeeded()
                self.collectionView.alpha = 1
            }) { (_) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.updateContexts()
                }
            }
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private
    func pushToAllDetails() {
        
        nextButtonImage.shineAnimation()
        if let item = whenPushDetailsWithPackages() {
            if let vc = self.obtainParentViewController {
                let target = PackageCollectionViewController()
                var hud: JGProgressHUD?
                if let view = self.obtainParentViewController?.view {
                    if self.traitCollection.userInterfaceStyle == .dark {
                        hud = .init(style: .dark)
                    } else {
                        hud = .init(style: .light)
                    }
                    hud?.textLabel.text = "LoadingDataBase".localized()
                    hud?.show(in: view)
                }
                DispatchQueue.global(qos: .background).async {
                    target.setPackages(withSortedArray: item)
                    DispatchQueue.main.async {
                        hud?.dismiss()
                        if let nav = vc.navigationController {
                            nav.pushViewController(target, animated: true)
                        } else {
                            vc.present(target, animated: true, completion: nil)
                        }
                    }
                }
            }
        } else {
            whenPushDetailsWithAnotherBlock()
        }
        
    }
    
    private var privHeight: CGFloat = -1
    @objc
    func updateContexts() {
        guard let data = whenUpdateCollectionViewDatas() else {
            fatalError()
        }
        self.safePackagePool = data
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.collectionView.reloadData()
            let target = self.suggestedHeight
            if self.privHeight != target && target > 1 {
                self.privHeight = target
                UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
                    self.collectionView.snp.updateConstraints { (x) in
                        x.height.equalTo(target)
                    }
                    self.collectionView.layoutSubviews()
                }) { (_) in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        NotificationCenter.default.post(name: self.notificationLayoutName, object: nil)
                    }
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NotificationCenter.default.post(name: self.notificationLayoutName, object: nil)
                }
            }
        }
    }
    
    func touches(at: CGPoint) {
        if abs(nextButtonCore.center.x - at.x) < nextButtonCore.frame.width / 2 &&
           abs(nextButtonCore.center.y - at.y) < nextButtonCore.frame.height / 2 {
            nextButtonCore.sendActions(for: .touchUpInside)
            return
        }
        let minX = collectionView.frame.minX
        let minY = collectionView.frame.minY
        let realTouchY = at.y - minY
        let realTouchX = at.x - minX
        if let indexPath = collectionView.indexPathForItem(at: CGPoint(x: realTouchX, y: realTouchY)) {
            collectionView.delegate?.collectionView?(collectionView, didSelectItemAt: indexPath)
        }
    }
    
}

extension PackageCollectionView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionViewCalculatesCellSize() -> (CGSize, Int, Int /*size, item per line, wanted items count*/) {
        let total = self.bounds.width
        var itemPerRow: CGFloat = 1
        let gap: CGFloat = 8
        var ret: CGSize = CGSize()
        ret.width = 2333
        if total > 400 {
            while ret.width > 300 && itemPerRow < 10 {
                itemPerRow += 1
                let trySizeWithGap = (total - gap) / itemPerRow
                ret.width = trySizeWithGap
                ret.height = ret.width * 0.25
            }
        } else {
            ret.width = total - gap * 2
        }
        if ret.height > 72 { ret.height = 72 }
        if ret.height < 58 { ret.height = 58 }
        let wantedItems = Int(itemPerRow) * lineLimit // item per line * line limit
        
        // .................... 😓
        if ret.width < 0 || ret.height < 0 {
            ret.width = 0
            ret.height = 0
        }
        
        if wantedItems >= safePackagePool.count || lineLimit < 0 {
            return (ret, Int(itemPerRow), safePackagePool.count)
        } else {
            return (ret, Int(itemPerRow), wantedItems)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if safePackagePool.count < 1 {
            return 1
        }
        return collectionViewCalculatesCellSize().2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = (collectionView.dequeueReusableCell(withReuseIdentifier: CellID, for: indexPath) as? PackagePreviewCoCell) ?? PackagePreviewCoCell()
        let count = safePackagePool.count
        if count > 0 {
            let pack = safePackagePool[indexPath.row]
            cell.name.text = pack.obtainNameIfExists()
            cell.auth.text = pack.obtainAuthorIfExists()
            cell.desc.text = pack.obtainDescriptionIfExistsOrVersion()
            cell.icon.image =  UIImage(named: "mod")
            cell.litt.image = nil
            cell.packageRef = pack
            let iconlink = pack.obtainIconIfExists()
            if let img = iconlink.1 {
                cell.icon.image = img
            } else {
                if let il = iconlink.0, il.hasPrefix("http") {
                    cell.icon.sd_setImage(with: URL(string: il), placeholderImage:  UIImage(named: "mod"), options: .avoidAutoSetImage, context: nil, progress: nil) { (image, err, _, url) in
                        if let img = image, cell.packageRef?.identity == pack.identity {
                            cell.icon.image = img
                        }
                    }
                } else if let il = iconlink.0, il.hasPrefix("file://") {
                    if let img = UIImage(contentsOfFile: String(il.dropFirst("file://".count))) {
                        cell.icon.image = img
                    }
                }
            }
            whenSetupCells(cell)
        } else {
            cell.name.text = emptyInfoElements?.0
            cell.auth.text = emptyInfoElements?.1
            cell.desc.text = emptyInfoElements?.2
            cell.icon.image = UIImage(named: "mod")
            cell.litt.image = nil
            cell.packageRef = nil
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionViewCalculatesCellSize().0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.puddingAnimate()
        
        if let package = (cell as? PackagePreviewCoCell)?.packageRef {
            let target = PackageViewController()
            target.PackageObject = package
            if let vc = self.obtainParentViewController {
                if let nav = vc.navigationController {
                    nav.pushViewController(target)
                } else {
                    vc.present(target, animated: true, completion: nil)
                }
            } else {
                if let vc = self.window?.rootViewController {
                    if let nav = vc.navigationController {
                        nav.pushViewController(target)
                    } else {
                        vc.present(target, animated: true, completion: nil)
                    }
                } else {
                    fatalError("NO VIEW CONTROLLER AVAILABLE") // what kind of thing can happen here?
                }
            }
        } else {
            let alert = UIAlertController(title: "Error".localized(), message: "Package_ContentDamaged".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
            self.obtainParentViewController?.present(alert, animated: true, completion: nil)
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? PackagePreviewCoCell {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
                cell.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }) { (_) in
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? PackagePreviewCoCell {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
                cell.transform = .identity
            }) { (_) in
            }
        }
    }
    
}

