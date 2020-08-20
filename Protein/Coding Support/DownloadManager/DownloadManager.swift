//
//  DownloadManager.swift
//  Protein
//
//  Created by Lakr Aream on 2020/7/13.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import Foundation

final class DownloadManager {
    
    private let down = ObjCDown.shared()
    private let downDir: String
    private let downloadInProgressLocation: String
    public  let downloadedContainerLocation: String
    private let downloadedRecordLocation: String
    
    required init(_ token: String = "") {
        // Download manager is and is only managed by Task Manager
        assert(token == "E1ACFFDB-1EC3-47C9-AACE-530C1A32E6F0")
        
        downDir = ConfigManager.shared.documentString + "/Downloads"
        downloadInProgressLocation = downDir + "/InProgress"
        downloadedContainerLocation = downDir + "/Completed"
        downloadedRecordLocation = downDir + "/DownloadedRecords.txt"
        
        for item in [downDir, downloadedContainerLocation, downloadInProgressLocation] {
            var check = ObjCBool(false)
            let status = FileManager.default.fileExists(atPath: item, isDirectory: &check)
            if !check.boolValue || !(status) {
                try? FileManager.default.removeItem(atPath: item)
                try? FileManager.default.createDirectory(atPath: item, withIntermediateDirectories: true, attributes: nil)
            }
        }
        
        for item in [downloadedRecordLocation] {
            var check = ObjCBool(false)
            let status = FileManager.default.fileExists(atPath: item, isDirectory: &check)
            if check.boolValue || !(status) {
                try? FileManager.default.removeItem(atPath: item)
                FileManager.default.createFile(atPath: downloadedRecordLocation, contents: nil, attributes: nil)
            }
        }
        
        let readFromExists = (try? String(contentsOfFile: downloadedRecordLocation)) ?? ""
        var write = ""
        for item in readFromExists.components(separatedBy: "\n") {
            let split = item.components(separatedBy: "|")
            if split.count != 2 {
                continue
            }
            if !FileManager.default.fileExists(atPath: split[1]) {
                continue
            }
            write += split[0] + "|" + split[1] + "\n"
        }
        try? FileManager.default.removeItem(atPath: downloadedRecordLocation)
        try? write.write(toFile: downloadedRecordLocation, atomically: true, encoding: .utf8)
        
        // MOCK
        
//        let mock = URL(string: "http://mirror.filearena.net/pub/speed/SpeedTest_256MB.dat")!
//        let mock2 = URL(string: "http://mirror.filearena.net/pub/speed/SpeedTest_256MB.md5")!
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
//            print("send")
//            self.sendToDownload(fromURL: mock, withFileName: "test.bin") { (f) in
//                print(f)
//            }
//        }
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
//            print("cancel")
//            self.cancelDownload(withUrlAsKey: mock.urlString)
//        }
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 12) {
//            print("resend")
//            self.sendToDownload(fromURL: mock, withFileName: "test.bin") { (f) in
//                print(f)
//            }
//        }
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 12) {
//            print("send2")
//            self.sendToDownload(fromURL: mock2, withFileName: "test.bin2") { (f) in
//                print(f)
//            }
//        }
        
    }
    
    struct downloadElement {
        var prog: Float
        var task: URLSessionTask
        var pakg: PackageStruct?
    }
    @Atomic // Fuck Swift compiler error crashed my app! ...
    private var inDownload = [String : downloadElement]()
    private var queueItem = [(URL, String, ((Float) -> ()), PackageStruct?)]()
    private var downloadFailed = [String : Int]()
    private var downloadBroken = [String : Int]()
    private let thot = CommonThrottler(minimumDelay: 0.5)
    
    struct reportElement {
        var name: String
        var from: String
        var time: Double
        var status: reportStatusElement
        
        init(name n: String, from f: String, status s: reportStatusElement) {
            name = n
            from = f
            status = s
            time = Date().timeIntervalSince1970
        }
        
    }
    enum reportStatusElement: String {
        case invalid = "DownloadStatusInvalid"
        case started = "DownloadStatusStarted"
        case succeed = "DownloadStatusSucceed"
        case verifyFailed = "DownloadStatusVerifyFailed"
        case broken = "DownloadStatusBroken"
        case unknown = "DownloadStatusUnknown"
    }
    @Atomic private var reports = [reportElement]()
    
    func sendToDownload(fromPackage: PackageStruct?, fromURL from: URL?, withFileName name: String, restart: Bool = false, onProgress: @escaping (Float) -> ()) {

        defer {
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(name: .TaskNumberChanged, object: nil)
            }
        }
        
