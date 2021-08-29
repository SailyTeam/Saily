//
//  File.swift
//
//
//  Created by Lakr Aream on 2021/8/10.
//

import Foundation

public extension RepositoryCenter {
    /// post notification with this object
    struct UpdateNotification {
        public let representedRepo: URL
        public let progress: Progress?
        public let complete: Bool
        public let success: Bool
        public let queueLeft: Int
    }
}
