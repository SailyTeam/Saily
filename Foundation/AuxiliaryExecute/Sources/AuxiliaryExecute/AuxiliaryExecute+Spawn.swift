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
    ///   - output: a block call from pipeControlQueue in background when buffer from stdout or stderr available for read
    /// - Returns: execution recipe, see it's definition for details
    @discardableResult
    static func spawn(
        command: String,
        args: [String] = [],
        environment: [String: String] = [:],
        timeout: Double = 0,
        setPid: ((pid_t) -> Void)? = nil,
        output: ((String) -> Void)? = nil
    )
        -> ExecuteRecipe
    {
        let outputLock = NSLock()
        let result = spawn(
            command: command,
            args: args,
            environment: environment,
            timeout: timeout,
            setPid: setPid
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

    /// call posix spawn to begin execute and block until the process exits
    /// - Parameters:
    ///   - command: full path of the binary file. eg: "/bin/cat"
    ///   - args: arg to pass to the binary, exclude argv[0] which is the path itself. eg: ["nya"]
    ///   - environment: any environment to be appended/overwrite when calling posix spawn. eg: ["mua" : "nya"]
    ///   - timeout: any wall timeout if lager than 0, in seconds. eg: 6
    ///   - stdout: a block call from pipeControlQueue in background when buffer from stdout available for read
    ///   - stderr: a block call from pipeControlQueue in background when buffer from stderr available for read
    /// - Returns: execution recipe, see it's definition for details
    static func spawn(
        command: String,
        args: [String] = [],
        environment: [String: String] = [:],
        timeout: Double = 0,
        setPid: ((pid_t) -> Void)? = nil,
        stdoutBlock: ((String) -> Void)? = nil,
        stderrBlock: ((String) -> Void)? = nil
    ) -> ExecuteRecipe {
        let sema = DispatchSemaphore(value: 0)
        var recipe: ExecuteRecipe!
        spawn(
            command: command,
            args: args,
            environment: environment,
            timeout: timeout,
            setPid: setPid,
            stdoutBlock: stdoutBlock,
            stderrBlock: stderrBlock
        ) {
            recipe = $0
            sema.signal()
        }
        sema.wait()
        return recipe
    }

    /// call posix spawn to begin execute
    /// - Parameters:
    ///   - command: full path of the binary file. eg: "/bin/cat"
    ///   - args: arg to pass to the binary, exclude argv[0] which is the path itself. eg: ["nya"]
    ///   - environment: any environment to be appended/overwrite when calling posix spawn. eg: ["mua" : "nya"]
    ///   - timeout: any wall timeout if lager than 0, in seconds. eg: 6
    ///   - setPid: called sync when pid available
    ///   - stdoutBlock: a block call from pipeControlQueue in background when buffer from stdout available for read
    ///   - stderrBlock: a block call from pipeControlQueue in background when buffer from stderr available for read
    ///   - completionBlock: a block called from processControlQueue or current queue when the process is finished or an error occurred
    static func spawn(
        command: String,
        args: [String] = [],
        environment: [String: String] = [:],
        timeout: Double = 0,
        setPid: ((pid_t) -> Void)? = nil,
        stdoutBlock: ((String) -> Void)? = nil,
        stderrBlock: ((String) -> Void)? = nil,
        completionBlock: ((ExecuteRecipe) -> Void)? = nil
    ) {
        // MARK: PREPARE FILE PIPE -

        var pipestdout: [Int32] = [0, 0]
        var pipestderr: [Int32] = [0, 0]

        let bufsiz = Int(exactly: BUFSIZ) ?? 65535

        pipe(&pipestdout)
        pipe(&pipestderr)

        guard fcntl(pipestdout[0], F_SETFL, O_NONBLOCK) != -1 else {
            let recipe = ExecuteRecipe.failure(error: .openFilePipeFailed)
            completionBlock?(recipe)
            return
        }
        guard fcntl(pipestderr[0], F_SETFL, O_NONBLOCK) != -1 else {
            let recipe = ExecuteRecipe.failure(error: .openFilePipeFailed)
            completionBlock?(recipe)
            return
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

        var fileAttribute: posix_spawnattr_t?

        if getuid() != 0 {
            posix_spawnattr_init(&fileAttribute)

            typealias posix_spawnattr_set_persona_np = @convention(c) (
                _ v1: UnsafeMutablePointer<posix_spawnattr_t?>?,
                _ v2: Any,
                _ v3: Any
            ) -> Void
            typealias posix_spawnattr_set_persona_uid_np = @convention(c) (
                _ v1: UnsafeMutablePointer<posix_spawnattr_t?>?,
                _ v2: Any
            ) -> Void
            typealias posix_spawnattr_set_persona_gid_np = @convention(c) (
                _ v1: UnsafeMutablePointer<posix_spawnattr_t?>?,
                _ v2: Any
            ) -> Void

            let open = dlopen(nil, RTLD_NOW)
            if unsafeBitCast(open, to: Int.self) > 0x1024 {
                let _posix_spawnattr_set_persona_np = dlsym(open, "posix_spawnattr_set_persona_np")
                let __posix_spawnattr_set_persona_np = unsafeBitCast(
                    _posix_spawnattr_set_persona_np,
                    to: posix_spawnattr_set_persona_np.self
                )
                __posix_spawnattr_set_persona_np(&fileAttribute, 99, 1)

                let _posix_spawnattr_set_persona_uid_np = dlsym(open, "posix_spawnattr_set_persona_uid_np")
                let __posix_spawnattr_set_persona_uid_np = unsafeBitCast(
                    _posix_spawnattr_set_persona_uid_np,
                    to: posix_spawnattr_set_persona_uid_np.self
                )
                __posix_spawnattr_set_persona_uid_np(&fileAttribute, 0)

                let _posix_spawnattr_set_persona_gid_np = dlsym(open, "posix_spawnattr_set_persona_gid_np")
                let __posix_spawnattr_set_persona_gid_np = unsafeBitCast(
                    _posix_spawnattr_set_persona_gid_np,
                    to: posix_spawnattr_set_persona_gid_np.self
                )
                __posix_spawnattr_set_persona_gid_np(&fileAttribute, 0)
            }
        }

        defer {
            if fileAttribute != nil { posix_spawnattr_destroy(&fileAttribute) }
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
        let spawnStatus = posix_spawn(&pid, command, &fileActions, &fileAttribute, argv + [nil], realEnv + [nil])
        if spawnStatus != 0 {
            let recipe = ExecuteRecipe.failure(error: .posixSpawnFailed)
            completionBlock?(recipe)
            return
        }

        setPid?(pid)

        close(pipestdout[1])
        close(pipestderr[1])

        var stdoutStr = ""
        var stderrStr = ""

        // MARK: OUTPUT BRIDGE -

        let stdoutSource = DispatchSource.makeReadSource(fileDescriptor: pipestdout[0], queue: pipeControlQueue)
        let stderrSource = DispatchSource.makeReadSource(fileDescriptor: pipestderr[0], queue: pipeControlQueue)

        let stdoutSem = DispatchSemaphore(value: 0)
        let stderrSem = DispatchSemaphore(value: 0)

        stdoutSource.setCancelHandler {
            close(pipestdout[0])
            stdoutSem.signal()
        }
        stderrSource.setCancelHandler {
            close(pipestderr[0])
            stderrSem.signal()
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

        let realTimeout = timeout > 0 ? timeout : maxTimeoutValue
        let wallTimeout = DispatchTime.now() + (
            TimeInterval(exactly: realTimeout) ?? maxTimeoutValue
        )
        var status: Int32 = 0
        var wait: pid_t = 0
        var isTimeout = false

        let timerSource = DispatchSource.makeTimerSource(flags: [], queue: processControlQueue)
        timerSource.setEventHandler {
            isTimeout = true
            kill(pid, SIGKILL)
        }

        let processSource = DispatchSource.makeProcessSource(identifier: pid, eventMask: .exit, queue: processControlQueue)
        processSource.setEventHandler {
            wait = waitpid(pid, &status, 0)

            processSource.cancel()
            timerSource.cancel()

            stdoutSem.wait()
            stderrSem.wait()

            // by using exactly method, we won't crash it!
            let recipe = ExecuteRecipe(
                exitCode: Int(exactly: status) ?? -1,
                pid: Int(exactly: pid) ?? -1,
                wait: Int(exactly: wait) ?? -1,
                error: isTimeout ? .timeout : nil,
                stdout: stdoutStr,
                stderr: stderrStr
            )
            completionBlock?(recipe)
        }
        processSource.resume()

        // timeout control
        timerSource.schedule(deadline: wallTimeout)
        timerSource.resume()
    }
}
