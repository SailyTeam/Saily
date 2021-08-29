//
//  PackageCollectionController.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/18.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import UIKit

class PackageCollectionController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var dataSource: [Package] = []
    let cellId = UUID().uuidString
    var collectionViewCellSizeCache = CGSize()

    let collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        flowLayout.scrollDirection = UICollectionView.ScrollDirection.vertical
        flowLayout.minimumInteritemSpacing = 0.0
        let view = UICollectionView(frame: CGRect(), collectionViewLayout: flowLayout)
        view.backgroundColor = .clear
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        if title?.count ?? 0 < 1 {
            title = NSLocalizedString("PACKAGES", comment: "Packages")
        }
        view.backgroundColor = .systemBackground
        preferredContentSize = preferredPopOverSize

        collectionView.alwaysBounceVertical = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(PackageCollectionCell.self, forCellWithReuseIdentifier: cellId)
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { x in
            x.edges.equalToSuperview()
        }
        updateCellSize()

        if navigationController == nil {
            let bigTitle = UILabel()
            bigTitle.text = NSLocalizedString("PACKAGES", comment: "Packages")
            bigTitle.font = .systemFont(ofSize: 28, weight: .bold)
            view.addSubview(bigTitle)
            bigTitle.snp.makeConstraints { x in
                x.leading.equalToSuperview().offset(15)
                x.right.equalToSuperview().offset(-15)
                x.top.equalToSuperview().offset(20)
                x.height.equalTo(40)
            }
            collectionView.snp.remakeConstraints { x in
                x.top.equalTo(bigTitle.snp.bottom).offset(15)
                x.leading.equalToSuperview().offset(15)
                x.trailing.equalToSuperview().offset(-15)
                x.bottom.equalToSuperview()
            }
        }

        collectionView.reloadData()

        emptyItemBehavior()
    }

    func emptyItemBehavior() {
        if dataSource.count == 0 {
            let imageView = UIImageView()
            imageView.tintColor = .gray.withAlphaComponent(0.2)
            imageView.image = .init(systemName: "questionmark.circle.fill")
            imageView.contentMode = .scaleAspectFit
            view.addSubview(imageView)
            imageView.snp.makeConstraints { x in
                x.center.equalToSuperview()
                x.width.equalTo(80)
                x.height.equalTo(80)
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        DispatchQueue.main.async {
            self.updateCellSize()
        }
    }

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

    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        dataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView
            .dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath)
            as! PackageCollectionCell
        cell.prepareForNewValue()
        cell.loadValue(package: dataSource[indexPath.row])
        return cell
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        collectionViewCellSizeCache
    }

    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
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

    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
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

    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let data = dataSource[indexPath.row]
        let target = PackageController(package: data)
        present(next: target)
    }
}
