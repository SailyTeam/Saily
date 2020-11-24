//
//  DashNavCard.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/18.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit

class DashNavCard: UIView {
    
    private let dashCard = DashNavCardInstance(text: "DashBoardNavigatorCard_DashBoard".localized(),
                                               selectIconName: "DashNAV.DashboardSelected",
                                               selectBackgroundColor: UIColor(named: "DashNAV.DashboardSelectedColor")!,
                                               unselectIconName: "DashNAV.DashboardUnselected",
                                               defaultSelected: true)
    
    private let settCard = DashNavCardInstance(text: "DashBoardNavigatorCard_Setting".localized(),
                                               selectIconName: "DashNAV.SettingSelected",
                                               selectBackgroundColor: UIColor(named: "DashNAV.SettingSelectedColor")!,
                                               unselectIconName: "DashNAV.SettingUnselected",
                                               defaultSelected: false)
    
    private let taskCard = DashNavCardInstance(text: "DashBoardNavigatorCard_Tasks".localized(),
                                               selectIconName: "DashNAV.TaskSelected",
                                               selectBackgroundColor: UIColor(named: "DashNAV.TaskSelectedColor")!,
                                               unselectIconName: "DashNAV.TaskUnselected",
                                               defaultSelected: false)
    
    private let instCard = DashNavCardInstance(text: "DashBoardNavigatorCard_Installed".localized(),
                                               selectIconName: "DashNAV.InstalledSelected",
                                               selectBackgroundColor: UIColor(named: "DashNAV.InstalledSelectedColor")!,
                                               unselectIconName: "DashNAV.InstalledUnselected",
                                               defaultSelected: false)
    
    private var _SplitBoardingDash: UIViewController? = SplitDetailDashBoardNAV()
    private var _SplitDetailSetting: UIViewController? = SplitDetailSetting()
    private var _SplitDetailTask: UIViewController? = SplitDetailTask()
    private var _SplitDetailInstalled: UIViewController? = SplitDetailInstalledNAV()
    
    private var cardClosureDash: (UIViewController) -> () = { (_) in }
    private var cardClosureSett: (UIViewController) -> () = { (_) in }
    private var cardClosureTask: (UIViewController) -> () = { (_) in }
    private var cardClosureInst: (UIViewController) -> () = { (_) in }
    
    func setCardClosureDash(_ hi: @escaping (UIViewController) -> ()) { cardClosureDash = hi }
    func setCardClosureSett(_ hi: @escaping (UIViewController) -> ()) { cardClosureSett = hi }
    func setCardClosureTask(_ hi: @escaping (UIViewController) -> ()) { cardClosureTask = hi }
    func setCardClosureInst(_ hi: @escaping (UIViewController) -> ()) { cardClosureInst = hi }

    required init?(coder: NSCoder) {
        fatalError()
    }
    
    required init(requiresViewController: Bool = true) {
        super.init(frame: CGRect())
     
        if requiresViewController {
            _SplitBoardingDash = SplitDetailDashBoardNAV()
            _SplitDetailSetting = SplitDetailSetting()
            _SplitDetailTask = SplitDetailTask()
            _SplitDetailInstalled = SplitDetailInstalledNAV()
        }
        
        addSubview(dashCard)
        dashCard.setTouchEvent {
            self.selectDash()
        }
        dashCard.snp.makeConstraints { (x) in
            x.top.equalTo(self.snp.top).offset(8)
            x.left.equalTo(self.snp.left)
            x.bottom.equalTo(self.snp.centerY).offset(-8)
            x.right.equalTo(self.snp.centerX).offset(-8)
        }
        
        addSubview(settCard)
        settCard.setTouchEvent {
            self.selectSetting()
        }
        settCard.snp.makeConstraints { (x) in
            x.top.equalTo(self.snp.top).offset(8)
            x.left.equalTo(self.snp.centerX).offset(8)
            x.bottom.equalTo(self.snp.centerY).offset(-8)
            x.right.equalTo(self.snp.right)
        }
        
        addSubview(taskCard)
        taskCard.setTouchEvent {
            self.selectTask()
        }
        taskCard.snp.makeConstraints { (x) in
            x.top.equalTo(self.snp.centerY).offset(8)
            x.left.equalTo(self.snp.left)
            x.bottom.equalTo(self.snp.bottom).offset(-8)
            x.right.equalTo(self.snp.centerX).offset(-8)
        }
        
        addSubview(instCard)
        instCard.setTouchEvent {
            self.selectInstalled()
        }
        instCard.snp.makeConstraints { (x) in
            x.top.equalTo(self.snp.centerY).offset(8)
            x.left.equalTo(self.snp.centerX).offset(8)
            x.bottom.equalTo(self.snp.bottom).offset(-8)
            x.right.equalTo(self.snp.right)
        }
        
        (_SplitBoardingDash as? SplitDetailDashBoardNAV)?.assignedDashCard = self
//        _SplitDetailSetting.assignedDashCard = self
//        _SplitDetailTask.assignedDashCard = self
        (_SplitDetailInstalled as? SplitDetailInstalledNAV)?.assignedDashCard = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateTaskCardBadgeText), name: .TaskNumberChanged, object: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.updateTaskCardBadgeText()
        }
        
    }

    func selectDash() {
        dashCard.select()
        settCard.deselecte()
        taskCard.deselecte()
        instCard.deselecte()
        if let get = _SplitBoardingDash {
            cardClosureDash(get)
        }
    }
    
    func selectSetting() {
        dashCard.deselecte()
        settCard.select()
        taskCard.deselecte()
        instCard.deselecte()
        if let get = _SplitDetailSetting {
            cardClosureSett(get)
        }
        NotificationCenter.default.post(name: .SettingsUpdated, object: nil)
    }
    
    func selectTask() {
        dashCard.deselecte()
        settCard.deselecte()
        taskCard.select()
        instCard.deselecte()
        if let get = _SplitDetailTask {
            cardClosureTask(get)
        }
    }
    
    func selectInstalled() {
        dashCard.deselecte()
        settCard.deselecte()
        taskCard.deselecte()
        instCard.select()
        if let get = _SplitDetailInstalled {
            cardClosureInst(get)
        }
    }
    
    @objc private
    func updateTaskCardBadgeText() {
        TaskManager.shared.updateTaskList()
        let count = TaskManager.shared.taskCount()
        DispatchQueue.main.async {
            self.taskCard.badgeText = String(count)
        }
    }
    
    func cancelAllShadow() {
        dashCard.cancelAllShadow()
        settCard.cancelAllShadow()
        taskCard.cancelAllShadow()
        instCard.cancelAllShadow()
    }
    
}
