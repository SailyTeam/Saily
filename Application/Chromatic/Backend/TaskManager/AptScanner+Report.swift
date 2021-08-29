//
//  AptScanner+Report.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/22.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import Foundation

/*
 only used by diagnostic view controller
 */

class PackageActionReport {
    static let shared = PackageActionReport()

    private var currentSession: String = ""
    private let accessLock = NSLock()

    private var reportList = [String]()

    func openSession() {
        accessLock.lock()
        currentSession = ""
        accessLock.unlock()
    }

    func append(_ str: String) {
        accessLock.lock()
        currentSession += str + "\n"
        accessLock.unlock()
    }

    @discardableResult
    func commit() -> String {
        accessLock.lock()
        let content = currentSession
        currentSession = ""
        reportList.append(content)
        accessLock.unlock()
        return content
    }

    func allAvailable() -> String {
        accessLock.lock()
        let result = reportList
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count > 0 }
            .joined(separator: "\n\n===>\n")
        reportList = []
        accessLock.unlock()
        return result
    }

    func clear() {
        accessLock.lock()
        reportList = []
        currentSession = ""
        accessLock.unlock()
    }
}
