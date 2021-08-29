//
//  spawn.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/23.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import Dog
import UIKit

enum AuxiliaryExecute {
    private(set) static var chromaticspawn: String = "/usr/sbin/chromaticspawn"

    private(set) static var cp: String = "/bin/cp"
    private(set) static var chmod: String = "/bin/chmod"
    private(set) static var mv: String = "/bin/mv"
    private(set) static var mkdir: String = "/bin/mkdir"
    private(set) static var touch: String = "/usr/bin/touch"
    private(set) static var rm: String = "/bin/rm"
    private(set) static var kill: String = "/bin/kill"
    private(set) static var killall: String = "/bin/killall"
    private(set) static var sbreload: String = "/usr/bin/sbreload"
    private(set) static var uicache: String = "/usr/bin/uicache"
    private(set) static var apt: String = "/usr/bin/apt"
    private(set) static var dpkg: String = "/usr/bin/dpkg"

    private static let searchPath = "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
        .components(separatedBy: ":")

    static func setupExecutables() {
        do {
            let bundle = Bundle
                .main
                .url(forAuxiliaryExecutable: "chromaticspawn")
            if let bundle = bundle {
                chromaticspawn = bundle.path
                Dog.shared.join(self,
                                "preferred bundled executable \(bundle.path) rather then system one",
                                level: .info)
            }
        }

        var allBinary = [String: URL]()

        #if DEBUG
            let searchBegin = Date()
        #endif

        searchPath.forEach { path in
            guard let items = try? FileManager
                .default
                .contentsOfDirectory(atPath: path)
            else {
                return
            }
            for item in items {
                let url = URL(fileURLWithPath: path)
                    .appendingPathComponent(item)
                allBinary[item] = url
            }
        }

        if let cp = allBinary["cp"] {
            self.cp = cp.path
            Dog.shared.join("BinaryFinder", "setting up binary cp at \(cp.path)")
        }
        if let chmod = allBinary["chmod"] {
            self.chmod = chmod.path
            Dog.shared.join("BinaryFinder", "setting up binary chmod at \(chmod.path)")
        }
        if let mv = allBinary["mv"] {
            self.mv = mv.path
            Dog.shared.join("BinaryFinder", "setting up binary mv at \(mv.path)")
        }
        if let mkdir = allBinary["mkdir"] {
            self.mkdir = mkdir.path
            Dog.shared.join("BinaryFinder", "setting up binary mkdir at \(mkdir.path)")
        }
        if let touch = allBinary["touch"] {
            self.touch = touch.path
            Dog.shared.join("BinaryFinder", "setting up binary touch at \(touch.path)")
        }
        if let rm = allBinary["rm"] {
            self.rm = rm.path
            Dog.shared.join("BinaryFinder", "setting up binary rm at \(rm.path)")
        }
        if let kill = allBinary["kill"] {
            self.kill = kill.path
            Dog.shared.join("BinaryFinder", "setting up binary kill at \(kill.path)")
        }
        if let killall = allBinary["killall"] {
            self.killall = killall.path
            Dog.shared.join("BinaryFinder", "setting up binary killall at \(killall.path)")
        }
        if let sbreload = allBinary["sbreload"] {
            self.sbreload = sbreload.path
            Dog.shared.join("BinaryFinder", "setting up binary sbreload at \(sbreload.path)")
        }
        if let uicache = allBinary["uicache"] {
            self.uicache = uicache.path
            Dog.shared.join("BinaryFinder", "setting up binary uicache at \(uicache.path)")
        }
        if let apt = allBinary["apt"] {
            self.apt = apt.path
            Dog.shared.join("BinaryFinder", "setting up binary apt at \(apt.path)")
        }
        if let dpkg = allBinary["dpkg"] {
            self.dpkg = dpkg.path
            Dog.shared.join("BinaryFinder", "setting up binary dpkg at \(dpkg.path)")
        }

        #if DEBUG
            let used = Date().timeIntervalSince(searchBegin)
            debugPrint("binary lookup took \(String(format: "%.2f", used))s")
        #endif
    }

    static func suspendApplication() {
        UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
    }

