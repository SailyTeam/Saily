//
//  CellularNetworkTool.swift
//  Protein
//
//  Created by soulghost on 30/5/2020.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import Foundation

class CellularNetworkTool {
    static func fixIt() {
        fixItImpl()
    }
    
    @objc private static func fixItImpl() {
        if let bundleId = Bundle.main.bundleIdentifier {
            SGNetworkConfigurationModifier .resolveNetworkProblmeForApp(withBundleId: bundleId)
        }
    }
}
