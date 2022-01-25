//
//  RecentUpdateController.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/29.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import UIKit

class RecentUpdateController: PackageCollectionController {
    let formatter: DateFormatter = {
        var formatter = DateFormatter()
        formatter.formatterBehavior = .behavior10_4
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()

    var updateDataKeys: [Date] = []
    var updateDataSource: [Date: [(String, URL?)]] = [:] {
        didSet {
            updateDataKeys = updateDataSource.keys.sorted(by: >)
            collectionView.reloadData()
        }
    }

    let headerIdentity = UUID().uuidString

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("RECENT_UPDATE", comment: "Recent Update")
        collectionView.register(ReuseTimerHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: headerIdentity)
    }

    override func updateGuiderOpacity() {
        emptyElementGuider.isHidden = true
    }

    func numberOfSections(in _: UICollectionView) -> Int {
        updateDataKeys.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath)
        -> UICollectionReusableView
    {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                   withReuseIdentifier: headerIdentity,
                                                                   for: indexPath)
        if let view = view as? ReuseTimerHeaderView {
            view.horizontalPadding = 5
            view.loadText(formatter.string(from: updateDataKeys[indexPath.section]))
        }
        return view
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, referenceSizeForHeaderInSection _: Int) -> CGSize {
        CGSize(width: 300, height: 20)
    }

    override func collectionView(_: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        updateDataSource[updateDataKeys[section]]?.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView
            .dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath)
            as! PackageCollectionCell
        cell.prepareForNewValue()
        if let item = obtainPackageFor(indexPath: indexPath) {
            cell.loadValue(package: item)
        }
        return cell
    }

    func obtainPackageFor(indexPath: IndexPath) -> Package? {
        let keys = updateDataKeys[indexPath.section]
        if let item = updateDataSource[keys]?[indexPath.row] {
            if let url = item.1,
               let repo = RepositoryCenter
               .default
               .obtainImmutableRepository(withUrl: url),
               let package = repo.metaPackage[item.0]
            {
                return package
            } else if let pkg = PackageCenter
                .default
                .obtainUpdateForPackage(with: item.0, version: "0")
                .first
            {
                return pkg
            }
        }
        return nil
    }

    override func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        if let item = obtainPackageFor(indexPath: indexPath) {
            let target = PackageController(package: item)
            present(next: target)
        }
    }

    override func collectionView(_: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point _: CGPoint) -> UIContextMenuConfiguration? {
        guard let data = obtainPackageFor(indexPath: indexPath),
              let view = view
        else {
            return nil
        }
        return InterfaceBridge.packageContextMenuConfiguration(for: data, reference: view)
    }

    override func collectionView(_: UICollectionView, willPerformPreviewActionForMenuWith _: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        guard let destinationViewController = animator.previewViewController else { return }
        animator.addAnimations {
            self.show(destinationViewController, sender: self)
        }
    }
}
