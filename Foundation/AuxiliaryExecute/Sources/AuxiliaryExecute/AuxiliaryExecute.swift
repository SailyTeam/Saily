//
//  AuxiliaryExecute.swift
//  MyYearWithGit
//
//  Created by Lakr Aream on 2021/11/27.
//

import Foundation

/// Execute command or shell with posix, shared with AuxiliaryExecute.local
public class AuxiliaryExecute {
    /// we do not recommend you to subclass this singleton
    public static let local = AuxiliaryExecute()

    // if binary not found when you call the shell api
    // we will take some time to rebuild the bianry table each time
    // -->>> this is a time-heavy-task
    // so use binaryLocationFor(command:) to cache it if needed

    // system path
    internal var currentPath: [String] = []
    // system binary table
    internal var binaryTable: [String: String] = [:]

    // for you to put your own search path
    internal var extraSearchPath: [String] = []
    // for you to set your own binary table and will be used firstly
    // if you set nil here
    // -> we will return nil even the binary found in system path
    internal var overwriteTable: [String: String?] = [:]

    /// when reading from file pipe, must called from async queue
    internal let pipeReadQueue = DispatchQueue(
        label: "wiki.qaq.AuxiliaryExecute.pipeRead",
        attributes: .concurrent
    )

    /// used for setting binary table, avoid crash
    internal let lock = NSLock()

    /// nope!
    private init() {
        // no need to setup binary table
        // we will make call to it when you call the shell api
        // if you only use the spawn api
        // we don't need to setup the hole table cause it‘s time-heavy-task
    }

    /// Execution Error, do the localization your self
    public enum ExecuteError: Error, LocalizedError, Codable {
        // not found in path
        case commandNotFound
        // invalid, may be missing, wrong permission or any other reason
        case commandInvalid
        // fcntl failed
        case openFilePipeFailed
        // posix failed
        case posixSpawnFailed
        // waitpid failed
        case waitPidFailed
        // timeout when execute
        case timeout
    }

    /// Execution Recipe
    public struct ExecuteRecipe: Codable {
        // exit code, usually 0 - 255 by system
        // -1 means something bad happened, set by us for convince
        public let exitCode: Int
        // any error from us, not the command it self
        // DOES NOT MEAN THAT THE COMMAND DONE WELL
        public let error: ExecuteError?
        // stdout
        public let stdout: String
        // stderr
        public let stderr: String
    }
}
