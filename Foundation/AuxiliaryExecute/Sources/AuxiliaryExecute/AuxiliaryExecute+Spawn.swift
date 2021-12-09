//
//  AuxiliaryExecute+Spawn.swift
//  AuxiliaryExecute
//
//  Created by Lakr Aream on 2021/12/6.
//

import Foundation

public extension AuxiliaryExecute {
    /// call posix spawn to begin execute
    /// - Parameters:
    ///   - command: full path of the binary file. eg: "/bin/cat"
    ///   - args: arg to pass to the binary, exclude argv[0] which is the path itself. eg: ["nya"]
    ///   - environment: any environment to be appended/overwrite when calling posix spawn. eg: ["mua" : "nya"]
    ///   - timeout: any wall timeout if lager than 0, in seconds. eg: 6
    ///   - output: a block call from pipeReadQueue in background when buffer from stdout or stderr available for read
    /// - Returns: execution recipe, see it's definition for details
    static func spawn(
        command: String,
        args: [String] = [],
        environment: [String: String] = [:],
        timeout: Double = 0,
        output: ((String) -> Void)? = nil
    )
        -> ExecuteRecipe
    {
        let outputLock = NSLock()
        let result = spawn(
            command: command,
            args: args,
            environment: environment,
            timeout: timeout
        ) { str in
            outputLock.lock()
            output?(str)
            outputLock.unlock()
        } stderrBlock: { str in
            outputLock.lock()
            output?(str)
            outputLock.unlock()
        }
        return result
    }

    /// call posix spawn to begin execute
    /// - Parameters:
    ///   - command: full path of the binary file. eg: "/bin/cat"
    ///   - args: arg to pass to the binary, exclude argv[0] which is the path itself. eg: ["nya"]
    ///   - environment: any environment to be appended/overwrite when calling posix spawn. eg: ["mua" : "nya"]
    ///   - timeout: any wall timeout if lager than 0, in seconds. eg: 6
    ///   - stdout: a block call from pipeReadQueue in background when buffer from stdout available for read
    ///   - stderr: a block call from pipeReadQueue in background when buffer from stderr available for read
    /// - Returns: execution recipe, see it's definition for details
    static func spawn(
        command: String,
        args: [String] = [],
        environment: [String: String] = [:],
        timeout: Double = 0,
        stdoutBlock: ((String) -> Void)? = nil,
        stderrBlock: ((String) -> Void)? = nil
    )
        -> ExecuteRecipe
    {
        // MARK: PREPARE FILE PIPE -

        var pipestdout: [Int32] = [0, 0]
        var pipestderr: [Int32] = [0, 0]

        let bufsiz = Int(exactly: BUFSIZ) ?? 65535

        pipe(&pipestdout)
        pipe(&pipestderr)

        guard fcntl(pipestdout[0], F_SETFL, O_NONBLOCK) != -1 else {
            return .init(
                exitCode: -1,
                error: .openFilePipeFailed,
                stdout: "",
                stderr: ""
            )
        }
        guard fcntl(pipestderr[0], F_SETFL, O_NONBLOCK) != -1 else {
            return .init(
                exitCode: -1,
                error: .openFilePipeFailed,
                stdout: "",
                stderr: ""
            )
        }

        // MARK: PREPARE FILE ACTION -

        var fileActions: posix_spawn_file_actions_t?
        posix_spawn_file_actions_init(&fileActions)
        posix_spawn_file_actions_addclose(&fileActions, pipestdout[0])
        posix_spawn_file_actions_addclose(&fileActions, pipestderr[0])
        posix_spawn_file_actions_adddup2(&fileActions, pipestdout[1], STDOUT_FILENO)
        posix_spawn_file_actions_adddup2(&fileActions, pipestderr[1], STDERR_FILENO)
        posix_spawn_file_actions_addclose(&fileActions, pipestdout[1])
        posix_spawn_file_actions_addclose(&fileActions, pipestderr[1])

        defer {
            posix_spawn_file_actions_destroy(&fileActions)
        }

        // MARK: PREPARE ENV -

        var realEnvironmentBuilder: [String] = []
        // before building the environment, we need to read from the existing environment
        do {
            var envBuilder = [String: String]()
            var currentEnv = environ
            while let rawStr = currentEnv.pointee {
                defer { currentEnv += 1 }
                // get the env
                let str = String(cString: rawStr)
                guard let key = str.components(separatedBy: "=").first else {
                    continue
                }
                if !(str.count >= "\(key)=".count) {
                    continue
                }
                // this is to aviod any problem with mua=nya=nya= that ending with =
                let value = String(str.dropFirst("\(key)=".count))
                envBuilder[key] = value
            }
            // now, let's overwrite the environment specified in parameters
            for (key, value) in environment {
                envBuilder[key] = value
            }
            // now, package those items
            for (key, value) in envBuilder {
                realEnvironmentBuilder.append("\(key)=\(value)")
            }
        }
        // making it a c shit
        let realEnv: [UnsafeMutablePointer<CChar>?] = realEnvironmentBuilder.map { $0.withCString(strdup) }
        defer { for case let env? in realEnv { free(env) } }

        // MARK: PREPARE ARGS -

        let args = [command] + args
        let argv: [UnsafeMutablePointer<CChar>?] = args.map { $0.withCString(strdup) }
        defer { for case let arg? in argv { free(arg) } }

        // MARK: NOW POSIX_SPAWN -

        var pid: pid_t = 0
        let spawnStatus = posix_spawn(&pid, command, &fileActions, nil, argv + [nil], realEnv + [nil])
        if spawnStatus != 0 {
            return .init(
                exitCode: -1,
                error: .posixSpawnFailed,
                stdout: "",
                stderr: ""
            )
        }

        close(pipestdout[1])
        close(pipestderr[1])

        var stdoutStr = ""
        var stderrStr = ""

        let mutex = DispatchSemaphore(value: 0)

        // MARK: OUTPUT BRIDGE -

        let stdoutSource = DispatchSource.makeReadSource(fileDescriptor: pipestdout[0], queue: pipeReadQueue)
        let stderrSource = DispatchSource.makeReadSource(fileDescriptor: pipestderr[0], queue: pipeReadQueue)

        stdoutSource.setCancelHandler {
            close(pipestdout[0])
            mutex.signal()
        }
        stderrSource.setCancelHandler {
            close(pipestderr[0])
            mutex.signal()
        }

        stdoutSource.setEventHandler {
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufsiz)
            defer { buffer.deallocate() }
            let bytesRead = read(pipestdout[0], buffer, bufsiz)
            guard bytesRead > 0 else {
                if bytesRead == -1, errno == EAGAIN {
                    return
                }
                stdoutSource.cancel()
                return
            }

            let array = Array(UnsafeBufferPointer(start: buffer, count: bytesRead)) + [UInt8(0)]
            array.withUnsafeBufferPointer { ptr in
                let str = String(cString: unsafeBitCast(ptr.baseAddress, to: UnsafePointer<CChar>.self))
                stdoutStr += str
                stdoutBlock?(str)
            }
        }
        stderrSource.setEventHandler {
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufsiz)
            defer { buffer.deallocate() }

