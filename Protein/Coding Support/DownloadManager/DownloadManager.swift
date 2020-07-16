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
    
    @Atomic private var inDownload = [String : (Float, URLSessionTask, PackageStruct?)]()
    private var queueItem = [(URL, String, ((Float) -> ()), PackageStruct?)]()
    private let thot = CommonThrottler(minimumDelay: 0.5)
    
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
                    self.inDownload[object.0.urlString] = (0, task, object.3)
                }
            }
        }
    }
    
    private func doDownload(fromURL from: URL, withFileName name: String, onProgress: @escaping (Float) -> (), pkgRef: PackageStruct?) -> URLSessionTask {
        
        let str = downloadInProgressLocation + "/" + String.sha256From(data: from.urlString.data) + ".pdl" // MAKE SURE THERE IS EXTENSION NAME
        let dest = URL(fileURLWithPath: str)
        // cache is not located at dest, instead, redownload due to not possible to recover from same priv record location
        if FileManager.default.fileExists(atPath: dest.urlString) {
            try? FileManager.default.removeItem(atPath: dest.urlString)
        }
        let task = down.downlod(from: from, toLocation: dest, withHeaders: Tools.createCydiaHeaders(), onProgress: { (float) in
            onProgress(float)
            if let object = self.inDownload[from.urlString] {
                self.inDownload[from.urlString] = (float, object.1, object.2)
            }
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
                        return
                    }
                    NotificationCenter.default.post(name: .TaskNumberChanged, object: nil)
                    try? FileManager.default.moveItem(atPath: dest.fileString, toPath: self.downloadedContainerLocation + "/" + name)
                    self.saveDownloadedRecord(urlStringAsKey: from.urlString, andLocation: self.downloadedContainerLocation + "/" + name)
                } else {
                    print("[DownloadManager] Download task broken: " + from.urlString)
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
            if let pkg = item.value.2 {
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
            object.1.cancel()
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
        return inDownload[urlAsKey]?.0
    }
    
}

