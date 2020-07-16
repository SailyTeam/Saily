//
//  RecentInstalled.swift
//  Protein
//
//  Created by Lakr Aream on 2020/5/8.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit

class RecentInstalledView: PackageCollectionView {

    required init() {
        super.init(titleText: "RecentInstalled".localized(), notifyUpdateName: .InstalledShouldUpdate, notifyLayoutName: .InstalledShouldLayout)

        emptyInfoElements = ("ErrorReadInstalledPackages".localized(), "⚠️", "PleaseTryReInstallApp".localized())
        
        whenUpdateCollectionViewDatas = { () in
            var new = [PackageStruct]()
            hi: for (index, item) in PackageManager.shared.niceInstalled.enumerated() {
                new.append(item)
                if index > 50 {
                    break hi
                }
            }
            return new
        }
        
        whenPushDetailsWithPackages = { () in
            if (self.obtainParentViewController?.navigationController as? SplitDetailDashBoardNAV)?.assignedDashCard != nil {
                return nil
            }
            return PackageManager.shared.niceInstalled
        }
        
        whenPushDetailsWithAnotherBlock = { () in
            if let card = self.obtainParentViewController?.navigationController as? SplitDetailDashBoardNAV,
                let assign = card.assignedDashCard {
                assign.selectInstalled()
            }
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
}
