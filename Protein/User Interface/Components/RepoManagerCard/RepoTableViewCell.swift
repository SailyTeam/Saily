//
//  RepoTableViewCell.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/19.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit
import SnapKit

struct RepoTableViewCellNotifyStatusObject {
    let urlStringRef: String
    let lastUpdateRelease: Double
    let lastUpdatePackage: Double
    let nameStringRef: String
}

class RepoTableViewCell: UITableViewCell {

    static var updateLock = false
    
    var name = UILabel()
    let url = UILabel()
    let updateStatus = UILabel()
    let arrow = UIImageView(image: UIImage(named: "RepoTableViewCell.Right"))
    var icon = UIImageView()
    var urlStringRef: String = ""
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        
        contentView.addSubview(icon)
        contentView.addSubview(name)
        contentView.addSubview(url)
        contentView.addSubview(updateStatus)
        contentView.addSubview(arrow)
        
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        icon.image = UIImage(named: "RepoTableViewCell.Missing")
        icon.layer.cornerRadius = 8
        icon.clipsToBounds = true
        icon.contentMode = .scaleAspectFit
        icon.snp.remakeConstraints { (x) in
            x.centerY.equalTo(contentView.snp.centerY)
            x.left.equalTo(contentView.snp.left).offset(12)
            x.height.equalTo(33)
            x.width.equalTo(33)
        }
        
        name.font = .boldSystemFont(ofSize: 16)
        name.clipsToBounds = false
        name.textColor = UIColor(named: "RepoTableViewCell.Text")
        name.snp.remakeConstraints { (x) in
            x.left.equalTo(icon.snp.right).offset(8)
            x.right.equalTo(arrow.snp.left).offset(-10)
            x.height.equalTo(20)
            x.bottom.equalTo(url.snp.top).offset(0)
        }
        
        url.font = .boldSystemFont(ofSize: 10)
        url.lineBreakMode = .byTruncatingTail
        url.textColor = UIColor(named: "RepoTableViewCell.SubText")
        url.snp.makeConstraints { (x) in
            x.centerY.equalTo(icon.snp.centerY).offset(4)
            x.left.equalTo(icon.snp.right).offset(8)
            x.right.equalTo(contentView.snp.right).offset(-30)
            x.height.equalTo(14)
        }
        
        updateStatus.font = .boldSystemFont(ofSize: 8)
        updateStatus.lineBreakMode = .byTruncatingTail
        updateStatus.textColor = UIColor(named: "RepoTableViewCell.SubText")
        updateStatus.snp.makeConstraints { (x) in
            x.left.equalTo(icon.snp.right).offset(8)
            x.right.equalTo(contentView.snp.right)
            x.top.equalTo(url.snp.bottom).offset(0)
            x.height.equalTo(12)
        }
        
        arrow.contentMode = .scaleAspectFit
        arrow.snp.makeConstraints { (x) in
            x.centerY.equalTo(contentView.snp.centerY)
            x.right.equalTo(contentView.snp.right).offset(-4)
            x.height.equalTo(16)
            x.width.equalTo(16)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateStatusLabel(object:)), name: .RepoManagerUpdatedAMeta, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateStatusLabelUnconditionally), name: .RepoManagerUpdatedAllMeta, object: nil)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    @objc
    func updateStatusLabelUnconditionally() {
        DispatchQueue.global(qos: .background).async {
            if RepoTableViewCell.updateLock || self.urlStringRef == "" {
                return
            }
            guard let url = URL(string: self.urlStringRef) else {
                return
            }
            
            let tintInUpdate = "RepoCard_Cell_RepoInUpdate".localized()
            let tintPendingUpdate = "RepoCard_Cell_PendingUpdate".localized()
            if RepoManager.shared.inUpdate.contains(url) {
                DispatchQueue.main.async {
                    self.updateStatus.text = tintInUpdate
                }
                return
            }
            if RepoManager.shared.updateQueue.contains(url) {
                DispatchQueue.main.async {
                    self.updateStatus.text = tintPendingUpdate
                }
                return
            }
            
            let copy = RepoManager.shared.repos
            for repo in copy where repo.url.urlString == self.urlStringRef {
                let v1 = repo.lastUpdateRelease
                let v2 = repo.lastUpdatePackage
                let use = v1 < v2 ? v1 : v2        // smaller means earlier
                let date = Date().timeIntervalSince1970
                let newUpdateStatusText = "RepoCard_Cell_LastUpdateTimeHintPrefix".localized() + Tools.obtainTimeGapDescription(fromA: date, toB: use)
                DispatchQueue.main.async {
                    self.updateStatus.text = newUpdateStatusText
                    self.name.text = repo.obtainPossibleName()
                }
                return
            }
        }
    }
    
    @objc private
    func updateStatusLabel(object: Notification? = nil) {
        DispatchQueue.global(qos: .background).async {
            if RepoTableViewCell.updateLock || self.urlStringRef == "" {
                return
            }
            guard let url = URL(string: self.urlStringRef) else {
                return
            }
            if let notify = object, let notifyObject = notify.userInfo?["attach"] as? RepoTableViewCellNotifyStatusObject {
                if notifyObject.urlStringRef != self.urlStringRef {
                    return
                }
                let tintInUpdate = "RepoCard_Cell_RepoInUpdate".localized()
                let tintPendingUpdate = "RepoCard_Cell_PendingUpdate".localized()
                if RepoManager.shared.inUpdate.contains(url) {
                    DispatchQueue.main.async {
                        self.updateStatus.text = tintInUpdate
                    }
                    return
                }
                if RepoManager.shared.updateQueue.contains(url) {
                    DispatchQueue.main.async {
                        self.updateStatus.text = tintPendingUpdate
                    }
                    return
                }
                let v1 = notifyObject.lastUpdateRelease
                let v2 = notifyObject.lastUpdatePackage
                let use = v1 < v2 ? v1 : v2        // smaller means earlier
                let date = Date().timeIntervalSince1970
                let newUpdateStatusText = "RepoCard_Cell_LastUpdateTimeHintPrefix".localized() + Tools.obtainTimeGapDescription(fromA: date, toB: use)
                DispatchQueue.main.async {
                    self.updateStatus.text = newUpdateStatusText
                    self.name.text = notifyObject.nameStringRef
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}
