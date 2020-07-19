//
//  Split-BoardingDash+iPad.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/18.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit
import SnapKit
import LTMorphingLabel
import DropDown

// MARK: Views
class SplitBoardingDash: UIViewController, UINavigationControllerDelegate {
    
    private let container = UIScrollView()
    
    // please follow design xd file to build this code
    private let shadow = UIImageView(image: UIImage(named: "SplitBoardingDash.Shadow"))
    private let licenseButton = UIButton()
    private let welcomeCard = WelcomeCard()
    private let dashNavCardTitle = UILabel()
    private let dashNavCard = DashNavCard()
    private let repoCardTitle = UILabel()
    private let repoCardCountTitle = LTMorphingLabel()
    private let repoCard = RepoCard()
    private let downTinit = UILabel()
    private var privNavRecordTag: Int = 0
    private var contentLenthOfRepoCard = CGFloat() {
        didSet {                                   // was is read from ~~xd file~~ reveal
            container.contentSize = CGSize(width: 0, height: 640 + contentLenthOfRepoCard)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadNavClosure()
        bootstrapLayouts()
    }
    
    func loadNavClosure() {
        dashNavCard.setCardClosureDash { (vc) in self.DashNavSelectDash(vc) }
        dashNavCard.setCardClosureSett { (vc) in self.DashNavSelectSetting(vc) }
        dashNavCard.setCardClosureTask { (vc) in self.DashNavSelectTask(vc) }
        dashNavCard.setCardClosureInst { (vc) in self.DashNavSelectInstalled(vc) }
    }
    
    func _setDetailViewController() {
        switch privNavRecordTag {
        case 0: dashNavCard.selectDash()
        case 1: dashNavCard.selectSetting()
        case 2: dashNavCard.selectTask()
        case 3: dashNavCard.selectInstalled()
        default:
            print("privNavRecordTag is damaged")
        }
    }
    
    func setDetailViewController() {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//            self._setDetailViewController()
//        }
    }
    
    func hidesShadowView() {
        shadow.alpha = 0
    }
    
    func showShadowView() {
        shadow.alpha = 1
    }
    
}

// MARK: BootStrap Views
extension SplitBoardingDash {

