//
//  DataBase.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/18.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import Foundation
import WCDBSwift

class RepoStore: WCDBSwift.TableCodable {
    
    var url: URL?
    var attach: [Int : RepoStruct]? = [:]
    
    init(with repo: RepoStruct) {
        url = repo.url
        attach![0] = repo
    }
    
    enum CodingKeys: String, CodingTableKey {
        typealias Root = RepoStore
        
        case url
        case attach
        
        static let objectRelationalMapping = TableBinding(CodingKeys.self)
        
        static var columnConstraintBindings: [CodingKeys: ColumnConstraintBinding]? {
            return [
                .url: ColumnConstraintBinding(isPrimary: true, isUnique: true)
            ]
        }

    }
    
    func obtainAttach() -> RepoStruct {
        return attach![0]!
    }
    
}

// Sample Meta

//Origin: Dynastic Repo
//Label: Dynastic Repo
//Suite: stable
//Version: 1.0
//Codename: ios
//Architectures: iphoneos-arm
//Components: main
//Description: The best place to download the best tweaks.
//Host-Software: Dynastic Repo
