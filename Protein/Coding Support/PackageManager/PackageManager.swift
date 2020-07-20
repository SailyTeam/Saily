//
//  PackageManager.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/18.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import Foundation
import WCDBSwift

final class PackageManager {
    
    static let shared = PackageManager("wiki.qaq.Protein.vender.PackageManager")
    
    static let atom = DispatchQueue(label: "wiki.qaq.Protein.PackageManager.atom")

    public  let database: Database
    
    public  let tableNamePackageMetaRecords = "Protein_PackageManager_metaUpdatedList"
    public  let tableNameInstalledRecord = "Protein_PackageManager_rawInstalled"
    public  let tableNameWichList = "Protein_PackageManager_wishList"
    
    @Atomic var indexInProgress = false
    
    @Atomic var metaUpdatedList: [PackageStruct] = [] {
        didSet {
            DispatchQueue.global(qos: .background).async {
                NotificationCenter.default.post(name: .RecentUpdateShouldUpdate, object: nil)
            }
        }
    }
    @Atomic var rawInstalled: [PackageStruct] = [] {
        didSet {
            let copy = rawInstalled
            var new = [PackageStruct]()
            copy.withUnsafeBufferPointer { (p) -> () in
                for i in p {
                    if !i.isCydiaGSCPackage() {
                        new.append(i)
                    }
                }
            }
            niceInstalled = new
            updateUpdateCandidate()
            DispatchQueue.global(qos: .background).async {
                NotificationCenter.default.post(name: .rawInstalledShouldUpdate, object: nil)
            }
        }
    }
    @Atomic var niceInstalled: [PackageStruct] = [] {
        didSet {
            DispatchQueue.global(qos: .background).async {
                NotificationCenter.default.post(name: .InstalledShouldUpdate, object: nil)
            }
        }
    }
    @Atomic var installedUpdateCandidate: [(PackageStruct, PackageStruct)] = [] {
        didSet {
            DispatchQueue.global(qos: .background).async {
                NotificationCenter.default.post(name: .UpdateCandidateShouldUpdate, object: nil)
            }
        }
    }
    
    @Atomic var wishList: [PackageStruct] = []
    
    required init(_ vender: String) {
        if vender != "wiki.qaq.Protein.vender.PackageManager" {
            fatalError()
        }
        
        let loca = ConfigManager.shared.documentURL.appendingPathComponent("Protein.Package.Records")
        database = Database(withFileURL: loca)
        
        if let _: [PackageRecordVersionOnly] = try? database.getObjects(fromTable: tableNamePackageMetaRecords, limit: 1) {
        } else {
            Tools.rprint("[PackageManager] Table " + tableNamePackageMetaRecords + " failed to load, mic drop!")
            try? database.drop(table: tableNamePackageMetaRecords)
            try? database.create(table: tableNamePackageMetaRecords, of: PackageRecordVersionOnly.self)
        }
        
        if let _: [PackageRecordUniqueIdentity] = try? database.getObjects(fromTable: tableNameInstalledRecord, limit: 1) {
        } else {
            Tools.rprint("[PackageManager] Table " + tableNameInstalledRecord + " failed to load, mic drop!")
            try? database.drop(table: tableNameInstalledRecord)
            try? database.create(table: tableNameInstalledRecord, of: PackageRecordUniqueIdentity.self)
        }
        
        if let _: [PackageRecordUniqueIdentity] = try? database.getObjects(fromTable: tableNameWichList, limit: 1) {
        } else {
            Tools.rprint("[PackageManager] Table " + tableNameWichList + " failed to load, mic drop!")
            try? database.drop(table: tableNameWichList)
            try? database.create(table: tableNameWichList, of: PackageRecordUniqueIdentity.self)
        }
        if let hi: [PackageRecordUniqueIdentity] = try? database.getObjects(fromTable: tableNameWichList) {
            var newList = [PackageStruct]()
            for i in hi {
                newList.append(i.obtainPackageStruct())
            }
            wishList = newList
        }
        
        updateInstalledFromDpkgStatus()
        updateUpdateCandidate() // setter wont be called duing start up
        syncUpdateMetaUpdateRecords()
        SearchIndexManager.shared.reBuildIndexSync()
    }

