//
//  AuxiliaryExecute+Shell.swift
//  AuxiliaryExecute
//
//  Created by Lakr Aream on 2021/12/6.
//

import Foundation

public extension AuxiliaryExecute {
    /// Setup binary table, require lock
    internal func setupBinaryTable() {
        lock.lock()

        let environmentPath = ProcessInfo
            .processInfo
            .environment["PATH"]?
            .components(separatedBy: ":")
            .compactMap { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            ?? []

        currentPath = environmentPath
        binaryTable.removeAll()

        // now, let's search inside your path and system path
        for eachPath in environmentPath + extraSearchPath {
            if let dirElements = try? FileManager
                .default
                .contentsOfDirectory(atPath: eachPath)
            {
                for node in dirElements {
                    let itemLocation = URL(fileURLWithPath: eachPath)
                        .appendingPathComponent(node)
                    if !isBinaryValid(at: itemLocation) {
                        continue
                    }
                    binaryTable[node] = itemLocation.path
                }
            }
        }

        lock.unlock()
    }

    /// append the search path, thread safe
    /// - Parameter value: the path
    func appendSearchPath(with value: String) {
        lock.lock()
        extraSearchPath.append(value)
        lock.unlock()
    }

    /// update the customized search path, thread safe
    /// - Parameter block: update inside this block
    func updateExtraSearchPath(with block: (inout [String]) -> Void) {
        lock.lock()
        block(&extraSearchPath)
        lock.unlock()
    }

    /// update the customized binary table, thread safe
    /// - Parameter block: update inside this block
    func updateOverwriteTable(with block: (inout [String: String?]) -> Void) {
        lock.lock()
        block(&overwriteTable)
        lock.unlock()
    }

    /// return whether you telling us to not to find anything with this command in shell
    /// - Parameter command: command name
    /// - Returns: should skip search
    internal func commandShouldNotExists(command: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if overwriteTable.keys.contains(command) {
            if let value = overwriteTable[command] {
                // it is a String?? :)
                return value == nil
            } else {
                // there must be something wrong
                assertionFailure("broken memory found with overwriteTable")
                return false
            }
        }
        return false
    }

    /// safely grab the full path for shell command
    /// - Parameter command: command name
    /// - Returns: full path if exists, otherwise nil
    func binaryLocationFor(command: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        // check if you overwritten the command first
        if overwriteTable.keys.contains(command) {
            if let value = overwriteTable[command] {
                // it is a String?? :)
                // you telling us to not find anything with this command
                return value
            } else {
                // there must be something wrong
                assertionFailure("broken memory found with overwriteTable")
                return nil
            }
        } else {
            return binaryTable[command]
        }
    }

    /// Indicate if a file has permission to execute, check's with permission
    /// - Parameter at: file url
    /// - Returns: able to execute or not
    private func isBinaryValid(at: URL) -> Bool {
        FileManager
            .default
            .isExecutableFile(atPath: at.path)
    }

    /// call a binary to execute
    /// - Parameters:
    ///   - command: the command's name, not full path. eg: bash
    ///   - args: arg to pass to the binary, exclude argv[0] which is the path itself. eg: ["nya"]
    ///   - environment: any environment to be appended/overwrite when calling posix spawn. eg: ["mua" : "nya"]
    ///   - timeout: any wall timeout if lager than 0, in seconds. eg: 6
    ///   - stdout: a block call from pipeControlQueue in background when buffer from stdout available for read
    ///   - stderr: a block call from pipeControlQueue in background when buffer from stderr available for read
    /// - Returns: execution recipe, see it's definition for details
    @discardableResult
    func shell(
        command: String,
        args: [String] = [],
        environment: [String: String] = [:],
        timeout: Double = 0,
        stdoutBlock: ((String) -> Void)? = nil,
        stderrBlock: ((String) -> Void)? = nil
    ) -> ExecuteRecipe {
        // the command with full file system path
        var commandLocation: String?
        if let location = binaryLocationFor(command: command) {
            commandLocation = location
        } else if !commandShouldNotExists(command: command) {
            // before calling to setup, check if you telling us so
            // if not so, search for the binary, for two reason:
            // - table is not yet built
            // - it may be added to the system after last setup
            setupBinaryTable()
        }
        // if nil, look for the command once again, after another setup
        if commandLocation == nil {
            commandLocation = binaryLocationFor(command: command)
        }
        // make sure we find the command
        guard let commandLocation = commandLocation else {
            return ExecuteRecipe.failure(error: .commandNotFound)
        }
        // now, let's validate the command
        guard isBinaryValid(at: URL(fileURLWithPath: commandLocation)) else {
            return ExecuteRecipe.failure(error: .commandInvalid)
        }
        // finally let‘s call the spawn
        let recipe = AuxiliaryExecute.spawn(
            command: commandLocation,
            args: args,
            environment: environment,
            timeout: timeout,
            stdoutBlock: stdoutBlock,
            stderrBlock: stderrBlock
        )
        return recipe
    }

    /// run script with bash, if bash available
    /// - Parameters:
    ///   - command: script to be passed to bash. eg: "echo nya"
    ///   - environment: any environment to be appended/overwrite when calling posix spawn. eg: ["mua" : "nya"]
    ///   - timeout: any wall timeout if lager than 0, in seconds. eg: 6
    ///   - stdout: a block call from pipeControlQueue in background when buffer from stdout available for read
    ///   - stderr: a block call from pipeControlQueue in background when buffer from stderr available for read
    /// - Returns: execution recipe, see it's definition for details
    @discardableResult
    func bash(
        command: String,
        environment: [String: String] = [:],
        timeout: Double = 0,
        stdoutBlock: ((String) -> Void)? = nil,
        stderrBlock: ((String) -> Void)? = nil
    ) -> ExecuteRecipe {
        let result = shell(
            command: "bash",
            args: ["-c", command],
            environment: environment,
            timeout: timeout,
            stdoutBlock: stdoutBlock,
            stderrBlock: stderrBlock
        )
        return result
    }
}