        guard let from = from else {
            return
        }
        if inDownload[from.urlString] != nil {
            print("[DownloadManager] Task already exists")
            return
        }
        if !restart && getDownloadedFileLocation(withUrlStringAsKey: from.urlString) != nil {
            let location = getDownloadedFileLocation(withUrlStringAsKey: from.urlString) ?? UUID().uuidString
            if location == self.downloadedContainerLocation + "/" + name {
                print("[DownloadManager] Download file for: " + from.urlString + " already exists")
                return
            }
        }
        
        queue.sync {
            for item in queueItem where item.0.urlString == from.urlString {
                return
            }
            queueItem.append((from, name, onProgress, fromPackage))
            thot.throttle {
                DispatchQueue.global(qos: .background).async {
                    self.queueHandler()
                }
            }
            
        }
        
    }

    private let queue = DispatchQueue(label: "wiki.qaq.Protein.DownloadSync")
    private func queueHandler() {
        thot.throttle {
            self.queue.sync {
                let left = ConfigManager.shared.Networking.maxRepoUpdateQueueNumber - self.inDownload.count
                var capture = self.queueItem
                if left <= 0 {
                    return
                }
                for _ in 0...left {
                    if capture.count <= 0 {
                        return
                    }
                    let object = capture.removeFirst()
                    self.queueItem = capture
                    let task = self.doDownload(fromURL: object.0, withFileName: object.1, onProgress: object.2, pkgRef: object.3)
                    self.inDownload[object.0.urlString] = downloadElement(prog: 0, task: task, pakg: object.3)
                }
            }
        }
    }
    
    let progressFoo = CommonThrottler(minimumDelay: 0.2)
    private func doDownload(fromURL from: URL, withFileName name: String, onProgress: @escaping (Float) -> (), pkgRef: PackageStruct?) -> URLSessionTask {
        
        reports.append(reportElement(name: name, from: from.urlString, status: .started))
        
        if downloadFailed[from.urlString] != nil {
            downloadFailed.removeValue(forKey: from.urlString)
        }
        if downloadBroken[from.urlString] != nil {
            downloadBroken.removeValue(forKey: from.urlString)
        }
        
        let str = downloadInProgressLocation + "/" + String.sha256From(data: from.urlString.data) + ".pdl" // MAKE SURE THERE IS EXTENSION NAME
        let dest = URL(fileURLWithPath: str)
        // cache is not located at dest, instead, redownload due to not possible to recover from same priv record location
        if FileManager.default.fileExists(atPath: dest.urlString) {
            try? FileManager.default.removeItem(atPath: dest.urlString)
        }
        let task = down.downlod(from: from, toLocation: dest, withHeaders: Tools.createCydiaHeaders(), onProgress: { (float) in
            onProgress(float)
            self.progressFoo.throttle {
                if self.inDownload[from.urlString] != nil  {
                    self.inDownload[from.urlString]?.prog = float
                }
            }
            // Saily(32546,0x700005346000) malloc: *** error for object 0x7f7f32091000: pointer being freed was not allocated
            }) { () in
                defer {
                    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1) {
                        NotificationCenter.default.post(name: .TaskNumberChanged, object: nil)
                    }
                }
                if FileManager.default.fileExists(atPath: dest.fileString) {
                    print("[DownloadManager] Download task completed: " + from.urlString)
                    if let pkg = pkgRef, !Tools.DEBDownloadIsVerified(withPkg: pkg, andFileLocation: dest.fileString) {
                        print("[DownloadManager] Package broken, delete! " + pkg.obtainNameIfExists())
                        try? FileManager.default.removeItem(atPath: dest.fileString)
                        self.downloadFailed[from.urlString] = 1
                        self.reports.append(reportElement(name: name, from: from.urlString, status: .broken))
                        return
                    }
                    NotificationCenter.default.post(name: .TaskNumberChanged, object: nil)
                    try? FileManager.default.moveItem(atPath: dest.fileString, toPath: self.downloadedContainerLocation + "/" + name)
                    self.saveDownloadedRecord(urlStringAsKey: from.urlString, andLocation: self.downloadedContainerLocation + "/" + name)
                    self.reports.append(reportElement(name: name, from: from.urlString, status: .succeed))
                } else {
                    print("[DownloadManager] Download task broken: " + from.urlString)
                    self.downloadBroken[from.urlString] = 1
                    self.reports.append(reportElement(name: name, from: from.urlString, status: .broken))
                }
                NotificationCenter.default.post(name: .DownloadFinished, object: ["attach" : from])
                self.inDownload.removeValue(forKey: from.urlString)
                DispatchQueue.global(qos: .background).async {
                    self.queueHandler()
                }
        }
        return task
    }
    
    func saveDownloadedRecord(urlStringAsKey: String, andLocation: String) {
        let readFromExists = (try? String(contentsOfFile: downloadedRecordLocation)) ?? ""
        var write = ""
        for item in readFromExists.components(separatedBy: "\n") {
            let split = item.components(separatedBy: "|")
            if split.count != 2 {
                continue
            }
            write += split[0] + "|" + split[1] + "\n"
        }
        write += urlStringAsKey + "|" + andLocation
        try? FileManager.default.removeItem(atPath: downloadedRecordLocation)
        try? write.write(toFile: downloadedRecordLocation, atomically: true, encoding: .utf8)
    }
    
    func deleteDownloadedRecord(withKey: String) {
        let readFromExists = (try? String(contentsOfFile: downloadedRecordLocation)) ?? ""
        var write = ""
        for item in readFromExists.components(separatedBy: "\n") {
            let split = item.components(separatedBy: "|")
            if split.count != 2 {
                continue
            }
            if withKey == split[0] {
                try? FileManager.default.removeItem(atPath: split[1])
                continue
            }
            write += split[0] + "|" + split[1] + "\n"
        }
        try? FileManager.default.removeItem(atPath: downloadedRecordLocation)
        try? write.write(toFile: downloadedRecordLocation, atomically: true, encoding: .utf8)
    }
    
    func getDownloadedFileLocation(withUrlStringAsKey: String) -> String? {
        let readFromExists = (try? String(contentsOfFile: downloadedRecordLocation)) ?? ""
        for item in readFromExists.components(separatedBy: "\n") {
            let split = item.components(separatedBy: "|")
            if split.count != 2 {
                continue
            }
            if withUrlStringAsKey == split[0] {
                return split[1]
            }
        }
        return nil
    }
    
    func generateTaskReport() -> [TaskManager.Task] {
        var list = [TaskManager.Task]()
        for item in inDownload {
            if let pkg = item.value.pakg {
                let task = TaskManager.Task(id: UUID().uuidString,
                                            type: .downloadTask, name: "TaskOperationName_Download".localized() + pkg.obtainNameIfExists(),
                                            description: item.key,
                                            status: .activated, relatedObjects: ["url" : item.0])
                list.append(task)
            } else {
                let task = TaskManager.Task(id: UUID().uuidString,
                                            type: .downloadTask, name: "TaskOperationName_Download".localized(),
                                            description: "TaskOperationName_DownloadHint".localized(),
                                            status: .activated, relatedObjects: ["url" : item.0])
                list.append(task)
            }
        }
        for item in queueItem {
            if let pkg = item.3 {
                let task = TaskManager.Task(id: UUID().uuidString,
                                            type: .downloadTask, name: "TaskOperationName_Download".localized() + pkg.obtainNameIfExists(),
                                            description: item.0.absoluteString,
                                            status: .queued, relatedObjects: ["url" : item.0])
                list.append(task)
            } else {
                let task = TaskManager.Task(id: UUID().uuidString,
                                            type: .downloadTask, name: "TaskOperationName_Download".localized(),
                                            description: "TaskOperationName_DownloadHint".localized(),
                                            status: .queued, relatedObjects: ["url" : item.0])
                list.append(task)
            }
        }
        return list
    }
    
    func cancelDownload(withUrlAsKey key: String) {
        if let object = inDownload[key] {
            object.task.cancel()
        }
    }
    
    func deleteEverything() {
        
        for item in [downDir, downloadedContainerLocation, downloadInProgressLocation, downDir + "/Caches"] {
            try? FileManager.default.removeItem(atPath: item)
            do {
                try FileManager.default.createDirectory(atPath: item, withIntermediateDirectories: true, attributes: nil)
            } catch let err {
                print(err.localizedDescription)
            }
        }
        
        for item in [downloadedRecordLocation] {
            try? FileManager.default.removeItem(atPath: item)
            FileManager.default.createFile(atPath: downloadedRecordLocation, contents: nil, attributes: nil)
        }
        
    }
    
    func reportProgressOn(urlAsKey: String) -> Float? {
        return inDownload[urlAsKey]?.prog
    }
    
    func doesDownloadEverFailed(urlAsKey: String) -> Bool {
        return downloadFailed[urlAsKey] != nil
    }
    
    func doesDownloadEverBroken(urlAsKey: String) -> Bool {
        return downloadBroken[urlAsKey] != nil
    }
    
    func reportDownloadLogsAndRecords() -> String {
        var ret = ""
        
        for item in reports.sorted(by: { (a, b) -> Bool in
            return a.time > b.time ? true : false
        }) {
            ret += "+ \(item.name)\n  -> \(item.from) \n  -> \(item.status.rawValue.localized())\n\n"
        }
        
        if ret == "" {
            ret = "NoTaskAvailable".localized()
        }
        
        return ret
    }
    
}

