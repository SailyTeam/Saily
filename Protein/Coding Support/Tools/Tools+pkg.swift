//
//  Tools+dpkg.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/29.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import Foundation

extension Tools {
    
    private static let dpkg = dpkgWrapper()
    
    static func testIfStringIsDEBIANContext(strToTest: String) -> Bool {
        if strToTest.hasPrefix("<!DOCTYPE html>") {
            return false
        }
        guard let one = strToTest.components(separatedBy: "\n\n").first else {
            return false
        }
        if invokeDebianMeta(context: one).count < 1 {
            return false
        }
        return true
    }
    
    static func obtainNewestVersion(versions: [String]) -> String {
        // compiler error, lets break it down
        let ver = versions
        let sort = ver.sorted { (verA, verB) -> Bool in
            return Tools.dpkg.compareVersionA(verA, andB: verB) > 0 ? true : false
        }
        return sort.first ?? ""
    }
    
    static func DEBVersionIsValid(_ what: String) -> Bool {
        return dpkg.isVersionVaild(what)
    }
    
    enum DEBVersionCompareResult: String {
        case AisBigger
        case AisLower
        case AisEqualToB
        case AorBisInvalid
        case unkown
    }
    
    static func DEBVersionCompare(A: String, B: String) -> DEBVersionCompareResult {
        let ret = Tools.dpkg.compareVersionA(A, andB: B)
        if ret > 0 {
            return .AisBigger
        }
        if ret < 0 {
            return .AisLower
        }
        if ret == 0 {
            return .AisEqualToB
        }
        return .AorBisInvalid
    }
    
    static func invokeDebianMeta(context: String) -> [String : String] {
        
        if context.count < 2 { return [:] }
        
        var metas = [(String, String)]()
        for compose in context.components(separatedBy: "\n") where compose != "" {
            var line = compose
            line.removeSpaces()
            if line.contains(":") && !compose.hasPrefix("  ") {
                let split = line.components(separatedBy: ":")
                if split.count >= 2 {
                    var key = split[0]
                    var val = ""
                    for (index, item) in split.enumerated() where index > 0 {
                        var get = item
                        get.removeSpaces()
                        val += get
                        val += ":"
                    }
                    val.removeLast()
                    key.removeSpaces()
                    val.removeSpaces()
                    metas.append((key, val))
                } else {
//                    return [:] // invaild package
                }
            } else {
                if var get = metas.last {
                    metas.removeLast()
                    get.1 = get.1 + "\n" + line
                    metas.append(get)
                }
            }
        }
        
        var ret = [String : String]()
        metas.forEach { (object) in
            let key = object.0.lowercased()
            var val = object.1
            if DEFINE.DPKG_CONTROL_LOWERKEYS.contains(key) {
                val = val.lowercased()
            }
            ret[key] = val
        }
        
        // Release Vaildate BROKEN
        
//        if let versionCheckIfThereIs = ret["version"], !dpkg.isVersionVaild(versionCheckIfThereIs) {
//            Tools.rprint("[PKG] Invoke rejected due to version field invalid " + ret.description)
//            return [:]
//        }
        return ret
        
    }
    
    static func invokeDebianMetaAndReturnPackage(context: String, fromRepoRef: String?) -> PackageStruct? {
        let meta = invokeDebianMeta(context: context)
        guard let id = meta["package"], let ver = meta["version"] else {
            return nil
        }
        if !Tools.dpkg.isVersionVaild(ver) {
            return nil
        }
        return PackageStruct(identity: id, versions: [ver : meta], fromRepoUrlRef: fromRepoRef)
    }
    
    static func invokeDebianMetaForPackages(context: String, fromRepoRef: String?) -> [String : PackageStruct] {
        var ret = [String : PackageStruct]()
        for item in context.components(separatedBy: "\n\n") {
            if let obj = Tools.invokeDebianMetaAndReturnPackage(context: item, fromRepoRef: fromRepoRef) {
                if let get = ret[obj.identity] {
                    var dic: [String : [String : String]] = get.versions
                    guard let ver = obj.versions.first else {
                        continue
                    }
                    dic[ver.key] = ver.value
                    ret[obj.identity] = PackageStruct(identity: obj.identity, versions: dic, fromRepoUrlRef: fromRepoRef)
                } else {
                    ret[obj.identity] = obj
                }
            }
        }
        return ret
    }
    
    static func DEBDownloadIsVerified(withPkg: PackageStruct, andFileLocation: String) -> Bool {
        if let meta = withPkg.newestMetaData() {
            let data = NSData(contentsOfFile: andFileLocation)
            if let sha256 = meta["sha256"], let data = data {
                if String.sha256From(data: data as Data) == sha256 {
                    return true
                } else {
                    return false
                }
            }
            if let sha1 = meta["sha1"], let data = data {
                if String.sha1From(data: data as Data) == sha1 {
                    return true
                } else {
                    return false
                }
            }
            if let md5 = meta["md5sum"], let data = data {
                if String.md5From(data: data as Data) == md5 {
                    return true
                } else {
                    return false
                }
            }
            Tools.rprint("[PackageManager] Package " + withPkg.obtainNameIfExists() + " is not being able to verify, check bypassed.")
            return true
        }
        return false
    }
    
    static func DEBLoadFromFile(atLocation: String) -> PackageStruct? {
        
//        guard let data = try? Data(contentsOf: URL(fileURLWithPath: atLocation)) else {
//            Tools.rprint("|E| Error loading data from file: " + atLocation)
//            return nil
//        }
        
        let cacheDir = ConfigManager.shared.documentString + "/ExtraDataCache"
        try? FileManager.default.removeItem(atPath: cacheDir)
        try? FileManager.default.createDirectory(atPath: cacheDir, withIntermediateDirectories: true, attributes: nil)
        let _ = Tools.spawnCommandSycn("dpkg -e " + atLocation + " " + cacheDir)
        usleep(23333);
        print(cacheDir)
        
//        guard let str = try? libArchiveGetControlString(data) else {
//            Tools.rprint("|E| Failed loading control file from package: " + atLocation)
//            return nil
//        }
//
        
        let read = try? String(contentsOfFile: cacheDir + "/control")
//        #if targetEnvironment(simulator)
//        let str = """
//        Package: wiki.qaq.Protein
//        Name: Saily
//        Version: 1.0-1-1595069022
//        """
//        #else
        try? FileManager.default.removeItem(atPath: cacheDir)
        guard let str = read else {
            Tools.rprint("|E| Failed loading control file from package: " + atLocation)
            return nil
        }
//        #endif
        
        let meta = Tools.invokeDebianMetaForPackages(context: str + "\n", fromRepoRef: nil)
        if meta.count != 1 {
            Tools.rprint("|E| Invalid return from invokeDebianMetaForPackages with file: " + atLocation)
            return nil
        }
        
        guard let ret = meta.values.first else {
            Tools.rprint("|E| Invalid return from meta.keys.first with file: " + atLocation)
            return nil
        }
        
        return ret
    }
    
}
