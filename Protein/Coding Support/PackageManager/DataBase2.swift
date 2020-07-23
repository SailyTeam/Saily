//
//  DataBase3.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/18.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import Foundation
import WCDBSwift

class PackageRecord: WCDBSwift.TableCodable {
    
    var identity: String?
    var attach: [Int : PackageStruct]? = [:]
    var timeStamp: Double?
    
    var sortName: String?
    
    init(withPkg: PackageStruct, andTimeStamp: Double) {
        identity = withPkg.identity
        timeStamp = andTimeStamp
        attach![0] = withPkg
        sortName = withPkg.obtainNameIfExists()
    }
    
    func obtainPackageStruct() -> PackageStruct {
        return attach![0]!
    }
    
    enum CodingKeys: String, CodingTableKey {
        typealias Root = PackageRecord
        
        case identity
        case attach
        case timeStamp
        case sortName
        
        static let objectRelationalMapping = TableBinding(CodingKeys.self)
    }
    
}

class PackageRecordVersionOnly: WCDBSwift.TableCodable {
    
    var identity: String?
    var version: String?
    var repoUrlRef: String?
    var timeStamp: Double?
    var sortName: String?
    
    init(withPkg: PackageStruct, andTimeStamp: Double) {
        identity = withPkg.identity
        version = withPkg.newestVersion()
        repoUrlRef = withPkg.fromRepoUrlRef
        timeStamp = andTimeStamp
        sortName = withPkg.obtainNameIfExists()
    }
    
    func obtainPackageStruct() -> PackageStruct? {
        guard let repoUrlRef = repoUrlRef, let identity = identity else {
            return nil
        }
        let copy = RepoManager.shared.repos
        for repo in copy where repo.url.urlString == repoUrlRef {
            return repo.metaPackage[identity]
        }
        return nil
    }
    
    enum CodingKeys: String, CodingTableKey {
        typealias Root = PackageRecordVersionOnly
        
        case identity
        case version
        case repoUrlRef
        case timeStamp
        case sortName
        
        static let objectRelationalMapping = TableBinding(CodingKeys.self)
    }
    
}

class PackageRecordUniqueIdentity: WCDBSwift.TableCodable {
    
    var uniqueIdentity: String?
    var attach: [Int : PackageStruct]? = [:]
    var timeStamp: Double?
    
    var sortName: String?
    
    init(withPkg: PackageStruct, andTimeStamp: Double) {
        uniqueIdentity = withPkg.identity
        timeStamp = andTimeStamp
        attach![0] = withPkg
        sortName = withPkg.obtainNameIfExists()
    }
    
    func obtainPackageStruct() -> PackageStruct? {
        let ret = attach?[0]
        #if DEBUG
        if ret == nil {
            fatalError("there cant be nil")
        }
        #endif
        return ret
    }
    
    enum CodingKeys: String, CodingTableKey {
        typealias Root = PackageRecordUniqueIdentity
        
        case uniqueIdentity
        case attach
        case timeStamp
        case sortName
        
        static let objectRelationalMapping = TableBinding(CodingKeys.self)
        
        static var columnConstraintBindings: [CodingKeys: ColumnConstraintBinding]? {
            return [
                .uniqueIdentity: ColumnConstraintBinding(isPrimary: true, isUnique: true)
            ]
        }
        
    }
    
}

