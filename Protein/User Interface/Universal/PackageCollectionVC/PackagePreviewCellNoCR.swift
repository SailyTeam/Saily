//
//  PackagePreviewCell.swift
//  Protein
//
//  Created by Lakr Aream on 2020/5/2.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit
import SnapKit

//    Collection No Corner Radius Cell
class PackagePreviewCoNoCRCell: PackagePreviewCoCell {

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        container.backgroundColor = .clear
        container.layer.cornerRadius = 6
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
