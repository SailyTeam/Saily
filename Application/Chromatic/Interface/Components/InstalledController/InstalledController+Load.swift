//
//  InstalledController+Load.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/29.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import UIKit

extension InstalledController {
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("INSTALLED", comment: "Installed")

        view.backgroundColor = .systemBackground

        let leftItem = UIBarButtonItem(image: .fluent(.arrowSort24Filled),
                                       style: .done,
                                       target: self,
                                       action: #selector(selectSortOption))
        navigationItem.leftBarButtonItem = leftItem

        setupRightButtonItem()

        view.backgroundColor = .systemBackground

        searchController.searchBar.addSubview(leftAnchor)
        searchController.searchBar.addSubview(rightAnchor)

        leftAnchor.snp.makeConstraints { x in
            x.leading.equalToSuperview().offset(15)
            x.top.equalToSuperview()
            x.width.equalTo(200)
            x.height.equalTo(10)
        }

        rightAnchor.snp.makeConstraints { x in
            x.trailing.equalToSuperview().offset(-15)
            x.top.equalToSuperview()
            x.width.equalTo(200)
            x.height.equalTo(10)
        }

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = .clear
        collectionView.register(PackageCollectionCell.self, forCellWithReuseIdentifier: cellId)
        collectionView.register(ReuseTimerHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: headerId)

        searchController.searchBar.placeholder = NSLocalizedString("SEARCH_INSTALLED", comment: "Search Installed")
        searchController.searchBar.setValue(NSLocalizedString("CANCEL", comment: "Cancel"),
                                            forKey: "cancelButtonText")
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.textField?.autocapitalizationType = .none
        searchController.searchBar.textField?.autocorrectionType = .no

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        collectionView.addSubview(refreshControl)

        updateCellSize()
        updateSource()

        // for overwrite indicators
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(justReload),
                                               name: .TaskContainerChanged,
                                               object: nil)

        // for update recheck
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(justReload),
                                               name: RepositoryCenter.metadataUpdate,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(justReload),
                                               name: RepositoryCenter.registrationUpdate,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(justReload),
                                               name: PackageCenter.packageRecordChanged,
                                               object: nil)
    }
}
