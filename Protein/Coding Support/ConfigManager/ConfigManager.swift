//
//  ConfigManager.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/18.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit
import WCDBSwift

struct __CydiaConfig: Encodable {
    var udid: String
    var machine: String
    var firmware: String
    var ua: String
    var mess: Bool                                      // ✅
}

struct __ApplicationConfig: Encodable, Decodable {
    var shouldSaveRepoRecord: Bool = true               // ✅
    var smartRefreshTimeGapInMin: Int = 720             // ✅
    var homeScreenShouldShowTips: Bool = true
    var usedLanguage: String = ""                       // ✅
    
    var shouldUploadRepoAnalysis: Bool = false          // ✅
    var shouldAutoUpdateWhenAppLaunch: Bool = false     // ✅
    var shouldNotifyWhenUpdateAvailable: Bool = false   // ✅
    var shouldUploadPackageAnalysis: Bool = false       // ✅
}

struct __NetworkConfig: Encodable, Decodable {
    var maxRepoUpdateQueueNumber: Int = 6               // ✅
    var maxWaitTimeToDownloadRepo: Int = 60             // ✅
}

final class ConfigManager {
    
    static let shared = ConfigManager("wiki.qaq.Protein.vender.ConfigManager")
    static let availableLanguage = ["zh-Hans", "en"]
    
    @Atomic public var CydiaConfig: __CydiaConfig
    @Atomic public var Application: __ApplicationConfig
    @Atomic public var Networking:  __NetworkConfig
    
    public let documentURL: URL
    public var documentString: String {
        get {
            return documentURL.fileString
        }
    }
    
