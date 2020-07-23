//
//  RepoManager.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/18.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import Foundation
import WCDBSwift
import SDWebImage

final class RepoManager {
    
    static let shared = RepoManager("wiki.qaq.Protein.vender.RepoManager")

    @Atomic public var repos: [RepoStruct] = []
    @Atomic public var updateToken: Double = 0
    
    public let database: Database
    public let tableName = "Protein_RepoManager_Table"
    
    private var historyLocation: String {
        get {
            return ConfigManager.shared.documentURL.appendingPathComponent("Protein.Repos.History.Record").fileString
        }
    }
    
    @Atomic var updateDispatchLock = false
    @Atomic private(set) var inUpdate: [URL] = []
    @Atomic private(set) var updateQueue: [URL] = [] {
        didSet {
            DispatchQueue.global(qos: .background).async {
                self.doUpdateIfNeeded()
            }
        }
    }
    
    required init(_ vender: String) {
        if vender != "wiki.qaq.Protein.vender.RepoManager" {
            fatalError()
        }
        
        // Looking for database
        let loca = ConfigManager.shared.documentURL.appendingPathComponent("Protein.Repos")
        database = Database(withFileURL: loca)
        
        if let _: [RepoStore] = try? database.getObjects(fromTable: tableName, limit: 1) {
            reloadReposFromDataBase()
        } else {
            Tools.rprint("[RepoManager] Table " + tableName + " failed to load, mic drop!")
            try? database.drop(table: tableName)
            try? database.create(table: tableName, of: RepoStore.self)
        }
        
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 6) {
            let _ = self.sendToSmartUpdateRepo()
        }
        
    }
    
    public func reloadReposFromDataBase(silent: Bool = false) {
        if let read: [RepoStore] = try? database.getObjects(fromTable: tableName, orderBy: [RepoStore.Properties.url.asOrder(by: .ascending)]) {
            repos = read.map({ (from) -> RepoStruct in
                return from.obtainAttach()
            })
        }
        if !silent {
            DispatchQueue.global(qos: .background).async {
                NotificationCenter.default.post(name: .RepoStoreUpdated, object: nil)
            }
        }
    }
    
    func writeToDataBase(withObject object: RepoStruct, andSync: Bool = false) {
        let store = RepoStore(with: object)
        try? database.insertOrReplace(objects: store, intoTable: tableName)
        if andSync {
            reloadReposFromDataBase()
        } else {
            let operatorCache = self.repos
            var newRepoArray = [RepoStruct]()
            operatorCache.withUnsafeBufferPointer { (pointers) -> () in
                for i in pointers where i.url.urlString != object.url.urlString {
                    newRepoArray.append(i)
                }
            }
            newRepoArray.append(object)
            newRepoArray.sort { (A, B) -> Bool in
                return A.url.urlString < B.url.urlString ? true : false
            }
            repos = newRepoArray
        }
    }
    
    func deleteFromDataBase(_ url: URL, andSync: Bool = false) {
        try? database.delete(fromTable: tableName, where: RepoStore.Properties.url == url.urlString)
        if andSync {
            reloadReposFromDataBase(silent: false)
        } else {
            let operatorCache = self.repos
            var newRepoArray = [RepoStruct]()
            operatorCache.withUnsafeBufferPointer { (pointers) -> () in
                for i in pointers where i.url.urlString != url.urlString {
                    newRepoArray.append(i)
                }
            }
            newRepoArray.sort { (A, B) -> Bool in
                return A.url.urlString < B.url.urlString ? true : false
            }
            repos = newRepoArray
        }
        DispatchQueue.global(qos: .background).async {
            PackageManager.shared.updateIndexes()
        }
    }
    
    func saveHistory(_ url: URL) {
        if !ConfigManager.shared.Application.shouldSaveRepoRecord {
            try? FileManager.default.removeItem(atPath: historyLocation)
            return
        }
        if url.urlString.contains("|") {
            return
        }
        let time = Int(Date().timeIntervalSince1970)
        if !FileManager.default.fileExists(atPath: historyLocation) {
            FileManager.default.createFile(atPath: historyLocation, contents: nil, attributes: nil)
        }
        let read = (try? String(contentsOfFile: historyLocation)) ?? ""
        var save = ""
        var added = [String]()
        for item in read.components(separatedBy: "\n") {
            if let timeString = item.components(separatedBy: "|").last,
                let compare = Int(timeString),
                abs(compare - time) < 1209600,
                let urlString = item.components(separatedBy: "|").first,
                url.urlString != urlString,
                !added.contains(urlString) {
                save += item + "\n"
                added.append(urlString)
            }
        }
        save += url.urlString + "|" + String(time) + "\n"
        do {
            try FileManager.default.removeItem(atPath: historyLocation)
            try save.write(toFile: historyLocation, atomically: true, encoding: .utf8)
        } catch {
            Tools.rprint("[RepoManager] Failed to save history")
        }
    }
    
    func getHistory() -> [URL] {
        if !ConfigManager.shared.Application.shouldSaveRepoRecord {
            try? FileManager.default.removeItem(atPath: historyLocation)
            return []
        }
        if !FileManager.default.fileExists(atPath: historyLocation) {
            return []
        }
        let read = (try? String(contentsOfFile: historyLocation)) ?? ""
        var ret = [URL]()
        let time = Int(Date().timeIntervalSince1970)
        for item in read.components(separatedBy: "\n") {
            if let timeString = item.components(separatedBy: "|").last,
                let compare = Int(timeString),
                abs(compare - time) < 1209600,
                let urlString = item.components(separatedBy: "|").first,
                let url = URL(string: urlString) {
                ret.append(url)
            }
        }
        return ret
    }
    
    func appendNewRepos(withURLs urls: [URL],
                        andSync: Bool = true) {
        for item in urls {
            var create = RepoStruct(url: item)
            var temp = create.obtainPossibleName()
            let a = temp.first ?? "-"
            temp.removeFirst()
            let b = temp.first ?? "-"
            if let data = UIImage.generateImageFrom(charA: a, charB: b, andColor: .randomAsPudding)?.pngData() {
                create.icon = data
            }
            writeToDataBase(withObject: create, andSync: false)
        }
        if andSync {
            reloadReposFromDataBase(silent: true)
        }
        DispatchQueue.global(qos: .background).async {
            NotificationCenter.default.post(name: .RepoManagerUpdatedAllMeta, object: nil)
        }
        let _ = sendToSmartUpdateRepo()
    }
    
    func sendToUpdateQueue(withURL: [URL]) {
        var temp = [URL]()
        let v1 = inUpdate
        var v2 = updateQueue
        for item in withURL {
            let mapper1 = v1.map { (url) -> String in
                return url.urlString
            }
            let mapper2 = v2.map { (url) -> String in
                return url.urlString
            }
            if mapper1.contains(item.urlString) || mapper2.contains(item.urlString) {
                continue
            }
            temp.append(item)
        }
        v2.append(contentsOf: temp)
        updateQueue = v2
        DispatchQueue.global(qos: .background).async {
            for item in withURL {
                let info = RepoTableViewCellNotifyStatusObject(urlStringRef: item.urlString, lastUpdateRelease: 0, lastUpdatePackage: 0, nameStringRef: "")
                NotificationCenter.default.post(name: .RepoManagerUpdatedAMeta, object: nil, userInfo: ["attach" : info])
            }
        }
        self.doUpdateIfNeeded()
    }

    func sendToSmartUpdateRepo() -> Bool {
        var ret = false
        let copy = repos
        let date = Date().timeIntervalSince1970
        var newQ = self.updateQueue
        let inQ = self.inUpdate
        let timeGap = Double(ConfigManager.shared.Application.smartRefreshTimeGapInMin * 60)
        var notifyTarget: [String] = []
        for item in copy {
            let packGap = abs(item.lastUpdatePackage - date)
            let releGap = abs(item.lastUpdateRelease - date)
            if packGap > timeGap || releGap > timeGap {
                if !newQ.contains(item.url) && !inQ.contains(item.url) {
                    ret = true
                    newQ.append(item.url)
                    notifyTarget.append(item.url.urlString)
                }
            }
        }
        updateQueue = newQ
        DispatchQueue.global(qos: .background).async {
            for item in notifyTarget {
                let info = RepoTableViewCellNotifyStatusObject(urlStringRef: item, lastUpdateRelease: 0, lastUpdatePackage: 0, nameStringRef: "")
                NotificationCenter.default.post(name: .RepoManagerUpdatedAMeta, object: nil, userInfo: ["attach" : info])
            }
            self.doUpdateIfNeeded()
        }
        return ret
    }
    
    private var sendEverythingToUpdateTot = CommonThrottler(minimumDelay: 1)
    func sendEverythingToUpdate() {
        sendEverythingToUpdateTot.throttle {
            let copy = self.repos
            var newQ = self.updateQueue
            for item in copy {
                if !newQ.contains(item.url) {
                    newQ.append(item.url)
                }
            }
            self.updateQueue = newQ
            DispatchQueue.global(qos: .background).async {
                NotificationCenter.default.post(name: .RepoManagerUpdatedAllMeta, object: nil)
            }
            self.doUpdateIfNeeded()
        }
    }
    
    @objc private
    func doUpdateIfNeeded() {
        // thread safe is a fuck thing
        if updateDispatchLock {
            return
        }
        updateDispatchLock = true
        defer {
            updateDispatchLock = false
        }
        
        // locked already
        let ouq = self.updateQueue
        let oiu = self.inUpdate
        let maxUpdateLimit = ConfigManager.shared.Networking.maxRepoUpdateQueueNumber
        if oiu.count > maxUpdateLimit {
            return
        }
            
        let howManyToAddToQueue = maxUpdateLimit - oiu.count
        var willUpdate: [URL] = []
        var newUpdateQueue = [URL]()
        for (index, object) in ouq.enumerated() {
            if index < howManyToAddToQueue {
                willUpdate.append(object)
            } else {
                newUpdateQueue.append(object)
            }
        }
        updateQueue = newUpdateQueue

        let copy = repos
        for item in willUpdate {
            var repo: RepoStruct?
            for r in copy where r.url.urlString == item.urlString {
                repo = r
            }
            if let repo = repo {
                let guardDetect = inUpdate
                var found = false
                for item in guardDetect where item.urlString == repo.url.urlString {
                    found = true
                }
                if found {
                    rprintStatus(repo.obtainPossibleName(), "Rejected to update due to already in update")
                } else {
                    inUpdate.append(repo.url)
                }
            }
        }
            
        for item in willUpdate {
            Tools.rprint("[RepoManager] Sending update " + item.absoluteString + " 🚀")
            DispatchQueue.global(qos: .background).async {
                var repo: RepoStruct?
                for r in copy where r.url.urlString == item.urlString {
                    repo = r
                }
                if let repo = repo {
                    self._doUpdateInThisBlock(withRepoRef: repo)
                }
            }
        }

    }

    private func _doUpdateInThisBlock(withRepoRef repo: RepoStruct) {
        
        let secondCheck = RepoManager.shared.repos
        var lookupExists = false
        lookup0: for item in secondCheck {
            if item.url.urlString == repo.url.urlString {
                lookupExists = true
                break lookup0
            }
        }
        if !lookupExists {
            rprintStatus(repo.obtainPossibleName(), "An update was rejected due to repo no longer exists")
            let oiu = inUpdate
            var new = [URL]()
            for item in oiu where item.urlString != repo.url.urlString {
                new.append(item)
            }
            inUpdate = new
            if inUpdate.count < 1 && updateQueue.count < 1 {
                reloadReposFromDataBase()
            }
            return
        }
        
        defer {
            DispatchQueue.global(qos: .background).async {
                NotificationCenter.default.post(name: .TaskNumberChanged, object: nil)
            }
        }
        
        DispatchQueue.global(qos: .background).async {
            NotificationCenter.default.post(name: .RepoManagerUpdatedAMeta, object: nil, userInfo: ["attach" : RepoTableViewCellNotifyStatusObject(urlStringRef: repo.url.urlString, lastUpdateRelease: 0, lastUpdatePackage: 0, nameStringRef: "")])
        }
        
        rprintStatus(repo.obtainPossibleName(), "An update was started")
        
        let beginTimeStamp = Date().timeIntervalSince1970
        
        let releaseSem = DispatchSemaphore(value: 0)
        let packageSem = DispatchSemaphore(value: 0)
        
        // Crashed too many times
        let networkAppendQueue = DispatchQueue(label: "wiki.qaq.Protein.RepoManager.networkAppendQueue")
        var _networkTasks: [Any] = []
        var networkTasks: [Any] {
            set {
                networkAppendQueue.sync {
                    _networkTasks = newValue
                }
            }
            get {
                networkAppendQueue.sync {
                    return _networkTasks
                }
            }
        }
        
        var releaseRAW: String?
        var packageRAW: String?
        var packageSearchCache: String?
        rl: do {
            guard let target = URL(string: repo.obtainReleaseLink()) else {
                releaseSem.signal()
                break rl
            }
            DispatchQueue.global(qos: .background).async {
                let request = Tools.createCydiaRequest(url: target, slient: true, timeout: ConfigManager.shared.Networking.maxWaitTimeToDownloadRepo)
                let config = URLSessionConfiguration.default
                let session = URLSession(configuration: config)
                let task = session.dataTask(with: request) { (data, resp, error) in
                    if let data = data, let resp = resp as? HTTPURLResponse {
                        if resp.statusCode != 200 {
                        } else {
                            if var str = String(data: data, encoding: .utf8), Tools.testIfStringIsDEBIANContext(strToTest: str) {
                                str.cleanAndReplaceLineBreaker()
                                releaseRAW = str
                                self.rprintStatus(repo.obtainPossibleName(), "A release update was found at " + target.absoluteString + " encoded as utf8 ✅")
                            } else if var str = String(data: data, encoding: .ascii), Tools.testIfStringIsDEBIANContext(strToTest: str) {
                                str.cleanAndReplaceLineBreaker()
                                releaseRAW = str
                                self.rprintStatus(repo.obtainPossibleName(), "A release update was found at " + target.absoluteString + " encoded as ascii ✅")
                            } else {
                                self.rprintStatus(repo.obtainPossibleName(), "A release update was failed to decode ❌")
                            }
                        }
                    }
                    releaseSem.signal()
                }
                task.resume()
            }
        }
        dl: do {
            guard let target = URL(string: repo.obtainPackageLink()) else {
                break dl
            }
            if repo.cacheSearchPath != "" {
                func tryToDownloadPackagesFromCachedSearchPath(url: URL, type: String) -> String? {
                    let sem = DispatchSemaphore(value: 0)
                    let decodeSem = DispatchSemaphore(value: 0)
                    var downloadedSignal = false
                    var get: String?
                    DispatchQueue.global(qos: .background).async {
                        let request: URLRequest
                        if type == "" {
                            request = Tools.createCydiaRequest(url: url, slient: true, timeout: ConfigManager.shared.Networking.maxWaitTimeToDownloadRepo)
                        } else {
                            request = Tools.createCydiaRequest(url: url.appendingPathExtension(type), slient: true, timeout: ConfigManager.shared.Networking.maxWaitTimeToDownloadRepo)
                        }
                        let config = URLSessionConfiguration.default
                        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
                        let task = session.dataTask(with: request) { (data, respond, error) in
                            if let data = data, let resp = respond as? HTTPURLResponse {
                                if resp.statusCode != 200 {
                                    
                                } else {
                                    downloadedSignal = true
                                    let decode: Data?
                                    if type == "" {
                                        decode = data
                                    } else if type == "bz" || type == "bz2" {
                                        decode = Tools.decompressBZ(data: data)
                                    } else {
                                        decode = libArchiveGetData(data)
                                    }
                                    if let decoded = decode, decoded.count > 0 {
                                        if var str = String(data: decoded, encoding: .utf8),
                                            str.cleanAndReplaceLineBreakerInIfLet(),
                                            Tools.testIfStringIsDEBIANContext(strToTest: str) {
                                            get = str
                                        } else if var str = String(data: decoded, encoding: .ascii),
                                            str.cleanAndReplaceLineBreakerInIfLet(),
                                            Tools.testIfStringIsDEBIANContext(strToTest: str) {
                                            str.cleanAndReplaceLineBreaker()
                                            get = str
                                        }
                                    } else {
                                        
                                    }
                                    decodeSem.signal()
                                }
                            }
                            sem.signal()
                        }
                        task.resume()
                    } // Dispatch
                    if get == nil {
                        let _ = sem.wait(timeout: .now() + Double(ConfigManager.shared.Networking.maxWaitTimeToDownloadRepo))
                    }
                    if downloadedSignal {
                        decodeSem.wait()
                    }
                    if get?.hasPrefix("<!DOCTYPE html>") ?? false {
                        get = nil
                    }
                    return get
                }
                
                let pathType = repo.cacheSearchPath == "wiki.qaq.Protein.Empty.DataStore" ? "" : repo.cacheSearchPath
                if let downloadFromLastPath = tryToDownloadPackagesFromCachedSearchPath(url: target, type: pathType) {
                    rprintStatus(repo.obtainPossibleName(), "A package update was found at cached search path at " + target.absoluteString + " ✅")
                    packageRAW = downloadFromLastPath
                    packageSearchCache = repo.cacheSearchPath
                    packageSem.signal()
                    break dl
                } else {
                    rprintStatus(repo.obtainPossibleName(), "Cached search path returned nil at " + target.absoluteString)
                }
            }
            
            let search = ["bz2", "", "xz", "gz", "lzma", "lzma2", "bz", "xz2", "gz2"]
            var searchCount = search.count
            for item in search {
                DispatchQueue.global(qos: .background).async {
                    let request: URLRequest
                    if item == "" {
                        request = Tools.createCydiaRequest(url: target, slient: true, timeout: ConfigManager.shared.Networking.maxWaitTimeToDownloadRepo)
                    } else {
                        request = Tools.createCydiaRequest(url: target.appendingPathExtension(item), slient: true, timeout: ConfigManager.shared.Networking.maxWaitTimeToDownloadRepo)
                    }
                    let sync = DispatchQueue(label: "wiki.qaq.Protein.sync.rnd." + UUID().uuidString)
                    let config = URLSessionConfiguration.default
                    let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
                    let task = session.dataTask(with: request) { (data, respond, error) in
                        if let data = data, let resp = respond as? HTTPURLResponse {
                            if resp.statusCode != 200 {
                            } else {
                                let decode: Data?
                                if item == "" {
                                    decode = data
                                } else if item == "bz" || item == "bz2" {
                                    decode = Tools.decompressBZ(data: data)
                                } else {
                                    decode = libArchiveGetData(data)
                                }
                                if let decoded = decode, decoded.count > 0 {
                                    if var str = String(data: decoded, encoding: .utf8),
                                        str.cleanAndReplaceLineBreakerInIfLet(),
                                        Tools.testIfStringIsDEBIANContext(strToTest: str) {
                                        sync.sync {
                                            if packageRAW != nil {
                                                return
                                            }
                                            if packageSearchCache == nil {
                                                packageSearchCache = item == "" ? "wiki.qaq.Protein.Empty.DataStore" : item
                                            }
                                            packageRAW = str
                                        }
                                        packageSem.signal()
                                        self.rprintStatus(repo.obtainPossibleName(), "A package update was found at " + target.absoluteString  + " - " + item + " with utf8 decoder ✅")
                                        return
                                    } else if var str = String(data: decoded, encoding: .ascii),
                                        str.cleanAndReplaceLineBreakerInIfLet(),
                                        Tools.testIfStringIsDEBIANContext(strToTest: str) {
                                        sync.sync {
                                            if packageRAW != nil {
                                                return
                                            }
                                            if packageSearchCache == nil {
                                                packageSearchCache = item == "" ? "wiki.qaq.Protein.Empty.DataStore" : item
                                            }
                                            packageRAW = str
                                        }
                                        packageSem.signal()
                                        self.rprintStatus(repo.obtainPossibleName(), "A package update was found at " + target.absoluteString  + " - " + item + " with ascii decoder ✅")
                                        return
                                    } else {
                                        self.rprintStatus(repo.obtainPossibleName(), "A package update was failed at " + target.absoluteString  + " - " + item + " due to error return from decoder ❌")
                                    }
                                }
                            }
                        }
                        searchCount -= 1
                        if searchCount < 1 {
                            self.rprintStatus(repo.obtainPossibleName(), "Breaking DispatchSemaphore due to meta look up failed at all ⚠️ ❌")
                            self.rprintStatus(repo.obtainPossibleName(), "Last error recorded was: " + (error?.localizedDescription ?? " [NO DESCRIPTION PROVIDED]"))
                            packageSem.signal()
                        }
                    }
                    task.resume()
                    var get = networkTasks
                    get.append(task)
                    networkTasks = get
                }
            }
        }
        
        let paymentSem = DispatchSemaphore(value: 0)
        var paymentEndpoint: String? = nil
        DispatchQueue.global(qos: .background).async {
            paymentEndpoint = RepoPaymentManager.shared.queryEndpointAndSaveToRam(urlAsKey: repo.url.urlString, fromUpdate: true)
            paymentSem.signal()
        }
        
        
        if releaseRAW == nil {
            let _ = releaseSem.wait(timeout: .now() + Double(ConfigManager.shared.Networking.maxWaitTimeToDownloadRepo))
        }
        
        if packageRAW == nil {
            let _ = packageSem.wait(timeout: .now() + Double(ConfigManager.shared.Networking.maxWaitTimeToDownloadRepo))
        }
        
        if paymentEndpoint == nil {
            let _ = paymentSem.wait(timeout: .now() + Double(ConfigManager.shared.Networking.maxWaitTimeToDownloadRepo))
        }
        
        let timeUsedToUpdateMetas = Double(Int((Date().timeIntervalSince1970 - beginTimeStamp) * 100)) / 100
        rprintStatus(repo.obtainPossibleName(), "Meta lookup finished in " + String(timeUsedToUpdateMetas) + "s, stop all networks...")
        
        let readTasks = networkTasks
        networkAppendQueue.sync {
            for item in readTasks {
                if let task = item as? URLSessionTask {
                    task.cancel()
                    continue
                }
                if let task = item as? URLSessionDataTask {
                    task.cancel()
                    continue
                }
            }
        }
        
        let metaTimeStamp = Date().timeIntervalSince1970
        
        var newRepo: RepoStruct? = nil
        
        if packageRAW != nil {
            var _newRepo = repo
            if let release = releaseRAW {
                _newRepo.setReleaseMeta(withContext: release)
            }
            if let package = packageRAW {
                _newRepo.setPackageMeta(withContext: package)
            }
            if let cache = packageSearchCache {
                _newRepo.cacheSearchPath = cache
            }
            if let paymentEndpoint = paymentEndpoint {
                _newRepo.paymentInfo["endpoint"] = paymentEndpoint
            }
            let timeUsedToInvokeMetas = Double(Int((Date().timeIntervalSince1970 - metaTimeStamp) * 100)) / 100
            rprintStatus(repo.obtainPossibleName(), "Meta invoke finished in " + String(timeUsedToInvokeMetas) + "s")

            let timeUsedToUpdate = Double(Int((Date().timeIntervalSince1970 - beginTimeStamp) * 100)) / 100

            if _newRepo.metaPackage.count > 0 {
                // check if still exists before write
                let dododo = self.repos
                var found = false
                for item in dododo where item.url.urlString == repo.url.urlString {
                    found = true
                }
                if found {
                    writeToDataBase(withObject: _newRepo, andSync: false)
                } else {
                    rprintStatus(repo.obtainPossibleName(), "Rejected to write due to repo not found in ram, maybe deleted.")
                }
                Tools.rprint("")
                Tools.rprint("[RepoManager] An update was finished in " + String(timeUsedToUpdate) + " second(s)")
                Tools.rprint("      * " + _newRepo.url.urlString)
                Tools.rprint("      *       Release Objects: " + String(_newRepo.metaRelease.count))
                Tools.rprint("      *       Package Objects: " + String(_newRepo.metaPackage.count))
                Tools.rprint("      *       Search Location: " + String(_newRepo.cacheSearchPath))
                Tools.rprint("")
                newRepo = _newRepo
            } else {
                Tools.rprint("")
                Tools.rprint("❌")
                Tools.rprint("[RepoManager] Ignoring repo that contains 0 package but finished in " + String(timeUsedToUpdate) + " second(s)")
                Tools.rprint("      * " + _newRepo.url.urlString)
                Tools.rprint("      *       Release Objects: " + String(_newRepo.metaRelease.count))
                Tools.rprint("      *       Package Objects: " + String(_newRepo.metaPackage.count))
                Tools.rprint("      *       Search Location: " + String(_newRepo.cacheSearchPath))
                Tools.rprint("")
            }
        } else {
            // skip update due to bad fetch
            self.rprintStatus(repo.obtainPossibleName(), "Update was rejected due to nil package data")

        }
        
        // At the end of the world
        
        DispatchQueue.global(qos: .background).async {
            let oiu = self.inUpdate
            var new = [URL]()
            for item in oiu where item.urlString != repo.url.urlString {
                new.append(item)
            }
            self.inUpdate = new
            if self.inUpdate.count < 1 && self.updateQueue.count < 1 {
//                Tools.rprint("[RepoManager] Batch update requested database reload")
//                self.reloadReposFromDataBase()
                Tools.rprint("[RepoManager] Batch update finished")
                self.updateToken = Date().timeIntervalSince1970
                PackageManager.shared.updateIndexes()
            } else {
                Tools.rprint("[RepoManager] 🕶️ " + String(self.updateQueue.count + self.inUpdate.count) + " repo(s) left to go!")
                DispatchQueue.global(qos: .background).async {
                    self.doUpdateIfNeeded()
                }
            }
            
            DispatchQueue.global(qos: .background).async {
                NotificationCenter.default.post(name: .RecentUpdateShouldUpdate, object: nil)
                if let newRepo = newRepo {
                    let info = RepoTableViewCellNotifyStatusObject(urlStringRef: newRepo.url.urlString, lastUpdateRelease:newRepo.lastUpdateRelease, lastUpdatePackage: newRepo.lastUpdatePackage, nameStringRef: newRepo.obtainPossibleName())
                    NotificationCenter.default.post(name: .RepoManagerUpdatedAMeta, object: nil, userInfo: ["attach" : info])
                } else {
                    let info = RepoTableViewCellNotifyStatusObject(urlStringRef: repo.url.urlString, lastUpdateRelease: repo.lastUpdateRelease,lastUpdatePackage: repo.lastUpdatePackage, nameStringRef: repo.obtainPossibleName())
                    NotificationCenter.default.post(name: .RepoManagerUpdatedAMeta, object: nil, userInfo: ["attach" : info])
                }
            }
        }
           
    }
    
    private func rprintStatus(_ repoDescriptionName: String, _ what2print: String) {
        Tools.rprint("[RepoManager] " + repoDescriptionName + " -> " + what2print)
    }
    
}

