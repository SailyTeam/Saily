//
//  NotificationCenter.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/18.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import Foundation

extension Notification.Name {
    
    static let ApplicationRecoveredRunning = Notification.Name("wiki.qaq.Protein.ApplicationRecoveredRunning")
    static let AvatarUpdated = Notification.Name("wiki.qaq.Protein.AvatarUpdated")
    
    static let UISizeChanged = Notification.Name("wiki.qaq.Protein.UISizeChanged")
    
    static let TaskNumberChanged = Notification.Name("wiki.qaq.Protein.TaskNumberChanged")
    static let TaskSystemFinished = Notification.Name("wiki.qaq.Protein.TaskSystemFinished")
    
    static let RepoStoreUpdated = Notification.Name("wiki.qaq.Protein.RepoStoreUpdated")
    static let RepoManagerUpdatedAMeta = Notification.Name("wiki.qaq.Protein.RepoManagerUpdatedAMeta")
    static let RepoManagerUpdatedAllMeta = Notification.Name("wiki.qaq.Protein.RepoManagerUpdatedAllMeta")
    
    static let RepoCardAttemptToDeleteCell = Notification.Name("wiki.qaq.Protein.RepoCardAttemptToDeleteCell")
    
    static let RecentUpdateShouldUpdate = Notification.Name("wiki.qaq.Protein.RecentUpdateShouldUpdate")
    static let RecentUpdateShouldLayout = Notification.Name("wiki.qaq.Protein.RecentUpdateShouldLayout")
    
    static let rawInstalledShouldUpdate = Notification.Name("wiki.qaq.Protein.rawInstalledShouldUpdate")
    static let rawInstalledShouldLayout = Notification.Name("wiki.qaq.Protein.rawInstalledShouldLayout")
    
    static let InstalledShouldUpdate = Notification.Name("wiki.qaq.Protein.InstalledShouldUpdate")
    static let InstalledShouldLayout = Notification.Name("wiki.qaq.Protein.InstalledShouldLayout")
    
    static let UpdateCandidateShouldUpdate = Notification.Name("wiki.qaq.Protein.UpdateCandidateShouldUpdate")
    static let UpdateCandidateShouldLayout = Notification.Name("wiki.qaq.Protein.UpdateCandidateShouldLayout")
    
    static let WishListShouldUpdate = Notification.Name("wiki.qaq.Protein.WishListShouldUpdate")
    static let WishListShouldLayout = Notification.Name("wiki.qaq.Protein.WishListShouldLayout")
    
    static let TaskListUpdated = Notification.Name("wiki.qaq.Protein.TaskListUpdated")
    
    static let SettingsUpdated = Notification.Name("wiki.qaq.Protein.SettingsUpdated")
    
    static let DownloadProgressUpdated = Notification.Name("wiki.qaq.Protein.DownloadProgressUpdated")
    static let DownloadFinished = Notification.Name("wiki.qaq.Protein.DownloadFinished")
    
}
