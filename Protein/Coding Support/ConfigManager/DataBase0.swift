//
//  DataBase.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/18.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import Foundation
import WCDBSwift

class ConfigStore: WCDBSwift.TableCodable {
    
    var attach: [String : String] = [:]
        
    enum CodingKeys: String, CodingTableKey {
        typealias Root = ConfigStore
        
        case attach
        
        static let objectRelationalMapping = TableBinding(CodingKeys.self)

    }
    
}
