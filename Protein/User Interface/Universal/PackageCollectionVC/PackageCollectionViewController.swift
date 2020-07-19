//
//  PackageCollectionViewController.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/26.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit
import SDWebImage

class PackageCollectionViewController: UIViewControllerWithCustomizedNavBar, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    private var privViewSize = CGSize()
    let collectionView: UICollectionView
    
    public var nothingInfo: (String, String, String)? = nil
    
    required init() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.sectionInset = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        flowLayout.scrollDirection = UICollectionView.ScrollDirection.vertical
        flowLayout.minimumInteritemSpacing = 0.0
        collectionView = UICollectionView(frame: CGRect(), collectionViewLayout: flowLayout)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private var store = [PackageStruct]()
    
    private let CellID = "wiki.qaq.Protein.PackageCollectionViewController-" + UUID().uuidString
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        
        view.addSubview(collectionView)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.clipsToBounds = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.decelerationRate = .fast
        collectionView.snp.remakeConstraints { (x) in
            x.top.equalTo(self.SimpleNavBar.snp.bottom).offset(20)
            x.left.equalTo(self.view.snp.left)//.offset(2)
            x.right.equalTo(self.view.snp.right).offset(-6)
            x.bottom.equalTo(self.view.snp.bottom).offset(-20)
        }
        
        view.backgroundColor = UIColor(named: "G-ViewController-Background")
        collectionView.backgroundColor = .clear
        preferredContentSize = CGSize(width: 700, height: 555)
        
        collectionView.register(PackagePreviewCoNoCRCell.self, forCellWithReuseIdentifier: CellID)
        
    }

    func setPackages(withSortedArray: [PackageStruct]) {
        store = withSortedArray
    }
    
    override func viewDidLayoutSubviews() {
        if privViewSize != view.bounds.size {
            privViewSize = view.bounds.size
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return store.count < 1 ? 1 : store.count
    }
    
    //                                                  item per row
    func collectionViewCalculatesCellSize() -> (CGSize, Int) {
        let total = self.view.bounds.width - 40
        var itemPerRow: CGFloat = 1
        let gap: CGFloat = 4
        var ret: CGSize = CGSize()
        ret.width = 2333
        if total > 400 {
            while ret.width > 250 && itemPerRow < 10 {
                itemPerRow += 1
                let trySizeWithGap = (total - gap * 2) / itemPerRow
                ret.width = trySizeWithGap
                ret.height = ret.width * 0.25
            }
        } else {
            ret.width = total - gap * 2
        }
        if ret.height > 72 { ret.height = 72 } // for macOS
        if ret.height < 58 { ret.height = 58 }
        return (ret, Int(itemPerRow))
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionViewCalculatesCellSize().0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = (collectionView.dequeueReusableCell(withReuseIdentifier: CellID, for: indexPath) as? PackagePreviewCoNoCRCell) ?? PackagePreviewCoNoCRCell()
        if store.count > 0 {
            let pack = store[indexPath.row]
            cell.packageRef = pack
            cell.name.text = pack.obtainNameIfExists()
            cell.auth.text = pack.obtainAuthorIfExists()
            cell.desc.text = pack.obtainDescriptionIfExistsOrVersion()
            cell.icon.image =  UIImage(named: "mod")
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
        } else {
            if let nothing = nothingInfo {
                cell.name.text = nothing.0
                cell.auth.text = nothing.1
                cell.desc.text = nothing.2
            } else {
                cell.name.text = "NoRecentUpdate".localized()
                cell.auth.text = "😄"
                cell.desc.text = "NoRecentUpdateInstruction".localized()
            }
            cell.icon.image =  UIImage(named: "mod")
            cell.packageRef = nil
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.puddingAnimate()
        
        if let package = (cell as? PackagePreviewCoNoCRCell)?.packageRef {
            let target = PackageViewController()
            target.PackageObject = package
            target.preferredContentSize = self.preferredContentSize
            target.modalPresentationStyle = .formSheet;
            target.modalTransitionStyle = .coverVertical;
            if let nav = self.navigationController {
                nav.pushViewController(target)
            } else {
                self.present(target, animated: true, completion: nil)
            }
        } else {
            if store.count == 0 {
                return
            }
            let alert = UIAlertController(title: "Error".localized(), message: "Package_ContentDamaged".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? PackagePreviewCoNoCRCell {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
                cell.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }) { (_) in
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? PackagePreviewCoNoCRCell {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
                cell.transform = .identity
            }) { (_) in
            }
        }
    }
    
}
