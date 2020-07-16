//
//  MasterView.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/25.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit

class MasterView: SplitBoardingDash {
    
    override func viewDidLoad() {

        view.subviews.forEach { (view) in
            view.removeFromSuperview()
        }
        
        super.viewDidLoad()

    }
    
}