            let bytesRead = read(pipestderr[0], buffer, bufsiz)
            guard bytesRead > 0 else {
                if bytesRead == -1, errno == EAGAIN {
                    return
                }
                stderrSource.cancel()
                return
            }

            let array = Array(UnsafeBufferPointer(start: buffer, count: bytesRead)) + [UInt8(0)]
            array.withUnsafeBufferPointer { ptr in
                let str = String(cString: unsafeBitCast(ptr.baseAddress, to: UnsafePointer<CChar>.self))
                stderrStr += str
                stderrBlock?(str)
            }
        }

        stdoutSource.resume()
        stderrSource.resume()

        // MARK: WAIT + TIMEOUT CONTROL -

        // the terminate process is a little bit tricky
        // listen carefully

        var everTimeout: Bool = false
        let realTimeout = timeout > 0 ? timeout : 2_147_483_647
        let wallTimeout = DispatchWallTime.now() + realTimeout

        let waitResultA = mutex.wait(wallTimeout: wallTimeout)
        if waitResultA == .timedOut {
            // if the first pipe failed to close in limit
            // that means timeout alreay occurred
            // perform a kill
            kill(pid, SIGKILL)
            everTimeout = true
        }

        let waitResultB = mutex.wait(wallTimeout: wallTimeout)
        if waitResultB == .timedOut {
            // the second pipe may still timeout
            // perform a kill just in case
            kill(pid, SIGKILL)
            everTimeout = true
        }

        func isNotTimeout() -> Bool {
            let result = wallTimeout >= .now()
            if !result { everTimeout = true }
            return result
        }

        var status: Int32 = 0
        var wait: pid_t = 0
        // now, let's loop over the waitpid func
        // as process may close file handler to bypass the timeout limit
        repeat {
            wait = waitpid(pid, &status, WUNTRACED | WCONTINUED)
        } while Signal.continueWaitLoop(wait) && isNotTimeout()

        // now, either process terminated it self, or timeout occurred
        if everTimeout {
            kill(pid, SIGKILL)
        }

        // wait for the final time
        waitpid(pid, &status, 0)

        // MARK: DONE -

        let code = Int(exactly: status) ?? -1 // ??? what ???

        return .init(
            exitCode: code,
            error: everTimeout ? .timeout : nil,
            stdout: stdoutStr,
            stderr: stderrStr
        )
    }
}
