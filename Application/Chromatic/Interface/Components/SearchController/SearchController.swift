//
//  SearchController.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/13.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import Dog
import PropertyWrapper
import SafariServices
import SwiftThrottle
import UIKit

class SearchController: UITableViewController {
    let cellId = UUID().uuidString
    let searchController = UISearchController()
    @Atomic var previousSearchValue = "" {
        didSet {
            if previousSearchValue.count == 0 {
                setSearchResult(with: [])
            }
            updateGuiderOpacity()
        }
    }

    @Atomic var searchToken: UUID? = nil

    private var searchResults = [[SearchResult]]()
    let guider = SearchPlaceholder()

    @UserDefaultsWrapper(key: "wiki.qaq.chromatic.searchWithCaseSensitive", defaultValue: false)
    var searchWithCaseSensitive: Bool

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("SEARCH", comment: "Search")
        view.backgroundColor = .systemBackground

        tableView.separatorColor = .clear
        tableView.register(SearchCell.self, forCellReuseIdentifier: cellId)

        searchController.searchBar.placeholder = NSLocalizedString("SEARCH", comment: "Search")
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

        guider.isUserInteractionEnabled = false
        view.addSubview(guider)
        guider.snp.makeConstraints { x in
            x.centerX.equalToSuperview()
            x.centerY.equalToSuperview().multipliedBy(0.6)
            x.height.equalTo(300)
            x.width.equalTo(300)
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: .fluent(.bookOpenGlobe24Filled),
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(openiOSRepoUpdate))
    }

    @objc
    func openiOSRepoUpdate() {
        let url = URL(string: "https://www.ios-repo-updates.com/")!
        let target = SFSafariViewController(url: url)
        target.title = NSLocalizedString("WORLDWIDE_SEARCH", comment: "Worldwide Search")
        present(target, animated: true, completion: nil)
    }

    override func numberOfSections(in _: UITableView) -> Int {
        let fetch = searchResults.count
        if fetch > 0 { return fetch }
        return 1
    }

    override func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        60
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if previousSearchValue.count > 0 {
            if section >= 0, section < searchResults.count {
                return searchResults[section].count
            }
            if section == 0, searchResults.count == 0 {
                return 1
            }
            return 0
        } else {
            return 0
        }
    }

    override func tableView(_: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section >= 0, section < searchResults.count {
            let sectionData = searchResults[section]
            guard sectionData.first != nil else { return 0 }
            return 20
        }
        return 0
    }

    override func tableView(_: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section >= 0, section < searchResults.count {
            let sectionData = searchResults[section]
            guard let first = sectionData.first else { return nil }
            let box = UIView()
            let label = UILabel()
            label.font = .systemFont(ofSize: 12, weight: .semibold)
            label.textColor = .gray.withAlphaComponent(0.5)
            box.addSubview(label)
            label.snp.makeConstraints { x in
                x.leading.equalToSuperview().offset(15)
                x.trailing.equalToSuperview().offset(-15)
                x.centerY.equalToSuperview()
            }
            let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
            box.addSubview(blurEffectView)
            blurEffectView.snp.makeConstraints { x in
                x.edges.equalToSuperview()
            }
            box.sendSubviewToBack(blurEffectView)
            switch first.associatedValue {
            case .author:
                label.text = NSLocalizedString("AUTHOR", comment: "Author")
            case .installed:
                label.text = NSLocalizedString("INSTALLED", comment: "Installed")
            case .package:
                label.text = NSLocalizedString("PACKAGE", comment: "Package")
            case .repository:
                label.text = NSLocalizedString("REPOSITORY", comment: "Repository")
            case .collection:
                label.text = NSLocalizedString("Collection", comment: "Search Result: Collection")
            }
            return box
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! SearchCell
        let token = cell.prepareNewValue()
        if searchResults.count == 0 {
            cell.makeEmptyHinter()
        } else {
            cell.insertValue(with: searchResults[indexPath.section][indexPath.row], token: token)
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if searchResults.count < 1 { return }
        let object = searchResults[indexPath.section][indexPath.row]
        switch object.associatedValue {
        case let .installed(package), let .collection(package):
            let target = PackageController(package: package)
            present(next: target)
        case let .package(identity, repository):
            if let lookup = RepositoryCenter
                .default
                .obtainImmutableRepository(withUrl: repository)?
                .metaPackage[identity]
            {
                let target = PackageController(package: lookup)
                present(next: target)
            }
        case let .repository(url):
            guard let repo = RepositoryCenter
                .default
                .obtainImmutableRepository(withUrl: url)
            else {
                return
            }
            let target = RepoDetailController(withRepo: repo)
            present(next: target)
        case let .author(name):
            let list = PackageCenter.default.obtainPackage(by: name)
            let target = PackageCollectionController()
            target.dataSource = list.sorted {
                PackageCenter.default.name(of: $0)
                    < PackageCenter.default.name(of: $1)
            }
            present(next: target)
        }
    }

    override func tableView(_: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point _: CGPoint) -> UIContextMenuConfiguration? {
        if searchResults.count < 1 { return nil }
        let object = searchResults[indexPath.section][indexPath.row]
        switch object.associatedValue {
        case let .installed(package), let .collection(package):
            return InterfaceBridge.packageContextMenuConfiguration(for: package, reference: view)
        case let .package(identity, repository):
            if let lookup = RepositoryCenter
                .default
                .obtainImmutableRepository(withUrl: repository)?
                .metaPackage[identity]
            {
                return InterfaceBridge.packageContextMenuConfiguration(for: lookup, reference: view)
            }
        case .repository, .author:
            return nil
        }
        return nil
    }

    override func tableView(_: UITableView, willPerformPreviewActionForMenuWith _: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        guard let destinationViewController = animator.previewViewController else { return }
        animator.addAnimations {
            self.show(destinationViewController, sender: self)
        }
    }

    func updateGuiderOpacity() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.25) { [self] in
                if previousSearchValue.count > 0 {
                    guider.alpha = 0
                } else {
                    guider.alpha = 1
                }
            }
        }
    }

    private let reloadQueue = DispatchQueue(label: "wiki.qaq.tableView.realod.\(UUID())")
    func setSearchResult(with value: [[SearchResult]]) {
        #if DEBUG
            Dog.shared.join(self, "\(value.count) result will be applied")
        #endif
        DispatchQueue.main.async { [self] in
            self.searchResults = value // set it in main thread
            tableView.reloadData()
        }
    }
}

