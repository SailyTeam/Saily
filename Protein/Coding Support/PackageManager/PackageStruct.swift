//
//  PackageStruct.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/26.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import Foundation

struct PackageStruct: Equatable, Encodable, Decodable {
    
    let identity: String
    let versions: [String : [String : String]]
    let fromRepoUrlRef: String?
    
    func newestVersion() -> String {
        return Tools.obtainNewestVersion(versions: Array<String>(versions.keys))
    }
    
    func newestMetaData() -> [String : String]? {
        return self.versions[newestVersion()]
    }
    
    func obtainNameIfExists() -> String {
        guard let target = newestMetaData()?["name"] else {
            return identity
        }
//        func issx(p: String) -> Bool {
//            // they are not empty! try to use arrow key to see them
//            for item in ["", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "ô", "²", "ó", "µ", "Ð", "S", "Ú", "H", "á", "<", "¬", "Í", "Ù", "é", "¯", ">", "Ã", "Ø", "Â", "¨", "Å", "Ü", "ð", "õ", "¶", "Ñ", "£", "Ò", "¹", "Ê", "Î", "ä", "å", "í", "ç", "Æ", "¾", "À", "ñ", "¤", "Þ", "Ç", "±", "«", "º", "ê", "»", "¡", "É", "ª", "¢", "Ö", "Y", "¼", "Ï", "Ì", "Ä", "Ô", "Õ", "Ó", "×", "ò", "æ", "Ý", "ö", "è", "ã", "ï", "ì", "´", "Á", "·", "°", "¦", "ß", "Ë", "Û", "à", "½", "â", "È", "ë", "¸", "î", "§", "³"] {
//                if p.contains(item) { return true }
//            }
//            // that is not so perfect but should work for most
//            return false
//        }
        if /*issx(p: target),*/
            let dx = target.data(using: .isoLatin1, allowLossyConversion: false),
            let sx = String(data: dx, encoding: .utf8) {
            return sx
        }
        return target
    }
    
    func obtainAuthorIfExists() -> String {
        if let raw = newestMetaData()?["author"] {
            var ret = [String]()
            for man in raw.components(separatedBy: ",") {
                var read = man
                read.removeSpaces()
                if let read = read.split(separator: "<").first {
                    var str = String(read)
                    str.removeSpaces()
                    ret.append(str)
                }
            }
            if ret.count > 0 {
                var str = ""
                ret.forEach { (read) in
                    str += read
                    str += ", "
                }
                str.removeLast(2)
                return str
            }
        }
        return "Package_NoName".localized()
    }
    
    func obtainDescriptionIfExistsOrVersion() -> String {
        let ver = newestVersion()
        if let get = versions[ver] {
            guard let target = get["description"] else {
                return ver
            }
            //        func issx(p: String) -> Bool {
            //            // they are not empty! try to use arrow key to see them
            //            for item in ["", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "ô", "²", "ó", "µ", "Ð", "S", "Ú", "H", "á", "<", "¬", "Í", "Ù", "é", "¯", ">", "Ã", "Ø", "Â", "¨", "Å", "Ü", "ð", "õ", "¶", "Ñ", "£", "Ò", "¹", "Ê", "Î", "ä", "å", "í", "ç", "Æ", "¾", "À", "ñ", "¤", "Þ", "Ç", "±", "«", "º", "ê", "»", "¡", "É", "ª", "¢", "Ö", "Y", "¼", "Ï", "Ì", "Ä", "Ô", "Õ", "Ó", "×", "ò", "æ", "Ý", "ö", "è", "ã", "ï", "ì", "´", "Á", "·", "°", "¦", "ß", "Ë", "Û", "à", "½", "â", "È", "ë", "¸", "î", "§", "³"] {
            //                if p.contains(item) { return true }
            //            }
            //            // that is not so perfect but should work for most
            //            return false
            //        }
            if /*issx(p: target),*/
                let dx = target.data(using: .isoLatin1, allowLossyConversion: false),
                let sx = String(data: dx, encoding: .utf8) {
                return sx
            }
            return target
        }
        return "Package_ContentDamaged".localized()
    }
    
