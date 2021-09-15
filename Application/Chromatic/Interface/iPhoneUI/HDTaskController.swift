//
//  HDTaskController.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/22.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import LNPopupController
import SPIndicator
import UIKit

class HDTaskController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var dataSource = [InterfaceBridge.TaskDataSection]()
    let padding: CGFloat = 15
    let cellId = UUID().uuidString

    let container = UIScrollView()
    let confirmBox = UIView()
    let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(container)
        container.addSubview(tableView)
        let bigTitle = UILabel()
        container.addSubview(bigTitle)

        container.alwaysBounceVertical = true
        container.snp.makeConstraints { x in
            x.edges.equalToSuperview()
        }

        bigTitle.text = NSLocalizedString("TASK_QUEUE", comment: "Task Queue")
        bigTitle.font = .systemFont(ofSize: 28, weight: .bold)
        bigTitle.snp.makeConstraints { x in
            x.leading.equalTo(view).offset(padding)
            x.trailing.equalTo(view).offset(-padding)
            x.top.equalToSuperview().offset(40)
            x.height.equalTo(40)
        }

        tableView.clipsToBounds = false
        tableView.snp.makeConstraints { x in
            x.top.equalTo(bigTitle.snp.bottom).offset(10)
            x.leading.equalTo(view)
            x.trailing.equalTo(view)
            x.height.equalTo(1000)
        }

        tableView.isScrollEnabled = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PackageTableCell.self, forCellReuseIdentifier: cellId)
        tableView.separatorColor = .clear
        view.backgroundColor = .systemBackground
        preferredContentSize = preferredPopOverSize

        title = NSLocalizedString("OPERATION_QUEUE", comment: "Operation Queue")

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

        let clearButton = UIButton()
        clearButton.setTitle(NSLocalizedString("CLEAR_TASKS", comment: "Clear Tasks").uppercased(),
                             for: .normal)
        clearButton.addTarget(self, action: #selector(clearTasks(sender:)), for: .touchUpInside)
        clearButton.layer.cornerRadius = 8
        clearButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        clearButton.setTitleColor(.systemOrange, for: .normal)
        clearButton.setTitleColor(.gray, for: .highlighted)
        container.addSubview(clearButton)
        clearButton.snp.makeConstraints { x in
            x.left.equalTo(view).offset(padding)
            x.top.equalTo(tableView.snp.bottom)
        }

        reloadTaskActions()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    func clearTasks(sender: UIButton) {
        sender.puddingAnimate()
        let alert = UIAlertController(title: "⚠️",
                                      message: NSLocalizedString("THIS_OPERATION_CANNOT_BE_UNDONE", comment: "This operation cannot be undone"),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("CONFIRM", comment: "Confirm"),
                                      style: .destructive, handler: { _ in
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

        tableView.layoutIfNeeded()
        tableView.snp.updateConstraints { x in
            x.height.equalTo(tableView.contentSize.height)
            container.contentSize = CGSize(width: 100,
                                           height: tableView.contentSize.height + 150)
        }
    }

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
        return box
    }

    func tableView(_: UITableView, viewForFooterInSection _: Int) -> UIView? {
        UIView()
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        5
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
//        if !data.isUserRequired { return }
        let target = PackageController(package: data.represent)
        present(next: target)
    }

    func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId) as! PackageTableCell
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

    @objc func confirmQueueActions(sender: UIButton) {
        InterfaceBridge.processTaskButtonTapped(button: sender)
    }
}