    private let indexQueue = DispatchQueue(label: "wiki.qaq.Protein.PackageManager.indexQueue")
    private var latestIndexRequest = Double()
    func updateIndexes() {
        let timeTicket = Date().timeIntervalSince1970
        latestIndexRequest = timeTicket
        indexQueue.async {
            if self.latestIndexRequest != timeTicket {
                return
            }
            self.indexInProgress = true
            DispatchQueue.global(qos: .background).async {
                NotificationCenter.default.post(name: .TaskNumberChanged, object: nil)
            }
            let ticket = UUID().uuidString
            Tools.rprint("[PackageManager] updateIndexes begin with ticket [" + ticket + "]")
            let begin = Date().timeIntervalSince1970
            defer {
                let end = Date().timeIntervalSince1970
                let str = Double(Int((end - begin) * 100)) / 100
                Tools.rprint("[PackageManager] updateIndexes finished with ticket [" + ticket + "] in " + String(str) + "s")
                self.indexInProgress = false
                DispatchQueue.global(qos: .background).async {
                    NotificationCenter.default.post(name: .TaskNumberChanged, object: nil)
                }
            }
            self.updateMetaUpdateRecords()
            self.updateUpdateCandidate()
            SearchIndexManager.shared.reBuildIndexSync()
        }
    }
    
    func updateMetaUpdateRecords() {
        let hi = RepoManager.shared.repos
        var placeHolder = [String : PackageStruct]()
        hi.withUnsafeBufferPointer { (v1) -> () in
            for i in v1 {
                i.metaPackage.forEach { (v2) in
                    placeHolder[v2.key] = v2.value
                }
            }
        }
        if placeHolder.count < 0 {
            return
        }
        if let databaseRecord: [PackageRecordVersionOnly] = try? database.getObjects(fromTable: tableNamePackageMetaRecords) {
            let batchTime = Date().timeIntervalSince1970
            var write = [String : PackageRecordVersionOnly]()
            for item in placeHolder {
                if let has = write[item.key], let get = has.obtainPackageStruct() {
                    let old = get.newestVersion()
                    let new = item.value.newestVersion()
                    if Tools.DEBVersionCompare(A: new, B: old) == .AisBigger {
                        write[item.key] = PackageRecordVersionOnly(withPkg: item.value, andTimeStamp: batchTime)
                    }
                } else {
                    write[item.key] = PackageRecordVersionOnly(withPkg: item.value, andTimeStamp: batchTime)
                }
            }
            for item in databaseRecord {
                if let pkg = placeHolder[item.identity!], let get = item.obtainPackageStruct() {
                    let old = get.newestVersion()
                    let new = pkg.newestVersion()
                    if Tools.DEBVersionCompare(A: old, B: new) == .AisEqualToB {
                        write[item.identity!] = item
                    }
                }
            }
            
            var dodo: [PackageRecordVersionOnly] = []
            for each in write {
                dodo.append(each.value)
            }
            
            try? database.drop(table: tableNamePackageMetaRecords)
            try? database.create(table: tableNamePackageMetaRecords, of: PackageRecordVersionOnly.self)
            try? database.insertOrReplace(objects: dodo, intoTable: tableNamePackageMetaRecords)
        } else {
            fatalError("Your database is damaged - [53CF4D10-9987-4D9B-A4D6-B87A36491390]")
        }
        syncUpdateMetaUpdateRecords()
    }
    
    private func syncUpdateMetaUpdateRecords() {
        if let databaseRecord: [PackageRecordVersionOnly] = try? database.getObjects(fromTable: tableNamePackageMetaRecords,
                                                                          orderBy: [PackageRecordVersionOnly.Properties.timeStamp.asOrder(by: .descending),
                                                                                    PackageRecordVersionOnly.Properties.sortName.asOrder(by: .ascending)])
        {
            var list = [PackageStruct]()
            for item in databaseRecord {
                if let get = item.obtainPackageStruct() {
                    list.append(get)
                }
            }
            metaUpdatedList = list
            Tools.rprint("[PackageManager] syncUpdateMetaUpdateRecords reported " + String(list.count) + " package(s)")
        } else {
            fatalError("Your database is damaged - [53CF4D10-9987-4D9B-A4D6-B87A36491390]")
        }
    }
    
