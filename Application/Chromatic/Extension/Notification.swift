//
//  Notification.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/8.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let UserInterfaceFrameChanged = Notification.Name("wiki.qaq.UserInterfaceFrameChanged")

    static let AppleCardColorUpdated = Notification.Name("wiki.qaq.AppleCardColorUpdated")
    static let AppleCardAvatarUpdated = Notification.Name("wiki.qaq.AppleCardAvatarUpdated")

    static let TaskContainerChanged = Notification.Name("wiki.qaq.TaskCountChanged")
    static let DownloadProgress = Notification.Name("wiki.qaq.DownloadProgress")

    static let RepositoryQueueChanged = Notification.Name("wiki.qaq.RepositoryQueueChanged")
    static let RepositoryPaymenChanged = Notification.Name("wiki.qaq.RepositoryPaymenChanged")

    static let LXMainControllerSwitchDashboard = Notification.Name("wiki.qaq.LXMainControllerSwitchDashboard")
    static let LXMainControllerSwitchSettings = Notification.Name("wiki.qaq.LXMainControllerSwitchSettings")
    static let LXMainControllerSwitchTasks = Notification.Name("wiki.qaq.LXMainControllerSwitchTasks")
    static let LXMainControllerSwitchInstalled = Notification.Name("wiki.qaq.LXMainControllerSwitchInstalled")

    static let SettingReload = Notification.Name("wiki.qaq.SettingReload")
}
