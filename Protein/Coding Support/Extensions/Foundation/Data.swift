//
//  Data.swift
//  Protein
//
//  Created by Lakr Aream on 2020/7/19.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import Foundation

extension Data {

    init<T>(from value: T) {
        var value = value
        self.init(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }

    func to<T>(type: T.Type) -> T {
        return self.withUnsafeBytes { $0.load(as: T.self) }
    }
}
