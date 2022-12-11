// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation

struct BenchmarkMetadata: Codable, Equatable {
    var timestamp: TimeInterval?
    var osInfo: String
    var swiftVersion: String
    var swcVersion: String
    var description: String?

    private static func run(command: URL, arguments: [String] = []) throws -> String {
        let task = Process()
        let pipe = Pipe()

        task.standardOutput = pipe
        task.standardError = pipe
        task.executableURL = command
        task.arguments = arguments
        task.standardInput = nil

        try task.run()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!
        return output
    }

    private static func getExecURL(for command: String) throws -> URL {
        let args = ["-c", "which \(command)"]
        #if os(Windows)
            swcompExit(.benchmarkCannotGetSubcommandPathWindows)
        #else
            let output = try BenchmarkMetadata.run(command: URL(fileURLWithPath: "/bin/sh"), arguments: args)
        #endif
        return URL(fileURLWithPath: String(output.dropLast()))
    }

    private static func getOsInfo() throws -> String {
        #if os(Linux)
            return try BenchmarkMetadata.run(command: BenchmarkMetadata.getExecURL(for: "uname"), arguments: ["-a"])
        #else
            #if os(Windows)
                return "Unknown Windows OS"
            #else
                return try BenchmarkMetadata.run(command: BenchmarkMetadata.getExecURL(for: "sw_vers"))
            #endif
        #endif
    }

    init(_ description: String?, _ preserveTimestamp: Bool) throws {
        timestamp = preserveTimestamp ? Date.timeIntervalSinceReferenceDate : nil
        osInfo = try BenchmarkMetadata.getOsInfo()
        #if os(Windows)
            swiftVersion = "Unknown Swift version on Windows"
        #else
            swiftVersion = try BenchmarkMetadata.run(command: BenchmarkMetadata.getExecURL(for: "swift"),
                                                     arguments: ["-version"])
        #endif
        swcVersion = _SWC_VERSION
        self.description = description
    }

    func print() {
        Swift.print("OS Info: \(osInfo)", terminator: "")
        Swift.print("Swift version: \(swiftVersion)", terminator: "")
        Swift.print("SWC version: \(swcVersion)")
        if let timestamp = timestamp {
            Swift.print("Timestamp: " +
                DateFormatter.localizedString(from: Date(timeIntervalSinceReferenceDate: timestamp),
                                              dateStyle: .short, timeStyle: .short))
        }
        if let description = description {
            Swift.print("Description: \(description)")
        }
        Swift.print()
    }
}
