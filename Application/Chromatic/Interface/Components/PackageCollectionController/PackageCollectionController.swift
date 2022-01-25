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
    var dataSource: [Package] = [] {
        didSet {
            updateGuiderOpacity()
        }
    }

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

    let emptyElementGuider = UIImageView()
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

        if navigationController == nil {
            let bigTitle = UILabel()
            bigTitle.text = title ?? NSLocalizedString("PACKAGES", comment: "Packages")
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
                x.leading.equalToSuperview().offset(10)
                x.trailing.equalToSuperview().offset(-10)
                x.bottom.equalToSuperview()
            }
        }

        updateCellSize()
        collectionView.reloadData()

        emptyElementGuider.tintColor = .gray.withAlphaComponent(0.2)
        emptyElementGuider.image = .init(systemName: "questionmark.circle.fill")
        emptyElementGuider.contentMode = .scaleAspectFit
        view.addSubview(emptyElementGuider)
        emptyElementGuider.snp.makeConstraints { x in
            x.center.equalToSuperview()
            x.width.equalTo(80)
            x.height.equalTo(80)
        }
        updateGuiderOpacity()
    }

    func updateGuiderOpacity() {
        if dataSource.count == 0 {
            emptyElementGuider.isHidden = false
        } else {
            emptyElementGuider.isHidden = true
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        DispatchQueue.main.async {
            self.updateCellSize()
        }
    }

    func updateCellSize() {
        let inset: CGFloat = 15
        collectionView.contentInset = UIEdgeInsets(top: 10, left: inset, bottom: 10, right: inset)
        collectionViewCellSizeCache = InterfaceBridge
            // we are not inside UICollectionViewController
            // so don't use collectionView.contentSize
            // otherwise it will load all of the cells when boot
            .calculatesPackageCellSize(availableWidth: view.frame.width - inset * 2)
        collectionView.collectionViewLayout.invalidateLayout()
    }

    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        dataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        debugPrint("loading cell at \(indexPath)")
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

    // didHighlightItemAt removed because we have add preview
    // subclass may have it's own impl for data source
    // make sure to add safe:

    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let data = dataSource[safe: indexPath.row] else { return }
        let target = PackageController(package: data)
        present(next: target)
    }

    func collectionView(_: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point _: CGPoint) -> UIContextMenuConfiguration? {
        guard let data = dataSource[safe: indexPath.row],
              let view = view
        else {
            return nil
        }
        return InterfaceBridge.packageContextMenuConfiguration(for: data, reference: view)
    }

    func collectionView(_: UICollectionView, willPerformPreviewActionForMenuWith _: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        guard let destinationViewController = animator.previewViewController else { return }
        animator.addAnimations {
            self.show(destinationViewController, sender: self)
        }
    }
}