    func obtainDescriptionIfExistsOrNil() -> String? {
        let ver = newestVersion()
        if let get = versions[ver] {
            return get["description"]
        }
        return "Package_ContentDamaged".localized()
    }
    
    func obtainIconIfExists() -> (String?, UIImage?) {
        guard let meta = newestMetaData() else {
            return (nil, DEFINE.PKG_DEFAULT_ICON)
        }
        if let iconLink = meta["icon"] {
            if iconLink.hasPrefix("./"), let repoRef = self.fromRepoUrlRef {
                return (repoRef + String(iconLink.dropFirst()), nil)
            }
            return (iconLink, nil)
        }
        if let section = meta["section"] {
            switch section {
            case "application", "app":
                return (nil, UIImage(named: "app"))
            default:
                return (nil, DEFINE.PKG_DEFAULT_ICON)
            }
        } else {
            return (nil, DEFINE.PKG_DEFAULT_ICON)
        }
    }
    
    func obtainDownloadLocationFromNewestVersion() -> URL? {
        if let meta = newestMetaData(), let raw = meta["filename"] {
            if raw.hasPrefix("./") {
                if let repo = fromRepoUrlRef {
                    return URL(string: repo + "/" + raw.dropFirst(2))
                } else {
                    return nil
                }
            } else if raw.hasPrefix("http://") || raw.hasPrefix("https://") {
                return URL(string: raw)
            } else {
                if let repo = fromRepoUrlRef {
                    return URL(string: repo + "/" + raw)
                } else {
                    return nil
                }
            }
        }
        return URL(string: "")
    }
    
    func setIconImage(withUIImageView target: UIImageView) {
        let iconlink = obtainIconIfExists()
        if let il = iconlink.0, il.hasPrefix("http") {
            target.sd_setImage(with: URL(string: il), placeholderImage:  UIImage(named: "mod"), options: .avoidAutoSetImage, context: nil, progress: nil) { (image, err, _, url) in
                if let img = image {
                    target.image = img
                } else {
                    target.image = UIImage(named: "mod")
                }
            }
        } else if let il = iconlink.0, il.hasPrefix("file://") {
            if let img = UIImage(contentsOfFile: String(il.dropFirst("file://".count))) {
                target.image = img
            } else {
                target.image = UIImage(named: "mod")
            }
        } else {
            target.image = UIImage(named: "mod")
        }
    }
    
    func isCydiaGSCPackage() -> Bool {
        if let meta = newestMetaData() {
            if /*identity.hasPrefix("gsc.") &&*/ (meta["tag"]?.contains("role::cydia") ?? false) {
                return true
            }
        }
        return false
    }
    
    func truncateMetaDataBy(version: String) -> PackageStruct? {
        if let verMeta = versions[version] {
            let newMeta = [version : verMeta]
            return PackageStruct(identity: identity, versions: newMeta, fromRepoUrlRef: fromRepoUrlRef)
        }
        return nil
    }
    
    func obtainPackageProvides() -> PackageWantsGroup? {
        if let provides = newestMetaData()?["provides"] {
            let ret = obtainPackageWantsInstanceGroup(fromString: provides, andType: .depends)
            return ret
        } else {
            return nil
        }
    }
    
