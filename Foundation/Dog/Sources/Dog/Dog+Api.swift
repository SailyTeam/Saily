//
//  Dog.swift
//  Chromatic
//
//  Created by Lakr Aream on 12/15/20.
//

import Foundation

public extension Dog {
    /// grab all available logs
    /// - Returns: there file url
    func obtainAllLogFilePath() -> [URL] {
        var ret = [URL]()
        if let base = currentLogFileDirLocation,
           let items = try? FileManager.default.contentsOfDirectory(atPath: base.path)
        {
            for item in items where item.hasPrefix(loggingPrefix) {
                ret.append(base.appendingPathComponent(item))
            }
        }
        return ret
    }

    /// grab current logs
    /// - Returns: log in String
    func obtainCurrentLogContent() -> String {
        var str = ""
        if let path = currentLogFileLocation?.path,
           let read = try? String(contentsOfFile: path, encoding: .utf8)
        {
            str = read
        }
        return str
    }

    /// write to logging system and write
    /// - Parameters:
    ///   - kind: grouped tagging, we suggest use the class name
    ///   - message: message
    ///   - level: level for logging, can be used to filtering log later on
    func join(_ kind: String, _ message: String, level: DogLevel = .info) {
        // thread safe
        executionLock.lock()
        defer { executionLock.unlock() }

        // the real message to write
        let content: String
        if lastTag == kind {
            content = "* |\(level.rawValue)| \(formatter.string(from: Date()))| \(message)"
        } else {
            lastTag = kind
            content = "[\(kind)]\n* |\(level.rawValue)| \(formatter.string(from: Date()))| \(message)"
        }
        // print stdout
        print(content)
        // check
        guard let handler = logFileHandler else {
            print("[E] failed/didn't open then file handler")
            return
        }
        // write
        if let data = content.appending("\n").data(using: .utf8) {
            handler.write(data)
        } else {
            print("Dog failed to create log data using utf8")
        }
    }

    /// an wrapper around describing class
    /// - Parameters:
    ///   - kind: grouped tagging, we suggest use the class name
    ///   - message: message
    ///   - level: level for logging, can be used to filtering log later on
    func join(_ kind: Any, _ message: String, level: DogLevel = .info) {
        join(String(describing: kind.self), message, level: level)
    }

    /// initialize to dir, call only once
    /// - Parameter config: configuration
    func initialization(writableDir: URL? = nil) throws {
        var dispathDir = writableDir
        if dispathDir == nil {
            dispathDir = FileManager
                .default
                .urls(for: .documentDirectory, in: .userDomainMask)
                .first
        }
        guard let dispathDir = dispathDir else {
            throw NSError(domain: "wiki.qaq.chromatic", code: -1, userInfo: [:])
        }

        try? FileManager
            .default
            .createDirectory(atPath: dispathDir.path,
                             withIntermediateDirectories: true,
                             attributes: nil)
        let storeLocationDir = dispathDir
            .appendingPathComponent(Dog.dirBase, isDirectory: true)
        try? FileManager.default.createDirectory(atPath: storeLocationDir.path,
                                                 withIntermediateDirectories: true,
                                                 attributes: nil)

        var bool = ObjCBool(false)
        let dirValidate = FileManager
            .default
            .fileExists(atPath: storeLocationDir.path, isDirectory: &bool)
        if !(dirValidate && bool.boolValue) {
            print("unable to initialize, permission denied at \(storeLocationDir.path)")
            throw NSError(domain: "wiki.qaq.chromatic", code: -1, userInfo: [:])
        }

        currentLogFileDirLocation = storeLocationDir

        // please keep file date name will use it later on

        var logFileLocation: URL
        do {
            let dateName = String(formatter.string(from: Date()))
            // randomized sub suffix
            var suffix = String(UUID().uuidString)
            while suffix.count > loggingRndSuffix.count {
                suffix.removeLast()
            }
            // create file name
            let name = [
                loggingPrefix, "_",
                dateName, "_",
                suffix, ".",
                loggingSuffix,
            ]
            .joined()
            #if DEBUG
                // double check
                assert(!name.contains(" "), "\(#file) \(#line) invalid log file name: \(name)")
                assert(name.count == cLogFilenameLenth, "\(#file) \(#line) invalid log file name: \(name)")
            #endif
            logFileLocation = storeLocationDir.appendingPathComponent(name)
            // for very edge case, we handle this
            try? FileManager.default.removeItem(at: logFileLocation)
        }

        // delete logs that exceed limit
        do {
            try cleanLogs()
        } catch {
            // some very bad permission issue
            print("[Dog] \(#file) \(#line) failed to enumerate contents of directory: \(storeLocationDir)")
            throw error
        }

        // Create file now
        FileManager.default.createFile(atPath: logFileLocation.path, contents: nil, attributes: nil)
        print("[Dog] \(logFileLocation.path)")

        // open the handler
        if let handler = FileHandle(forWritingAtPath: logFileLocation.path) {
            logFileHandler = handler
        } else {
            throw NSError(domain: "wiki.qaq.chromatic", code: -1, userInfo: [:])
        }

        currentLogFileLocation = logFileLocation
    }

    // TODO: Filtering Level
}
