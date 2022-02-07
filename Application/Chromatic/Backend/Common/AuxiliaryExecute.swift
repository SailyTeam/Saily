//
//  spawn.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/23.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AuxiliaryExecute
import Bugsnag
import Dog
import UIKit

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
    private(set) static var apt: String = "/usr/bin/apt"
    private(set) static var dpkg: String = "/usr/bin/dpkg"

    private(set) static var session: String?

    static let sessionTiketLocation = documentsDirectory
        .appendingPathComponent("wiki.qaq.root.sessions")

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

        let binarySearchPath = [
            "/usr/local/bin",
            "/usr/bin",
            "/bin",
        ]
        // "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

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
        if let apt = binaryLookupTable["apt"] {
            self.apt = apt.path
            Dog.shared.join("BinaryFinder", "setting up binary apt at \(apt.path)")
        }
        if let dpkg = binaryLookupTable["dpkg"] {
            self.dpkg = dpkg.path
            Dog.shared.join("BinaryFinder", "setting up binary dpkg at \(dpkg.path)")
        }

        #if DEBUG
            let used = Date().timeIntervalSince(searchBegin)
            debugPrint("binary lookup took \(String(format: "%.2f", used))s")
        #endif
    }

    static func createPrivilegedSession() {
        var maxRetry = 3
        while maxRetry > 0 {
            maxRetry -= 1
            // call the helper to generate the session
            let result = mobilespawn(command: chromaticspawn,
                                     args: ["ipc.create.root.session", sessionTiketLocation.path],
                                     timeout: 0) { _ in
            }
            // it should now output the session ticket in stdout
            // some tweak may interrupt our data stream so we lookup for them each line
            let lookup = result
                .1
                .components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            for ticket in lookup {
                // validate the ticket to have ticket:// prefix and aa55 suffix
                guard ticket.hasPrefix("ticket://"),
                      ticket.hasSuffix("AA55")
                else {
                    continue
                }
                session = ticket
                // for future use, we need to pass the session inside the env
                Dog.shared.join(self, "created privileged session \(ticket)", level: .info)
                Dog.shared.join(self, "ticket located at \(sessionTiketLocation.path)", level: .info)
                return
            }
            Dog.shared.join(self, "failed to create privileged session", level: .error)
        }
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
        if getuid() == 0 {
            Dog.shared.join(
                "AuxiliaryExecute",
                "\(command): \(args.joined(separator: " "))",
                level: .info
            )
            let recipe = AuxiliaryExecute.spawn(
                command: command,
                args: args,
                environment: [
                    "chromaticAuxiliaryExec": "1",
                ],
                timeout: Double(exactly: timeout) ?? 0,
                output: output
            )
            return (recipe.exitCode, recipe.stdout, recipe.stderr)
        } else {
            Dog.shared.join(
                "AuxiliaryExecute",
                "\(chromaticspawn): \(([command] + args).joined(separator: " "))",
                level: .info
            )
            let recipe = AuxiliaryExecute.spawn(
                command: chromaticspawn,
                args: [command] + args,
                environment: [
                    "chromaticAuxiliaryExec": "1",
                    "chromaticAuxiliaryExecTicket": session ?? "undefined",
                    "chromaticAuxiliaryExecTicketStore": sessionTiketLocation.path,
                ],
                timeout: Double(exactly: timeout) ?? 0,
                output: output
            )
            return (recipe.exitCode, recipe.stdout, recipe.stderr)
        }
    }

    @discardableResult
    static func mobilespawn(command: String,
                            args: [String],
                            timeout: Int,
                            output: @escaping (String) -> Void)
        -> (Int, String, String)
    {
        Dog.shared.join(
            "AuxiliaryExecute",
            "\(command): \(args.joined(separator: " "))",
            level: .info
        )
        let recipe = AuxiliaryExecute.spawn(
            command: command,
            args: args,
            environment: [
                "chromaticAuxiliaryExec": "1",
            ],
            timeout: Double(exactly: timeout) ?? 0,
            output: output
        )
        return (recipe.exitCode, recipe.stdout, recipe.stderr)
    }
}

/*
 Developer Notes

 //  [Uncover]
 // * |info| 2021-09-17_09-19-08| setting up binary cp at /bin/cp
 // * |info| 2021-09-17_09-19-08| setting up binary chmod at /bin/chmod
 // * |info| 2021-09-17_09-19-08| setting up binary mv at /bin/mv
 // * |info| 2021-09-17_09-19-08| setting up binary mkdir at /bin/mkdir
 // * |info| 2021-09-17_09-19-08| setting up binary touch at /bin/touch
 // * |info| 2021-09-17_09-19-08| setting up binary rm at /bin/rm
 // * |info| 2021-09-17_09-19-08| setting up binary kill at /bin/kill
 // * |info| 2021-09-17_09-19-08| setting up binary killall at /usr/bin/killall
 // * |info| 2021-09-17_09-19-08| setting up binary sbreload at /usr/bin/sbreload
 // * |info| 2021-09-17_09-19-08| setting up binary uicache at /usr/bin/uicache
 // * |info| 2021-09-17_09-19-08| setting up binary apt at /usr/bin/apt
 // * |info| 2021-09-17_09-19-08| setting up binary dpkg at /usr/bin/dpkg

 */
