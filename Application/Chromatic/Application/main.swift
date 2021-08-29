//
//  Main.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/5.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import Dog
import UIKit

// MARK: - Security

#if !DEBUG
    do {
        typealias ptrace = @convention(c) (_ request: Int, _ pid: Int, _ addr: Int, _ data: Int) -> AnyObject
        let open = dlopen("/usr/lib/system/libsystem_kernel.dylib", RTLD_NOW)
        if unsafeBitCast(open, to: Int.self) > 0x1024 {
            let result = dlsym(open, "ptrace")
            if let result = result {
                let target = unsafeBitCast(result, to: ptrace.self)
                _ = target(0x1F, 0, 0, 0)
            }
        }
    }
#endif

// MARK: - Document

UserDefaults
    .standard
    .setValue("wiki.qaq.chromatic", forKey: "wiki.qaq.chromatic.storeDirPrefix")

private let availableDirectories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
public let documentsDirectory = availableDirectories[0].appendingPathComponent("wiki.qaq.chromatic")

let previousSetupLocation = UserDefaults
    .standard
    .string(forKey: "wiki.qaq.chromatic.setupLocation")
if let previousSetupLocation = previousSetupLocation,
   previousSetupLocation != documentsDirectory.path
{
    let previousSetupURL = URL(fileURLWithPath: previousSetupLocation)
    // document has been moved to a new place
    var isDir = ObjCBool(false)
    let result = FileManager.default.fileExists(atPath: previousSetupURL.path,
                                                isDirectory: &isDir)
    if result, isDir.boolValue {
        // remove our empty dir if something should happens happened
        try? FileManager.default.removeItem(at: documentsDirectory)
        // try to move it back to our place
        try? FileManager.default.moveItem(at: previousSetupURL, to: documentsDirectory)
        // if we can move it, there should not be any permission issue
        NSLog("[App Container] moving document dir from \(previousSetupURL.path) to \(documentsDirectory.path)")
    } else {
        NSLog("[App Container] can not access previous container or permission denied on \(previousSetupURL.path)")
    }
}

UserDefaults
    .standard
    .setValue(documentsDirectory.path, forKey: "wiki.qaq.chromatic.setupLocation")

// MARK: - LOGGING ENGINE

do {
    try Dog.shared.initialization(writableDir: documentsDirectory)
} catch {
    let errorDescription = "[E] Setup persist logging engine failed with error \(error.localizedDescription)"
    #if DEBUG
        fatalError(errorDescription)
    #else
        NSLog(errorDescription)
    #endif
}

private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
Dog.shared.join("App",
                """

                \(Bundle.main.bundleIdentifier ?? "unknown bundle") - \(appVersion ?? "unknown bundle version")
                Location:
                    [*] \(Bundle.main.bundleURL.path)
                    [*] \(documentsDirectory.path)
                """,
                level: .info)

// MARK: - Check Privilege

let result = AuxiliaryExecute.rootspawn(command: "whoami", args: [], timeout: 1) { _ in }
Dog.shared.join("Privilege", "stdout: [\(result.1.trimmingCharacters(in: .whitespacesAndNewlines))]", level: .info)
Dog.shared.join("Privilege", "stderr: [\(result.2.trimmingCharacters(in: .whitespacesAndNewlines))]", level: .info)

// MARK: - Boot Application

DeviceInfo.current.setupUserAgents()

private let application = UIApplication.shared
private let delegate = AppDelegate()
application.delegate = delegate

_ = UIApplicationMain(CommandLine.argc,
                      CommandLine.unsafeArgv,
                      nil,
                      NSStringFromClass(AppDelegate.self))

/*

 the initialization was moved to SetupController

 */