    func obtainPackageWantsInstanceGroup(fromString: String, andType: PackageWantsType) -> PackageWantsGroup {
        var instanceArray = [[PackageWantsInstance]]()
        for item in fromString.components(separatedBy: ",") {
            var compo = item
            compo.removeSpaces()
            compo.removeNewLine()
            var instanceGroup = [PackageWantsInstance]()
            var instanceGroupRawString = [String]()
            compo.components(separatedBy: "|").forEach { (str) in
                var get = str
                get.removeSpaces()
                instanceGroupRawString.append(get)
            }
            instanceGroupRawString.forEach { (requirementString) in
                var foundMets = false
                breaker: if requirementString.contains("(") {
                    let sp = requirementString.components(separatedBy: "(")
                    if sp.count != 2 {
                        break breaker
                    }
                    var a0 = sp[0]
                    var a1 = sp[1]
                    a0.removeSpaces() // identity
                    a1.removeSpaces() // >= 100) || >=100
                    if !a1.hasSuffix(")") {
                        break breaker
                    }
                    a1.removeLast() // >= 100
                    var b0: String? = nil
                    var b1: String? = nil
                    if a1.contains(" ") {
                        let bs = a1.components(separatedBy: " ")
                        if bs.count != 2 {
                            break breaker
                        }
                        b0 = bs[0]          // >= > = == < <=
                        b1 = bs[1]          // 100
                    } else {
                        let cutter = a1         // >=100
                        var isInDigital = false
                        var g0 = ""
                        var g1 = ""
                        for char in cutter {
                            let str = String(char)
                            if isInDigital {
                                g1 += str
                            } else {
                                if str == ">" || str == "<" || str == "=" {
                                    g0 += str
                                } else {
                                    g1 += str
                                    isInDigital = true
                                }
                            }
                        }
                        b0 = g0
                        b1 = g1
                    }
                    
                    
                    switch b0 {
                    case ">=":
                        instanceGroup.append(PackageWantsInstance(identity: a0,
                                                                  mets: .biggerOrEqual, metsRecord: b1))
                    case ">", ">>":
                        instanceGroup.append(PackageWantsInstance(identity: a0,
                                                                  mets: .bigger, metsRecord: b1))

                    case "=", "==":
                        instanceGroup.append(PackageWantsInstance(identity: a0,
                                                                  mets: .equal, metsRecord: b1))
                    case "<", "<<":
                        instanceGroup.append(PackageWantsInstance(identity: a0,
                                                                      mets: .smaller, metsRecord: b1))
                    case "<=":
                        instanceGroup.append(PackageWantsInstance(identity: a0,
                                                                      mets: .smallerOrEqual, metsRecord: b1))
                    default:
                        break breaker
                    }
                    
                    foundMets = true
                }
                if !foundMets {
                    instanceGroup.append(PackageWantsInstance(identity: requirementString,
                                                              mets: .any, metsRecord: nil))
                }
            }
            instanceArray.append(instanceGroup)
        }
        return PackageWantsGroup(conditions: instanceArray, majorType: andType)
    }
    
    func obtainWantsGroupFromNewestVersion() -> [PackageWantsGroup] {
        var ret = [PackageWantsGroup]()
        if let meta = self.newestMetaData() {
            if let dependsRawString = meta["depends"] {
                let group = obtainPackageWantsInstanceGroup(fromString: dependsRawString, andType: .depends)
                ret.append(group)
            }
            if let dependsRawString = meta["pre-depends"] {
                let group = obtainPackageWantsInstanceGroup(fromString: dependsRawString, andType: .depends)
                ret.append(group)
            }
            if let dependsRawString = meta["conflicts"] {
                let group = obtainPackageWantsInstanceGroup(fromString: dependsRawString, andType: .conflict)
                ret.append(group)
            }
            if let dependsRawString = meta["replaces"] {
                let group = obtainPackageWantsInstanceGroup(fromString: dependsRawString, andType: .conflict)
                ret.append(group)
            }
            if let dependsRawString = meta["breaks"] {
                let group = obtainPackageWantsInstanceGroup(fromString: dependsRawString, andType: .conflict)
                ret.append(group)
            }
            return ret
        } else {
            #if DEBUG
            fatalError("nil meta passed into obtainWantsGroupFromNewestVersion")
            #endif
        }
        #if !DEBUG
        return []
        #endif
    }
    
