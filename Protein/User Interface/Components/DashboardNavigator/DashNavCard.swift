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
    
    private var _SplitBoardingDash = SplitDetailDashBoardNAV()
    private var _SplitDetailSetting = SplitDetailSetting()
    private var _SplitDetailTask = SplitDetailTask()
    private var _SplitDetailInstalled = SplitDetailInstalledNAV()
    
    private var cardClosureDash: (SplitDetailDashBoardNAV) -> () = { (_) in }
    private var cardClosureSett: (SplitDetailSetting) -> () = { (_) in }
    private var cardClosureTask: (SplitDetailTask) -> () = { (_) in }
    private var cardClosureInst: (SplitDetailInstalledNAV) -> () = { (_) in }
    
    func setCardClosureDash(_ hi: @escaping (SplitDetailDashBoardNAV) -> ()) { cardClosureDash = hi }
    func setCardClosureSett(_ hi: @escaping (SplitDetailSetting) -> ()) { cardClosureSett = hi }
    func setCardClosureTask(_ hi: @escaping (SplitDetailTask) -> ()) { cardClosureTask = hi }
    func setCardClosureInst(_ hi: @escaping (SplitDetailInstalledNAV) -> ()) { cardClosureInst = hi }

    required init?(coder: NSCoder) {
        fatalError()
    }
    
    required init() {
        super.init(frame: CGRect())
     
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
        
        _SplitBoardingDash.assignedDashCard = self
//        _SplitDetailSetting.assignedDashCard = self
//        _SplitDetailTask.assignedDashCard = self
        _SplitDetailInstalled.assignedDashCard = self
        
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
        cardClosureDash(_SplitBoardingDash)
    }
    
    func selectSetting() {
        dashCard.deselecte()
        settCard.select()
        taskCard.deselecte()
        instCard.deselecte()
        cardClosureSett(_SplitDetailSetting)
        NotificationCenter.default.post(name: .SettingsUpdated, object: nil)
    }
    
    func selectTask() {
        dashCard.deselecte()
        settCard.deselecte()
        taskCard.select()
        instCard.deselecte()
        cardClosureTask(_SplitDetailTask)
    }
    
    func selectInstalled() {
        dashCard.deselecte()
        settCard.deselecte()
        taskCard.deselecte()
        instCard.select()
        cardClosureInst(_SplitDetailInstalled)
    }
    
    @objc private
    func updateTaskCardBadgeText() {
        TaskManager.shared.updateTaskList()
        let count = TaskManager.shared.taskCount()
        DispatchQueue.main.async {
            self.taskCard.badgeText = String(count)
        }
    }
    
}
