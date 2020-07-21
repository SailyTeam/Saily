//
//  SplitDetailTask.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/20.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit
import SDWebImage
import DropDown
import LTMorphingLabel

class SplitDetailTask: UIViewController {
    
    private let tableView = UITableView()
    private let runButton = UIButton()
    
    deinit {
        print("[ARC] SplitDetailTask has been deinited")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(named: "SplitDetail-G-Background")
        
        let _ = buildTaskDataSource()
//        NotificationCenter.default.addObserver(self, selector: #selector(updateTasks), name: .TaskListUpdated, object: nil)
        
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = .clear
        tableView.clipsToBounds = true
        tableView.register(TaskCell.self, forCellReuseIdentifier: "wiki.qaq.Protein.TaskCells")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (x) in
            x.edges.equalToSuperview()
        }
        
        let cover = UIView()
        cover.backgroundColor = view.backgroundColor
        view.addSubview(cover)
        cover.snp.makeConstraints { (x) in
            x.left.equalToSuperview()
            x.right.equalToSuperview()
            x.top.equalToSuperview().offset(-100)
            x.bottom.equalTo(self.view.snp.top).offset(40)
        }
        
        runButton.imageView?.contentMode = .scaleAspectFit
        runButton.setImage(UIImage(named: "FireTasks"), for: .normal)
        runButton.setTitleColor(.blue, for: .normal)
        runButton.addTarget(self, action: #selector(tryFireTasks), for: .touchUpInside)
        runButton.dropShadow()
        view.addSubview(runButton)
        runButton.snp.makeConstraints { (x) in
            x.right.equalTo(self.view.snp.right).offset(-28)
            x.bottom.equalTo(self.view.snp.bottom).offset(-28)
            x.width.equalTo(66)
            x.height.equalTo(66)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(fastReloadNow), name: .TaskListUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadWithThrottler), name: .TaskNumberChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadWithThrottler), name: .TaskListUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadWithThrottler), name: .TaskSystemFinished, object: nil)
    }
    
    @Atomic private var taskSummary = [[TaskManager.Task]]()
    func buildTaskDataSource() -> [[TaskManager.Task]] {
        let new = TaskManager.shared.generateTaskReport()
        let old = taskSummary
        taskSummary = []
        // [downloadTasks, packageTasks, unownedTasks]
        taskSummary.append(new[0].sorted(by: { (A, B) -> Bool in
            return false
        }))
        taskSummary.append(new[1].sorted(by: { (A, B) -> Bool in
            return A.name < B.name ? true : false
        }))
        taskSummary.append(new[2])
        return old
    }
    
    @objc
    func fastReloadNow() {
        NotificationCenter.default.post(name: .TaskNumberChanged, object: nil)
        let _ = self.buildTaskDataSource()
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    @objc func tryFireTasks() {
        runButton.puddingAnimate()
        
        let capture = TaskManager.shared.generatePackageTaskReport()
        if capture.count < 1 {
            let alert = UIAlertController(title: "Error".localized(), message: "InstallAgent_NoTaskAvailable".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
            present(alert, animated: true, completion: {
                TaskManager.shared.downloadEverything()
            })
        }
        
        for payload in capture where payload.value.0 == .pullupInstall || payload.value.0 == .selectInstall {
            if let url = payload.value.1.obtainDownloadLocationFromNewestVersion(),
                TaskManager.shared.downloadManager.getDownloadedFileLocation(withUrlStringAsKey: url.urlString) == nil {
                let alert = UIAlertController(title: "Error".localized(), message: "InstallAgent_DownloadNotFinished".localized(), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
                present(alert, animated: true, completion: {
                    TaskManager.shared.downloadEverything()
                })
                return
            }
        }
        
        let pop = InstallationAgent()
        pop.modalPresentationStyle = .formSheet;
        pop.modalTransitionStyle = .coverVertical;
        self.present(pop, animated: true, completion: nil)
        
    }
    
    @objc
    func cancelAllPackageTasks() {
        TaskManager.shared.cancelAllTasks()
    }

    private let tot = CommonThrottler(minimumDelay: 0.5)
    @objc
    func reloadWithThrottler() {
        tot.throttle {
            self.fastReloadNow()
        }
    }
}

extension SplitDetailTask: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3 + 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 || section == 4 {
            return 0
        }
        let capture = taskSummary
        
        let captureCount = capture.count
        let target = section - 1
        if captureCount <= target || target < 0 {
            return 0
        }
        
        let get = capture[target].count
        return get > 0 ? get : 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: TaskCell
        if let get = tableView.dequeueReusableCell(withIdentifier: "wiki.qaq.Protein.TaskCells", for: indexPath) as? TaskCell {
            cell = get
        } else {
            cell = TaskCell()
        }
        
        if indexPath.section == 0 {
            return cell
        }
        
        let capture = taskSummary
        
        let captureCount = capture.count
        let target = indexPath.section - 1
        if captureCount <= target || target < 0 {
            return cell
        }
        
        if capture[indexPath.section - 1].count > 0 {
            cell.setTask(task: taskSummary[indexPath.section - 1][indexPath.row])
            if indexPath.section == 3 {
                cell.hideButton()
            }
        } else {
            cell.setTask(task: nil)
            cell.noTaskAvail()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case 0:
            let container = UIView()
            container.backgroundColor = self.view.backgroundColor
            let label = UILabel()
            label.font = .systemFont(ofSize: 26, weight: .bold)
            label.text = "Tasks".localized()
            container.addSubview(label)
            label.snp.makeConstraints { (x) in
                x.left.equalToSuperview().offset(28)
                x.height.equalTo(60)
                x.bottom.equalToSuperview().offset(-10)
                x.width.equalTo(233)
            }
            return container
        case 1:
            let container = UIView()
            container.backgroundColor = self.view.backgroundColor
            let label = UILabel()
            label.font = .systemFont(ofSize: 22, weight: .semibold)
            label.text = "Download Tasks".localized()
            container.addSubview(label)
            label.snp.makeConstraints { (x) in
                x.left.equalToSuperview().offset(28)
                x.height.equalToSuperview()
                x.bottom.equalToSuperview()
                x.width.equalTo(233)
            }
            return container
        case 2:
            let container = UIView()
            container.backgroundColor = self.view.backgroundColor
            let label = UILabel()
            label.font = .systemFont(ofSize: 22, weight: .semibold)
            label.text = "Package Tasks".localized()
            container.addSubview(label)
            label.snp.makeConstraints { (x) in
                x.left.equalToSuperview().offset(28)
                x.height.equalToSuperview()
                x.bottom.equalToSuperview()
                x.width.equalTo(233)
            }
            let cancelAllButton = UIButton()
            cancelAllButton.setTitle("CancelAll".localized(), for: .normal)
            cancelAllButton.addTarget(self, action: #selector(cancelAllPackageTasks), for: .touchUpInside)
            cancelAllButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
            cancelAllButton.setTitleColor(UIColor(named: "DashNAV.DashboardSelectedColor"), for: .normal)
            cancelAllButton.setTitleColor(.black, for: .highlighted)
            container.addSubview(cancelAllButton)
            cancelAllButton.snp.makeConstraints { (x) in
                x.centerY.equalTo(label).offset(2)
                x.right.equalToSuperview().offset(-30)
            }
            return container
        case 3:
            let container = UIView()
            container.backgroundColor = self.view.backgroundColor
            let label = UILabel()
            label.font = .systemFont(ofSize: 22, weight: .semibold)
            label.text = "Other Tasks".localized()
            container.addSubview(label)
            label.snp.makeConstraints { (x) in
                x.left.equalToSuperview().offset(28)
                x.height.equalToSuperview()
                x.bottom.equalToSuperview()
                x.width.equalTo(233)
            }
            return container
        default:
            return UIView()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return 130
        case 1:
            return 80
        case 2:
            return 80
        case 3:
            return 80
        case 4:
            return 150
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 66
    }
        
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? TaskCell
        cell?.puddingAnimate()
        if let pkg = cell?.taskCache?.relatedObjects?["attach"] as? PackageStruct {
            let pop = PackageViewController()
            pop.PackageObject = pkg
            pop.modalPresentationStyle = .formSheet
            pop.modalTransitionStyle = .coverVertical
            cell?.obtainParentViewController?.present(pop, animated: true, completion: nil)
            return
        }
        if let pkg = cell?.taskCache?.relatedObjects?["attachString"] as? String {
            for lookup in PackageManager.shared.rawInstalled where lookup.identity == pkg {
                let pop = PackageViewController()
                pop.PackageObject = lookup
                pop.modalPresentationStyle = .formSheet
                pop.modalTransitionStyle = .coverVertical
                cell?.obtainParentViewController?.present(pop, animated: true, completion: nil)
                return
            }
            return
        }
    }
    
}

fileprivate class TaskCell: UITableViewCell {
    
    private let contaienr = UIView()
    private let activateIndicator = UIActivityIndicatorView()
    private let titleLab = UILabel()
    private let descLab = UILabel()
    private let iconView = UIImageView()
    private let progressLab = LTMorphingLabel()
    private let optionBtn = UIButton()
    private let dropDownAnchor = UIView()
    
    public var taskCache: TaskManager.Task?
    public var isPlaceHolderAsHint = true
    
    private var urlAsKeyIfIsDownloadTask: String? = nil
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        addSubview(contaienr)
        contaienr.addSubview(activateIndicator)
        contaienr.addSubview(titleLab)
        contaienr.addSubview(descLab)
        contaienr.addSubview(iconView)
        contaienr.addSubview(progressLab)
        contaienr.addSubview(optionBtn)
        contaienr.addSubview(dropDownAnchor)
        
        selectionStyle = .none
        
        backgroundColor = .clear
        
        contaienr.snp.makeConstraints { (x) in
            x.edges.equalToSuperview()
        }
        
        activateIndicator.snp.makeConstraints { (x) in
            x.centerY.equalToSuperview()
            x.left.equalToSuperview().offset(20)
        }
        
        iconView.layer.cornerRadius = 8
        iconView.clipsToBounds = true
        iconView.contentMode = .scaleAspectFill
        iconView.snp.makeConstraints { (x) in
            x.centerY.equalToSuperview()
            x.left.equalTo(activateIndicator.snp.right).offset(14)
            x.width.equalTo(32)
            x.height.equalTo(32)
        }
        
        titleLab.font = .boldSystemFont(ofSize: 18)
        titleLab.clipsToBounds = false
        titleLab.textColor = UIColor(named: "RepoTableViewCell.Text")
        titleLab.snp.makeConstraints { (x) in
            x.left.equalTo(iconView.snp.right).offset(14)
            x.top.equalTo(iconView.snp.top).offset(-6)
            x.height.equalTo(26)
            x.right.equalTo(self.optionBtn.snp.left).offset(-8)
        }
        
        descLab.font = .boldSystemFont(ofSize: 12)
        descLab.clipsToBounds = false
        descLab.clipsToBounds = false
        descLab.textColor = UIColor(named: "RepoTableViewCell.SubText")
        descLab.snp.makeConstraints { (x) in
            x.left.equalTo(iconView.snp.right).offset(14)
            x.top.equalTo(titleLab.snp.bottom).offset(4)
            x.right.equalTo(self.optionBtn.snp.left).offset(-8)
        }
        
        optionBtn.setTitle("...", for: .normal)
        optionBtn.titleLabel?.font = .systemFont(ofSize: 14, weight: .black)
        optionBtn.setTitleColor(UIColor(named: "DashNAV.TaskSelectedColor"), for: .normal)
        optionBtn.addTarget(self, action: #selector(optionPressed), for: .touchUpInside)
        optionBtn.snp.makeConstraints { (x) in
            x.centerY.equalToSuperview()
            x.right.equalToSuperview().offset(-18)
            x.width.equalTo(60)
            x.height.equalTo(40)
        }
        
        dropDownAnchor.snp.makeConstraints { (x) in
            x.right.equalToSuperview().offset(-28)
            x.width.equalTo(233)
            x.height.equalTo(1)
            x.top.equalTo(self.optionBtn.snp.bottom).offset(8)
        }
        
        progressLab.textAlignment = .right
        progressLab.morphingEffect = .evaporate
        progressLab.font = UIFont.roundedFont(ofSize: 18, weight: .bold).monospacedDigitFont
        progressLab.clipsToBounds = false
        progressLab.textColor = UIColor(named: "RepoTableViewCell.SubText")
        progressLab.snp.makeConstraints { (x) in
            x.centerY.equalToSuperview()
            x.right.equalTo(optionBtn.snp.left).offset(-18)
            x.width.equalTo(120)
            x.height.equalTo(44)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(downloadProgressUpdated), name: .DownloadProgressUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadCompleteCall), name: .DownloadFinished, object: nil)
        
    }
    
    func setTask(task: TaskManager.Task?) {
        if let task = task {
            if taskCache == task {
                return
            }
            taskCache = task
            optionBtn.isHidden = false
            isPlaceHolderAsHint = false
            iconView.isHidden = false
            iconView.snp.updateConstraints { (x) in
                x.width.equalTo(32)
            }
            titleLab.text = task.name
            descLab.text = task.description
            
            if task.status == .activated {
                activateIndicator.startAnimating()
                activateIndicator.snp.updateConstraints { (x) in
                    x.left.equalToSuperview().offset(12)
                }
            } else {
                activateIndicator.snp.updateConstraints { (x) in
                    x.left.equalToSuperview().offset(0)
                }
            }
            
            if let taskMeta = task.relatedObjects {
                if let icon = taskMeta["icon"] as? UIImage {
                    iconView.image = icon
                } else if let url = taskMeta["iconlink"] as? URL, let image = SDImageCache.shared.imageFromCache(forKey: url.absoluteString) {
                    iconView.image = image
                } else {
                    iconView.image = UIImage(named: "task")
                }
                if let progress = taskMeta["progress"] as? Double {
                    let str = String(Int(progress * 100)) + "%"
                    progressLab.text = str
                }
            } else {
                iconView.image = UIImage(named: "task")
            }
            
            if task.type == .packageTask {
                iconView.image = UIImage(named: "mod")
                if let package = task.relatedObjects?["attach"] as? PackageStruct {
                    let promise = package.obtainIconIfExists()
                    if let img = promise.1 {
                        iconView.image = img
                    } else if let link = URL(string: promise.0 ?? ""),
                        let image = SDImageCache.shared.imageFromCache(forKey: link.absoluteString) {
                        iconView.image = image
                    }
                } else if let type = task.relatedObjects?["type"] as? TaskManager.PackageTaskType,
                    type == .selectDelete || type == .pullupDelete {
                    iconView.image = UIImage(named: "delete")
                }
            }
            
            if task.type == .downloadTask {
                iconView.image = UIImage(named: "download")
            }
            
            // test if download completed
            downloadCompleteCall()
        } else {
            iconView.image = nil
            activateIndicator.stopAnimating()
            titleLab.text = ""
            descLab.text = ""
            optionBtn.isHidden = false
            iconView.snp.updateConstraints { (x) in
                x.width.equalTo(0)
            }
            activateIndicator.snp.updateConstraints { (x) in
                x.left.equalToSuperview().offset(-10)
            }
            downloadProgressUpdated()
        }
        
        
    }
    
    func noTaskAvail() {
        taskCache = nil
        optionBtn.isHidden = true
        iconView.isHidden = true
        iconView.snp.updateConstraints { (x) in
            x.width.equalTo(0)
        }
        activateIndicator.snp.updateConstraints { (x) in
            x.left.equalToSuperview().offset(-10)
        }
        activateIndicator.stopAnimating()
        titleLab.text = "NoTaskAvailable".localized()
        descLab.text = "NoTaskAvailableTint".localized()
        progressLab.text = ""
        isPlaceHolderAsHint = true
    }
    
    @objc
    func optionPressed() {
        let dropDown = DropDown()
        var actionSource = ["Cancel"]
        var cntUrl: URL? = nil
        if let task = taskCache, task.type == .packageTask,
        let ttype = task.relatedObjects?["type"] as? TaskManager.PackageTaskType, ttype == .pullupInstall || ttype == .selectInstall,
        let pkg = task.relatedObjects?["attach"] as? PackageStruct, let url = pkg.obtainDownloadLocationFromNewestVersion() {
            if TaskManager.shared.downloadManager.doesDownloadEverBroken(urlAsKey: url.urlString) {
                cntUrl = url
                actionSource.append("Continue")
            }
        }
        dropDown.dataSource = actionSource.map({ (str) -> String in
            return "   " + str.localized()
        })
        dropDown.anchorView = self.dropDownAnchor
        dropDown.direction = .bottom
        dropDown.selectionAction = { [unowned self] (index: Int, _: String) in
            let item = actionSource[index]
            switch item {
            case "Cancel":
                if self.taskCache?.type == .downloadTask {
                    if let url = self.taskCache?.relatedObjects?["url"] as? String {
                        TaskManager.shared.downloadManager.cancelDownload(withUrlAsKey: url)
                    } else if let url = self.taskCache?.relatedObjects?["url"] as? URL {
                        TaskManager.shared.downloadManager.cancelDownload(withUrlAsKey: url.urlString)
                    }
                } else {
                    if let package = self.taskCache?.relatedObjects?["attach"] as? PackageStruct {
                        let ret = TaskManager.shared.removeQueuedPackage(withIdentity: [package.identity])
                        if !ret.didSuccess {
                            let alert = UIAlertController(title: "Error".localized(),
                                                          message: "PackageOperation_OperationInvalid".localized(),
                                                          preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
                            self.obtainParentViewController?.present(alert, animated: true, completion: nil)
                        }
                    } else if let identity = self.taskCache?.relatedObjects?["attachString"] as? String {
                        let ret = TaskManager.shared.removeQueuedPackage(withIdentity: [identity])
                        if !ret.didSuccess {
                            let alert = UIAlertController(title: "Error".localized(),
                                                          message: "PackageOperation_OperationInvalid".localized(),
                                                          preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
                            self.obtainParentViewController?.present(alert, animated: true, completion: nil)
                        }
                    } else {
                        let alert = UIAlertController(title: "Error".localized(),
                                                      message: "PackageOperation_OperationInvalid".localized(),
                                                      preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
                        self.obtainParentViewController?.present(alert, animated: true, completion: nil)
                    }
                }
            case "Continue":
                if let url = cntUrl {
                    TaskManager.shared.downloadPackageWith(urlAsKey: url.urlString)
                }
            default:
                print("[TaskManager] Operation not understood: " + item)
            }
        }
        dropDown.show(onTopOf: self.window)
    }
    
    @objc
    func downloadProgressUpdated(object: Notification? = nil) {
        if let url = (taskCache?.relatedObjects?["url"] as? URL)?.urlString,
            let urlString = object?.userInfo?["key"] as? String, url == urlString,
            let progress = object?.userInfo?["progress"] as? Float {
            let userFriendlyProgress = String(Int(progress * 100)) + " %"
            DispatchQueue.main.async {
                self.progressLab.text = userFriendlyProgress
            }
        } else if let task = taskCache, task.type == .downloadTask,
            let url = task.relatedObjects?["url"] as? String,
            let prog = TaskManager.shared.downloadManager.reportProgressOn(urlAsKey: url) {
            DispatchQueue.main.async {
                let userFriendlyProgress = String(Int(prog * 100)) + " %"
                self.progressLab.text = userFriendlyProgress
            }
        } else if !downloadCheckIsDownloaded() {
            DispatchQueue.main.async {
                self.progressLab.text = ""
            }
        }
    }
    
    func hideButton() {
        optionBtn.isHidden = true
    }
    
    @objc
    func downloadCompleteCall() {
        let _ = downloadCheckIsDownloaded()
    }
    
    private func downloadCheckIsDownloaded() -> Bool {
        if let task = taskCache, task.type == .packageTask,
            let ttype = task.relatedObjects?["type"] as? TaskManager.PackageTaskType, ttype == .pullupInstall || ttype == .selectInstall,
            let pkg = task.relatedObjects?["attach"] as? PackageStruct, let url = pkg.obtainDownloadLocationFromNewestVersion() {
            if TaskManager.shared.downloadManager.getDownloadedFileLocation(withUrlStringAsKey: url.urlString) != nil {
                DispatchQueue.main.async {
                    self.progressLab.text = "Downloaded".localized()
                }
                return true
            } else if TaskManager.shared.downloadManager.doesDownloadEverFailed(urlAsKey: url.urlString) {
                DispatchQueue.main.async {
                    self.progressLab.text = "Failed".localized()
                }
            } else if TaskManager.shared.downloadManager.doesDownloadEverBroken(urlAsKey: url.urlString) {
                DispatchQueue.main.async {
                    self.progressLab.text = "Suspended".localized()
                }
            }
            
        }
        return false
    }
    
}
