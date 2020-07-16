//
//  URL.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/19.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import Foundation

extension URL {
    
    var urlString: String {
        get {
            var v1 = self.absoluteString
            while v1.hasSuffix("/") {
                v1.removeLast()
            }
            return v1
        }
    }
    
    var fileString: String {
        get {
            var get = self.absoluteString
            if get.hasPrefix("file:") {
                get.removeFirst("file:".count)
            }
            return get
        }
    }
    
}
