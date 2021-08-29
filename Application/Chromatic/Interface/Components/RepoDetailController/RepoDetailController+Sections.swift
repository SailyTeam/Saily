//
//  RepoDetailController+Sections.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/17.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import UIKit

extension RepoDetailController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func setupCollectionView(anchor: inout UIView) {
        let flowLayout = AlignedCollectionViewFlowLayout(horizontalAlignment: .left,
                                                         verticalAlignment: .center)
        collectionView = UICollectionView(frame: CGRect(),
                                          collectionViewLayout: flowLayout)
        collectionView?.register(SimpleLabelSectionCell.self,
                                 forCellWithReuseIdentifier: "wiki.qaq.chromatic.SimpleLabelSectionCell")

        container.addSubview(collectionView!)
        collectionView!.delegate = self
        collectionView!.dataSource = self
        collectionView!.backgroundColor = nil
        collectionView!.snp.makeConstraints { x in
            x.top.equalTo(anchor.snp.bottom).offset(10)
            x.leading.equalTo(anchor)
            x.trailing.equalTo(anchor)
            x.height.equalTo(0)
        }
        anchor = collectionView!

        DispatchQueue.main.async {
            self.layoutCollectionView()
        }
    }

    func layoutCollectionView() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
            self.collectionView?.snp.updateConstraints { x in
                x.height.equalTo(self.collectionView?.collectionViewLayout.collectionViewContentSize ?? 0)
            }
            self.collectionView?.layoutIfNeeded()
        }, completion: nil)
    }

    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        sectionDetailsSortedKeys.count + 1
    }

    func textForCellAt(row: Int) -> String {
        if row >= sectionDetailsSortedKeys.count {
            return "All (" + String(repo.metaPackage.count) + ")"
        }
        var currentString = sectionDetailsSortedKeys[row]
        if let counted = sectionDetails[sectionDetailsSortedKeys[row]]?.count {
            currentString += " (" + String(counted) + ")"
        }
        return currentString
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "wiki.qaq.chromatic.SimpleLabelSectionCell", for: indexPath) as! SimpleLabelSectionCell
        cell.setText(textForCellAt(row: indexPath.row))
        return cell
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let currentString = textForCellAt(row: indexPath.row)
        let font = SimpleLabelSectionCell.sharedFont
        let size = currentString.sizeOfString(usingFont: font)
        return CGSize(width: size.width + 30, height: 26)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        collectionView.cellForItem(at: indexPath)?.contentView.puddingAnimate()
        var packages = [Package]()
        if indexPath.row < sectionDetailsSortedKeys.count {
            let key = sectionDetailsSortedKeys[indexPath.row]
            packages = sectionDetails[key, default: []]
        } else {
            packages = [Package](repo.metaPackage.values)
        }
        let target: UIViewController
        if packages.count == 1 {
            target = PackageController(package: packages[0])
        } else {
            let collection = PackageCollectionController()
            collection.dataSource = packages.sorted {
                PackageCenter.default.name(of: $0)
                    < PackageCenter.default.name(of: $1)
            }
            target = collection
        }
        present(next: target)
    }
}

private class SimpleLabelSectionCell: UICollectionViewCell {
    private var label = UILabel()
    private var container = UIView()

    static let sharedFont: UIFont = .systemFont(ofSize: 14, weight: .semibold)

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(container)
        container.addSubview(label)
        label.snp.makeConstraints { x in
            x.edges.equalTo(self.container)
        }
        container.snp.makeConstraints { x in
            x.left.equalToSuperview()
            x.right.equalToSuperview().offset(-4)
            x.top.equalToSuperview()
            x.bottom.equalToSuperview().offset(-2)
        }
        var color = UIColor.gray
        color = color.withAlphaComponent(0.1)
        container.backgroundColor = color
        container.layer.cornerRadius = 4

        label.font = SimpleLabelSectionCell.sharedFont
        label.textColor = UIColor(named: "TEXT_TITLE")
        label.textAlignment = .center
        label.lineBreakMode = .byCharWrapping
    }

    func setText(_ str: String) {
        label.text = str
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
