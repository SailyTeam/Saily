//
//  NowUpdateView.swift
//  Protein
//
//  Created by Lakr Aream on 2020/5/10.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit

class NowUpdateView: PackageCollectionView {
    
    required init() {
                
        super.init(titleText: "AvailableUpdate".localized(), maxLineLimit: -1, shouldShowButton: true, notifyUpdateName: .UpdateCandidateShouldUpdate, notifyLayoutName: .UpdateCandidateShouldLayout)
        
        whenUpdateCollectionViewDatas = { () in
            return PackageManager.shared.installedUpdateCandidate.map { (obj) -> PackageStruct in
                return obj.1
            }
        }

        whenSetupCells = { (cell) in
            cell.litt.image = UIImage(named: "PackageCollectionView.Update")
            if let pkg = cell.packageRef,
                TaskManager.shared.packageIsInQueue(identity: pkg.identity) {
                cell.litt.image = UIImage(named: "PackageCollectionView.Queued")
            }
        }
        
        whenPushDetailsWithAnotherBlock = {
            for (_, new) in PackageManager.shared.installedUpdateCandidate {
                let _ = TaskManager.shared.addInstall(with: new)
            }
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
}
