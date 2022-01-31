//
//  DTImageView.swift
//  Pods
//
//  Created by Admin on 17/01/2017.
//
//

import UIKit

class DTImageView: UIImageView {    
    override var image: UIImage? {
        didSet {
            imageChangeBlock?(image)
        }
    }
    
    var imageChangeBlock: ((UIImage?) -> Void)?
}
