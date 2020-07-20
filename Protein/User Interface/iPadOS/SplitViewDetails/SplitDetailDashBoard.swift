//
//  SplitDetailDashBoard.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/20.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit
import JGProgressHUD

class SplitDetailDashBoardNAV: UINavigationController {

    let context: UIViewController = SplitDetailDashBoard()

    var assignedDashCard: DashNavCard?

    init() {
        super.init(nibName: nil, bundle: nil)
        preferredContentSize = CGSize(width: 700, height: 555)
        viewControllers = [context]
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

}

fileprivate class SplitDetailDashBoard: UIViewController {

    var assignedTo: UIViewController?

    private let cellHeadGap: CGFloat = 14
    private var container: UIScrollView = UIScrollView()
    private var tableView: UITableView = UITableView()
    private let CellID: String = "wiki.qaq.Protein.SplitDetailDashBoard.CellID-" + UUID().uuidString
    private let bottom = UIView()

    private let searchBar = SearchBar()
    private let sectionWish = WishListView()
    private let sectionUpdate = NowUpdateView()
    private let sectionInstall = RecentInstalledView()
    private let sectionRecentUpdate = RecentUpdatesView()

    deinit {
        print("[ARC] SplitDetailDashBoard has been deinited")
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        preferredContentSize = CGSize(width: 700, height: 555)
        view.backgroundColor = UIColor(named: "SplitDetail-G-Background")

        container.backgroundColor = .clear
        container.showsVerticalScrollIndicator = false
        container.showsHorizontalScrollIndicator = false
        container.decelerationRate = .fast
        container.alwaysBounceVertical = true
        view.addSubview(container)
        container.snp.makeConstraints { (x) in
            x.top.equalTo(self.view.snp.top)
            x.bottom.equalTo(self.view.snp.bottom)
            x.left.equalTo(self.view.snp.left).offset(20)
            x.right.equalTo(self.view.snp.right).offset(-20)
        }

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: CellID)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.isScrollEnabled = false
        tableView.separatorColor = .clear
        tableView.backgroundColor = .clear
        tableView.allowsSelection = false
        container.addSubview(tableView)
        tableView.snp.makeConstraints { (x) in
            x.top.equalToSuperview()
            x.left.equalTo(self.view.snp.left).offset(20)
            x.right.equalTo(self.view.snp.right).offset(-20)
            x.height.equalTo(888)
        }

        container.addSubview(bottom)
        bottom.snp.makeConstraints { (x) in
            x.top.equalTo(tableView.snp.bottom)
            x.height.equalTo(88)
            x.left.equalTo(self.view.snp.left)
            x.right.equalTo(self.view.snp.right)
        }

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tableViewTapped(recognizer:)))
        tableView.addGestureRecognizer(tapGestureRecognizer)

        let kilakila = UIActivityIndicatorView()
        kilakila.startAnimating()
        kilakila.alpha = 0
        view.addSubview(kilakila)
        
        DispatchQueue.main.async {
            kilakila.alpha = 1
            kilakila.snp.makeConstraints { (x) in
                x.center.equalTo(self.view.center)
            }
        }
        
        tableView.alpha = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UIView.animate(withDuration: 0.5, animations: {
                self.tableView.alpha = 1
                kilakila.alpha = 0
            }) { (_) in
                kilakila.isHidden = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.updateContainerHeight()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateContainerHeight), name: .WishListShouldLayout, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateContainerHeight), name: .UpdateCandidateShouldLayout, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateContainerHeight), name: .RecentUpdateShouldLayout, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateContainerHeight), name: .InstalledShouldLayout, object: nil)

    }

    @objc func tableViewTapped(recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: self.tableView)
        if let indexPath = self.tableView.indexPathForRow(at: location) {
            if let cell = tableView.cellForRow(at: indexPath) {
                var locationInCell = recognizer.location(in: cell)
                locationInCell.y -= cellHeadGap
                switch indexPath.row {
                case 0:
                    searchBar.puddingAnimate()
                    var hud: JGProgressHUD?
                    if let view = self.parent?.view {
                        if self.traitCollection.userInterfaceStyle == .dark {
                            hud = .init(style: .dark)
                        } else {
                            hud = .init(style: .light)
                        }
                        hud?.textLabel.text = "IndexInProgress".localized()
                        hud?.show(in: view)
                    }
                    DispatchQueue.global(qos: .background).async {
                        SearchIndexManager.shared.waitUntilIndexingFinished()
                        DispatchQueue.main.async {
                            hud?.dismiss()
                            let vc = SearchViewController()
                            self.navigationController?.pushViewController(vc, animated: true)
                        }
                    }

                case 2:
                    sectionUpdate.touches(at: locationInCell)
                case 3:
                    sectionWish.touches(at: locationInCell)
                case 4:
                    sectionInstall.touches(at: locationInCell)
                case 5:
                    sectionRecentUpdate.touches(at: locationInCell)
                default:
                    do { }
                }

            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    @objc func updateContainerHeight() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.tableView.beginUpdates()
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
                self.tableView.endUpdates()
                var calc: CGFloat = 0
                let obt = self.obtainHeightForEachRow()
                obt.forEach { (i) in
                    calc += i
                }
                self.tableView.snp.updateConstraints { (x) in
                    x.height.equalTo(calc)
                }
                self.tableView.layoutSubviews()
            }) { (_) in
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
                }) { (_) in
                    self.container.contentSize.height = self.bottom.center.y
                }
            }
        }
    }

}

