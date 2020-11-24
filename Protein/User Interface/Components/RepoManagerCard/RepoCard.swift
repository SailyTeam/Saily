//
//  RepoCard.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/18.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit
import SDWebImage
import JGProgressHUD

class RepoCard: UIView {
    
    static var lock: Bool = false
    static let lockQueue = DispatchQueue(label: "wiki.qaq.Protein.RepoCard.lock")
    
    private let id = UUID().uuidString
    
    private var didUpdateLayouts: () -> () = {}
    func afterLayoutUpdate(_ hi: @escaping () -> ()) { didUpdateLayouts = hi }
    
    private let box = UIView()
    
    private var rowNumberCache = 0
    
    private let btnCoverAdd = UIImageView(image: UIImage(named: "RepoCard.Add"))
    private let btnCoverScan = UIImageView(image: UIImage(named: "RepoCard.ScanQR"))
    private let btnCoverRefresh = UIImageView(image: UIImage(named: "RepoCard.Refresh"))
    private let btnCoverShare = UIImageView(image: UIImage(named: "RepoCard.Share"))
    private let btnCoverHelp = UIImageView(image: UIImage(named: "RepoCard.Info"))
    private let buttonAdd = UIButton()
    private let buttonScan = UIButton()
    private let buttonRefresh = UIButton()
    private let buttonShare = UIButton()
    private let buttonHelp = UIButton()
    
    private let tableView = UITableView()
    private let cellidentity = "wiki.qaq.RepoCard.tableView.cellidentity"
    private let cellHeight: CGFloat = 52
    
    private let detailPushAsFormSheet: Bool
    
    func repoCount() -> Int { return RepoManager.shared.repos.count }
    