    private func bootstrapLayouts() {
        
        hideKeyboardWhenTappedAround()
        view.backgroundColor = UIColor(named: "SplitBoardingDash.Background")
        
        container.decelerationRate = .fast
        container.showsVerticalScrollIndicator = false
        container.showsHorizontalScrollIndicator = false
        container.alwaysBounceVertical = true
        view.addSubview(container)
        container.snp.makeConstraints { (x) in
            x.edges.equalTo(self.view.snp.edges)
        }
        
        var anchor = UIView()
        let safeAnchor = anchor
        container.addSubview(anchor)
        anchor.snp.makeConstraints { (x) in
            x.top.equalTo(container.snp.top).offset(30)
            x.height.equalTo(2)
            x.left.equalTo(self.view.snp.left).offset(20)
            x.right.equalTo(self.view.snp.right).offset(-20)
        }
        
        container.addSubview(licenseButton)
        licenseButton.setTitle("LICENSE".localized(), for: .normal)
        licenseButton.setTitleColor(UIColor(named: "G-Button-Normal"),
                                    for: .normal)
        licenseButton.setTitleColor(UIColor(named: "G-Button-Highlighted"),
                                    for: .highlighted)
        licenseButton.contentHorizontalAlignment = .right
        licenseButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        licenseButton.addTarget(self, action: #selector(showLicenseViewController), for: .touchUpInside)
//        licenseButton.addTarget(self, action: #selector(showLogViewController), for: .touchUpOutside)
        licenseButton.snp.makeConstraints { (x) in
            x.top.equalTo(anchor.snp.bottom)
            x.right.equalTo(safeAnchor.snp.right).offset(-4)
            x.height.equalTo(20)
            x.width.equalTo(100)
        }
        anchor = licenseButton
        
        welcomeCard.setTouchEvent {
            self.welcomeCardWhenTouchCard()
        }
        welcomeCard.setTouchIconEvent {
            self.welcomeCardWhenTouchIcon()
        }
        container.addSubview(welcomeCard)
        welcomeCard.snp.makeConstraints { (x) in
            x.left.equalTo(safeAnchor.snp.left)
            x.right.equalTo(safeAnchor.snp.right)
            x.top.equalTo(anchor.snp.bottom).offset(35)
            x.height.equalTo(180)
        }
        anchor = welcomeCard
        
        dashNavCardTitle.text = "SplitView_Feature".localized()
        dashNavCardTitle.textColor = UIColor(named: "G-TextTitle")
        dashNavCardTitle.font = .systemFont(ofSize: 22, weight: .heavy)
        dashNavCardTitle.textAlignment = .left
        container.addSubview(dashNavCardTitle)
        dashNavCardTitle.snp.makeConstraints { (x) in
            x.left.equalTo(safeAnchor.snp.left).offset(-4)
            x.width.equalTo(188)
            x.height.equalTo(35)
            x.top.equalTo(anchor.snp.bottom).offset(20)
        }
        anchor = dashNavCardTitle
        
        container.addSubview(dashNavCard)
        dashNavCard.snp.makeConstraints { (x) in
            x.left.equalTo(safeAnchor.snp.left)
            x.right.equalTo(safeAnchor.snp.right)
            x.top.equalTo(anchor.snp.bottom).offset(8)
            x.height.equalTo(210)
        }
        anchor = dashNavCard
        
        // auto select dash card 0
        dashNavCard.selectDash();
        
        repoCardTitle.text = "SplitView_MyRepo".localized()
        repoCardTitle.textColor = UIColor(named: "G-TextTitle")
        repoCardTitle.font = .systemFont(ofSize: 22, weight: .heavy)
        repoCardTitle.textAlignment = .left
        container.addSubview(repoCardTitle)
        repoCardTitle.snp.makeConstraints { (x) in
            x.left.equalTo(safeAnchor.snp.left).offset(-4)
            x.width.equalTo(188)
            x.height.equalTo(35)
            x.top.equalTo(anchor.snp.bottom).offset(10)
        }
        repoCardCountTitle.text = String(repoCard.repoCount())
        repoCardCountTitle.morphingEffect = .evaporate
        repoCardCountTitle.font = UIFont.roundedFont(ofSize: 22, weight: .bold).monospacedDigitFont
        repoCardCountTitle.textAlignment = .right
        container.addSubview(repoCardCountTitle)
        repoCardCountTitle.snp.makeConstraints { (x) in
            x.right.equalTo(safeAnchor.snp.right)
            x.width.equalTo(188)
            x.height.equalTo(35)
            x.top.equalTo(anchor.snp.bottom).offset(10)
        }
        anchor = repoCardTitle
        
        repoCard.afterLayoutUpdate { self.repoCardDidLayoutItsSubviews(shouldLayout: true) }
        container.addSubview(repoCard)
        repoCard.snp.makeConstraints { (x) in
            x.top.equalTo(anchor.snp.bottom).offset(8)
            x.left.equalTo(safeAnchor.snp.left)
            x.right.equalTo(safeAnchor.snp.right)
            x.height.equalTo(repoCard.suggestHeight)
        }
        repoCardDidLayoutItsSubviews(shouldLayout: false)
        anchor = repoCard

        downTinit.text = "Lakr Aream @ 2020.4 - Project Protein"
        downTinit.font = .systemFont(ofSize: 12, weight: .semibold)
        downTinit.textAlignment = .center
        downTinit.textColor = .gray
        container.addSubview(downTinit)
        downTinit.snp.makeConstraints { (x) in
            x.left.equalTo(safeAnchor.snp.left)
            x.right.equalTo(safeAnchor.snp.right)
            x.top.equalTo(anchor.snp.bottom).offset(8)
            x.height.equalTo(20)
        }
        
        shadow.contentMode = .scaleToFill
        view.addSubview(shadow)
        shadow.snp.makeConstraints { (x) in
            x.top.equalTo(self.view.snp.top).offset(-233)
            x.bottom.equalTo(self.view.snp.bottom).offset(233)
            x.width.equalTo(9)
            x.right.equalTo(self.view.snp.right)
        }
        
    }
    
}

// MARK: Operations
extension SplitBoardingDash: UIImagePickerControllerDelegate {
    
    @objc
    func showLicenseViewController() {
        licenseButton.puddingAnimate()
        let pop = LicenseViewController()
        pop.modalPresentationStyle = .formSheet;
        pop.modalTransitionStyle = .coverVertical;
        present(pop, animated: true, completion: nil)
    }
    
    func welcomeCardWhenTouchCard() {
//        let alert = UIAlertController(title: "Error".localized(), message: "Account management is not available in this beta", preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
//        self.present(alert, animated: true, completion: nil)
        let pop = RepoPaymentViewController()
        pop.modalPresentationStyle = .formSheet
        pop.modalTransitionStyle = .coverVertical
        self.present(pop, animated: true, completion: nil)
    }
    
