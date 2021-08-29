//
//  Dog.swift
//  Chromatic
//
//  Created by Lakr Aream on 12/11/20.
//

import Foundation

// MARK: - CHANGE ME IF NEEDED

// Dog_2021-03-01_22-10-43_ACAF51D1.log

internal let loggingPrefix = "Dog"
internal let loggingFormatter = "yyyy-MM-dd_HH-mm-ss"
internal let loggingRndSuffix = "AAAAAAAA"
internal let loggingSuffix = "log"
internal let cLogFilenameLenth = [
    loggingPrefix, "_",
    loggingFormatter, "_",
    loggingRndSuffix, ".",
    loggingSuffix,
]
.joined()
.count

// MARK: CHANGE ME IF NEEDED -

// MARK: - THE CLASS

public final class Dog {
    public enum DogLevel: String {
        /// Everything
        case verbose
        /// Normal output like when the (information) was updated
        case info
        /// Recoverable issue (warning) that would not break the logic flow
        /// - if the user wrote the wrong data but we can ignore the error and continue to execute
        case warning
        /// Non-recoverable (error), will impact logic flow
        /// - such as permission denied and the method shall return or throw
        case error
        /// (Fatal) where the application must exit or terminate
        /// fatalError or assert failure
        case critical
    }

    /// how many logs that you want to keep
    /// set before calling initialization
    public var maximumLogCount = 128 {
        didSet { try? cleanLogs() }
    }

    /// the place we save our logs
    internal static let dirBase = "Journal"

    /// shared
    public static let shared = Dog()

    public internal(set) var currentLogFileLocation: URL?
    public internal(set) var currentLogFileDirLocation: URL?
    internal var logFileHandler: FileHandle? {
        didSet {
            #if DEBUG
                if let oldValue = oldValue {
                    fatalError("[Dog] logFileHandler was being modified \(oldValue)")
                }
            #endif
        }
    }

    /// Thread Safe
    internal let executionLock = NSLock()

    /// grouped tagging
    internal var lastTag: String?

    /// date formatter for log name
    internal var formatter: DateFormatter = {
        let initDateFormatter = DateFormatter()
        initDateFormatter.dateFormat = loggingFormatter
        return initDateFormatter
    }()

    private init() {}
}
