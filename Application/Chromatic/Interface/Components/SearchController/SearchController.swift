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
    let searchThrottle = Throttle(minimumDelay: 0.5, queue: .init(label: "wiki.qaq.search.serial"))
    var previousSearchValue = "" {
        didSet {
            if previousSearchValue.count == 0 {
                setSearchResult(with: [])
            }
            updateGuiderOpacity()
        }
    }

    private var searchResults = [SearchResult]()
    private let accessLock = NSLock()
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
            x.centerY.equalToSuperview().multipliedBy(0.5)
            x.height.equalTo(200)
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
        1
    }

    override func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        65
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        if previousSearchValue.count > 0 {
            let count = searchResults.count
            return count > 0 ? count : 1
        } else {
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! SearchCell
        let token = cell.prepareNewValue()
        if searchResults.count == 0 {
            cell.makeEmptyHinter()
        } else {
            cell.insertValue(with: searchResults[indexPath.row], token: token)
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if searchResults.count < 1 { return }
        let object = searchResults[indexPath.row]
        switch object.associatedValue {
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

    func setSearchResult(with value: [SearchResult]) {
        #if DEBUG
            Dog.shared.join(self, "\(value.count) result will be applied")
        #endif
        accessLock.lock()
        searchResults = value
        DispatchQueue.main.async { [self] in
            tableView.reloadData { [self] in
                accessLock.unlock()
            }
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
            searchThrottle.throttle {
                if self.previousSearchValue == text {
                    return
                }
                self.previousSearchValue = text
                #if DEBUG
                    Dog.shared.join(self, "should search with text [\(text)]")
                #endif
                self.buildSearchResultWith(key: text)
            }
        }
    }

    func searchBar(_: UISearchBar, textDidChange _: String) {}
}
