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
        DispatchQueue.main.async {
            self.updateCellSize()
        }
    }

    // MARK: - COLLECTION VIEW

    func updateCellSize() {
        collectionViewCellSizeCache = collectionViewCalculatesCellSize()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    func collectionViewCalculatesCellSize() -> CGSize {
        let available = view.frame.width
        var itemsPerRow: CGFloat = 1
        let padding: CGFloat = 8
        var result = CGSize()
        result.width = 2000

        // get me the itemsPerRow
        let maximumWidth: CGFloat = 300 // soft limit
        // | padding [minimalWidth] padding [minimalWidth] padding |
        if available > maximumWidth * 2 + padding * 3 {
            // just in case, dont loop forever
            while result.width > maximumWidth, itemsPerRow <= 10 {
                itemsPerRow += 1
                // [minimalWidth] padding |
                var recalculate = (available - padding) / itemsPerRow
                // [minimalWidth]
                recalculate -= padding
                result.width = recalculate
                result.height = result.width * 0.25
            }
        } else {
            itemsPerRow = 1
        }

        // now, do the final math
        var recalculate = (available - padding) / itemsPerRow
        // [minimalWidth]
        recalculate -= padding
        result.width = recalculate
        result.height = 50

        // don't crash my app any how
        if result.width < 0 { result.width = 0 }

        return result
    }

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
                                 viewForSupplementaryElementOfKind _: String,
                                 at indexPath: IndexPath)
        -> UICollectionReusableView
    {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: String(describing: ReuseTimerHeaderView.self),
                                                                   withReuseIdentifier: headerId,
                                                                   for: indexPath)
            as! ReuseTimerHeaderView
        view.loadText(dataSource[indexPath.section].section ?? "")
        return view
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let data = dataSource[indexPath.section].package[indexPath.row]
        let target = PackageController(package: data)
        present(next: target)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
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

    // MARK: COLLECTION VIEW -
}
