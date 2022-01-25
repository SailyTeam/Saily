// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

#if os(Linux)
    import CoreFoundation
#endif

import Foundation
import SWCompression
import SwiftCLI

protocol BenchmarkCommand: Command {
    associatedtype InputType
    associatedtype OutputType

    var inputs: [String] { get }

    var benchmarkName: String { get }

    var benchmarkInput: InputType? { get set }

    var benchmarkInputSize: Double? { get set }

    func benchmarkSetUp(_ input: String)

    func iterationSetUp()

    @discardableResult
    func benchmark() -> OutputType

    func iterationTearDown()

    func benchmarkTearDown()

    // Compression ratio is calculated only if the OutputType is Data, and the size of the output is greater than zero.
    var calculateCompressionRatio: Bool { get }
}

extension BenchmarkCommand {
    func benchmarkSetUp() {}

    func benchmarkTearDown() {
        benchmarkInput = nil
        benchmarkInputSize = nil
    }

    func iterationSetUp() {}

    func iterationTearDown() {}
}

extension BenchmarkCommand where InputType == Data {
    func benchmarkSetUp(_ input: String) {
        do {
            let inputURL = URL(fileURLWithPath: input)
            benchmarkInput = try Data(contentsOf: inputURL, options: .mappedIfSafe)
            benchmarkInputSize = Double(benchmarkInput!.count)
        } catch {
            print("\nERROR: Unable to set up benchmark: input=\(input), error=\(error).")
            exit(1)
        }
    }
}

extension BenchmarkCommand {
    var calculateCompressionRatio: Bool {
        false
    }

    func execute() {
        let title = "\(benchmarkName) Benchmark\n"
        print(String(repeating: "=", count: title.count))
        print(title)

        let formatter = ByteCountFormatter()
        formatter.zeroPadsFractionDigits = true

        for input in inputs {
            benchmarkSetUp(input)
            print("Input: \(input)")

            var totalSpeed = 0.0

            var maxSpeed = Double(Int.min)
            var minSpeed = Double(Int.max)

            print("Iterations: ", terminator: "")
            #if !os(Linux)
                fflush(__stdoutp)
            #endif
            // Zeroth (excluded) iteration.
            iterationSetUp()
            let startTime = CFAbsoluteTimeGetCurrent()
            let warmupOutput = benchmark()
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            let speed = benchmarkInputSize! / timeElapsed
            print("(\(formatter.string(fromByteCount: Int64(speed))))/s", terminator: "")
            #if !os(Linux)
                fflush(__stdoutp)
            #endif
            iterationTearDown()

            for _ in 1 ... 10 {
                print("  ", terminator: "")
                iterationSetUp()
                let startTime = CFAbsoluteTimeGetCurrent()
                benchmark()
                let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                let speed = benchmarkInputSize! / timeElapsed
                print("\(formatter.string(fromByteCount: Int64(speed)))/s", terminator: "")
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
                iterationTearDown()
            }
            let avgSpeed = totalSpeed / 10
            let speedUncertainty = (maxSpeed - minSpeed) / 2
            print("\nAverage: \(formatter.string(fromByteCount: Int64(avgSpeed)))/s \u{B1} \(formatter.string(fromByteCount: Int64(speedUncertainty)))/s")

            if let outputData = warmupOutput as? Data, calculateCompressionRatio, outputData.count > 0 {
                let compressionRatio = Double(benchmarkInputSize!) / Double(outputData.count)
                print(String(format: "Compression ratio: %.3f", compressionRatio))
            }
            print()
            benchmarkTearDown()
        }
    }
}
