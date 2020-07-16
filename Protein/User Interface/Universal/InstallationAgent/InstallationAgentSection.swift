//
//  InstallationAgentSection.swift
//  Protein
//
//  Created by Lakr Aream on 2020/7/15.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit
import SDWebImage

class InstallAgentSection: UIView {
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private let height = 50
    private let packageList: [PackageStruct]
    private let isDelete: Bool
    
    required init(withPkgList packages: [PackageStruct], isDelete b: Bool) {
        isDelete = b
        packageList = packages
        super.init(frame: CGRect())
        
        var anchor: UIView?
        for item in packages {
            let container = UIView()
            let icon = UIImageView()
            let l1 = UILabel()
            let l2 = UILabel()
            let name = item.obtainNameIfExists()
            let version = item.newestVersion()
            addSubview(container)
            addSubview(icon)
            addSubview(l1)
            addSubview(l2)
            if let anchor = anchor {
                container.snp.makeConstraints { (x) in
                    x.top.equalTo(anchor.snp.bottom)
                    x.left.equalToSuperview()
                    x.right.equalToSuperview()
                    x.height.equalTo(self.height)
                }
            } else {
                container.snp.makeConstraints { (x) in
                    x.top.equalToSuperview()
                    x.left.equalToSuperview()
                    x.right.equalToSuperview()
                    x.height.equalTo(self.height)
                }
            }
            anchor = container
            // layout single package
            if isDelete {
                icon.image = UIImage(named: "delete")
            } else {
                let payload = item.obtainIconIfExists()
                if let img = payload.1 {
                    icon.image = img
                } else if let r = payload.0, let url = URL(string: r),
                    let imgData = SDImageCache.shared.diskImageData(forKey: url.absoluteString),
                    let img = UIImage(data: imgData) {
                    icon.image = img
                } else {
                    icon.image = UIImage(named: "mod")
                }
            }
            icon.contentMode = .scaleAspectFill
            icon.clipsToBounds = true
            icon.layer.cornerRadius = 8
            icon.snp.makeConstraints { (x) in
                x.centerY.equalTo(container)
                x.left.equalToSuperview()
                x.width.equalTo(28)
                x.height.equalTo(28)
            }
            l1.text = name
            l1.snp.makeConstraints { (x) in
                x.bottom.equalTo(icon.snp.centerY).offset(4)
                x.left.equalTo(icon.snp.right).offset(8)
            }
            l2.text = version
            l2.snp.makeConstraints { (x) in
                x.top.equalTo(icon.snp.centerY).offset(4)
                x.left.equalTo(icon.snp.right).offset(8)
            }
            l1.font = .systemFont(ofSize: 16, weight: .semibold)
            l1.textColor = UIColor(named: "RepoTableViewCell.Text")
            l2.font = .systemFont(ofSize: 12, weight: .semibold)
            l2.textColor = UIColor(named: "RepoTableViewCell.Text")?.withAlphaComponent(0.5)
        }        
    }
    
    func reportHeight() -> CGFloat {
        return CGFloat(packageList.count * height + 30)
    }
    
}
