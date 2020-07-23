//
//  PackagePreviewCell.swift
//  Protein
//
//  Created by Lakr Aream on 2020/5/2.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit
import SnapKit

class PackagePreviewCoCell: UICollectionViewCell {
    
    let container = UIView()
    let icon = UIImageView(image:  UIImage(named: "mod"))
    let name = UILabel()
    let auth = UILabel()
    let desc = UILabel()
    let litt = UIImageView()
    
    private var installedTint = UIView()
    
    var packageRef: PackageStruct? {
        didSet {
            if let identity = packageRef?.identity,
                PackageManager.shared.rawInstalledFastQueryUnsafeCache[identity] ?? false {
                installedTint.isHidden = false
            } else {
                installedTint.isHidden = true
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(container)
        addSubview(icon)
        addSubview(name)
        addSubview(auth)
        addSubview(desc)
        addSubview(litt)
        addSubview(installedTint)
        
        container.backgroundColor = UIColor(named: "G-Background-Cell")
        container.layer.cornerRadius = 12
        container.dropShadow(opacity: 0.2)
        let i = 6
        container.snp.makeConstraints { (x) in
            x.top.equalTo(self.snp.top).offset(i / 2)
            x.bottom.equalTo(self.snp.bottom).offset(-i / 2)
            x.left.equalTo(self.snp.left).offset(i)
            x.right.equalTo(self.snp.right).offset(-i)
        }
        
        icon.contentMode = .scaleAspectFill
        icon.layer.cornerRadius = 10
        icon.clipsToBounds = true
        icon.snp.makeConstraints { (x) in
            x.centerY.equalTo(self.snp.centerY)
            x.top.equalTo(self.snp.top).offset(Double(i) * 2.3)
            x.left.equalTo(self.snp.left).offset(i * 3)
            x.width.equalTo(icon.snp.height)
        }
        
        name.font = .boldSystemFont(ofSize: 15)
        name.clipsToBounds = false
        name.lineBreakMode = .byTruncatingTail
        name.textColor = UIColor(named: "PackageCollectionView.Text")
        name.snp.remakeConstraints { (x) in
            x.left.equalTo(icon.snp.right).offset(8)
            x.right.equalTo(litt.snp.left).offset(-4)
            x.top.equalTo(icon.snp.top).offset(-8)
            x.bottom.equalTo(icon.snp.centerY).offset(-2)
        }
        
        auth.font = .boldSystemFont(ofSize: 9)
        auth.lineBreakMode = .byTruncatingTail
        auth.textColor = UIColor(named: "PackageCollectionView.SubText")
        auth.snp.makeConstraints { (x) in
            x.top.equalTo(name.snp.bottom).offset(0)
            x.left.equalTo(icon.snp.right).offset(8)
            x.right.equalTo(self.snp.right).offset(-i - 5)
            x.height.equalTo(12)
        }
        
        desc.font = .boldSystemFont(ofSize: 8)
        desc.lineBreakMode = .byTruncatingTail
        desc.textColor = UIColor(named: "RepoTableViewCell.SubText")
        desc.snp.makeConstraints { (x) in
            x.top.equalTo(auth.snp.bottom).offset(-2)
            x.left.equalTo(icon.snp.right).offset(8)
            x.right.equalTo(self.snp.right).offset(-i - 5)
            x.height.equalTo(12)
        }
        
        litt.contentMode = .scaleAspectFill
        litt.clipsToBounds = true
        litt.snp.makeConstraints { (x) in
            x.width.equalTo(14)
            x.height.equalTo(14)
            x.top.equalTo(self.snp.top).offset(6)
            x.right.equalTo(self.snp.right).offset(-12)
        }
        
        installedTint.isHidden = true
        installedTint.clipsToBounds = true
        installedTint.backgroundColor = #colorLiteral(red: 0.5567936897, green: 0.9780793786, blue: 0.6893508434, alpha: 1)
        installedTint.layer.cornerRadius = 4
        installedTint.snp.makeConstraints { (x) in
            x.centerX.equalTo(self.icon.snp.right).offset(-2)
            x.centerY.equalTo(self.icon.snp.bottom).offset(-2)
            x.width.equalTo(8)
            x.height.equalTo(8)
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    func showLittleBadge(withImage: UIImage) {
        litt.image = withImage
    }
    
}
