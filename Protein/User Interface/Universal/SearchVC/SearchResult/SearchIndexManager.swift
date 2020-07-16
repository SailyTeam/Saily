//
//  SearchIndexManager.swift
//  Protein
//
//  Created by soulghost on 11/5/2020.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import Foundation

class SearchEntity : Hashable {
    var key: String = ""
    var priority: Int
    
    static func == (lhs: SearchEntity, rhs: SearchEntity) -> Bool {
        return lhs.key == rhs.key
    }
    
    static func < (lhs: SearchEntity, rhs: SearchEntity) -> Bool {
        if (lhs.key < rhs.key) {
            return true
        } else if (lhs.key > rhs.key) {
            return false
        } else {
            return lhs.priority < rhs.priority
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }
    
    init(key: String, priority: Int) {
        self.key = key
        self.priority = priority
    }
    
    
}

class SearchIndexManager {
    
    // objc 的 用方法获取 等同于Swift自动生成的这种
    // static let shared = some() {
    //   get {
    //     return ...
    //   }
    // }

    
    static let shared = SearchIndexManager()
    
    private var indexSaveDir: String?
    private var indexSavePath: String?
    private var indices: [String: PackageStruct]?
    private var packageMap: [String : PackageStruct]?
    private var tokenMap: [String: Set<SearchEntity>]?
    var fakeIndex: [PackageStruct]?
    private var indexLock: NSRecursiveLock?
    private var indexQueue: DispatchQueue?
    private var indexing: Bool
    
    init() {
        indexing = false
        indexLock = NSRecursiveLock()
        indexQueue = DispatchQueue.init(label: "wiki.qaq.Protein.SearchIndexManager.IndexingQueue", qos: .background, attributes: .concurrent, autoreleaseFrequency: .workItem, target: nil)
        
        indexSaveDir = ConfigManager.shared.documentString + "/cached_index"
        
        NotificationCenter.default.addObserver(self, selector: #selector(cleanFakeIndex), name: .RecentUpdateShouldUpdate, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private
    func cleanFakeIndex() {
        self.fakeIndex = nil
    }
    
    func getFakeIndex() -> [PackageStruct] {
        buildIndexV1()
        return []
    }
    
    func buildIndexAsync() {
        var packages = [PackageStruct]()
        let copy = RepoManager.shared.repos // thread safe
        for repo in copy {
            packages.append(contentsOf: repo.metaPackage.map({ (object) -> PackageStruct in
                return object.value
            }))
        }
        packages.sort { (A, B) -> Bool in
            return A.obtainNameIfExists() < B.obtainNameIfExists() ? true : false
        }
        
        indexLock?.lock()
        indexing = true
        indexQueue?.async(execute: {
            defer {
                self.indexLock?.unlock()
                self.indexing = false
            }
            
            // FIXME: the real index
            self.fakeIndex = packages
        })
    }
    
    func buildIndexV1() {
        // hit mem cache
        if tokenMap != nil {
            return
        }
        
        // FIXME: index update
//        if let indexPath = indexSavePath, FileManager.default.fileExists(atPath: indexPath) {
//            do {
//                let fileData = try Data.init(contentsOf: URL.init(fileURLWithPath: indexPath))
//                tokenMap = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(fileData) as? [String : Set<SearchEntity>]
//            } catch {
//                
//            }
//        }
        
        // Step 1. cache id->repo map
        var packageMap: [String : PackageStruct] = [:]
        let repos = RepoManager.shared.repos
        for repo in repos {
            packageMap.merge(repo.metaPackage, uniquingKeysWith: {(_, second) in second})
        }
        self.packageMap = packageMap
        
        // hit file cache
//        if tokenMap != nil {
//            return
//        }
        
        // Step 2. tokenize and save
        // token -> [key]
        var tokenMap: [String: Set<SearchEntity>] = [:]
        for (key, pkg) in packageMap {
            autoreleasepool {
                let name = pkg.obtainNameIfExists().lowercased()
                // let author = pkg.obtainAuthorIfExists().lowercased()
                // let desc = pkg.obtainDescriptionIfExistsOrVersion().lowercased()
                            
                // every part in name is token
                var parts: Set<SearchEntity> = []
                var word = ""
                var title = ""
                for c in name {
                    let token = String(c)
                    word += token
                    title += token
                    
                    // insert word entity (split by space chars)
                    parts.insert(SearchEntity(key: word, priority: word.count))
                
                    // insert title entity (full match)
                    let titleEntity = SearchEntity(key: title, priority: title.count)
                    // mark full name as high priority
                    if titleEntity.key == name {
                        titleEntity.priority *= 10
                    }
                    parts.insert(titleEntity)
                    
                    // break word if needed
                    if token.lengthOfBytes(using: .utf8) == 0 {
                        word = ""
                    }
                }
                for part in parts.reversed() {
                    insertToTokenMap(tokenMap: &tokenMap, entity: part, packageKey: key)
                }
            }
        }
        
        // Step 3. save
        self.tokenMap = tokenMap;
//        do {
//            let data = try NSKeyedArchiver.archivedData(withRootObject: tokenMap, requiringSecureCoding: true)
//            if let indexPath = indexSavePath {
//                try data.write(to: URL.init(fileURLWithPath: indexPath))
//            }
//        } catch {
//
//        }
    }
    
    func tokenize(_ str: String) -> [String] {
        var tokens: [String] = []
        let descOCStr = NSString.init(string: str.lowercased())
        let tokenizer = CFStringTokenizerCreate(nil, descOCStr, CFRangeMake(0, descOCStr.length), kCFStringTokenizerUnitWordBoundary, nil)
        while true {
            CFStringTokenizerAdvanceToNextToken(tokenizer)
            let tokenRange = CFStringTokenizerGetCurrentTokenRange(tokenizer)
            if (tokenRange.length == 0) {
                break
            }
            let token = descOCStr.substring(with: NSMakeRange(tokenRange.location, tokenRange.length)).trimmingCharacters(in: .whitespacesAndNewlines)
            tokens.append(token)
        }
        return tokens
    }
    
    func insertToTokenMap(tokenMap: inout [String: Set<SearchEntity>], entity: SearchEntity, packageKey: String) {
        if tokenMap.keys.contains(entity.key) {
            // conver token priority to tokenMap priority
            // token -> key priority
            tokenMap[entity.key]!.insert(SearchEntity(key: packageKey, priority: entity.priority))
        } else {
            tokenMap[entity.key] = [SearchEntity(key: packageKey, priority: entity.priority)]
        }
    }
    
    func searchInSnapshotWith(keywords: String) -> [PackageStruct] {
        guard tokenMap != nil && packageMap != nil else {
            return []
        }
        
        let tokens = tokenize(keywords)
        var hitEntities = Set<SearchEntity>()
        for token in tokens {
            if let entities = tokenMap![token] {
                for entity in entities {
                    hitEntities.insert(entity)
                }
            }
        }
        
        var hitPackages: [PackageStruct] = []
        for entity in hitEntities.sorted(by: { !($0 < $1) }) {
            if let package = packageMap![entity.key] {
                hitPackages.append(package)
            }
        }
        return hitPackages
//        let indices = self.fakeIndex
//        let matcher = keywords.lowercased()
//        return indices?.filter {
//            $0.obtainNameIfExists().lowercased().contains(matcher)   ||
//                $0.obtainAuthorIfExists().lowercased().contains(matcher) ||
//                $0.obtainDescriptionIfExistsOrVersion().lowercased().contains(matcher)
//            } ?? []
    }
}