    func generateInstallReport() -> PackageResolveReturn {
        
        let wantsGroup = obtainWantsGroupFromNewestVersion()
        
        var passed = PackageResolvePackage(emptyTag: false,
                                           extraInstall: [:],
                                           extraDelete: [],
                                           failed: [:],
                                           capturedPackageList: [],
                                           capturedInstalledList: [:])
        for want in wantsGroup {
            let aResolve = want.tryResolveAllConditions()
            for extraInstallPkg in aResolve.extraInstall {
                if passed.extraInstall[extraInstallPkg.identity] == nil { // dont override
                    // todo decision handler
                    passed.extraInstall[extraInstallPkg.identity] = extraInstallPkg
                }
            }
            for extraDeletePkg in aResolve.extraDelete {
                if !passed.extraDelete.contains(extraDeletePkg) {
                    passed.extraDelete.append(extraDeletePkg)
                }
            }
            //  ▿ PackageWantsGroup
            for failed in aResolve.failed {
                //  ▿ [PackageWantsInstance]
                for condition in failed.conditions {
                    for oneCondition in condition {
                        if passed.failed[oneCondition.identity] == nil {
                            passed.failed[oneCondition.identity] = PackageWantsGroup(conditions: failed.conditions, majorType: failed.majorType)
                        }
                    }
                }
            }
        }
        
        return PackageResolveReturn(extraInstall: Array<PackageStruct>(passed.extraInstall.values),
                                    extraDelete: [],
                                    failed: Array<PackageWantsGroup>(passed.failed.values))
    }
    
    func isPaid() -> Bool {
        if newestMetaData()?["tag"]?.lowercased().contains("cydia::commercial") ?? false {
            return true
        }
        return false
    }
    
}

enum PackageWantsType: String {
    case depends
    case conflict
}

enum PackageWantsVersionType: String {
    case equal
    case bigger
    case biggerOrEqual
    case smaller
    case smallerOrEqual
    case any
}

struct PackageWantsGroup {
    
    let conditions: [[PackageWantsInstance]]
    let majorType: PackageWantsType

    private func doesTheyMatch(type: PackageWantsVersionType, requirementValue: String, targetValue: String) ->  Bool {
        switch type {
        case .any:
            return Tools.DEBVersionIsValid(targetValue)
        case .bigger:
            let compare = Tools.DEBVersionCompare(A: targetValue, B: requirementValue)
            return compare == .AisBigger
        case .biggerOrEqual:
            let compare = Tools.DEBVersionCompare(A: targetValue, B: requirementValue)
            return compare == .AisBigger || compare == .AisEqualToB
        case .equal:
            let compare = Tools.DEBVersionCompare(A: targetValue, B: requirementValue)
            return compare == .AisEqualToB
        case .smaller:
            let compare = Tools.DEBVersionCompare(A: targetValue, B: requirementValue)
            return compare == .AisLower
        case .smallerOrEqual:
            let compare = Tools.DEBVersionCompare(A: targetValue, B: requirementValue)
            return compare == .AisLower || compare == .AisEqualToB
        }
    }
    