    public var suggestHeight: CGFloat {
        get {
            return repoCount() < 1 ? cellHeight + 100 : CGFloat(repoCount() * Int(cellHeight) + 100)
        }
    }   // get
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    required init(pushAsFormSheet: Bool = true) {
        
        detailPushAsFormSheet = pushAsFormSheet
        
        super.init(frame: CGRect())
        
        addSubview(box)
        addSubview(btnCoverAdd)
        addSubview(btnCoverScan)
        addSubview(btnCoverRefresh)
        addSubview(btnCoverShare)
        addSubview(btnCoverHelp)
        addSubview(buttonAdd)
        addSubview(buttonScan)
        addSubview(buttonRefresh)
        addSubview(buttonShare)
        addSubview(buttonHelp)

        box.backgroundColor = UIColor(named: "RepoCard.Background")
//        box.dropShadow()  // Follow Google Design
        box.layer.cornerRadius = 14
        box.snp.makeConstraints { (x) in
            x.left.equalTo(self.snp.left)
            x.right.equalTo(self.snp.right)
            x.bottom.equalTo(self.snp.bottom)
            x.top.equalTo(self.snp.top).offset(22)
        }
        
        btnCoverAdd.contentMode = .scaleAspectFit
        btnCoverScan.contentMode = .scaleAspectFit
        btnCoverRefresh.contentMode = .scaleAspectFit
        btnCoverShare.contentMode = .scaleAspectFit
        btnCoverHelp.contentMode = .scaleAspectFit
        
//        btnCoverAdd.dropShadow(ofColor: btnCoverAdd.image!.areaAverage(), opacity: 0.233)
//        btnCoverScan.dropShadow(ofColor: btnCoverScan.image!.areaAverage(), opacity: 0.233)
//        btnCoverRefresh.dropShadow(ofColor: btnCoverRefresh.image!.areaAverage(), opacity: 0.233)
//        btnCoverShare.dropShadow(ofColor: btnCoverShare.image!.areaAverage(), opacity: 0.233)
//        btnCoverHelp.dropShadow(ofColor: btnCoverHelp.image!.areaAverage(), opacity: 0.2)

        let size = 38
        let gap = 15
        
        btnCoverAdd.snp.makeConstraints { (x) in
            x.centerY.equalTo(box.snp.top)
            x.left.equalTo(box.snp.left).offset(15)
            x.width.equalTo(size)
            x.height.equalTo(size)
        }
        btnCoverScan.snp.makeConstraints { (x) in
            x.centerY.equalTo(box.snp.top)
            x.left.equalTo(btnCoverAdd.snp.right).offset(gap)
            x.width.equalTo(size)
            x.height.equalTo(size)
        }
        btnCoverRefresh.snp.makeConstraints { (x) in
            x.centerY.equalTo(box.snp.top)
            x.left.equalTo(btnCoverScan.snp.right).offset(gap)
            x.width.equalTo(size)
            x.height.equalTo(size)
        }
        btnCoverShare.snp.makeConstraints { (x) in
            x.centerY.equalTo(box.snp.top)
            x.left.equalTo(btnCoverRefresh.snp.right).offset(gap)
            x.width.equalTo(size)
            x.height.equalTo(size)
        }
        btnCoverHelp.snp.makeConstraints { (x) in
            x.right.equalTo(box.snp.right).offset(0)
            x.top.equalTo(box.snp.top).offset(0)
            x.width.equalTo(Double(size) / 1.344)
            x.height.equalTo(Double(size) / 1.344)
        }
        buttonAdd.snp.makeConstraints { (x) in
            x.edges.equalTo(btnCoverAdd.snp.edges)
        }
        buttonScan.snp.makeConstraints { (x) in
            x.edges.equalTo(btnCoverScan.snp.edges)
        }
        buttonRefresh.snp.makeConstraints { (x) in
            x.edges.equalTo(btnCoverRefresh.snp.edges)
        }
        buttonShare.snp.makeConstraints { (x) in
            x.edges.equalTo(btnCoverShare.snp.edges)
        }
        buttonHelp.snp.makeConstraints { (x) in
            x.edges.equalTo(btnCoverHelp.snp.edges)
        }
        
        buttonAdd.addTarget(self, action: #selector(eventEmitterAdd), for: .touchUpInside)
        buttonScan.addTarget(self, action: #selector(eventEmitterScan), for: .touchUpInside)
        buttonRefresh.addTarget(self, action: #selector(eventEmitterRefresh(shouldBeSmartUpdate:)), for: .touchUpInside)
        buttonShare.addTarget(self, action: #selector(eventEmitterShare), for: .touchUpInside)
        buttonHelp.addTarget(self, action: #selector(eventEmitterHelp), for: .touchUpInside)
        
        addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(RepoTableViewCell.self, forCellReuseIdentifier: cellidentity)
        tableView.isScrollEnabled = false
//        let height = repoCount < 1 ? 45 : repoCount * 45
        tableView.snp.makeConstraints { (x) in
//            x.height.equalTo(height)
            x.top.equalTo(btnCoverAdd.snp.bottom).offset(30)
            x.bottom.equalTo(box.snp.bottom).offset(-8)
            x.left.equalTo(box.snp.left).offset(8)
            x.right.equalTo(box.snp.right).offset(-8)
        }
     
        NotificationCenter.default.addObserver(self, selector: #selector(eventEmitterReload), name: .RepoStoreUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(eventEmitterReload), name: .RepoManagerUpdatedAllMeta, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(eventEmitterDeleteRowAtIndex(object:)), name: .RepoCardAttemptToDeleteCell, object: nil)
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}

// MARK: Button Touches Events

extension RepoCard {
    
    @objc
    func eventEmitterDeleteRowAtIndex(object: Notification? = nil) {
        DispatchQueue.global(qos: .background).async {
            if let object = object, let info = object.userInfo, let urlString = info["attach"] as? String, let notifyID = info["id"] as? String, RepoManager.shared.repos.count == self.rowNumberCache - 1, self.rowNumberCache > 1 {
                if notifyID == self.id {
                    return
                }
                DispatchQueue.main.async {
                    self.tableView.setEditing(false, animated: true)
                    var cellLookup: IndexPath?
                    lookup0: for index in 0..<self.rowNumberCache {
                        let ip = IndexPath(row: index, section: 0)
                        if let get = self.tableView.cellForRow(at: ip) as? RepoTableViewCell,
                            get.urlStringRef == urlString {
                            cellLookup = ip
                            break lookup0
                        }
                    }
                    if let ip = cellLookup {
                        self.tableView.deleteRows(at: [ip], with: .left)
                    }
                }
                return
            }
            // failed to lookup
            self.eventEmitterReload()
        }
    }
    
    @objc
    func eventEmitterReload() {
        DispatchQueue.global(qos: .background).async {
            DispatchQueue.main.async {
                if !self.tableView.isEditing {
                    self.tableView.reloadData()
                    self.didUpdateLayouts()
                } else {
                    if RepoManager.shared.repos.count != self.tableView.numberOfRows(inSection: 0) {
                        self.tableView.setEditing(false, animated: true)
                        self.tableView.reloadData()
                        self.didUpdateLayouts()
                    }
                }
            }
        }
    }
    
    @objc
    func eventEmitterAdd(){
        btnCoverAdd.shineAnimation()
        let pop = RepoAddViewController()
        if detailPushAsFormSheet {
            pop.modalPresentationStyle = .formSheet
            pop.modalTransitionStyle = .coverVertical
            self.obtainParentViewController?.present(pop, animated: true, completion: nil)
        } else {
            pop.useNavigationBar = true
            self.obtainParentViewController?.navigationController?.pushViewController(pop)
        }
    }
    
    @objc
    func eventEmitterScan() {
        btnCoverScan.shineAnimation()
//        let alert = UIAlertController(title: "Error".localized(), message: "Scan QR code is not available in this beta", preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "Confirm".localized(), style: .default, handler: { (_) in
//
//        }))
//        self.obtainParentViewController?.present(alert, animated: true, completion: nil)
        
        
        let pop = QRScanViewController()
        pop.modalPresentationStyle = .formSheet
        pop.modalTransitionStyle = .coverVertical
        if detailPushAsFormSheet {
            pop.modalPresentationStyle = .formSheet
            pop.modalTransitionStyle = .coverVertical
            self.obtainParentViewController?.present(pop, animated: true, completion: nil)
        } else {
            self.obtainParentViewController?.navigationController?.pushViewController(pop)
        }
    }
    
    @objc //  0 = refresh everything if all updated, 1 = force smart update, -1 = force everything
    func eventEmitterRefresh(shouldBeSmartUpdate: Int = 0) {
        btnCoverRefresh.shineAnimation()
        switch shouldBeSmartUpdate {
        case 1:
            let _ = RepoManager.shared.sendToSmartUpdateRepo()
        case -1:
            RepoManager.shared.sendEverythingToUpdate()
        case 0:
            fallthrough
        default:
            let ret = RepoManager.shared.sendToSmartUpdateRepo()
            if !ret {
                RepoManager.shared.sendEverythingToUpdate()
            }
        }
    }
    
    @objc
    func eventEmitterShare() {
        btnCoverShare.shineAnimation()
        let copy = RepoManager.shared.repos
        var shareText = ""
        copy.forEach { (item) in
            shareText.append(item.url.urlString)
            shareText.append("\n")
        }
        shareText.share(fromView: self.obtainParentViewController?.view)
    }
    
    @objc
    func eventEmitterHelp() {
        btnCoverHelp.shineAnimation()
//        guard let url = URL(string: DEFINE.WEB_LOCATION_DOCS) else {
//          return
//        }
//        if #available(iOS 10.0, *) {
//            UIApplication.shared.open(url, options: [:], completionHandler: nil)
//        } else {
//            UIApplication.shared.openURL(url)
//        }
        let pop = RamLogViewer()
        if detailPushAsFormSheet {
            pop.modalPresentationStyle = .formSheet
            pop.modalTransitionStyle = .coverVertical
            self.obtainParentViewController?.present(pop, animated: true, completion: nil)
        } else {
            self.obtainParentViewController?.navigationController?.pushViewController(pop)
        }
    }
    
}

// MARK: TABLE VIEW
extension RepoCard: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let get = repoCount() < 1 ? 1 : repoCount()
        rowNumberCache = get
        return get
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let get = (tableView.dequeueReusableCell(withIdentifier: cellidentity, for: indexPath) as? RepoTableViewCell) ?? RepoTableViewCell()
        
        tableView.separatorColor = .clear   // dont know who changed my color
        tableView.backgroundColor = .clear
        
        if repoCount() < 1 {
            get.name.text = "RepoCard_NoRepo".localized()
            get.url.text = "RepoCard_AddInstruction".localized()
            get.updateStatus.text = "RepoCard_AddInstructionHint".localized()
            get.icon.image = UIImage(named: "RepoCard.Tea")
            get.urlStringRef = ""
        } else {
            let repos = RepoManager.shared.repos
            get.urlStringRef = ""
            get.name.text = ""
            get.url.text = ""
            get.updateStatus.text = ""
            if indexPath.row < 0 || indexPath.row >= repos.count {
                return get
            }
            let repo = repos[indexPath.row]
            get.urlStringRef = repo.url.urlString
            get.name.text = repo.obtainPossibleName()
            get.url.text = repo.url.urlString
            
            let image = UIImage(data: repo.icon)
            get.icon.sd_setImage(with: URL(string: repo.obtainIconLink()),
                                 placeholderImage: image) { (img, err, _, _) in
            }
            get.updateStatusLabelUnconditionally()
        }
        
        return get
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let view = tableView.cellForRow(at: indexPath) {
            view.puddingAnimate()
        }
        if repoCount() < 1 {
            eventEmitterAdd()
            return
        }
        
        
        let repos = RepoManager.shared.repos
        if repos.count > indexPath.row && indexPath.row >= 0 {
            let repo = repos[indexPath.row]
            let pop = RepoViewController(withRepo: repo)
            pop.modalPresentationStyle = .formSheet;
            pop.modalTransitionStyle = .coverVertical;
            
            var hud: JGProgressHUD?
            if let view = self.obtainParentViewController?.view {
                if self.traitCollection.userInterfaceStyle == .dark {
                    hud = .init(style: .dark)
                } else {
                    hud = .init(style: .light)
                }
                hud?.textLabel.text = "WaitingForDataBase".localized()
                hud?.show(in: view)
            }
            DispatchQueue.main.async {
                if let vc = self.obtainParentViewController {
                    vc.present(pop, animated: true) {
                        hud?.dismiss()
                    }
                } else {
                    self.window?.rootViewController?.present(pop, animated: true) {
                        hud?.dismiss()
                    }
                }
            }
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if RepoManager.shared.repos.count < 1 {
            return nil
        }
        let deleteItem = UIContextualAction(style: .destructive, title: "Delete".localized()) {  (_, _, _) in
            let repos = RepoManager.shared.repos
            if indexPath.row < 0 || indexPath.row >= repos.count || RepoCard.lock {
                tableView.setEditing(false, animated: true)
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Warning".localized(), message: "OperationLocked".localized(), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Confirm".localized(), style: .default, handler: nil))
                    self.obtainParentViewController?.present(alert, animated: true, completion: nil)
                }
                return
            }
            RepoCard.lock = true
            var hud: JGProgressHUD?
            if let view = self.obtainParentViewController?.view {
                if self.traitCollection.userInterfaceStyle == .dark {
                    hud = .init(style: .dark)
                } else {
                    hud = .init(style: .light)
                }
                hud?.textLabel.text = "WaitingForDataBase".localized()
                hud?.show(in: view)
            }
                        
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let repo = repos[indexPath.row]
                tableView.isUserInteractionEnabled = false
                DispatchQueue.global(qos: .background).async {
                    RepoManager.shared.saveHistory(repo.url)
                    RepoManager.shared.deleteFromDataBase(repo.url, andSync: false)
                    DispatchQueue.main.async {
                        tableView.setEditing(false, animated: true)
                        // ALREADY RELOADED FROM NOTIFICATION
                        var sentDelteNotification = false
                        if repos.count > 1 {
                            if RepoManager.shared.repos.count == self.rowNumberCache - 1 {
                                tableView.deleteRows(at: [indexPath], with: .automatic)
                                sentDelteNotification = true
                                DispatchQueue.global(qos: .background).async {
                                    NotificationCenter.default.post(name: .RepoCardAttemptToDeleteCell, object: nil, userInfo: ["attach" : repo.url.urlString, "id" : self.id])
                                    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.6) {
                                        NotificationCenter.default.post(name: .RepoStoreUpdated, object: nil)
                                    }
                                }
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.tableView.reloadData()
                            self.tableView.isUserInteractionEnabled = true
                            if hud != nil {
                                hud?.dismiss()
                            }
                            DispatchQueue.global(qos: .background).async {
                                self.eventEmitterRefresh(shouldBeSmartUpdate: 1)
                                if !sentDelteNotification {
                                    NotificationCenter.default.post(name: .RepoStoreUpdated, object: nil)
                                }
                                RepoCard.lock = false
                            }
                        }
                    }
                }
                
            }
            
        }
        deleteItem.backgroundColor = UIColor(hex: 0xFA685C)
        let reloadItem = UIContextualAction(style: .normal, title: "Refresh".localized()) {  (_, _, _) in
            let repos = RepoManager.shared.repos
            if indexPath.row < 0 || indexPath.row >= repos.count {
                tableView.setEditing(false, animated: true)
                return
            }
            let repo = repos[indexPath.row]
            RepoManager.shared.sendToUpdateQueue(withURL: [repo.url])
            tableView.setEditing(false, animated: true)
        }
        reloadItem.backgroundColor = UIColor(hex: 0x7A95DF)
        return UISwipeActionsConfiguration(actions: [reloadItem, deleteItem])
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let copyItem = UIContextualAction(style: .normal, title: "Share".localized()) {  (_, _, _) in
            let repos = RepoManager.shared.repos
            if indexPath.row < 0 || indexPath.row >= repos.count {
                tableView.setEditing(false, animated: true)
                return
            }
            repos[indexPath.row].url.urlString.share(fromView: tableView.cellForRow(at: indexPath))
            tableView.setEditing(false, animated: true)
        }
        copyItem.backgroundColor = UIColor(hex: 0xBA82D0)
        return UISwipeActionsConfiguration(actions: [copyItem])
    }
    
    func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        RepoTableViewCell.updateLock = true
    }
    
    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        RepoTableViewCell.updateLock = false
        NotificationCenter.default.post(name: .RepoManagerUpdatedAllMeta, object: nil)
    }
}
