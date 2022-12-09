//
//  spawn.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/23.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AuxiliaryExecute
import Bugsnag
import Darwin
import Dog
import SPIndicator
import UIKit

private let execFlag = "exec-root"

enum AuxiliaryExecuteWrapper {
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
//    private(set) static var apt: String = "/usr/bin/apt" // not good under rootless
    private(set) static var dpkg: String = "/usr/bin/dpkg"

    private(set) static var binarySearchPath = [
        "/bin",
        "/usr/bin",
        "/usr/local/bin",
    ]

    static func setupSearchPath() {
        if FileManager.default.fileExists(atPath: "/var/jb/Library/dpkg/status") {
            binarySearchPath = [
                "/var/jb/usr/bin",
            ]
        }
        if let path = ProcessInfo.processInfo.environment["PATH"] {
            binarySearchPath = path.components(separatedBy: ":") + binarySearchPath
        }
    }

    static func setupExecutables() {
        let bundle = Bundle
            .main
            .url(forAuxiliaryExecutable: "chromaticspawn")
        if let bundle = bundle {
            chromaticspawn = bundle.path
            Dog.shared.join(self,
                            "preferred bundled executable \(bundle.path) rather then system one",
                            level: .info)
        }

        var binaryLookupTable = [String: URL]()

        #if DEBUG
            let searchBegin = Date()
        #endif

        for path in binarySearchPath {
            if let items = try? FileManager
                .default
                .contentsOfDirectory(atPath: path)
            {
                for item in items {
                    let url = URL(fileURLWithPath: path)
                        .appendingPathComponent(item)
                    binaryLookupTable[item] = url
                }
            }
        }

        if let cp = binaryLookupTable["cp"] {
            self.cp = cp.path
            Dog.shared.join("BinaryFinder", "setting up binary cp at \(cp.path)")
        }
        if let chmod = binaryLookupTable["chmod"] {
            self.chmod = chmod.path
            Dog.shared.join("BinaryFinder", "setting up binary chmod at \(chmod.path)")
        }
        if let mv = binaryLookupTable["mv"] {
            self.mv = mv.path
            Dog.shared.join("BinaryFinder", "setting up binary mv at \(mv.path)")
        }
        if let mkdir = binaryLookupTable["mkdir"] {
            self.mkdir = mkdir.path
            Dog.shared.join("BinaryFinder", "setting up binary mkdir at \(mkdir.path)")
        }
        if let touch = binaryLookupTable["touch"] {
            self.touch = touch.path
            Dog.shared.join("BinaryFinder", "setting up binary touch at \(touch.path)")
        }
        if let rm = binaryLookupTable["rm"] {
            self.rm = rm.path
            Dog.shared.join("BinaryFinder", "setting up binary rm at \(rm.path)")
        }
        if let kill = binaryLookupTable["kill"] {
            self.kill = kill.path
            Dog.shared.join("BinaryFinder", "setting up binary kill at \(kill.path)")
        }
        if let killall = binaryLookupTable["killall"] {
            self.killall = killall.path
            Dog.shared.join("BinaryFinder", "setting up binary killall at \(killall.path)")
        }
        if let sbreload = binaryLookupTable["sbreload"] {
            self.sbreload = sbreload.path
            Dog.shared.join("BinaryFinder", "setting up binary sbreload at \(sbreload.path)")
        }
        if let uicache = binaryLookupTable["uicache"] {
            self.uicache = uicache.path
            Dog.shared.join("BinaryFinder", "setting up binary uicache at \(uicache.path)")
        }
//        if let apt = binaryLookupTable["apt"] {
//            self.apt = apt.path
//            Dog.shared.join("BinaryFinder", "setting up binary apt at \(apt.path)")
//        }
        if let dpkg = binaryLookupTable["dpkg"] {
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
        suspendApplication()
        rootspawn(command: sbreload, args: [], timeout: 0, output: { _ in })
        sleep(3) // <-- sbreload failed?
        rootspawn(command: killall, args: ["backboardd"], timeout: 0, output: { _ in })
    }

    @discardableResult
    static func rootspawn(command: String,
                          args: [String],
                          timeout: Int,
                          output: @escaping (String) -> Void) -> (Int, String, String)
    {
        Dog.shared.join(
            "AuxiliaryExecute",
            "\(command) \(args.joined(separator: " "))",
            level: .info
        )
        guard let binary = Bundle.main.executablePath else {
            DispatchQueue.main.async {
                SPIndicator.present(title: "Broken Bundle",
                                    message: "",
                                    preset: .error,
                                    haptic: .error,
                                    from: .top,
                                    completion: nil)
            }
            return (Int(EPERM), "", "")
        }
        let recipe = AuxiliaryExecute.spawn(
            command: binary,
            args: [execFlag] + [command] + args,
            environment: [
                "chromaticAuxiliaryExec": "1",
            ],
            timeout: Double(exactly: timeout) ?? 0,
            output: output
        )
        Dog.shared.join(
            "AuxiliaryExecute",
            recipe.stdout + "\n" + recipe.stderr,
            level: .info
        )
        return (recipe.exitCode, recipe.stdout, recipe.stderr)
    }

    static func checkExecutorRequestAndExecuteIfNeeded() {
        var args = CommandLine.arguments
        args.removeFirst()
        guard args.first == execFlag else { return }
        args.removeFirst()

        PlatformSetup.giveMeRoot()

        let binary = args.removeFirst()
        if binary == "whoami" {
            print("whoami: uid \(getuid()) gid \(getgid())")
            exit(0)
        }

        guard getuid() == 0, getgid() == 0 else {
            fputs("Permission Denied", stderr)
            exit(EPERM)
        }

        if binary == "exec-uicache" {
            // we may need root to lookup for apps...
            Self.setupExecutables()
            for item in (try? FileManager.default.contentsOfDirectory(atPath: "/Applications")) ?? [] {
                let path = "/Applications/\(item)"
                print("calling uicache at \(path)")
                AuxiliaryExecute.spawn(
                    command: uicache,
                    args: ["-p"],
                    environment: [:],
                    timeout: 10,
                    setPid: nil
                ) { print($0) }
            }
            for item in (try? FileManager.default.contentsOfDirectory(atPath: "/var/jb/Applications")) ?? [] {
                let path = "/var/jb/Applications/\(item)"
                print("calling uicache at \(path)")
                AuxiliaryExecute.spawn(
                    command: uicache,
                    args: ["-p", path],
                    environment: [:],
                    timeout: 10,
                    setPid: nil
                ) { print($0) }
            }
            let list = AuxiliaryExecute.spawn(
                command: uicache,
                args: ["-l"],
                environment: [:],
                timeout: 30,
                setPid: nil
            ) { print($0) }
            for line in list.stdout.components(separatedBy: "\n") {
                guard line.contains(" : ") else { continue }
                var sep = line.components(separatedBy: " : ")
                guard sep.count == 2 else { continue }
                let bundleIdentifier = sep.removeFirst().trimmingCharacters(in: .whitespacesAndNewlines)
                let path = sep.removeFirst().trimmingCharacters(in: .whitespacesAndNewlines)
                guard !bundleIdentifier.lowercased().hasPrefix("com.apple.") else { continue }
                guard !FileManager.default.fileExists(atPath: path) else { continue }
                print("[*] removing uicache at \(path)")
                AuxiliaryExecute.spawn(
                    command: uicache,
                    args: ["-u", path],
                    environment: [:],
                    timeout: 10,
                    setPid: nil
                ) { print($0) }
            }
            exit(0)
        }

        for key in ProcessInfo.processInfo.environment.keys {
            unsetenv(key)
        }

        let ret = AuxiliaryExecute.spawn(
            command: binary,
            args: args,
            environment: ["PATH": binarySearchPath.joined(separator: ":")],
            timeout: 0,
            setPid: nil
        ) { str in
            fputs(str, stdout)
        } stderrBlock: { str in
            fputs(str, stderr)
        }
        exit(Int32(ret.exitCode))
    }
}