    static func reloadSpringboard() {
        AuxiliaryExecute.suspendApplication()
        AuxiliaryExecute.rootspawn(command: AuxiliaryExecute.sbreload, args: [], timeout: 0, output: { _ in })
        sleep(3) // <-- sbreload failed?
        AuxiliaryExecute.rootspawn(command: AuxiliaryExecute.killall, args: ["backboardd"], timeout: 0, output: { _ in })
    }

    @discardableResult
    static func rootspawn(command: String,
                          args: [String],
                          timeout: Int,
                          output: @escaping (String) -> Void) -> (Int, String, String)
    {
        let result = mobilespawn(command: AuxiliaryExecute.chromaticspawn,
                                 args: [command] + args,
                                 timeout: timeout,
                                 output: output)
        return result
    }

    @discardableResult
    static func mobilespawn(command: String,
                            args: [String],
                            timeout: Int,
                            output: @escaping (String) -> Void)
        -> (Int, String, String)
    {
        Dog.shared.join("Exec",
                        "begin exec on command: \(command), args: \(args.joined(separator: " "))",
                        level: .info)

        setenv("chromaticAuxiliaryExec", "YES", 1)

        var pipestdout: [Int32] = [0, 0]
        var pipestderr: [Int32] = [0, 0]

        let bufsiz = Int(BUFSIZ)

        pipe(&pipestdout)
        pipe(&pipestderr)

        guard fcntl(pipestdout[0], F_SETFL, O_NONBLOCK) != -1 else {
            return (-1, "", "")
        }
        guard fcntl(pipestderr[0], F_SETFL, O_NONBLOCK) != -1 else {
            return (-1, "", "")
        }

        var fileActions: posix_spawn_file_actions_t?
        posix_spawn_file_actions_init(&fileActions)
        posix_spawn_file_actions_addclose(&fileActions, pipestdout[0])
        posix_spawn_file_actions_addclose(&fileActions, pipestderr[0])
        posix_spawn_file_actions_adddup2(&fileActions, pipestdout[1], STDOUT_FILENO)
        posix_spawn_file_actions_adddup2(&fileActions, pipestderr[1], STDERR_FILENO)
        posix_spawn_file_actions_addclose(&fileActions, pipestdout[1])
        posix_spawn_file_actions_addclose(&fileActions, pipestderr[1])

        let args = [command] + args
        let argv: [UnsafeMutablePointer<CChar>?] = args.map { $0.withCString(strdup) }
        defer { for case let arg? in argv { free(arg) } }

        var pid: pid_t = 0

        let spawnStatus = posix_spawn(&pid, command, &fileActions, nil, argv + [nil], environ)
        if spawnStatus != 0 {
            return (-1, "", "")
        }

        close(pipestdout[1])
        close(pipestderr[1])

        var stdoutStr = ""
        var stderrStr = ""

        let mutex = DispatchSemaphore(value: 0)

        let readQueue = DispatchQueue(label: "wiki.qaq.command",
                                      qos: .userInitiated,
                                      attributes: .concurrent,
                                      autoreleaseFrequency: .inherit,
                                      target: nil)

        let stdoutSource = DispatchSource.makeReadSource(fileDescriptor: pipestdout[0], queue: readQueue)
        let stderrSource = DispatchSource.makeReadSource(fileDescriptor: pipestderr[0], queue: readQueue)

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
                output(str)
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
                output(str)
            }
        }

        stdoutSource.resume()
        stderrSource.resume()

        var terminated = false
        if timeout > 0 {
            DispatchQueue.global().async {
                var count = 0
                while !terminated {
                    sleep(1) // no need to get this job running precisely
                    count += 1
                    if count > timeout {
                        let kill = Darwin.kill(pid, 9)
                        NSLog("[E] execution timeout, kill \(pid) returns \(kill)")
                        terminated = true
                        return
                    }
                }
            }
        }

        mutex.wait()
        mutex.wait()
        var status: Int32 = 0

        waitpid(pid, &status, 0)
        terminated = true

        Dog.shared.join("Exec",
                        "exec on command: \(command) exited \(status)",
                        level: .info)

        return (Int(status), stdoutStr, stderrStr)
    }
}
