//
//  RepoTableViewCell.swift
//  Chromatic
//
//  Created by Lakr Aream on 2020/4/19.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//
import UIKit

class RepoTableViewCell: UITableViewCell {
    let coordinatedCell = RepoCell()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.addSubview(coordinatedCell)
        coordinatedCell.snp.makeConstraints { x in
            x.edges.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    func prepareForNewValue() {
        coordinatedCell.prepareForNewValue()
    }

    func setRepository(withUrl: URL) {
        coordinatedCell.setRepository(withUrl: withUrl)
    }

    func setNoRepoAvailable() {
        coordinatedCell.setNoRepoAvailable()
    }
}
