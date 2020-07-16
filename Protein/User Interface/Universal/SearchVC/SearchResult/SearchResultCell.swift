//
//  SearchResultCell.swift
//  Protein
//
//  Created by soulghost on 10/5/2020.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit

class SearchResultCell: UITableViewCell {
    
    private var _viewModel: SearchResultCellModel?
    var viewModel: SearchResultCellModel? {
        set (viewModel) {
            _viewModel = viewModel
            setup()
        }
        get {
            return _viewModel
        }
    }
    
    private var iconView: UIImageView?
    private var titleLabel: UILabel?
    private var subtitleLabel: UILabel?
    private var sep: UIView?
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    private func setupViews() {
        selectionStyle = .none
        
        iconView = UIImageView()
        // FIXME: 圆角优化 并不需要优化 :/
        iconView?.layer.cornerRadius = 12
        iconView?.layer.masksToBounds = true
        contentView.addSubview(iconView!)
        
        titleLabel = UILabel()
        contentView.addSubview(titleLabel!)
        
        subtitleLabel = UILabel()
        contentView.addSubview(subtitleLabel!)
        
        sep = UIView()
        sep?.backgroundColor = .gray
        sep?.alpha = 0.233
        contentView.addSubview(sep!)
        
        let contentView = self.contentView
        iconView?.snp.makeConstraints({ (x) in
            x.centerY.equalTo(contentView.snp.centerY)
            x.left.equalTo(contentView.snp.left).offset(20)
            x.width.equalTo(40)
            x.height.equalTo(40)
        })
        
        titleLabel?.snp.makeConstraints({ (x) in
            x.left.equalTo(iconView!.snp.right).offset(12)
            x.right.equalTo(contentView.snp.right).offset(-12)
            x.top.equalTo(iconView!.snp.top).offset(-2)
        })
        
        subtitleLabel?.snp.makeConstraints({ (x) in
            x.left.equalTo(titleLabel!.snp.left)
            x.right.equalTo(titleLabel!.snp.right)
            x.top.equalTo(titleLabel!.snp.bottom).offset(4)
        })
        
        sep?.snp.makeConstraints({ (x) in
            x.left.equalTo(iconView!.snp.right)
            x.bottom.equalTo(contentView.snp.bottom)
            x.right.equalTo(contentView.snp.right)
            x.height.equalTo(0.8)
        })
        
    }
    
    private func setup() {
        let iconEntity = viewModel?.iconEntity
        if let img = iconEntity?.1 {
            iconView?.image = img
        } else {
            if let il = iconEntity?.0, il.hasPrefix("http") {
                iconView?.sd_setImage(with: URL(string: il), placeholderImage:  UIImage(named: "mod"), options: .avoidAutoSetImage, context: nil, progress: nil) { (image, err, _, url) in
                    if let img = image {
                        self.iconView?.image = img
                    }
                }
            } else if let il = iconEntity?.0, il.hasPrefix("file://") {
                if let img = UIImage(contentsOfFile: String(il.dropFirst("file://".count))) {
                    iconView?.image = img
                }
            }
        }
        
        titleLabel?.attributedText = viewModel?.title
        subtitleLabel?.attributedText = viewModel?.subtitle
    }
}