    func tryResolveAllConditions(withResolveItem: PackageResolvePackage = PackageResolvePackage(), withDepth: Int = 0) -> PackageResolveReturn {
        
        if withDepth > 6 { // mostly it would be error
            return PackageResolveReturn(extraInstall: [], extraDelete: [], failed: [])
        }
        
        // preparing payloads...
        var passed: PackageResolvePackage
        if withResolveItem.emptyTag {
            var fullPackageList = [[String : PackageStruct]]()
            let repos = RepoManager.shared.repos
            for repo in repos {
                fullPackageList.append(repo.metaPackage)
            }
            var installedList = [String : PackageStruct]()
            for item in PackageManager.shared.rawInstalled {
                installedList[item.identity] = item
            }
            passed = PackageResolvePackage(emptyTag: false,
                                           extraInstall: [:],
                                           extraDelete: [],
                                           failed: [:],
                                           capturedPackageList: fullPackageList,
                                           capturedInstalledList: installedList,
                                           capturedTaskQueue: TaskManager.shared.generatePackageTaskReport())
        } else {
            passed = withResolveItem
        }
        
        //                           ▿ 51 elements
        b0: for conditionInstaceGroup in conditions {               // [PackageWantsInstance]
            switch majorType {
            case .depends:                                      // resolve needed
                var neededGroup = [PackageStruct]()
                var everFind = false                            // for future use, not reliable if neededGroup is used
                //                  ▿ 0 : PackageWantsInstance
                b1: for oneCondition in conditionInstaceGroup {
                    // if this is failed already
                    if passed.failed[oneCondition.identity] != nil {
                        // we may found other depends and reslove it!
                        continue b1
                    }
                    // if installed, one match, full passed
                    if let installed = passed.capturedInstalledList[oneCondition.identity] {
                        if doesTheyMatch(type: oneCondition.mets,
                                         requirementValue: oneCondition.metsRecord ?? "",
                                         targetValue: installed.newestVersion()) {              // cause installed only have one value
                            // everFind = true
                            continue b0
                        } // we dont care about if it is losted cause it means we are going to update then
                    }
                    // if installed package provides it
                    for (_, value) in passed.capturedInstalledList {
                        if let promise = value.obtainPackageProvides() {
                            for item in promise.conditions {
                                for providedPackage in item {
                                    if providedPackage.identity == oneCondition.identity {
                                        continue b0
                                        // todo
//                                        switch oneCondition.mets {
//                                        case .any:
//                                            continue b0
//                                        case. equal
//
//                                        }
                                    }
                                }
                            }
                        }
                    }
                    // if not install not failed, look it up in queue first
                    for (pkgIdentity, taskDetail) in passed.capturedTaskQueue where pkgIdentity == oneCondition.identity {
                        if taskDetail.0 == .pullupInstall || taskDetail.0 == .selectInstall {
                            continue b0
                        } else if taskDetail.0 == .selectDelete || taskDetail.0 == .pullupDelete {
                            var failedConditionGroup = [PackageWantsInstance]()
                            for failedCondition in conditionInstaceGroup {
                                failedConditionGroup.append(failedCondition)
                            }
                            for failedCondition in conditionInstaceGroup {
                                // we are checking them like -> if passed.failed[oneCondition.identity] != nil
                                passed.failed[failedCondition.identity] = PackageWantsGroup(conditions: [failedConditionGroup], majorType: majorType)
                            }
                            continue b0
                        }
                    }
                    // still not, search for it
                    for repo in passed.capturedPackageList {
                        if let get = repo[oneCondition.identity] {
                            var validVersionList = [String]()
                            for verison in Array<String>(get.versions.keys) {
                                if doesTheyMatch(type: oneCondition.mets,
                                                 requirementValue: oneCondition.metsRecord ?? "",
                                                 targetValue: verison) {
                                    validVersionList.append(verison)
                                }
                            }
                            var newPackageMeta = [String : [String : String]]()
                            for version in validVersionList {
                                if let metas = get.versions[version] {
                                    newPackageMeta[version] = metas
                                }
                            }
                            if newPackageMeta.count > 0 {
                                let newPackage = PackageStruct(identity: oneCondition.identity,
                                                               versions: newPackageMeta,
                                                               fromRepoUrlRef: get.fromRepoUrlRef)
                                neededGroup.append(newPackage)
                                everFind = true
                            }
                        }
                    }
                }
                if everFind {
                    // make decision in needed group
                    var newest: PackageStruct? = nil
                    for pkg in neededGroup {
                        if let old = newest {
                            if Tools.DEBVersionCompare(A: pkg.newestVersion(), B: old.newestVersion()) == .AisBigger {
                                newest = pkg
                            }
                        } else {
                            newest = pkg
                        }
                    }
                    if let found = newest {
                        // that package would be used to install
                        passed.extraInstall[found.identity] = found
                    } /* not possible for else */ else {
                        #if DEBUG
                        fatalError()
                        #endif
                    }
                } else {
                    // create failed group, failed them all, add them all
                    var failedConditionGroup = [PackageWantsInstance]()
                    for failedCondition in conditionInstaceGroup {
                        failedConditionGroup.append(failedCondition)
                    }
                    for failedCondition in conditionInstaceGroup {
                        // we are checking them like -> if passed.failed[oneCondition.identity] != nil
                        passed.failed[failedCondition.identity] = PackageWantsGroup(conditions: [failedConditionGroup], majorType: majorType)
                    }
                }
            case .conflict:                                     // delete everything
                // we only check confict in installed tabs
                b2: for oneCondition in conditionInstaceGroup {
                    // not one of them, but all. anything goes wrong, breaks all
                    if let get = passed.capturedInstalledList[oneCondition.identity] {
                        // dangerous! ps. we except expect
                        if doesTheyMatch(type: oneCondition.mets, requirementValue: oneCondition.metsRecord ?? "", targetValue: get.newestVersion()) {
                            // if they match, then force user to uninstall them on your own
                            // otherwise, they may doing some unwilling thing on their system
                            // additionally check the queue if already in delete queue
                            for (pkgIdentity, taskDetail) in passed.capturedTaskQueue where pkgIdentity == oneCondition.identity {
                                if taskDetail.0 == .selectDelete || taskDetail.0 == .pullupDelete {
                                    // todo conditional check
                                    continue b2
                                }
                            }
                            passed.failed[oneCondition.identity] = PackageWantsGroup(conditions: [conditionInstaceGroup], majorType: majorType)
                            continue b2
                        }
                    }
                }
            }
        }
        
        f0: for (key, value) in passed.extraInstall {
            
            if withResolveItem.extraInstall[key] != nil {
                continue f0
            }
            
            let theirWants = value.obtainWantsGroupFromNewestVersion()
            for wants in theirWants {
                let aResolve = wants.tryResolveAllConditions(withResolveItem: passed, withDepth:  withDepth + 1)
                for extraInstallPkg in aResolve.extraInstall {
                    if passed.extraInstall[extraInstallPkg.identity] == nil { // dont override
                        // todo decision handler
                        passed.extraInstall[extraInstallPkg.identity] = extraInstallPkg
                    }
                }
                for extraDeletePkg in aResolve.extraDelete {
                    if !passed.extraDelete.contains(extraDeletePkg) {
                        passed.extraDelete.append(extraDeletePkg)
                    }
                }
                //  ▿ PackageWantsGroup
                for failed in aResolve.failed {
                    //  ▿ [PackageWantsInstance]
                    for condition in failed.conditions {
                        for oneCondition in condition {
                            if passed.failed[oneCondition.identity] == nil {
                                passed.failed[oneCondition.identity] = PackageWantsGroup(conditions: failed.conditions, majorType: failed.majorType)
                            }
                        }
                    }
                }
            }
        }
        
        return PackageResolveReturn(extraInstall: Array<PackageStruct>(passed.extraInstall.values),
                                    extraDelete: [],
                                    failed: Array<PackageWantsGroup>(passed.failed.values))
        
    }
    
}

struct PackageResolvePackage {
    var emptyTag: Bool = true
    var extraInstall: [String : PackageStruct] = [:]
    var extraDelete: [String] = []                              // let user do it self, or todo
    var failed: [String : PackageWantsGroup] = [:]
    var capturedPackageList: [[String : PackageStruct]] = []
    var capturedInstalledList: [String : PackageStruct] = [:]
    var capturedTaskQueue: [String : (TaskManager.PackageTaskType, PackageStruct)] = [:]
}

struct PackageResolveReturn {
    let extraInstall: [PackageStruct]
    let extraDelete: [String]
    let failed: [PackageWantsGroup]
}

struct PackageWantsInstance {
    
    let identity: String
    let mets: PackageWantsVersionType
    let metsRecord: String?
    
    static func canMetsCondition() -> Bool {
        return true
    }
    
    static func alreadyMetsCondition() -> Bool {
        return true
    }
    
}
