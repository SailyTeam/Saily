//
//  DashboardController+CollectionView.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/9/14.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import UIKit

private let kCellLineLimit = 6

extension DashboardController {
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
        var itemsPerRow = 1
        collectionViewCellSizeCache = InterfaceBridge
            .calculatesPackageCellSize(availableWidth: view.frame.width - inset, andItemsPerRow: &itemsPerRow)
        cellLimit = itemsPerRow * kCellLineLimit
        debugPrint(collectionViewCellSizeCache)
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.reloadData()
    }

    // MARK: - DELEGATE

    override func numberOfSections(in _: UICollectionView) -> Int {
        dataSource.count
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, referenceSizeForHeaderInSection _: Int) -> CGSize {
        CGSize(width: 300, height: 60)
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 viewForSupplementaryElementOfKind kind: String,
                                 at indexPath: IndexPath)
        -> UICollectionReusableView
    {
        debugPrint("\(#function) viewForSupplementaryElementOfKind \(kind)")
        let view = collectionView
            .dequeueReusableSupplementaryView(ofKind: kind,
                                              withReuseIdentifier: generalHeaderID,
                                              for: indexPath)
        if let view = view as? LXDashboardSupplementHeaderCell {
            view.prepareNewValue()
            view.loadSection(data: dataSource[indexPath.section])
            view.overrideButtonAction = dataSource[indexPath.section].action
        }
        return view
    }

    override func collectionView(_: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let read = dataSource[section].package.count
        if dataSource[section].shouldLimit, read > cellLimit {
            return cellLimit
        }
        return read
    }

    override func collectionView(_: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if dataSource[indexPath.section].shouldLimit,
           indexPath.row == cellLimit - 1
        {
            let cell = collectionView
                .dequeueReusableCell(withReuseIdentifier: moreCellID, for: indexPath)
                as! LXDashboardMoreCell
            cell.backgroundColor = UIColor(light: .white, dark: .black)
            cell.layer.cornerRadius = 8
            return cell
        } else {
            let cell = collectionView
                .dequeueReusableCell(withReuseIdentifier: packageCellID, for: indexPath)
                as! PackageCollectionCell
            cell.prepareForNewValue()
            cell.loadValue(package: dataSource[indexPath.section].package[indexPath.row])
            cell.originalCell.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            cell.backgroundColor = UIColor(light: .white, dark: .black)
            cell.layer.cornerRadius = 8
            return cell
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        if collectionView.cellForItem(at: indexPath) is LXDashboardMoreCell {
            if let override = dataSource[safe: indexPath.section]?.action {
                override(self)
                return
            }
            let target = PackageCollectionController()
            target.title = dataSource[safe: indexPath.section]?.title
            target.dataSource = dataSource[safe: indexPath.section]?.package ?? []
            present(next: target)
            return
        }
        guard let data = dataSource[safe: indexPath.section]?
            .package[safe: indexPath.row]
        else {
            return
        }
        let target = PackageController(package: data)
        present(next: target)
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        collectionViewCellSizeCache
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
        guard !(collectionView.cellForItem(at: indexPath) is LXDashboardMoreCell),
              let data = dataSource[safe: indexPath.section]?
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
}