extension SearchController: UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        if let text = searchController
            .searchBar
            .text?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        {
            DispatchQueue.global().async { [self] in
                if self.previousSearchValue == text {
                    return
                }
                self.previousSearchValue = text
                #if DEBUG
                    Dog.shared.join(self, "should search with text [\(text)]")
                #endif
                let currentToken = UUID()
                self.searchToken = currentToken
                self.buildSearchResultWith(key: text, andToken: currentToken)
            }
        }
    }

    func searchBar(_: UISearchBar, textDidChange _: String) {}

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        guard var text = searchBar
            .text?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        else {
            return
        }
        while text.hasSuffix("/") {
            text.removeLast()
        }
        if text.hasPrefix("http"), let url = URL(string: text) {
            // check if already exists
            if RepositoryCenter.default.obtainImmutableRepository(withUrl: url) != nil {
                return
            }
            // if not, push to add
            guard let scheme = URL(string: "apt-repo://\(url.absoluteString)") else {
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                guard let self = self else { return }
                // check if user tapped a cell, and view controller is away
                if self.view.window?.topMostViewController != self.searchController {
                    // do not present
                    return
                }
                debugPrint(scheme)
                // now, add this repo
                UIApplication.shared.open(scheme, options: [:], completionHandler: nil)
            }
        }
    }
}
