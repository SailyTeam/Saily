//
//  File.swift
//
//
//  Created by Lakr Aream on 2021/8/7.
//

import Foundation

internal extension Dog {
    /// Compare date with log file name
    /// - Parameters:
    ///   - a: log a
    ///   - b: log b
    /// - Returns: if a was earlier
    func sortCompareFileName(a: String, b: String) -> Bool {
        // bad file name
        if a.count != cLogFilenameLenth || b.count != cLogFilenameLenth {
            return a < b
        }
        // eg. "Dog_"
        let prefixLenth = [
            loggingPrefix, "_",
        ]
        .joined()
        .count
        // eg. "_ACAF51D1.log"
        let suffixLenth = [
            "_",
            loggingRndSuffix, ".",
            loggingSuffix,
        ]
        .joined()
        .count
        // trim to grab data
        let dateStrA = String(a.dropFirst(prefixLenth).dropLast(suffixLenth))
        let dateStrB = String(b.dropFirst(prefixLenth).dropLast(suffixLenth))
        let dateA = Dog.shared.formatter.date(from: dateStrA)
        let dateB = Dog.shared.formatter.date(from: dateStrB)
        if let dateA = dateA, let dateB = dateB {
            // a is early then b
            return dateA.timeIntervalSince(dateB) < 0
        } else {
            // can not process
            return a < b
        }
    }

    /// Clean logs that exceed the limit by maximumLogCount
    /// - Throws: if any error
    func cleanLogs() throws {
        guard let underDir = currentLogFileDirLocation else {
            print("[Dog] unable to find working location")
            return
        }
        // grab all file names
        let rawSubitems = try FileManager
            .default
            .contentsOfDirectory(atPath: underDir.path)
        // if too much
        if rawSubitems.count > maximumLogCount {
            // we are comparing the date
            let subitems = rawSubitems.sorted { a, b -> Bool in
                sortCompareFileName(a: a, b: b)
            }
            let deleteCount = subitems.count - maximumLogCount
            if deleteCount > 0 {
                // the file that needs to be deleted
                for index in 0 ..< deleteCount {
                    #if DEBUG
                        print("please contact me if this assert really happens")
                        assert(index < subitems.count && index >= 0, "\(#file) \(#line) bad index")
                    #else
                        // again, edge cases
                        if index < subitems.count, index >= 0 {
                            continue
                        }
                    #endif
                    let file = underDir.appendingPathComponent("\(subitems[index])")
                    debugPrint("[Dog] cleaning log file[\(index)] at: \(file.path)")
                    do {
                        try FileManager.default.removeItem(at: file)
                    } catch {
                        print("[Dog] failed to delete old logs at: \(file)")
                        #if DEBUG
                            fatalError("You are responsible for making the permission right")
                        #else
                            throw NSError()
                        #endif
                    }
                }
            }
        }
    }
}
