//
//  SearchIndexManager.swift
//  Protein
//
//  Created by soulghost on 11/5/2020.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import Foundation

class SearchEntity : Hashable {
    var key: String
    var tokens: Set<String>
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
    
    init(key: String, tokens: Set<String>, priority: Int) {
        self.key = key
        self.tokens = tokens
        self.priority = priority
    }
    
    init(key: String, priority: Int) {
        self.key = key
        self.tokens = []
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
    private var indexLock: NSRecursiveLock
    private var indexQueue: DispatchQueue?
    private var indexing: Bool
    
    // sync
    private var tokenLock: NSRecursiveLock
    private var indexingToken: Int
    
    init() {
        indexing = false
        indexLock = NSRecursiveLock()
        tokenLock = NSRecursiveLock()
        indexingToken = 0
        indexQueue = DispatchQueue.init(label: "wiki.qaq.Protein.SearchIndexManager.IndexingQueue", qos: .background, attributes: .concurrent, autoreleaseFrequency: .workItem, target: nil)
        
        indexSaveDir = ConfigManager.shared.documentString + "/cached_index"
        
        NotificationCenter.default.addObserver(self, selector: #selector(invalidateIndexAndReload), name: .RecentUpdateShouldUpdate, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private
    func invalidateIndexAndReload() {
        self.tokenMap = nil
        reBuildIndexSync()
    }
    
    var isIndexValid: Bool {
        return !self.indexing && self.tokenMap != nil
    }
    
    func waitUntilIndexingFinished() {
        if self.isIndexValid {
            return
        }
        
        if self.indexing {
            // wait for indexing release the lock
            self.indexLock.lock()
            self.indexLock.unlock()
            return
        }
        
        reBuildIndexSync()
    }
    
    func reBuildIndexSync() {
        // update current token
        tokenLock.lock()
        indexingToken += 1
        tokenLock.unlock()
        
        defer {
            indexLock.unlock()
        }
        
        indexLock.lock()
        buildIndexV1(currentToken: indexingToken)
    }
    
    private func buildIndexV1(currentToken: Int) {
        // set indexing token
        // FIXME: index update
//        if let indexPath = indexSavePath, FileManager.default.fileExists(atPath: indexPath) {
//            do {
//                let fileData = try Data.init(contentsOf: URL.init(fileURLWithPath: indexPath))
//                tokenMap = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(fileData) as? [String : Set<SearchEntity>]
//            } catch {
//                
//            }
//        }
        tokenMap = nil
        
        // Step 1. cache id->repo map
        var packageMap: [String : PackageStruct] = [:]
        let repos = RepoManager.shared.repos
        for repo in repos {
            packageMap.merge(repo.metaPackage, uniquingKeysWith: {(_, second) in second})
        }
        self.packageMap = packageMap
        
        // Step 2. tokenize and save
        // token -> [key]
        enum SearchState {
            case Invalid;
            case Alnum;
            case Chinese;
            case Others;
        };
        var lastState: SearchState = .Invalid;
        var tokenMap: [String: Set<SearchEntity>] = [:]
        for (key, pkg) in packageMap {
            autoreleasepool {
                if (currentToken != indexingToken) {
                    Tools.rprint("[-] 😢  index token mismatch, cancel current index building")
                    return
                }
                
                let name = pkg.obtainNameIfExists().lowercased()
                // every part in name is token
                var parts: Set<SearchEntity> = []
                var word = ""
                var title = ""
                for c in name {
                    let token = String(c)
                    word += token
                    title += token
                    
                    // insert word entity (split by space chars)
                    let wordEntity = SearchEntity(key: word, tokens: [word], priority: word.count)
                    parts.insert(wordEntity)
                
                    // insert title entity (full match)
                    let titleEntity = SearchEntity(key: title, tokens: [title], priority: title.count)
                    // mark full name as high priority
                    if titleEntity.key == name {
                        titleEntity.priority *= 10
                    }
                    parts.insert(titleEntity)
                    
                    // break word if needed
                    var curState: SearchState
                    if (token.isAlnumOnly) {
                        curState = .Alnum
                    } else if (token.isChineseOnly) {
                        curState = .Chinese
                    } else {
                        curState = .Others
                    }
                    
                    if lastState != .Invalid && curState != lastState {
                        word = String(c)
                        // insert single word
                        let wordEntity = SearchEntity(key: word, tokens: [word], priority: word.count)
                        parts.insert(wordEntity)
                    }
                    lastState = curState;
                }
                for part in parts.reversed() {
                    insertToTokenMap(tokenMap: &tokenMap, entity: part, packageKey: key)
                }
            }
        }
        
        if (currentToken != indexingToken) {
            Tools.rprint("[-] 😢  index token mismatch, cancel current index building")
            return
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
        var tokens: [String] = [str]
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
            tokenMap[entity.key]!.insert(SearchEntity(key: packageKey, tokens: entity.tokens, priority: entity.priority))
        } else {
            tokenMap[entity.key] = [SearchEntity(key: packageKey, tokens: entity.tokens, priority: entity.priority)]
        }
    }
    
    func searchInSnapshotWith(keywords: String) -> [(PackageStruct, [String])] {
        guard tokenMap != nil && packageMap != nil else {
            return []
        }
        
        self.indexLock.lock()
        defer {
            self.indexLock.unlock()
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
        
        var hitPackages: [(PackageStruct, [String])] = []
        for entity in hitEntities.sorted(by: { !($0 < $1) }) {
            if let package = packageMap![entity.key] {
                hitPackages.append((package, Array(entity.tokens)))
            }
        }
        
        return hitPackages
    }
}
