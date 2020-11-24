//
//  RepoStruct.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/26.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import Foundation
import SDWebImage

struct RepoStruct: Equatable, Codable {
    
    var url: URL {
        didSet {
            let str = url.urlString
            #if DEBUG
            if str.hasSuffix("/") {
                fatalError()
            }
            #endif
        }
    }
    
    var icon: Data = Data()
    
    var lastUpdateRelease: Double = 0
    var lastUpdatePackage: Double = 0
    var metaRelease: [String : String] = [:]
    var metaPackage: [String : PackageStruct] = [:]
    
    var cacheSearchPath = "bz2"
    var paymentInfo: [String : String] = [:]
    
    var nameComment: String = "" {
        didSet {
            RepoManager.shared.writeToDataBase(withObject: self, andSync: false)
        }
    }
    
    func obtainIconLink() -> String {
        switch url.urlString {
//        case "https://apt.bingner.com", "http://apt.bingner.com":
//            return "https://apt.bingner.com/CydiaIcon.png"
        case "https://apt.saurik.com", "http://apt.saurik.com":
            return "http://apt.saurik.com/dists/ios/CydiaIcon.png"
        case "https://apt.thebigboss.org", "http://apt.thebigboss.org",
             "http://apt.thebigboss.org/repofiles/cydia",
             "https://apt.thebigboss.org/repofiles/cydia":
            return "http://apt.thebigboss.org/repofiles/cydia/dists/stable/CydiaIcon.png"
        default:
            return url.urlString + "/CydiaIcon.png"
        }
    }
    
    func obtainReleaseLink() -> String {
        switch url.urlString {
//        case "https://apt.bingner.com", "http://apt.bingner.com":
//            return "https://apt.bingner.com/ios/1443.00/Release"
        case "https://apt.saurik.com", "http://apt.saurik.com":
            return "http://apt.saurik.com/dists/ios/Release"
        case "https://apt.thebigboss.org", "http://apt.thebigboss.org",
            "http://apt.thebigboss.org/repofiles/cydia",
            "https://apt.thebigboss.org/repofiles/cydia":
            return "http://apt.thebigboss.org/repofiles/cydia/dists/stable/Release"
        default:
            return url.urlString + "/Release"
        }
    }
    
    func obtainPackageLink() -> String {
        switch url.urlString {
//        case "https://apt.bingner.com", "http://apt.bingner.com":
//            return "https://apt.bingner.com/ios/1443.00/main/binary-iphoneos-arm/Packages"
        case "https://apt.saurik.com", "http://apt.saurik.com":
            return "http://apt.saurik.com/dists/ios/main/binary-iphoneos-arm/Packages"
        case "https://apt.thebigboss.org", "http://apt.thebigboss.org",
            "http://apt.thebigboss.org/repofiles/cydia",
            "https://apt.thebigboss.org/repofiles/cydia":
            return "http://apt.thebigboss.org/repofiles/cydia/dists/stable/main/binary-iphoneos-arm/Packages"
        default:
        return url.urlString + "/Packages"
        }
    }
    
    mutating func setReleaseMeta(withContext str: String) {
        let read = Tools.invokeDebianMeta(context: str)
        if read.count > 0 {
            metaRelease = read
            lastUpdateRelease = Date().timeIntervalSince1970
        }
    }
     
    mutating func setPackageMeta(withContext str: String) {
        let read = Tools.invokeDebianMetaForPackages(context: str, fromRepoRef: url.urlString)
        if read.count > 0 {
            metaPackage = read
            lastUpdatePackage = Date().timeIntervalSince1970
        }
    }
    
    func obtainPossibleName() -> String {
        if nameComment != "" {
            return nameComment
        }
        if let name = metaRelease["label"] {
            return name
        }
        if let name = metaRelease["origin"] {
            return name
        }
        do {
            var location = url.absoluteString
            if location.hasPrefix("http") { location.removeFirst("http".count) }
            if location.hasPrefix("s") { location.removeFirst("s".count) }
            if location.hasPrefix("://") { location.removeFirst("://".count) }
            if location.hasPrefix("www.") { location.removeFirst("www.".count) }
            return location.split(separator: "/").first?.string() ?? "--"
        }
    }
    
    func obtainDescription() -> String {
        if let description = metaRelease["description"] {
            return description
        }
        if let version = metaRelease["version"] {
            return version
        }
        return "Repo_NoDescription".localized()
    }
    
    func obtainSectionDetails() -> [String : [PackageStruct]] {
        var ret = [String : [PackageStruct]]()
        for (_, item) in metaPackage {
            if let section = item.newestMetaData()?["section"] {
                if var get = ret[section] {
                    get.append(item)
                    ret[section] = get
                } else {
                    ret[section] = [item]
                }
            } else {
                let defaultSectionName = "Ungroupped".localized()
                if var get = ret[defaultSectionName] {
                    get.append(item)
                    ret[defaultSectionName] = get
                } else {
                    ret[defaultSectionName] = [item]
                }
            }
        }
        return ret
    }
    
    func isPaymentAvailable() -> Bool {
        return RepoPaymentManager.shared.queryEndpointAndSaveToRam(urlAsKey: url.urlString) == nil ? false : true
    }
    
}
