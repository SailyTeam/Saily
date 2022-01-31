//
//  DashboardController.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/10.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import UIKit

class DashboardController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    var dataSource = [InterfaceBridge.DashboardDataSection]()
    let refreshControl = UIRefreshControl()

    let packageCellID = UUID().uuidString
    let moreCellID = UUID().uuidString
    let generalHeaderID = UUID().uuidString

    var collectionViewFrameCache: CGSize?
    var collectionViewCellSizeCache = CGSize()

    var cellLimit = 16

    let searchBar: UIView = SearchBarButton()

    init() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        flowLayout.scrollDirection = UICollectionView.ScrollDirection.vertical
        flowLayout.minimumInteritemSpacing = 0.0
        super.init(collectionViewLayout: flowLayout)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.clipsToBounds = false
        collectionView.contentInset = UIEdgeInsets(top: 50, left: 20, bottom: 50, right: 20)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = .clear
        collectionView.register(LXDashboardSupplementHeaderCell.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: generalHeaderID)
        collectionView.register(PackageCollectionCell.self,
                                forCellWithReuseIdentifier: packageCellID)
        collectionView.register(LXDashboardMoreCell.self,
                                forCellWithReuseIdentifier: moreCellID)

        (searchBar as? SearchBarButton)?.onTouch = { [weak self] in
            self?.searchButton()
        }
        collectionView.addSubview(searchBar)
        searchBar.snp.makeConstraints { x in
            x.left.equalTo(view).offset(20)
            x.right.equalTo(view).offset(-20)
            x.bottom.equalTo(collectionView.snp.top)
            x.height.equalTo(40)
        }

        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        collectionView.addSubview(refreshControl)

        reloadDataSource(wait: true)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reloadDataSource),
                                               name: RepositoryCenter.metadataUpdate,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reloadDataSource),
                                               name: RepositoryCenter.registrationUpdate,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reloadDataSource),
                                               name: PackageCenter.packageRecordChanged,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reloadDataSource),
                                               name: .PackageCollectionChanged,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    func searchButton() {
        let target = SearchController()
        present(next: target)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            target.searchController.searchBar.becomeFirstResponder()
        }
    }
}

private class SearchBarButton: UIView {
    var iconView: UIImageView = {
        let view = UIImageView()
        view.image = .fluent(.search24Filled)
        view.tintColor = .gray
        return view
    }()

    var placeholder = UILabel()
    var coverButton = UIButton()

    var onTouch: (() -> Void)?

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    required init() {
        super.init(frame: CGRect())
        backgroundColor = .gray.withAlphaComponent(0.1)
        layer.cornerRadius = 8

        let gap = 12

        iconView.contentMode = .scaleAspectFit
        addSubview(iconView)
        iconView.snp.makeConstraints { x in
            x.centerY.equalTo(self.snp.centerY)
            x.left.equalTo(self.snp.left).offset(gap)
            x.height.equalTo(25)
            x.width.equalTo(30)
        }

        placeholder.text = NSLocalizedString("SEARCH", comment: "Search")
        placeholder.textColor = .gray
        placeholder.font = .roundedFont(ofSize: 18, weight: .semibold)
        addSubview(placeholder)
        placeholder.snp.makeConstraints { x in
            x.centerY.equalTo(self.snp.centerY)
            x.left.equalTo(iconView.snp.right).offset(gap)
            x.top.equalTo(self.snp.top).offset(gap / 2)
            x.width.equalTo(233)
        }

        addSubview(coverButton)
        coverButton.snp.makeConstraints { x in
            x.edges.equalToSuperview()
        }
        coverButton.addTarget(self, action: #selector(touched), for: .touchUpInside)
    }

    @objc private
    func touched() {
        puddingAnimate()
        onTouch?()
    }
}
