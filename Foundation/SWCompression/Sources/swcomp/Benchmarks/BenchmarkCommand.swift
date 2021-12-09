// Copyright (c) 2021 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation
import SWCompression
import SwiftCLI

#if os(Linux)
    import CoreFoundation
#endif

protocol BenchmarkCommand: Command {
    associatedtype InputType

    var inputs: [String] { get }

    var benchmarkName: String { get }

    func loadInput(_ input: String) throws -> (InputType, Double)

    var benchmarkFunction: (InputType) throws -> Any { get }

    // Compression ratio is calculated only if the InputType and the type of output is Data, and the size of the input
    // is greater than zero.
    var calculateCompressionRatio: Bool { get }
}

extension BenchmarkCommand where InputType == Data {
    func loadInput(_ input: String) throws -> (Data, Double) {
        let inputURL = URL(fileURLWithPath: input)
        let inputData = try Data(contentsOf: inputURL, options: .mappedIfSafe)
        let attr = try FileManager.default.attributesOfItem(atPath: input)
        let inputSize = Double(attr[.size] as! UInt64)
        return (inputData, inputSize)
    }
}

extension BenchmarkCommand {
    var calculateCompressionRatio: Bool {
        false
    }

    func execute() throws {
        let title = "\(benchmarkName) Benchmark\n"
        print(String(repeating: "=", count: title.count))
        print(title)

        for input in inputs {
            print("Input: \(input)")

            let (loadedInput, inputSize) = try loadInput(input)

            var totalSpeed: Double = 0

            var maxSpeed = Double(Int.min)
            var minSpeed = Double(Int.max)

            print("Iterations: ", terminator: "")
            #if !os(Linux)
                fflush(__stdoutp)
            #endif
            // Zeroth (excluded) iteration.
            let startTime = CFAbsoluteTimeGetCurrent()
            let warmupOutput = try benchmarkFunction(loadedInput)
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            let speed = inputSize / timeElapsed
            print("(\(SpeedFormat(speed).format())), ", terminator: "")
            #if !os(Linux)
                fflush(__stdoutp)
            #endif

            for _ in 1 ... 10 {
                let startTime = CFAbsoluteTimeGetCurrent()
                _ = try benchmarkFunction(loadedInput)
                let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                let speed = inputSize / timeElapsed
                print(SpeedFormat(speed).format() + ", ", terminator: "")
                #if !os(Linux)
                    fflush(__stdoutp)
                #endif
                totalSpeed += speed
                if speed > maxSpeed {
                    maxSpeed = speed
                }
                if speed < minSpeed {
                    minSpeed = speed
                }
            }
            let avgSpeed = totalSpeed / 10
            let avgSpeedFormat = SpeedFormat(avgSpeed)
            let speedUncertainty = (maxSpeed - minSpeed) / 2
            print("\nAverage: \(avgSpeedFormat.format().prefix { $0 != " " }) \u{B1} \(avgSpeedFormat.format(speedUncertainty))")

            if let inputData = loadedInput as? Data, let outputData = warmupOutput as? Data, calculateCompressionRatio,
               inputData.count > 0
            {
                let compressionRatio = Double(inputData.count) / Double(outputData.count)
                print(String(format: "Compression ratio: %.3f", compressionRatio))
            }
            print()
        }
    }
}
