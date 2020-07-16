//
//  RecentUpdate.swift
//  Protein
//
//  Created by Lakr Aream on 2020/5/2.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit
import SDWebImage
import JGProgressHUD


class RecentUpdatesView: PackageCollectionView {

    required init() {
        super.init(titleText: "RecentUpdate".localized(), notifyUpdateName: .RecentUpdateShouldUpdate, notifyLayoutName: .RecentUpdateShouldLayout)
        
        emptyInfoElements = ("NoRecentUpdate".localized(), "😄", "NoRecentUpdateInstruction".localized())
        
        whenUpdateCollectionViewDatas = { () in
            var new = [PackageStruct]()
            hi: for (index, item) in PackageManager.shared.metaUpdatedList.enumerated() {
                new.append(item)
                if index > 50 {
                    break hi
                }
            }
            return new
        }
        
        whenPushDetailsWithPackages = { () in
            return PackageManager.shared.metaUpdatedList
        }
        
        whenPushDetailsWithAnotherBlock = { () in
            return
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
}
