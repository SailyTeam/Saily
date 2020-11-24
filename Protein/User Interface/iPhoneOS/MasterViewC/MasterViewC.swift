//
//  MasterView.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/25.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit
import SnapKit
import LTMorphingLabel
import DropDown
import JGProgressHUD

class MasterViewNavigator: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = nil
    }
}

class MasterView: UIViewController {
    
    let container = UIScrollView()
    
    // please follow design xd file to build this code
    let welcomeCard = WelcomeCard()
    let searchBar = SearchBar()
    let searchBarSender = UIButton()
    let dashNavCardTitle = UILabel()
    let dashNavCard = DashNavCard(requiresViewController: false)
    let repoCardTitle = UILabel()
    let repoCardCountTitle = LTMorphingLabel()
    let repoCard = RepoCard(pushAsFormSheet: false)
    let downTinit = UILabel()
    var privNavRecordTag: Int = 0
    var contentLenthOfRepoCard = CGFloat() {
        didSet {                                   // was is read from ~~xd file~~ reveal
            container.contentSize = CGSize(width: 0, height: 660 + contentLenthOfRepoCard)
        }
    }
    
    let settingViewController = SettingViewController()
    let taskViewController = SplitDetailTask()
    let installViewController = InstalledViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadCardsClosure()
        bootstrapLayouts()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.dashNavCard.selectDash()
    }
    
    func loadCardsClosure() {        
        dashNavCard.setCardClosureDash { (vc) in
//            self.pushViewController(vc)
        }
        dashNavCard.setCardClosureSett { (vc) in
            self.pushViewController(self.settingViewController)
        }
        dashNavCard.setCardClosureTask { (vc) in
            self.pushViewController(self.taskViewController)
        }
        dashNavCard.setCardClosureInst { (vc) in
            self.pushViewController(self.installViewController)
        }
    }
    
    func pushViewController(_ vc: UIViewController) {
        if let vc = vc as? UINavigationController, let get = vc.viewControllers.first {
            self.navigationController?.pushViewController(get, animated: true)
        } else {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
}
