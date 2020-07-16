//
//  WishListView.swift
//  Protein
//
//  Created by Lakr Aream on 2020/5/21.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import Foundation

class WishListView: PackageCollectionView {
    
    required init() {
                
        super.init(titleText: "WishList".localized(), maxLineLimit: -1, shouldShowButton: false, notifyUpdateName: .WishListShouldUpdate, notifyLayoutName: .WishListShouldLayout)
        
        whenUpdateCollectionViewDatas = { () in
            return PackageManager.shared.wishList
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
}
