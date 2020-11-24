//
//  InstalledVC.swift
//  Protein
//
//  Created by Lakr Aream on 11/19/20.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit
import JJFloatingActionButton

class InstalledViewController: PackageCollectionViewController {
    
    enum SortType {
        case nameAcc
        case nameDec
        case dateAcc
        case dateDec
    }
    
    private var sortType = SortType.nameAcc
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SimpleNavBar.isHidden = true
        
        title = "Installed".localized()
        
        collectionView.snp.remakeConstraints { (x) in
            x.edges.equalToSuperview()
        }
        
        reloadData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .InstalledShouldUpdate, object: nil)
        
        let actionButton = JJFloatingActionButton()
        actionButton.buttonImage = UIImage(named: "SplitDetailInstalled.ActionMore")
        actionButton.buttonImageSize = CGSize(width: 22, height: 22)
        actionButton.buttonAnimationConfiguration = .transition(toImage: UIImage(named: "SplitDetailInstalled.ActionClose")!)
        actionButton.itemAnimationConfiguration = .popUp(withInterItemSpacing: 10, firstItemSpacing: 10)
            
        actionButton.delegate = self
        
        let item2 = actionButton.addItem(title: "Installed_SortByDateAccending".localized(), image: UIImage(named: "SplitDetailInstalled.Time")?.withRenderingMode(.alwaysTemplate))  { item in
            UIDevice.haptic(style: .light)
            self.sortType = .dateAcc
            self.reloadData()
        }
        item2.imageSize = CGSize(width: 20, height: 20)
        
        let item1 = actionButton.addItem(title: "Installed_SortByDateDesending".localized(), image: UIImage(named: "SplitDetailInstalled.Time")?.withRenderingMode(.alwaysTemplate)) { item in
            UIDevice.haptic(style: .light)
            self.sortType = .dateDec
            self.reloadData()
        }
        item1.imageSize = CGSize(width: 20, height: 20)
        
        
        let item4 = actionButton.addItem(title: "Installed_SortByNameDesending".localized(), image: UIImage(named: "SplitDetailInstalled.ActionName")?.withRenderingMode(.alwaysTemplate)) { item in
            UIDevice.haptic(style: .light)
            self.sortType = .nameDec
            self.reloadData()
        }
        item4.imageSize = CGSize(width: 20, height: 20)
        
        let item3 = actionButton.addItem(title: "Installed_SortByNameAccending".localized(), image: UIImage(named: "SplitDetailInstalled.ActionName")?.withRenderingMode(.alwaysTemplate)) { item in
            UIDevice.haptic(style: .light)
            self.sortType = .nameAcc
            self.reloadData()
        }
        item3.imageSize = CGSize(width: 20, height: 20)

        view.addSubview(actionButton)
        actionButton.snp.makeConstraints { (x) in
            x.right.equalTo(self.view.snp.right).offset(-30)
            x.bottom.equalTo(self.view.snp.bottom).offset(-30)
            x.height.equalTo(50)
            x.width.equalTo(50)
        }
        
    }
    
    @objc private
    func reloadData() {
        switch sortType {
            case .nameAcc:
                let get = PackageManager.shared.niceInstalled
                setPackages(withSortedArray: get.sorted(by: { (A, B) -> Bool in
                    return A.obtainNameIfExists() < B.obtainNameIfExists() ? true : false
                }))
            case .nameDec:
                let get = PackageManager.shared.niceInstalled
                setPackages(withSortedArray: get.sorted(by: { (A, B) -> Bool in
                    return A.obtainNameIfExists() > B.obtainNameIfExists() ? true : false
                }))
            case .dateDec:
                setPackages(withSortedArray: PackageManager.shared.niceInstalled)
            case .dateAcc:
                setPackages(withSortedArray: PackageManager.shared.niceInstalled.reversed())
        }

        collectionView.reloadData()
        
    }
    
}

extension InstalledViewController: JJFloatingActionButtonDelegate {
    
    func floatingActionButtonWillOpen() {
        UIDevice.haptic(style: .light)
    }
    
}

