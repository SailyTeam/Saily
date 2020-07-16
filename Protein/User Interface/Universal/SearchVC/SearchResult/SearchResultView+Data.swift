//
//  SearchResultView+Data.swift
//  Protein
//
//  Created by soulghost on 10/5/2020.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit

fileprivate let cellIdentifier = "SearchResultCell"

extension SearchResultView: UITableViewDelegate, UITableViewDataSource {
    
    func setupDataSource() {
        self.tableView?.delegate = self
        self.tableView?.dataSource = self
        self.tableView?.register(SearchResultCell.self, forCellReuseIdentifier: cellIdentifier)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        if let resultCell = cell as? SearchResultCell {
            if let results = self.results {
                // sanity check oob
                guard results.count > indexPath.row else {
                    return cell
                }
                resultCell.viewModel = results[indexPath.row]
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let results = self.results {
            // sanity check oob
            guard results.count > indexPath.row else {
                return 0
            }
            return results[indexPath.row].viewHeight()
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let copy = results { // thread safte jobsssssss
            if indexPath.row >= 0 && indexPath.row < copy.count {
                let item = copy[indexPath.row]
                let targetViewController = PackageViewController()
                targetViewController.PackageObject = item.packageRef
                if let vc = self.obtainParentViewController {
                    if let nav = vc.navigationController {
                        nav.pushViewController(targetViewController)
                    } else {
                        vc.present(targetViewController, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
}
