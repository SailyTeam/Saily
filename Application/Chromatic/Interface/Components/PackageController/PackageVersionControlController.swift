//
//  PackageVersionControlController.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/20.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import UIKit

class PackageVersionControlController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var currentPackage = Package(identity: "") {
        didSet {
            if currentPackage.identity.count > 0 {
                availableControl = [:]
                PackageCenter
                    .default
                    .obtainPackageSummary(with: currentPackage.identity)
                    .forEach { key, value in
                        availableControl[key] = PackageCenter
                            .default
                            .versionTrimmedSingleSubPackages(of: value)
                    }
            } else { availableControl = [:] }
        }
    }

    var availableSectionKeys: [URL] = []
    var availableControl: [URL: [Package]] = [:] {
        didSet {
            availableSectionKeys = [URL](
                availableControl
                    .keys
                    .sorted {
                        RepositoryCenter.default.obtainImmutableRepository(withUrl: $0)?.nickName ?? ""
                            <
                            RepositoryCenter.default.obtainImmutableRepository(withUrl: $1)?.nickName ?? ""
                    }
            )
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    let headerA = UIView()
    let FooterA = UIView()
    let tableView = UITableView()
    let padding: CGFloat = 15
    let sectionHeight: CGFloat = 30
    let cellId = UUID().uuidString

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        preferredContentSize = preferredPopOverSize

        title = NSLocalizedString("VERSION_CONTROL", comment: "Version Control")

        tableView.separatorColor = .clear
        tableView.register(PackageTableCell.self, forCellReuseIdentifier: cellId)
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        tableView.snp.makeConstraints { x in
            x.edges.equalToSuperview()
        }

        do {
            let label = UILabel()
            label.text = NSLocalizedString("CURRENT_SELECTED", comment: "Current Selected")
            label.font = .boldSystemFont(ofSize: 16)
            headerA.addSubview(label)
            headerA.backgroundColor = .systemBackground
            label.snp.makeConstraints { x in
                x.centerY.equalToSuperview()
                x.leading.equalToSuperview().offset(padding)
            }
        }

        do {
            let label = UILabel()
            label.font = .boldSystemFont(ofSize: 16)
            label.text = NSLocalizedString("AVAILABLE_VERSIONS", comment: "Available Versions")
            FooterA.addSubview(label)
            FooterA.backgroundColor = .systemBackground
            label.snp.makeConstraints { x in
                x.centerY.equalToSuperview()
                x.leading.equalToSuperview().offset(padding)
            }
        }

        if navigationController == nil {
            let bigTitle = UILabel()
            bigTitle.text = NSLocalizedString("VERSION_CONTROL", comment: "Version Control")
            bigTitle.font = .systemFont(ofSize: 28, weight: .bold)
            view.addSubview(bigTitle)
            bigTitle.snp.makeConstraints { x in
                x.leading.equalToSuperview().offset(padding)
                x.trailing.equalToSuperview().offset(-padding)
                x.top.equalToSuperview().offset(20)
                x.height.equalTo(40)
            }
            tableView.snp.remakeConstraints { x in
                x.top.equalTo(bigTitle.snp.bottom).offset(20)
                x.leading.equalToSuperview()
                x.trailing.equalToSuperview()
                x.bottom.equalToSuperview()
            }
        }
    }

    func numberOfSections(in _: UITableView) -> Int {
        availableSectionKeys.count + 1
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return 1 }
        return availableControl[availableSectionKeys[section - 1]]?.count ?? 0
    }

    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        sectionHeight
    }

    func tableView(_: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 { return headerA }
        let box = UIView()
        let cell = RepoCompactCell()
        cell.prepareForNewValue()
        cell.setRepository(withUrl: availableSectionKeys[section - 1])
        box.addSubview(cell)
        cell.snp.makeConstraints { x in
            x.edges.equalToSuperview()
        }
        box.backgroundColor = .systemBackground
        return box
    }

    func tableView(_: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 { return sectionHeight }
        return 0
    }

    func tableView(_: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == 0 { return FooterA }
        return nil
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        60
    }

    func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId) as! PackageTableCell
        cell.prepareForNewValue()
        cell.horizontalPadding = 12
        if let package = obtainPackage(at: indexPath) {
            cell.loadValue(package: package)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let package = obtainPackage(at: indexPath) else { return }
        let target = PackageController(package: package)
        present(next: target)
    }

    func obtainPackage(at indexPath: IndexPath) -> Package? {
        let section = indexPath.section - 1
        if section >= 0, section < availableSectionKeys.count {
            let key = availableSectionKeys[section]
            if let packages = availableControl[key],
               indexPath.row >= 0, indexPath.row < packages.count
            {
                let package = packages[indexPath.row]
                return package
            }
        } else if indexPath.section == 0 {
            return currentPackage
        }
        return nil
    }
}
