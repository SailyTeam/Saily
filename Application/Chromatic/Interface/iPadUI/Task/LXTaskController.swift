//
//  LXTaskController.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/10.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import SPIndicator
import UIKit

class LXTaskController: UIViewController {
    var dataSource = [InterfaceBridge.TaskDataSection]() {
        didSet {
            updateGuiderOpacity()
        }
    }

    let padding: CGFloat = 15
    let packageCellIdentity = UUID().uuidString
    let tableView = UITableView()

    let guider = LXTaskPlaceholder()

    let confirmBox = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.hidesBackButton = true
        view.backgroundColor = cLXUIDefaultBackgroundColor
        title = NSLocalizedString("TASKS", comment: "Tasks")

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: .fluent(.delete24Filled),
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(clearTasks(sender:)))

        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PackageTableCell.self, forCellReuseIdentifier: packageCellIdentity)
        tableView.separatorColor = .clear
        tableView.backgroundColor = .clear
        tableView.snp.makeConstraints { x in
            x.edges.equalToSuperview()
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reloadTaskActions),
                                               name: .TaskContainerChanged,
                                               object: nil)

        let playIcon = UIImageView()
        let confirmButton = UIButton()
        view.addSubview(confirmBox)
        view.addSubview(confirmButton)

        confirmBox.snp.makeConstraints { x in
            x.trailing.equalToSuperview().offset(-20)
            x.bottom.equalToSuperview().offset(-50)
            x.width.equalTo(60)
            x.height.equalTo(60)
        }
        confirmBox.addSubview(playIcon)
        playIcon.tintColor = .white
        playIcon.image = .fluent(.play24Filled)
        playIcon.snp.makeConstraints { x in
            x.center.equalToSuperview()
            x.width.equalTo(30)
            x.height.equalTo(30)
        }
        confirmBox.backgroundColor = UIColor(named: "DashNAV.TaskSelectedColor")
        confirmBox.layer.cornerRadius = 30
        confirmButton.snp.makeConstraints { x in
            x.edges.equalTo(confirmBox)
        }
        confirmButton.addTarget(self, action: #selector(confirmQueueActions(sender:)), for: .touchUpInside)

        guider.isUserInteractionEnabled = false
        view.addSubview(guider)
        guider.snp.makeConstraints { x in
            x.centerX.equalToSuperview()
            x.centerY.equalToSuperview().multipliedBy(0.8)
            x.height.equalTo(200)
            x.width.equalTo(300)
        }
        guider.alpha = 0

        reloadTaskActions()
    }

    func updateGuiderOpacity() {
        UIView.animate(withDuration: 0.5) { [self] in
            if dataSource.count == 0 {
                guider.alpha = 1
                tableView.isScrollEnabled = false
            } else {
                guider.alpha = 0
                tableView.isScrollEnabled = true
            }
        }
    }

    @objc
    func clearTasks(sender _: UIButton) {
        if dataSource.count == 0 {
            SPIndicator.present(title: NSLocalizedString("DONE", comment: "Done"),
                                message: "",
                                preset: .done,
                                haptic: .success,
                                from: .top,
                                completion: nil)
            return
        }
        let alert = UIAlertController(title: "⚠️",
                                      message: NSLocalizedString("THIS_OPERATION_CANNOT_BE_UNDONE", comment: "This operation cannot be undone"),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("CONFIRM", comment: "Confirm"),
                                      style: .destructive, handler: { _ in
                                          SPIndicator.present(title: NSLocalizedString("DONE", comment: "Done"),
                                                              message: "",
                                                              preset: .done,
                                                              haptic: .success,
                                                              from: .top,
                                                              completion: nil)
                                          TaskManager.shared.clearActions()
                                      }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("CANCEL", comment: "Cancel"),
                                      style: .cancel,
                                      handler: nil))
        present(alert, animated: true, completion: nil)
    }

    @objc
    func reloadTaskActions() {
        dataSource = InterfaceBridge.buildTaskDataSource()
        tableView.reloadData()
    }

    @objc func confirmQueueActions(sender: UIButton) {
        InterfaceBridge.processTaskButtonTapped(button: sender)
    }
}

extension LXTaskController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        dataSource.count
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataSource[section].content.count
    }

    func tableView(_: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let box = UIView()
        let title = dataSource[section].label
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        box.addSubview(label)
        label.snp.makeConstraints { x in
            x.leading.equalToSuperview().offset(padding)
            x.trailing.equalToSuperview().offset(-padding)
            x.bottom.equalToSuperview().offset(-2)
        }
        box.backgroundColor = view.backgroundColor // self.view
        return box
    }

    func tableView(_: UITableView, viewForFooterInSection _: Int) -> UIView? {
        UIView()
    }

    func tableView(_: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == dataSource.count - 1 {
            return 200
        }
        return 5
    }

    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        25
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        60
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let data = dataSource[indexPath.section].content[indexPath.row]
        let target = PackageController(package: data.represent)
        present(next: target)
    }

    func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: packageCellIdentity) as! PackageTableCell
        cell.prepareForNewValue()
        cell.horizontalPadding = padding
        let packageAction = dataSource[indexPath.section].content[indexPath.row]
        cell.loadValue(package: packageAction.represent)
        if packageAction.action == .install {
            if packageAction
                .represent
                .latestMetadata?[DirectInstallInjectedPackageLocationKey] != nil
            {
                cell.overrideDescribe(with: NSLocalizedString("DIRECT_INSTALL", comment: "Direct Install"))
            } else {
                cell.listenOnDownloadInfo()
            }
        }
        return cell
    }

    func tableView(_: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let data = dataSource[indexPath.section].content[indexPath.row]
        guard data.isUserRequired else { return nil }
        let deleteItem = UIContextualAction(style: .destructive, title: "Delete".localized()) { _, _, _ in
            _ = TaskManager.shared.cancelActionWithPackage(identity: data.represent.identity)
            SPIndicator.present(title: NSLocalizedString("DELETED", comment: "Deleted"), preset: .done)
            self.reloadTaskActions()
        }
        deleteItem.backgroundColor = UIColor(hex: 0xFA685C)
        return UISwipeActionsConfiguration(actions: [deleteItem])
    }
}
