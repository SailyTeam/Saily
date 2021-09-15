//
//  UpdateController.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/9/14.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import DropDown
import SPIndicator
import UIKit

class UpdateController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let tableView = UITableView()
    let cellID = UUID().uuidString

    var dataSource = [(Package, Package)]()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        preferredContentSize = preferredPopOverSize

        tableView.separatorColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PackageUpdateTableCell.self, forCellReuseIdentifier: cellID)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { x in
            x.edges.equalToSuperview()
        }

        title = NSLocalizedString("UPDATE", comment: "Update")

        if navigationController == nil {
            let bigTitle = UILabel()
            bigTitle.text = NSLocalizedString("UPDATE", comment: "Update")
            bigTitle.font = .systemFont(ofSize: 28, weight: .bold)
            view.addSubview(bigTitle)
            bigTitle.snp.makeConstraints { x in
                x.leading.equalToSuperview().offset(15)
                x.right.equalToSuperview().offset(-15)
                x.top.equalToSuperview().offset(20)
                x.height.equalTo(40)
            }
            tableView.snp.remakeConstraints { x in
                x.top.equalTo(bigTitle.snp.bottom).offset(15)
                x.leading.equalToSuperview().offset(10)
                x.trailing.equalToSuperview().offset(-10)
                x.bottom.equalToSuperview()
            }
        }

        let rightItem = UIBarButtonItem(title: NSLocalizedString("UPDATE_ALL", comment: "Update All"),
                                        style: .done,
                                        target: self,
                                        action: #selector(updateAll))
        navigationItem.rightBarButtonItem = rightItem

        reloadDataSource()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadDataSource()
    }

    @objc
    func updateAll() {
        let result = TaskManager.shared.updateEverything()
        if result {
            SPIndicator.present(title: NSLocalizedString("QUEUED", comment: "Queued"),
                                preset: .done)
        } else {
            let target = PackageDiagnosticController()
            present(next: target)
        }
    }

    func reloadDataSource() {
        let everything = PackageCenter
            .default
            .obtainInstalledPackageList()
            .filter { !($0.latestMetadata?["tag"]?.contains("role::cydia") ?? false) }
        var builder = [(Package, Package)]()
        for item in everything {
            guard let installInfo = PackageCenter
                .default
                .obtainPackageInstallationInfo(with: item.identity)
            else {
                continue
            }
            let candidateReader = PackageCenter
                .default
                .obtainUpdateForPackage(with: installInfo.identity,
                                        version: installInfo.version)
            if candidateReader.count > 0,
               let decision = PackageCenter
               .default
               .newestPackage(of: candidateReader)
            {
                let loader = (item, decision)
                builder.append(loader)
            }
        }
        dataSource = builder
        tableView.reloadData() // just in cause
        if builder.count < 1 {
            if let navigator = navigationController {
                navigator.popViewController()
            } else {
                dismiss(animated: true, completion: nil)
            }
            return
        }
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID) as! PackageUpdateTableCell
        cell.prepareForNewValue()
        if view.frame.width > 500 {
            cell.padding = 15
        } else {
            cell.padding = 5
        } // not horizontalPadding
        let fetch = dataSource[indexPath.row]
        cell.loadValue(package: fetch.0)
        cell.loadUpdateValue(package: fetch.1)

        if PackageCenter
            .default
            .obtainPackageInstallationInfo(with: fetch.0.identity) != nil,
            let current = fetch.0.latestVersion,
            PackageCenter
            .default
            .obtainUpdateForPackage(with: fetch.0.identity, version: current)
            .count > 0
        {
            cell.overrideIndicator(with: .fluent(.arrowUpCircle24Filled), and: .systemBlue)
        }

        return cell
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        60
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let read = dataSource[indexPath.row]
        let anchor = UIView()
        let cell = tableView.cellForRow(at: indexPath) ?? UIView()
        view.addSubview(anchor)
        anchor.snp.makeConstraints { x in
            x.bottom.equalTo(cell)
            x.trailing.equalTo(view).offset(-15)
            x.width.equalTo(300)
            x.height.equalTo(2)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            anchor.removeFromSuperview()
        }
        // wait for anchor to be layout
        DispatchQueue.main.async {
            let dropDown = DropDown(anchorView: anchor,
                                    selectionAction: { index, _ in
                                        switch index {
                                        case 0:
                                            guard let action = TaskManager.PackageAction(action: .install,
                                                                                         represent: read.1,
                                                                                         isUserRequired: true)
                                            else {
                                                return
                                            }
                                            let result = TaskManager
                                                .shared
                                                .startPackageResolution(action: action)
                                            PackageMenuAction.resolveAction(result: result, view: self.view)
                                        case 1:
                                            self.present(next: PackageController(package: read.0))
                                        case 2:
                                            self.present(next: PackageController(package: read.1))
                                        case 3:
                                            let target = PackageVersionControlController()
                                            target.currentPackage = read.0
                                            self.present(next: target)
                                        case 4:
                                            PackageCenter.default.blockedUpdateTable.append(read.0.identity)
                                            self.reloadDataSource()
                                        default:
                                            break
                                        }
                                    },
                                    dataSource:
                                    [
                                        NSLocalizedString("UPDATE", comment: "Update"),
                                        NSLocalizedString("CURRENT_INSTALLED", comment: "Current Installed"),
                                        NSLocalizedString("UPDATE_CANDIDATE", comment: "Update Candidate"),
                                        NSLocalizedString("VERSION_CONTROL", comment: "Version Control"),
                                        NSLocalizedString("BLOCK_UPDATE", comment: "Block Update"),
                                    ]
                                    .invisibleSpacePadding())
            dropDown.show(onTopOf: self.view.window)
        }
    }
}