    public let database: Database
    public let tableName = "Protein_ConfigManage_Table"
    
    
    required init(_ vender: String) {
        if vender != "wiki.qaq.Protein.vender.ConfigManager" {
            fatalError()
        }
        

        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!.appendingPathComponent("wiki.qaq.Protein")
        if (!FileManager.default.fileExists(atPath: url.fileString)) {
            try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
        documentURL = url
        
        // Looking for database
        let loca = documentURL.appendingPathComponent("Protein.Config")
        database = Database(withFileURL: loca)
        
        if let _: [ConfigStore] = try? database.getObjects(fromTable: tableName, limit: 1) {
        } else {
            Tools.rprint("[ConfigManager] Table " + tableName + " failed to load, mic drop!")
            try? database.drop(table: tableName)
            try? database.create(table: tableName, of: RepoStore.self)
        }
        
        let machine = UIDevice().identifierMachineFriendly
        let version = UIDevice().systemVersion
        
        CydiaConfig = __CydiaConfig(udid: "0000000000000000000000000000000000000000".lowercased(),
                                   machine: machine,
                                   firmware: version,
                                   ua: "Telesphoreo APT-HTTP/1.0.592",
                                   mess: false)
        Application = __ApplicationConfig()
        Networking = __NetworkConfig()
        
        let pct = ProcessInfo.processInfo.processorCount
        Tools.rprint("ProcessInfo->processorCount: " + String(pct))
        Networking.maxRepoUpdateQueueNumber = pct * 2

        #if DEBUG
        Networking.maxWaitTimeToDownloadRepo = 10
        #endif
        
        resetContainerIfNeeded()
        readUDIDIfNeeded()
        
        loadFromDatabase()
        writeToDatabase()
        NotificationCenter.default.addObserver(self, selector: #selector(writeToDatabase), name: .SettingsUpdated, object: nil)
    }
    
    func readUDIDIfNeeded() {
        let foo = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_GLOBAL | RTLD_LAZY)
        typealias MGCopyAnswerAddr = @convention(c) (CFString) -> CFString
        let MGCopyAnswer = unsafeBitCast(dlsym(foo, "MGCopyAnswer"), to: MGCopyAnswerAddr.self)
        let udid = MGCopyAnswer("UniqueDeviceID" as CFString) as String
        self.CydiaConfig.udid = udid
        Tools.rprint("-> " + udid)
    }
    
    func resetContainerIfNeeded() {
        let versionCompare = "00000022"
        Tools.rprint("Starting Application With Version Control Code [" + versionCompare + "] 👋")
        var root = documentString
        if root.count < 8 { // at least /var/root
            fatalError("Document root dir is not safe: " + root)
        }
        if !root.hasSuffix("/") {
            root += "/"
        }
        let loc = root + "databaseVersionControl"
        do {
            let strRead = try String(contentsOfFile: loc)
            if !strRead.hasPrefix(versionCompare) {
                // should delete
                Tools.rprint("⚠️⚠️⚠️ -> RESET REQUESTED <- ⚠️⚠️⚠️")
                try? FileManager.default.removeItem(atPath: root)
            }
        } catch {
            Tools.rprint("⚠️⚠️⚠️ -> RESET REQUESTED <- ⚠️⚠️⚠️")
            try? FileManager.default.removeItem(atPath: root)
        }
        try? FileManager.default.removeItem(atPath: loc)
        try? FileManager.default.createDirectory(atPath: root, withIntermediateDirectories: true, attributes: nil)
        FileManager.default.createFile(atPath: loc, contents: nil, attributes: nil)
        try? versionCompare.write(toFile: loc, atomically: true, encoding: .utf8)
    }
    
    func loadFromDatabase() {
        if let read: [ConfigStore] = try? database.getObjects(fromTable: tableName, limit: 1) {
            if read.count != 1 {
                return
            }
            let get = read[0]
            
            if let messed = get.attach["CydiaConfig.mess"] {
                if messed == "1" {
                    CydiaConfig.mess = true
                } else {
                    CydiaConfig.mess = false
                }
            }
            if let item = get.attach["NetworkConfig.maxRepoUpdateQueueNumber"] {
                if let value = Int(item) {
                    Networking.maxRepoUpdateQueueNumber = value
                }
            }
            if let item = get.attach["NetworkConfig.maxWaitTimeToDownloadRepo"] {
                if let value = Int(item) {
                    Networking.maxWaitTimeToDownloadRepo = value
                }
            }
            if let item = get.attach["ApplicationConfig.shouldUploadRepoAnalysis"] {
                if item == "1" {
                    Application.shouldUploadRepoAnalysis = true
                } else {
                    Application.shouldUploadRepoAnalysis = false
                }
            }
            if let item = get.attach["ApplicationConfig.shouldAutoUpdateWhenAppLaunch"] {
                if item == "1" {
                    Application.shouldAutoUpdateWhenAppLaunch = true
                } else {
                    Application.shouldAutoUpdateWhenAppLaunch = false
                }
            }
            if let item = get.attach["ApplicationConfig.shouldNotifyWhenUpdateAvailable"] {
                if item == "1" {
                    Application.shouldNotifyWhenUpdateAvailable = true
                } else {
                    Application.shouldNotifyWhenUpdateAvailable = false
                }
            }
            if let item = get.attach["ApplicationConfig.shouldUploadPackageAnalysis"] {
                if item == "1" {
                    Application.shouldUploadPackageAnalysis = true
                } else {
                    Application.shouldUploadPackageAnalysis = false
                }
            }
            if let item = get.attach["ApplicationConfig.shouldSaveRepoRecord"] {
                if item == "1" {
                    Application.shouldSaveRepoRecord = true
                } else {
                    Application.shouldSaveRepoRecord = false
                }
            }
            if let item = get.attach["ApplicationConfig.smartRefreshTimeGapInMin"] {
                if let value = Int(item) {
                    Application.smartRefreshTimeGapInMin = value
                }
            }
            if let item = get.attach["ApplicationConfig.usedLanguage"] {
                Application.usedLanguage = item
            }
            
            
        } else {
            print("[ConfigManager] Loader - Unknown Error")
        }
    }
    
    @objc
    func writeToDatabase() {
        let store = ConfigStore()
        
        store.attach["CydiaConfig.mess"] = CydiaConfig.mess ? "1" : "0"
        store.attach["NetworkConfig.maxRepoUpdateQueueNumber"] =  String(Networking.maxRepoUpdateQueueNumber)
        store.attach["NetworkConfig.maxWaitTimeToDownloadRepo"] = String(Networking.maxWaitTimeToDownloadRepo)
        store.attach["ApplicationConfig.shouldUploadRepoAnalysis"] = Application.shouldUploadRepoAnalysis == true ? "1" : "0"
        store.attach["ApplicationConfig.shouldAutoUpdateWhenAppLaunch"] = Application.shouldAutoUpdateWhenAppLaunch == true ? "1" : "0"
        store.attach["ApplicationConfig.shouldNotifyWhenUpdateAvailable"] = Application.shouldNotifyWhenUpdateAvailable == true ? "1" : "0"
        store.attach["ApplicationConfig.shouldUploadPackageAnalysis"] = Application.shouldUploadPackageAnalysis == true ? "1" : "0"
        store.attach["ApplicationConfig.shouldSaveRepoRecord"] = Application.shouldSaveRepoRecord == true ? "1" : "0"
        store.attach["ApplicationConfig.smartRefreshTimeGapInMin"] = String(Application.smartRefreshTimeGapInMin)
        store.attach["ApplicationConfig.usedLanguage"] = Application.usedLanguage
            
        try! database.drop(table: tableName)
        try! database.create(table: tableName, of: RepoStore.self)
        try! database.insert(objects: [store], intoTable: tableName)
        
    }
    
}