    func welcomeCardWhenTouchIcon() {
        
        let dropDown = DropDown()
        let actions = ["SetAvatar", "RemoveAvatar", "Accounts", "Cancel"]
        dropDown.dataSource = actions.map({ (str) -> String in
            return "   " + str.localized()
        })
        dropDown.selectionAction = { [unowned self] (index, _) in
            if actions[index] == "RemoveAvatar" {
                try? FileManager.default.removeItem(at: ConfigManager.shared.documentURL.appendingPathComponent("avatar.png"))
                NotificationCenter.default.post(name: .AvatarUpdated, object: nil)
                return
            }
            if actions[index] == "SetAvatar" {
                if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                    let picker = UIImagePickerController()
                    picker.modalPresentationStyle = .formSheet
                    picker.modalTransitionStyle = .coverVertical
                    picker.delegate = self
                    picker.sourceType = .photoLibrary
                    picker.allowsEditing = true
                    picker.preferredContentSize = CGSize(width: 700, height: 555)
                    self.present(picker, animated: true, completion: nil)
                } else {
                    let alert = UIAlertController(title: "Error".localized(), message: "PhotoLibraryUnavailableHint".localized(), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            if actions[index] == "Accounts" {
                self.welcomeCard.puddingAnimate()
                self.welcomeCardWhenTouchCard()
                return
            }
        }
        dropDown.anchorView = welcomeCard
        dropDown.show()
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: { () -> Void in
        })
        if let refUrl = info[.imageURL] as? URL {
            let img = UIImage(contentsOfFile: refUrl.fileString)
            try? img?.pngData()?.write(to: ConfigManager.shared.documentURL.appendingPathComponent("avatar.png"))
            NotificationCenter.default.post(name: .AvatarUpdated, object: nil)
        }
    }
    
    func DashNavSelectDash(_ viewController: UIViewController) {
        if let navCheck = viewController as? UINavigationController, navCheck.viewControllers.count < 1, navCheck.viewControllers.first == viewController {
            return
        }
        showDetailViewController(viewController, sender: nil)
        if privNavRecordTag == 0 {
            if let nav = viewController as? UINavigationController {
                nav.popToRootViewController(animated: true)
            } else {
                viewController.navigationController?.popToRootViewController(animated: true)
            }
        } else {
            privNavRecordTag = 0
        }
    }
    
    func DashNavSelectSetting(_ viewController: UIViewController) {
        if let navCheck = viewController as? UINavigationController, navCheck.viewControllers.count < 1, navCheck.viewControllers.first == viewController {
            return
        }
        showDetailViewController(viewController, sender: nil)
        if privNavRecordTag == 1 {
            if let nav = viewController as? UINavigationController {
                nav.popToRootViewController(animated: true)
            } else {
                viewController.navigationController?.popToRootViewController(animated: true)
            }
        } else {
            privNavRecordTag = 1
        }
    }
    
    func DashNavSelectTask(_ viewController: UIViewController) {
        if let navCheck = viewController as? UINavigationController, navCheck.viewControllers.count < 1, navCheck.viewControllers.first == viewController {
            return
        }
        showDetailViewController(viewController, sender: nil)
        if privNavRecordTag == 2 {
            if let nav = viewController as? UINavigationController {
                nav.popToRootViewController(animated: true)
            } else {
                viewController.navigationController?.popToRootViewController(animated: true)
            }
        } else {
            privNavRecordTag = 2
        }
    }
    
    func DashNavSelectInstalled(_ viewController: UIViewController) {
        if let navCheck = viewController as? UINavigationController, navCheck.viewControllers.count < 1, navCheck.viewControllers.first == viewController {
            return
        }
        showDetailViewController(viewController, sender: nil)
        if privNavRecordTag == 3 {
            if let nav = viewController as? UINavigationController {
                nav.popToRootViewController(animated: true)
            } else {
                viewController.navigationController?.popToRootViewController(animated: true)
            }
        } else {
            privNavRecordTag = 3
        }
    }
    
    func repoCardDidLayoutItsSubviews(shouldLayout: Bool = false) {
        let count = repoCard.repoCount()
        repoCardCountTitle.text = String(count)
        if !shouldLayout {
            contentLenthOfRepoCard = repoCard.suggestHeight
            return
        }
        UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
            self.repoCard.snp.updateConstraints { (x) in
                x.height.equalTo(self.repoCard.suggestHeight)
            }
            self.contentLenthOfRepoCard = self.repoCard.suggestHeight
            self.repoCard.superview?.layoutIfNeeded()
        }, completion: nil)
    }
    
}