    private
    func copyDpkgStatusOver() {
//        let _ = Tools.spawnCommandSycn("chmod -R 777 /Library/dpkg")
        let cacheDest = ConfigManager.shared.documentString + "/dpkgLoadCache"
        let saveDest = ConfigManager.shared.documentString + "/dpkgStatus"
        let _ = Tools.spawnCommandSycn("cp -rf /Library/dpkg/status " + saveDest + "/status")
        assert(cacheDest != "/")
        assert(cacheDest.count > 5) // keep us safe
        let _ = Tools.spawnCommandSycn("rm -rf " + cacheDest)
        usleep(2333)
        let _ = Tools.spawnCommandSycn("cp -rf /Library/dpkg " + cacheDest)
        usleep(2333)
        let _ = Tools.spawnCommandSycn("chmod -R 777 " + cacheDest)
        usleep(2333)
        try? FileManager.default.removeItem(atPath: cacheDest)
        var done = false
        do {
            try FileManager.default.copyItem(atPath: "/Library/dpkg", toPath: cacheDest)
            done = true
        } catch let error {
           Tools.rprint("[PackageManager] Copying system status from /Library/dpkg failed: " + error.localizedDescription)
        }
        if !done {
            do {
                try FileManager.default.copyItem(atPath: "/var/lib/dpkg", toPath: cacheDest)
                done = true
            } catch {
                Tools.rprint("[PackageManager] Copying system status from /var/lib/dpkg failed")
            }
        }
        if !done {
            Tools.rprint("[PackageManager] Failed to read system status, old one will be used")
            try? FileManager.default.removeItem(atPath: cacheDest)
        } else {
           do {
               if FileManager.default.fileExists(atPath: saveDest) {
                   try FileManager.default.removeItem(atPath: saveDest)
               }
               try FileManager.default.moveItem(atPath: cacheDest, toPath: saveDest)
               Tools.rprint("[DEB-PKG] Status Updated")
               usleep(233333) // just do it
           } catch let error {
               fatalError("Failed to copy items that we created, this is not a bug, this is something shouldnt happen at all: " + error.localizedDescription)
           }
        }
    }
    
    func updateInstalledFromDpkgStatus() {
        copyDpkgStatusOver()
        var placeHolder = [String : PackageStruct]()
        do {
            let saveDest = ConfigManager.shared.documentString + "/dpkgStatus"
            if let read = try? String(contentsOfFile: saveDest + "/status") {
                placeHolder = Tools.invokeDebianMetaForPackages(context: read, fromRepoRef: nil)
            }
            trick0: for foo in placeHolder {
                var meta: [String : [String : String]] = [:]
                let payloads = foo.value.newestMetaData()
                if payloads?["status"] == "deinstall ok config-files" {
                    continue trick0
                }
                meta[foo.value.newestVersion()] = payloads
                placeHolder[foo.key] = PackageStruct(identity: foo.key, versions: meta, fromRepoUrlRef: nil)
            }
        }
        if placeHolder.count < 1 {
            return
        }
        if let databaseRecord: [PackageRecordUniqueIdentity] = try? database.getObjects(fromTable: tableNameInstalledRecord) {
            var write = [PackageRecordUniqueIdentity]()
            let batch = Date().timeIntervalSince1970
            
            for (key, val) in placeHolder {
                // find if any record in databse
                var lookup: PackageRecordUniqueIdentity?
                databaseRecord.withUnsafeBufferPointer { (void) -> () in
                    for foo in void where foo.uniqueIdentity! == key && foo.obtainPackageStruct().newestVersion() == val.newestVersion() {
                        lookup = foo
                        return
                    }
                }
//                #if targetEnvironment(simulator)
//                if lookup != nil && (lookup?.obtainPackageStruct().versions.count ?? 0) != 1 {
//                    fatalError("[Databse Record] Invalid Record")
//                }
//                #endif
                if let lu = lookup, lu.obtainPackageStruct().newestVersion() == val.newestVersion() {
                    write.append(lu)
                } else {
                    write.append(PackageRecordUniqueIdentity(withPkg: val, andTimeStamp: batch))
                }
            }
//            #if targetEnvironment(simulator)
//            for (index, val) in write.enumerated() {
//                for (index2, val2) in write.enumerated() where index2 > index {
//                    if val2.uniqueIdentity == val.uniqueIdentity {
//                        fatalError("[Databse Record] Invalid Record")
//                    }
//                }
//            }
//            #endif
            try? database.drop(table: tableNameInstalledRecord)
            try? database.create(table: tableNameInstalledRecord, of: PackageRecordUniqueIdentity.self)
            try? database.insertOrReplace(objects: write, intoTable: tableNameInstalledRecord)
        } else {
            fatalError("Your database is damaged - [6E1DCD0D-D504-47BC-ABB5-BE28B595CE82]")
        }
        if let databaseRecord: [PackageRecordUniqueIdentity] = try? database.getObjects(fromTable: tableNameInstalledRecord,
                                                                          orderBy: [PackageRecordUniqueIdentity.Properties.timeStamp.asOrder(by: .descending),
                                                                                    PackageRecordUniqueIdentity.Properties.sortName.asOrder(by: .ascending)])
        {
            let repoCopy = RepoManager.shared.repos
            var newInstalled = [PackageStruct]()
            lookups: for obj in databaseRecord {
                guard let unid = obj.uniqueIdentity else {
                    newInstalled.append(obj.obtainPackageStruct())
                    continue lookups
                }
                var get: PackageStruct?
                repoCopy.withUnsafeBufferPointer { (repos) -> () in
                    for r in repos {
                        if let pkg = r.metaPackage[unid]?.truncateMetaDataBy(version: obj.obtainPackageStruct().newestVersion()) {
                            get = pkg
                            return
                        }
                    }
                }
                if let get = get {
                    newInstalled.append(get)
                    continue lookups
                }
                // local packages
                newInstalled.append(obj.obtainPackageStruct())
            }
            rawInstalled = newInstalled
        } else {
            fatalError("Your database is damaged - [6E1DCD0D-D504-47BC-ABB5-BE28B595CE82]")
        }
    }
    