extension SplitDetailDashBoard: UITableViewDelegate, UITableViewDataSource {

    // 搜索条 入门 最近通知 候选更新 心愿单 最近更新

    func obtainHeightForEachRow() -> [CGFloat] {
        var ret = [100, 0,
                   sectionUpdate.suggestedHeight + 72,
                   sectionWish.suggestedHeight + 72,
                   sectionInstall.suggestedHeight + 72,
                   sectionRecentUpdate.suggestedHeight + 72]
        
        if sectionUpdate.shouldHide {
            ret[2] = 0
        }
        if sectionWish.shouldHide {
            ret[3] = 0
        }
        if sectionInstall.shouldHide {
            ret[4] = 0
        }
        if sectionRecentUpdate.shouldHide {
            ret[5] = 0
        }
        return ret
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellID, for: indexPath)
        
        cell.backgroundColor = .clear
        cell.contentView.clipsToBounds = true
        cell.selectionStyle = .none
        
        switch indexPath.row {
        case 0:
            cell.contentView.subviews.forEach { (view) in
                view.removeFromSuperview()
            }
            cell.contentView.addSubview(searchBar)
            searchBar.snp.makeConstraints { (x) in
                x.left.equalTo(cell.contentView.snp.left)
                x.right.equalTo(cell.contentView.snp.right)
                x.centerY.equalTo(cell.contentView.snp.centerY)
                x.height.equalTo(45)
            }
            searchBar.isUserInteractionEnabled = false
        case 2:
            cell.contentView.subviews.forEach { (view) in
                view.removeFromSuperview()
            }
            cell.contentView.addSubview(sectionUpdate)
            sectionUpdate.snp.makeConstraints { (x) in
                x.left.equalTo(cell.contentView.snp.left)
                x.right.equalTo(cell.contentView.snp.right)
                x.top.equalTo(cell.contentView.snp.top).offset(cellHeadGap)
                x.height.equalTo(sectionUpdate.suggestedHeight)
            }
        case 3:
            cell.contentView.subviews.forEach { (view) in
                view.removeFromSuperview()
            }
            cell.contentView.addSubview(sectionWish)
            sectionWish.snp.makeConstraints { (x) in
                x.left.equalTo(cell.contentView.snp.left)
                x.right.equalTo(cell.contentView.snp.right)
                x.top.equalTo(cell.contentView.snp.top).offset(cellHeadGap)
                x.height.equalTo(sectionWish.suggestedHeight)
            }
        case 4:
            cell.contentView.subviews.forEach { (view) in
                view.removeFromSuperview()
            }
            cell.contentView.addSubview(sectionInstall)
            sectionInstall.snp.makeConstraints { (x) in
                x.left.equalTo(cell.contentView.snp.left)
                x.right.equalTo(cell.contentView.snp.right)
                x.top.equalTo(cell.contentView.snp.top).offset(cellHeadGap)
                x.height.equalTo(sectionInstall.suggestedHeight)
            }
        case 5:
            cell.contentView.subviews.forEach { (view) in
                view.removeFromSuperview()
            }
            cell.contentView.addSubview(sectionRecentUpdate)
            sectionRecentUpdate.snp.makeConstraints { (x) in
                x.left.equalTo(cell.contentView.snp.left)
                x.right.equalTo(cell.contentView.snp.right)
                x.top.equalTo(cell.contentView.snp.top).offset(cellHeadGap)
                x.height.equalTo(sectionRecentUpdate.suggestedHeight)
            }
        default:
            cell.backgroundColor = .randomAsPudding
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return obtainHeightForEachRow()[indexPath.row]
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

}
