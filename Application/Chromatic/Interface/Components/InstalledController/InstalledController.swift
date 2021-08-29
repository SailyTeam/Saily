//
//  InstalledController.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/29.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import DropDown
import FluentIcon
import PropertyWrapper
import SPIndicator
import SwiftThrottle
import UIKit

class InstalledController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    // MARK: - SORT OPTION

    enum SortOption: String, CaseIterable {
        case name
        case lastModification

        func convertToInterfaceString() -> String {
            switch self {
            case .name:
                return NSLocalizedString("NAME", comment: "Name")
            case .lastModification:
                return NSLocalizedString("LAST_MODIFICATION", comment: "Last Modification")
            }
        }
    }

    @UserDefaultsWrapper(key: "wiki.qaq.chromatic.installed.sortOption", defaultValue: SortOption.lastModification.rawValue)
    var _sortOption: String
    @UserDefaultsWrapper(key: "wiki.qaq.chromatic.installed.sortReversed", defaultValue: false)
    var _sortReversed: Bool

    var sortOption: SortOption {
        get { SortOption(rawValue: _sortOption) ?? .name }
        set {
            _sortOption = newValue.rawValue
            DispatchQueue.main.async { self.updateSource() }
        }
    }

    var sortReversed: Bool {
        get { _sortReversed }
        set {
            _sortReversed = newValue
            DispatchQueue.main.async { self.updateSource() }
        }
    }

    // MARK: SORT OPTION -

    @UserDefaultsWrapper(key: "wiki.qaq.chromatic.searchWithCaseSensitive", defaultValue: false)
    var searchWithCaseSensitive: Bool

    let searchController = UISearchController()
    let cellId = UUID().uuidString
    let headerId = UUID().uuidString

    struct InstalledData {
        let section: String?
        var package: [Package]
    }

    var dataSource: [InstalledData] = []
    var updateFound = false

    let formatter: DateFormatter = {
        var formatter = DateFormatter()
        formatter.formatterBehavior = .behavior10_4
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()

    var rightAnchor = UIView()
    var leftAnchor = UIView()

    let refreshControl = UIRefreshControl()

    var collectionViewCellSizeCache = CGSize()

    init() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        flowLayout.scrollDirection = UICollectionView.ScrollDirection.vertical
        flowLayout.minimumInteritemSpacing = 0.0
        super.init(collectionViewLayout: flowLayout)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    @objc
    func justReload() {
        DispatchQueue.main.async { [self] in
            updateSource()
        }
    }

    @objc
    func refresh() {
        DispatchQueue.global().async {
            PackageCenter.default.realodLocalPackages()
            DispatchQueue.main.async { [self] in
                refreshControl.endRefreshing()
                updateSource()
                SPIndicator
                    .present(title: NSLocalizedString("INSTALLATION_INFO_REFRESHED", comment: "Installation Info Refreshed"),
                             message: "",
                             preset: .done,
                             from: .top,
                             completion: nil)
            }
        }
    }

    @objc
    func sendUpdate() {
        let result = TaskManager.shared.updateEverything()
        if result {
            SPIndicator.present(title: NSLocalizedString("QUEUED", comment: "Queued"),
                                preset: .done)
        } else {
            let target = PackageDiagnosticController()
            present(next: target)
        }
    }

    @objc
    func selectSortOption() {
        let dropDown = DropDown(anchorView: leftAnchor.plainView)
        var dataSource = [String: SortOption]()
        SortOption.allCases.forEach { option in
            dataSource[option.convertToInterfaceString()] = option
        }
        let actions = SortOption.allCases
        dropDown.dataSource = actions
            .map { $0.convertToInterfaceString() }
            // padding it 🥺
            .map { "⁠\u{200b}   " + $0 + "⁠   \u{200b}" }
        dropDown.selectionAction = { (index: Int, _: String) in
            guard index >= 0, index < actions.count else { return }
            let action = actions[index]
            if self.sortOption == action {
                self.sortReversed.toggle()
            } else {
                self.sortOption = action
                self.sortReversed = false
            }
        }
        dropDown.show(onTopOf: view.window)
    }

    @objc
    func showAllUpdateToDate() {
        SPIndicator.present(title: NSLocalizedString("ALL_PACKAGES_UP_TO_DATE", comment: "All Packages Up to Date"),
                            preset: .done)
    }

    func setupRightButtonItem() {
        if updateFound {
            let rightItem = UIBarButtonItem(image: .fluent(.arrowUpCircle24Filled),
                                            style: .done,
                                            target: self,
                                            action: #selector(sendUpdate))
            navigationItem.rightBarButtonItem = rightItem
        } else {
            let rightItem = UIBarButtonItem(image: .fluent(.checkmarkCircle24Filled),
                                            style: .done,
                                            target: self,
                                            action: #selector(showAllUpdateToDate))
            rightItem.tintColor = .systemGreen
            navigationItem.rightBarButtonItem = rightItem
        }
    }
}
