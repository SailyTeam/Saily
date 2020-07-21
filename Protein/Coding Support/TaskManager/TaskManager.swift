//
//  TaskManager.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/19.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import Foundation
import SDWebImage

final class TaskManager {
    
    static let shared = TaskManager("wiki.qaq.Protein.vender.TaskManager")
    public let downloadManager = DownloadManager("E1ACFFDB-1EC3-47C9-AACE-530C1A32E6F0")
    
    required init(_ vender: String) {
        if vender != "wiki.qaq.Protein.vender.TaskManager" {
            fatalError()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(downloadEverything), name: .ApplicationRecoveredRunning, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadEverything), name: .TaskListUpdated, object: nil)
    }

    @Atomic private var ownTaskContainer: [Task] = []
    @Atomic private var unownedTaskContainer: [Task] = []
    
    @Atomic public var inSystemTask: Bool = false
    
    func updateTaskList() {
        
        var newUnownedTaskContainer = [Task]()
        
        // Repos
        let lookup = RepoManager.shared.repos
        let inupdates = RepoManager.shared.inUpdate.map { (url) -> Task in
            var repo: RepoStruct? = nil
            lk0: for item in lookup {
                if item.url.urlString == url.urlString {
                    repo = item
                    break lk0
                }
            }
            if let repo = repo, let url = URL(string: repo.obtainIconLink()) {
                if let image = SDImageCache.shared.imageFromCache(forKey: url.absoluteString) {
                    return Task(type: .unownedTask, name: "TaskOperationName_RepoUpdate".localized() + repo.obtainPossibleName(), description: "-> " + repo.url.urlString, status: .activated, relatedObjects: ["icon" : image])
                } else if let icon = UIImage(data: repo.icon) {
                    return Task(type: .unownedTask, name: "TaskOperationName_RepoUpdate".localized() + repo.obtainPossibleName(), description: "-> " + repo.url.urlString, status: .activated, relatedObjects: ["icon" : icon])
                } else {
                    return Task(type: .unownedTask, name: "TaskOperationName_RepoUpdate".localized() + repo.obtainPossibleName(), description: "-> " + repo.url.urlString, status: .activated, relatedObjects: nil)
                }
            }
            return Task(type: .unownedTask, name: "TaskOperationName_RepoUpdate".localized(), description: "-> " + url.urlString, status: .activated, relatedObjects: nil)
        }
        let queuedUpdate = RepoManager.shared.updateQueue.map { (url) -> Task in
            var repo: RepoStruct? = nil
            lk0: for item in lookup {
                if item.url.urlString == url.urlString {
                    repo = item
                    break lk0
                }
            }
            if let repo = repo, let url = URL(string: repo.obtainIconLink()) {
                if let image = SDImageCache.shared.imageFromCache(forKey: url.absoluteString) {
                    return Task(type: .unownedTask, name: "TaskOperationName_RepoUpdate".localized() + repo.obtainPossibleName(), description: "-> " + repo.url.urlString, status: .pending, relatedObjects: ["icon" : image])
                } else if let icon = UIImage(data: repo.icon) {
                    return Task(type: .unownedTask, name: "TaskOperationName_RepoUpdate".localized() + repo.obtainPossibleName(), description: "-> " + repo.url.urlString, status: .pending, relatedObjects: ["icon" : icon])
                } else {
                    return Task(type: .unownedTask, name: "TaskOperationName_RepoUpdate".localized() + repo.obtainPossibleName(), description: "-> " + repo.url.urlString, status: .pending, relatedObjects: nil)
                }
            }
            return Task(type: .unownedTask, name: "TaskOperationName_RepoUpdate".localized(), description: "-> " + url.urlString, status: .pending, relatedObjects: nil)
        }
        newUnownedTaskContainer.append(contentsOf: inupdates)
        newUnownedTaskContainer.append(contentsOf: queuedUpdate)
        if inupdates.count + queuedUpdate.count > 0 {
            newUnownedTaskContainer.append(Task(type: .unownedTask, name: "TaskOperationName_Index".localized(), description: "TaskOperationName_IndexDescription".localized(), status: .pending, relatedObjects: nil))
        } else {
            if PackageManager.shared.indexInProgress {
                newUnownedTaskContainer.append(Task(type: .unownedTask, name: "TaskOperationName_Index".localized(), description: "TaskOperationName_IndexDescription".localized(), status: .activated, relatedObjects: nil))
            }
        }
        unownedTaskContainer = newUnownedTaskContainer
        
    }
    
    func generateTaskReport() -> [[Task]] {
        var packageTasks: [Task] = []
        var unownedTasks: [Task] = unownedTaskContainer
        for item in ownTaskContainer {
            switch item.type {
            case .packageTask:
                packageTasks.append(item)
            case .downloadTask:
//                downloadTasks.append(item)
                print("downloadTask cant be here")
            case .unownedTask:
                unownedTasks.append(item)
                print("[WATCHOUT] Unowned task in owned container! " + String(item.name) + ": " + String(item.description))
            }
        }
        return [downloadManager.generateTaskReport(), packageTasks, unownedTasks]
    }
    
    func taskCount() -> Int {
        return ownTaskContainer.count + unownedTaskContainer.count + downloadManager.generateTaskReport().count
    }
    
    func packageIsInQueue(identity: String, container: [Task]? = nil) -> Bool {
        if let c = container {
            for item in c where item.type == .packageTask && item.relatedObjects!["identity"] as! String == identity {
                return true
            }
        } else {
            let capture = ownTaskContainer
            for item in capture where item.type == .packageTask && item.relatedObjects!["identity"] as! String == identity {
                return true
            }
        }
        return false
    }
    
    func generatePackageTaskReport() -> [String : (PackageTaskType, PackageStruct)] {
        var ret = [String : (PackageTaskType, PackageStruct)]()
        for item in ownTaskContainer where item.type == .packageTask {
            let type = item.relatedObjects!["type"]! as! PackageTaskType
            if type == .selectInstall || type == .pullupInstall {
                ret[item.relatedObjects!["identity"]! as! String] = (type, item.relatedObjects!["attach"]! as! PackageStruct)
            } else {
                let identity = item.relatedObjects!["identity"]! as! String
                var lookup: PackageStruct?
                lk0: for item in PackageManager.shared.rawInstalled where item.identity == identity {
                    lookup = item
                    break lk0
                }
                if let package = lookup {
                    ret[item.relatedObjects!["identity"]! as! String] = (type, package)
                }
            }
        }
        return ret
    }
    
    private func logPackageResolveReturn(withPackage: PackageStruct, withObject: PackageResolveReturn) {

        print("\n")
        print("---- Package Requirement Reported ----")
        print(withPackage.identity + " - " + withPackage.newestVersion())
        let resolveDiags = withPackage.obtainWantsGroupFromNewestVersion()
        for item in resolveDiags {
            print(item.majorType.rawValue + " -> ")
            for c in item.conditions {
                for b in c {
                    print(" * " + b.identity + ": " + b.mets.rawValue + " ~ " + (b.metsRecord ?? "any") + " *")
                }
            }
            print("")
        }
        
        print("* Extra Install *")
        for item in withObject.extraInstall {
            print(item.identity, separator: "", terminator: " ")
        }
        print("\n* Extra Delete *")
        for item in withObject.extraDelete {
            print(item, separator: "", terminator: " ")
        }
        print("\n* FAILED *")
        for item in withObject.failed {
            for i in item.conditions {
                for c in i {
                    print(c.identity, separator: "", terminator: " ")
                }
            }
        }
        print("\n---------------------------------------")
        print("\n")

        
    }
    
    private func addInstallGetList(with package: PackageStruct, andContainer: [Task], shouldPrint: Bool = true) -> ([Task], PackageResolveReturn) {
        
        let resolveAll = package.generateInstallReport()
        
        if shouldPrint {
            logPackageResolveReturn(withPackage: package, withObject: resolveAll)
        }
        
        if resolveAll.failed.count < 1 {
            // gotcha you!
            var taskToAdd = [Task]()
            // self
            taskToAdd.append(Task(id: UUID().uuidString,
                                  type: .packageTask,
                                  name: "TaskOperationName_PackageInstall".localized() + package.obtainNameIfExists(),
                                  description: "TaskOperationName_PackageInstall_SelectedInstall".localized() + package.newestVersion(),
                                  status: .prepare,
                                  relatedObjects: [
                                    "type": PackageTaskType.selectInstall,
                                    "attach": package,
                                    "identity": package.identity
            ]))
            for item in resolveAll.extraInstall {
                taskToAdd.append(Task(id: UUID().uuidString,
                                      type: .packageTask,
                                      name: "TaskOperationName_PackageInstall".localized() + item.obtainNameIfExists(),
                                      description: "TaskOperationName_PackageInstall_PulledInstall".localized() + item.newestVersion(),
                                      status: .prepare,
                                      relatedObjects: [
                                        "type": PackageTaskType.pullupInstall,
                                        "attach": item,
                                        "identity": item.identity
                ]))
            }
            for item in resolveAll.extraDelete {
                taskToAdd.append(Task(id: UUID().uuidString,
                                      type: .packageTask,
                                      name: "TaskOperationName_PackageDelete".localized() + item,
                                      description: "TaskOperationName_PackageInstall_PulledDelete".localized() + item,
                                      status: .prepare,
                                      relatedObjects: [
                                        "type": PackageTaskType.pullupDelete,
                                        "attachString": item,
                                        "identity": item
                ]))
            }
            // find if duplicated
            var newContainer = [Task]()
            for item in andContainer {
                newContainer.append(item)
            }
            for item in taskToAdd where !packageIsInQueue(identity: item.relatedObjects!["identity"] as! String, container: newContainer) {
                newContainer.append(item)
            }
            newContainer = newContainer.sorted(by: { (taskA, taskB) -> Bool in
                let AT = taskA.relatedObjects!["type"] as! PackageTaskType
                let BT = taskB.relatedObjects!["type"] as! PackageTaskType
                if AT == .selectDelete || AT == .selectDelete {
                    if AT == .selectDelete {
                        return true
                    }
                    if BT == .selectInstall {
                        return true
                    }
                }
                return false
            })
            return (newContainer, resolveAll)
        }
        
        return ([], resolveAll)
    }
    
    func addInstall(with package: PackageStruct) -> PackageTaskModificationReturn {
        
        if inSystemTask {
            return .init(didSuccess: false, resolveObject: PackageResolveReturn(extraInstall: [], extraDelete: [], failed: []))
        }
        
        let ret = addInstallGetList(with: package, andContainer: ownTaskContainer)
        if ret.1.failed.count < 1 {
            ownTaskContainer = ret.0
        }

        NotificationCenter.default.post(name: .TaskNumberChanged, object: nil)
        NotificationCenter.default.post(name: .TaskListUpdated, object: nil)
        NotificationCenter.default.post(name: .UpdateCandidateShouldUpdate, object: nil)
        
        return PackageTaskModificationReturn(didSuccess: ret.1.failed.count == 0, resolveObject: ret.1)
    }
    
    func addDelete(with package: PackageStruct, withContainer: [Task]? = nil) -> (PackageTaskModificationReturn, [Task]) {
        
        if inSystemTask {
            return (.init(didSuccess: false, resolveObject: PackageResolveReturn(extraInstall: [], extraDelete: [], failed: [])), [])
        }
        
        // 1 check all installed if this package is required
        // 2 if there is, return to diag
        let captureCurrentTask = withContainer == nil ? ownTaskContainer : withContainer!
        let captureInstalled = PackageManager.shared.rawInstalled
        var failed = false
        var extraDelete = [PackageStruct]()
        v0: for installedObjects in captureInstalled {
            // installedObjects must not include in queued objects
            for taskin in captureCurrentTask where taskin.type == .packageTask {
                if let identity = taskin.relatedObjects?["attachString"] as? String, identity == installedObjects.identity,
                    let type = taskin.relatedObjects?["type"] as? PackageTaskType, type == .pullupDelete || type == .selectDelete {
                    continue v0
                }
            }
            if installedObjects.identity == package.identity {
                continue v0
            }
            // get depends from packages
            let a0 = installedObjects.obtainWantsGroupFromNewestVersion()
            var passed = true
            for wants in a0 where wants.majorType == .depends {
                var allMets = true
                inner: for conditions in wants.conditions {
                    var groupmets = false
                    for oneCondition in conditions where oneCondition.identity != package.identity {
                        groupmets = true
                    }
                    if !groupmets {
                        // if this package already exists in deleteQueue
                        var inDelete = false
                        taskLookup: for oneCondition in conditions {
                            for taskin in captureCurrentTask where taskin.type == .packageTask {
                                if let identity = taskin.relatedObjects?["attachString"] as? String, identity == oneCondition.identity,
                                    let type = taskin.relatedObjects?["type"] as? PackageTaskType, type == .pullupDelete || type == .selectDelete {
                                    inDelete = true
                                    groupmets = true
                                    break taskLookup
                                }
                            }
                        }
                        // not in delete queue, report group of condition failed to hit
                        if !inDelete {
                            allMets = false
                            break inner
                        }
                    }
                } // inner: group condition lookup!
                if !allMets {
                    passed = false
                    extraDelete.append(installedObjects)
                }
            }
            if !passed {
                failed = true
            }
        }
        
        var returnTasks = captureCurrentTask
        tot: if !failed {
            // hhh, may be able to delete safely but do that later
            for task in returnTasks {
                if let identity = task.relatedObjects?["attachString"] as? String, identity == package.identity {
                    failed = true
                    extraDelete = []
                    returnTasks = []
                    break tot
                }
            }
            let task = Task(id: UUID().uuidString, type: .packageTask,
                            name: "TaskOperationName_PackageDelete".localized() + package.obtainNameIfExists(),
                            description: "TaskOperationName_PackageInstall_SelectedDelete".localized() + package.newestVersion(),
                            status: .pending, relatedObjects: [
                            "type": PackageTaskType.selectDelete,
                            "attachString": package.identity,
                            "identity": package.identity
            ])
            if withContainer == nil {
                ownTaskContainer.append(task)
                returnTasks = ownTaskContainer
            } else {
                returnTasks.append(task)
            }
        }
        
        NotificationCenter.default.post(name: .TaskNumberChanged, object: nil)
        NotificationCenter.default.post(name: .TaskListUpdated, object: nil)
        
        return (PackageTaskModificationReturn(didSuccess: !failed, resolveObject: PackageResolveReturn(extraInstall: [],
                                                                                                     extraDelete: extraDelete.map({ (A) -> String in
                                                                                                        return A.identity
                                                                                                     }),
                                                                                                     failed: [])),
                returnTasks
        )
        
    }
    
    func addDeletes(withList: [String], withContainer: [Task]? = nil) -> (PackageTaskModificationReturn, [Task]) {
        
        if inSystemTask {
            return (.init(didSuccess: false, resolveObject: PackageResolveReturn(extraInstall: [], extraDelete: [], failed: [])), [])
        }
        
        // 1 check all installed if this package is required
        // 2 if there is, return to diag
        let captureCurrentTask = withContainer == nil ? ownTaskContainer : withContainer!
        let captureInstalled = PackageManager.shared.rawInstalled
        var failed = false
        var extraDelete = [PackageStruct]()
        // if all installed's depends has one not in list, success
        v0: for installedObjects in captureInstalled {
            // installedObjects must not include in queued objects
            for taskin in captureCurrentTask where taskin.type == .packageTask {
                if let identity = taskin.relatedObjects?["attachString"] as? String, identity == installedObjects.identity,
                    let type = taskin.relatedObjects?["type"] as? PackageTaskType, type == .pullupDelete || type == .selectDelete {
                    continue v0
                }
            }
            if withList.contains(installedObjects.identity) {
                continue v0
            }
            // get depends from packages
            let a0 = installedObjects.obtainWantsGroupFromNewestVersion()
            var passed = true
            for wants in a0 where wants.majorType == .depends {
                var allMets = true
                inner: for conditions in wants.conditions {
                    var groupmets = false
                    for oneCondition in conditions where !withList.contains(oneCondition.identity) {
                        groupmets = true
                    }
                    if !groupmets {
                        // if this package already exists in deleteQueue
                        var inDelete = false
                        taskLookup: for oneCondition in conditions {
                            for taskin in captureCurrentTask where taskin.type == .packageTask {
                                if let identity = taskin.relatedObjects?["attachString"] as? String, identity == oneCondition.identity,
                                    let type = taskin.relatedObjects?["type"] as? PackageTaskType, type == .pullupDelete || type == .selectDelete {
                                    inDelete = true
                                    groupmets = true
                                    break taskLookup
                                }
                            }
                        }
                        // not in delete queue, report group of condition failed to hit
                        if !inDelete {
                            allMets = false
                            break inner
                        }
                    }
                } // inner: group condition lookup!
                if !allMets {
                    passed = false
                    extraDelete.append(installedObjects)
                }
            }
            if !passed {
                failed = true
            }
        }
        
        var returnTasks = captureCurrentTask
        tot: if !failed {
            doubleCheck: for item in withList {
                var lookInside: PackageStruct? = nil
                inner0: for installed in captureInstalled where installed.identity == item {
                    lookInside = installed
                    break inner0
                }
                if let pkg = lookInside {
                    for task in returnTasks {
                        if let identity = task.relatedObjects?["attachString"] as? String, identity == item {
                            failed = true
                            extraDelete = []
                            returnTasks = []
                            break tot
                        }
                    }
                    
                    let task = Task(id: UUID().uuidString, type: .packageTask,
                                    name: "TaskOperationName_PackageDelete".localized() + pkg.obtainNameIfExists(),
                                    description: "TaskOperationName_PackageInstall_SelectedDelete".localized() + pkg.newestVersion(),
                                    status: .pending, relatedObjects: [
                                    "type": PackageTaskType.selectDelete,
                                    "attachString": pkg.identity,
                                    "identity": pkg.identity
                    ])
                    if withContainer == nil {
                        ownTaskContainer.append(task)
                    } else {
                        returnTasks.append(task)
                    }
                }
            }
        }
        
        NotificationCenter.default.post(name: .TaskNumberChanged, object: nil)
        NotificationCenter.default.post(name: .TaskListUpdated, object: nil)
        
        return (PackageTaskModificationReturn(didSuccess: !failed, resolveObject: PackageResolveReturn(extraInstall: [],
                                                                                                     extraDelete: extraDelete.map({ (A) -> String in
                                                                                                        return A.identity
                                                                                                     }),
                                                                                                     failed: [])),
                returnTasks
        )
    }
    
    func removeQueuedPackage(withIdentity: [String]) -> PackageTaskModificationReturn {
        
        if inSystemTask {
            return .init(didSuccess: false, resolveObject: PackageResolveReturn(extraInstall: [], extraDelete: [], failed: []))
        }
        
        // 1 invoke list
        // 2 remove from list
        // 3 recalculates depends
        
        var requiredInstall = [PackageStruct]()
        var requiredDelete = [String]()
        
        for item in ownTaskContainer where item.type == .packageTask {
            if let pkgTaskType = item.relatedObjects?["type"] as? PackageTaskType {
                switch pkgTaskType {
                case .selectInstall:
                    if let attach = item.relatedObjects?["attach"] as? PackageStruct /*, !withIdentity.contains(attach.identity) */ {
                        requiredInstall.append(attach)
                    }
                case .selectDelete:
                    if let attach = item.relatedObjects?["attachString"] as? String {
                        requiredDelete.append(attach)
                    }
                default:
                    break
                }
            }
        }
        
        var newTaskContainer = [Task]()
        
        // double check
        let captureInstall = requiredInstall
        requiredInstall = []
        let captureDelete = requiredDelete
        requiredDelete = []
        func foo(id: String) -> Bool {
            for item in requiredInstall where item.identity == id {
                return true
            }
            return false
        }
        
        print("[TaskManager] Operation Task Queue Modification Report")
        for item in captureInstall where !withIdentity.contains(item.identity) && !foo(id: item.identity) {
            requiredInstall.append(item)
        }
        print(requiredInstall)
        for item in captureDelete where !withIdentity.contains(item) {
            requiredDelete.append(item)
        }
        print(requiredDelete)
        print("[TaskManager] ----------------------------------------")
        
        for item in requiredInstall {
            if requiredDelete.contains(item.identity) {
                return PackageTaskModificationReturn(didSuccess: false, resolveObject: PackageResolveReturn(extraInstall: [], extraDelete: [], failed: []))
            }
        }
        
        for pkg in requiredInstall {
            print("Looking for " + pkg.identity)
            let take = addInstallGetList(with: pkg, andContainer: newTaskContainer, shouldPrint: false)
            newTaskContainer = take.0
        }
        
        let ret = addDeletes(withList: requiredDelete, withContainer: newTaskContainer)
        if !ret.0.didSuccess {
            return PackageTaskModificationReturn(didSuccess: false, resolveObject: PackageResolveReturn(extraInstall: [], extraDelete: [], failed: []))
        } else {
            newTaskContainer = ret.1
        }
        
        if ownTaskContainer.count <= newTaskContainer.count {
            // we seen from result this means it is required so returns a fail
            return PackageTaskModificationReturn(didSuccess: false, resolveObject: PackageResolveReturn(extraInstall: [], extraDelete: [], failed: []))
        } else {
            ownTaskContainer = newTaskContainer
        }
        
        NotificationCenter.default.post(name: .TaskNumberChanged, object: nil)
        NotificationCenter.default.post(name: .TaskListUpdated, object: nil)
        NotificationCenter.default.post(name: .UpdateCandidateShouldUpdate, object: nil)
        
        return PackageTaskModificationReturn(didSuccess: true, resolveObject: PackageResolveReturn(extraInstall: [], extraDelete: [], failed: []))
    }
    
    func callForDeleteAllSolutionAndReturnDidSuccess(withList: [String]) -> Bool {
        
        if inSystemTask {
            return false
        }
        
        let capture = ownTaskContainer
        let ret = addDeletes(withList: withList, withContainer: capture)
        if !ret.0.didSuccess {
            return false
        }
        ownTaskContainer = ret.1
        NotificationCenter.default.post(name: .TaskNumberChanged, object: nil)
        NotificationCenter.default.post(name: .TaskListUpdated, object: nil)
        NotificationCenter.default.post(name: .UpdateCandidateShouldUpdate, object: nil)
        return true
    }
    
    private let downloadEverythingThrottler = CommonThrottler(minimumDelay: 0.4)
    @objc
    func downloadEverything() {
        downloadEverythingThrottler.throttle {
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.2) {
                var targets = [URL : PackageStruct]()
                let capture = self.ownTaskContainer
                for item in capture where item.type == .packageTask {
                    if let pkg = item.relatedObjects?["attach"] as? PackageStruct, let url = pkg.obtainDownloadLocationFromNewestVersion() {
                        targets[url] = pkg
                    }
                }
                for item in targets {
                    self.downloadManager.sendToDownload(fromPackage: item.value, fromURL: item.key, withFileName: item.key.lastPathComponent) { (progress) in
                        NotificationCenter.default.post(name: .DownloadProgressUpdated, object: nil, userInfo: ["key" : item.key.urlString, "progress" : progress])
                    }
                }
            }
        }
    }
    
    func downloadPackageWith(urlAsKey: String) {
        var targets = [URL : PackageStruct]()
        let capture = ownTaskContainer
        for item in capture where item.type == .packageTask {
            if let pkg = item.relatedObjects?["attach"] as? PackageStruct, let url = pkg.obtainDownloadLocationFromNewestVersion() {
                if url.urlString == urlAsKey {
                    targets[url] = pkg
                }
            }
        }
        for item in targets {
            downloadManager.sendToDownload(fromPackage: item.value, fromURL: item.key, withFileName: item.key.lastPathComponent) { (progress) in
                NotificationCenter.default.post(name: .DownloadProgressUpdated, object: nil, userInfo: ["key" : item.key.urlString, "progress" : progress])
            }
        }
    }
    
    func cancelAllTasks() {
        
        if inSystemTask {
            return
        }
        
        ownTaskContainer = []
        NotificationCenter.default.post(name: .TaskListUpdated, object: nil)
        NotificationCenter.default.post(name: .TaskNumberChanged, object: nil)
    }
    
}