    func updateUpdateCandidate() {
        let installed = niceInstalled
        let repos = RepoManager.shared.repos
        var candidate = [(PackageStruct, PackageStruct)]()
        for each in installed {
            let oldVersion = each.newestVersion()
            var update: PackageStruct?
            for repo in repos {
                if let pkg = repo.metaPackage[each.identity] {
                    let new = pkg.newestVersion()
                    if Tools.DEBVersionCompare(A: new, B: oldVersion) == .AisBigger {
                        if let priv = update, Tools.DEBVersionCompare(A: new, B: priv.newestVersion()) == .AisBigger {
                            update = pkg
                        } else {
                            update = pkg
                        }
                    }
                }
            }
            if let update = update {
                Tools.rprint("[PackageManager] Update candidate [" + each.identity + "] " + each.newestVersion() + " -> " + update.newestVersion() + " #" + (update.fromRepoUrlRef ?? "???"))
                candidate.append((each, update))
            }
        }
        installedUpdateCandidate = candidate
        
        // may crash the app if our task manager didn't finish init
        // but 3 sec should make it done other wise...... I turn the switcher off
        // todo here
        if ConfigManager.shared.Application.shouldAutoUpdateWhenAppLaunch {
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 3) {
                for (_, new) in PackageManager.shared.installedUpdateCandidate {
                    let _ = TaskManager.shared.addInstall(with: new)
                }
            }
        }
        
    }
 
    func wishListExists(withIdentity identity: String) -> Bool {
        let copy = wishList
        for item in copy where item.identity == identity {
            return true
        }
        return false
    }
    
    func wishListAppend(pkg: PackageStruct) {
        var newList = [PackageStruct]()
        for item in wishList where item.identity != pkg.identity {
            newList.append(item)
        }
        newList.append(pkg)
        wishList = newList
        try? database.insertOrReplace(objects: [PackageRecordUniqueIdentity(withPkg: pkg, andTimeStamp: Date().timeIntervalSince1970)], intoTable: tableNameWichList)
        DispatchQueue.global(qos: .background).async {
            NotificationCenter.default.post(name: .WishListShouldUpdate, object: nil)
        }
    }
    
    func wishListDelete(withIdentity identity: String) {
        var newList = [PackageStruct]()
        for item in wishList where item.identity != identity {
            newList.append(item)
        }
        wishList = newList
        try? database.delete(fromTable: tableNameWichList, where: PackageRecordUniqueIdentity.Properties.uniqueIdentity == identity)
        DispatchQueue.global(qos: .background).async {
            NotificationCenter.default.post(name: .WishListShouldUpdate, object: nil)
        }
    }
    
    enum packageStatus: String {
        case clear
        case installed
        case broken
        case outdated
        case undefined
    }
    func packageStatusLookup(identity: String, version: String) -> packageStatus {
        
        if !Tools.DEBVersionIsValid(version) || identity.count < 1 {
            return .broken
        }
        
        for item in installedUpdateCandidate where item.0.identity == identity {
            return .outdated
        }
        
        for item in rawInstalled where item.identity.lowercased() == identity.lowercased() {
            return .installed
        }
        
        return .clear
    }
    
    func getInstalledVersion(withIdentity: String) -> String? {
        for item in rawInstalled where item.identity == withIdentity {
            return item.newestVersion()
        }
        return nil
    }
    
}

