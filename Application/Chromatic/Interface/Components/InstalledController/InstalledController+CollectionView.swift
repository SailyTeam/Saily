//
//  InstalledController+CollectionView.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/29.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import UIKit

extension InstalledController {
    // MARK: - CELL SIZE

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if collectionView.size == collectionViewFrameCache {
            return
        }
        collectionViewFrameCache = collectionView.size
        DispatchQueue.main.async {
            self.updateCellSize()
        }
    }

    func updateCellSize() {
        let inset = collectionView.contentInset.left + collectionView.contentInset.right
        collectionViewCellSizeCache = InterfaceBridge
            .calculatesPackageCellSize(availableWidth: view.frame.width - inset)
        debugPrint(collectionViewCellSizeCache)
        collectionView.collectionViewLayout.invalidateLayout()
    }

    // MARK: - COLLECTION VIEW

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        collectionViewCellSizeCache
    }

    override func numberOfSections(in _: UICollectionView) -> Int {
        dataSource.count
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, referenceSizeForHeaderInSection _: Int) -> CGSize {
        if sortOption == .lastModification {
            return CGSize(width: 300, height: 20)
        }
        return CGSize(width: 0, height: 0)
    }

    override func collectionView(_: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        dataSource[section].package.count
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 viewForSupplementaryElementOfKind kind: String,
                                 at indexPath: IndexPath)
        -> UICollectionReusableView
    {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                   withReuseIdentifier: headerId,
                                                                   for: indexPath)
        if let view = view as? ReuseTimerHeaderView {
            view.loadText(dataSource[indexPath.section].section ?? "")
        }
        return view
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let data = dataSource[safe: indexPath.section]?
            .package[safe: indexPath.row]
        else {
            return
        }
        let target = PackageController(package: data)
        present(next: target)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        debugPrint("\(self) \(#function) \(indexPath)")
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! PackageCollectionCell
        let fetch = dataSource[indexPath.section].package[indexPath.row]
        cell.prepareForNewValue()
        cell.loadValue(package: fetch)

        if PackageCenter
            .default
            .obtainPackageInstallationInfo(with: fetch.identity) != nil,
            let current = fetch.latestVersion,
            PackageCenter
            .default
            .obtainUpdateForPackage(with: fetch.identity, version: current)
            .count > 0
        {
            cell.overrideIndicator(with: .fluent(.arrowUpCircle24Filled), and: .systemBlue)
        }

        cell.horizontalPadding = 4
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) {
            UIView.animate(withDuration: 0.5,
                           delay: 0,
                           usingSpringWithDamping: 1,
                           initialSpringVelocity: 1,
                           options: .curveEaseInOut,
                           animations: {
                               cell.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                           }) { _ in
            }
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) {
            UIView.animate(withDuration: 0.5,
                           delay: 0,
                           usingSpringWithDamping: 1,
                           initialSpringVelocity: 1,
                           options: .curveEaseInOut,
                           animations: {
                               cell.transform = .identity
                           }) { _ in
            }
        }
    }

    override func collectionView(_: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point _: CGPoint) -> UIContextMenuConfiguration? {
        guard let data = dataSource[safe: indexPath.section]?
            .package[safe: indexPath.row],
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

    // MARK: COLLECTION VIEW -
}
