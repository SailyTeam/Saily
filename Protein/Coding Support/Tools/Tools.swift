//
//  Extensions.swift
//  aLittle
//
//  Created by Lakr Aream on 3/13/20.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit

class Tools {
    
    required init() {
        fatalError("\n\nTools does not contain un_static_function so init not allowed")
    }
    
    @Atomic static var ramLogs = ""
    fileprivate static var logQueue = DispatchQueue(label: "wiki.qaq.Protein.RamLogs") // because it ever crashed
//* thread #12, queue = 'com.apple.root.background-qos', stop reason = EXC_BAD_ACCESS (code=1, address=0x10eb00008)
//        frame #3: 0x000000010090ed48 Protein`Atomic.load(self=Protein.Atomic<Swift.String> @ 0x000000016f72d1e0) at Atomic.swift:27:16
//        frame #4: 0x000000010090e970 Protein`Atomic.wrappedValue.getter(self=Protein.Atomic<Swift.String> @ 0x000000016f72d1e0) at Atomic.swift:20:20
//        frame #5: 0x00000001009a0d58 Protein`static Tools.ramLogs.modify(self=Protein.Tools) at Tools.swift:0
//        frame #6: 0x00000001009a0ff0 Protein`static Tools.rprint(str="      *       Package Objects: 10", self=Protein.Tools) at Tools.swift:21:9

    static func rprint(_ str: String) {
        var get = str
        print(str)
        if !get.hasSuffix("\n") {
            get.append("\n")
        }
        Tools.logQueue.async {
            ramLogs.append(get)
        }
    }
    
    static func createCydiaHeaders() -> [String : String] {
        
        var ret = [String : String]()
        
        if ConfigManager.shared.CydiaConfig.mess {
            ret["X-Machine"] = [
            "iPhone6,1", "iPhone6,2", "iPhone7,2", "iPhone7,1", "iPhone8,1", "iPhone8,2", "iPhone9,1", "iPhone9,3", "iPhone9,2", "iPhone9,4", "iPhone8,4", "iPhone10,1", "iPhone10,4", "iPhone10,2", "iPhone10,5", "iPhone10,3", "iPhone10,6", "iPhone11,2", "iPhone11,4", "iPhone11,6", "iPhone11,8", "iPhone12,1", "iPhone12,3", "iPhone12,5", "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4", "iPad3,1", "iPad3,2", "iPad3,3", "iPad3,4", "iPad3,5", "iPad3,6", "iPad6,11", "iPad6,12", "iPad7,5", "iPad7,6", "iPad7,11", "iPad7,12", "iPad4,1", "iPad4,2", "iPad4,3", "iPad5,3", "iPad5,4", "iPad11,4", "iPad11,5", "iPad2,5", "iPad2,6", "iPad2,7", "iPad4,4", "iPad4,5", "iPad4,6", "iPad4,7", "iPad4,8", "iPad4,9", "iPad5,1", "iPad5,2", "iPad11,1", "iPad11,2", "iPad6,3", "iPad6,4", "iPad7,3", "iPad7,4", "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4", "iPad8,9", "iPad8,10", "iPad6,7", "iPad6,8", "iPad7,1", "iPad7,2", "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8", "iPad8,11", "iPad8,12"
            ].randomElement()
            var udid = ""
            while udid.count < "E667727230424CEDAB64C41DF94536E7DF94536E".count {
                udid += UUID().uuidString.dropLast("-3042-4CED-AB64-C41DF94536E7".count)
            }
            while udid.count > "E667727230424CEDAB64C41DF94536E7DF94536E".count {
                udid = String(udid.dropLast())
            }
            udid = udid.lowercased()
            ret["X-Unique-ID"] = udid
            ret["X-Firmware"] = [
            "13.0", "13.1", "13.2", "13.3", "13.4",
            "12.0", "12.1", "12.2", "12.3", "12.4",
            "11.0", "11.1", "11.2", "11.3", "11.4",
            ].randomElement()
            ret["User-Agent"] = "Telesphoreo APT-HTTP/1.0." + String(Int.random(in: 580...620))
        } else {
            ret["X-Unique-ID"] = ConfigManager.shared.CydiaConfig.udid
            ret["X-Machine"] = ConfigManager.shared.CydiaConfig.machine
            ret["X-Firmware"] = ConfigManager.shared.CydiaConfig.firmware
            ret["User-Agent"] = ConfigManager.shared.CydiaConfig.ua
        }

        return ret
    }
    
    static func createCydiaRequest(url: URL, slient: Bool = false, timeout: Int = 10, messRequest: Bool = ConfigManager.shared.CydiaConfig.mess) -> URLRequest {
        
        if !slient {
            Tools.rprint("[CydiaRequest] Requesting GET to -> " + url.absoluteString)
        }
        
        var request: URLRequest
        request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval:  TimeInterval(timeout))
        
        let meta = Tools.createCydiaHeaders()
        for item in meta {
            request.setValue(item.value, forHTTPHeaderField: item.key)
        }
        
        request.httpMethod = "GET"
        
        return request
    }

    static func obtainTimeGapDescription(fromA: Double, toB: Double) -> String {
        let gap = abs(fromA - toB)
        if gap < 300 {
            return "TimeGap_JustNow".localized()
        }
        if gap < 3600 {
            let min = Int(gap / 60)
            return String(min) + "TimeGap_MinBefore".localized()
        }
        if gap < 86400 {
            let h = Int(gap / 3600)
            return String(h) + "TimeGap_HoursBefore".localized()
        }
        if gap < 2592000 {
            let d = Int(gap / 86400)
            return String(d) + "TimeGap_DaysBefore".localized()
        }
        return "TimeGap_OutDated".localized()
    }
    
    static func decompressBZ(data: Data) -> Data? {
        if let data = try? BZipCompression.decompressedData(with: data) {
            return data
        }
        return nil
    }
    
    static func spawnCommandSycn(_ cmd: String) -> String {
        #if targetEnvironment(simulator)
        return "System is not available on simulator"
        #else
        return objcSpawnCommandSync(cmd)
        #endif
    }
    
    static func spawnCommandAndWriteToFileReturnFileLocationAndSignalFileLocation(_ cmd: String) -> (String, String) {

        let dir = ConfigManager.shared.documentString + "/SystemEvents/"
        let signalFile = dir + UUID().uuidString + ".txt"
        let outFile = dir + UUID().uuidString + ".txt"
        let scriptLocation = dir + UUID().uuidString + ".sh"
        
        var objc = ObjCBool(false)
        let test = FileManager.default.fileExists(atPath: dir, isDirectory: &objc)
        if !test || !objc.boolValue {
            try? FileManager.default.removeItem(atPath: dir)
            try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
        }
        
        // generate script
        let scriptContext = "#!/bin/sh\n\n" + cmd + "\n" + "echo done &> " + signalFile + "\n" + "rm -f " + scriptLocation
        // write to target dir
        try? scriptContext.write(toFile: scriptLocation, atomically: true, encoding: .utf8)
        // generate system command
        let command = " (chmod +x " + scriptLocation + " && " + scriptLocation + " | tee " + outFile + " &)"
        
        Tools.rprint(scriptContext)
        Tools.rprint(command)
        
        DispatchQueue.global(qos: .background).async {
            let _ = Tools.spawnCommandSycn(command)
        }
        
        return (outFile, signalFile)
    }
    
}
