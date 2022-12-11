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

final class RunBenchmarkCommand: Command {
    let name = "run"
    let shortDescription = "Run the specified benchmark"
    let longDescription = "Runs the specified benchmark using external files.\nAvailable benchmarks: \(Benchmarks.allBenchmarks)"

    @Key("-i", "--iteration-count", description: "Sets the amount of the benchmark iterations")
    var iterationCount: Int?

    @Key("-s", "--save", description: "Saves results into the specified file")
    var savePath: String?

    @Flag("-a", "--append", description: "Appends results to a file instead of overwriting it when saving results")
    var append: Bool

    @Key("-c", "--compare", description: "Compares results with other results saved in the specified file")
    var comparePath: String?

    @Key("-d", "--description", description: "Adds a custom description when saving results")
    var description: String?

    @Flag("-t", "--preserve-timestamp", description: "Adds a timestamp when saving a result")
    var preserveTimestamp: Bool

    @Flag("-W", "--no-warmup", description: "Disables warmup iteration")
    var noWarmup: Bool

    @Param var selectedBenchmark: Benchmarks
    @CollectedParam(minCount: 1) var inputs: [String]

    func execute() throws {
        guard iterationCount == nil || iterationCount! >= 1
        else { swcompExit(.benchmarkSmallIterCount) }

        var baseResults = [String: [(BenchmarkResult, UUID)]]()
        var baseMetadatas = [UUID: String]()
        if let comparePath = comparePath {
            let baseSaveFile = try SaveFile.load(from: comparePath)

            baseMetadatas = Dictionary(uniqueKeysWithValues: zip(baseSaveFile.metadatas.keys, (1 ... baseSaveFile.metadatas.count).map { "(\($0))" }))
            if baseMetadatas.count == 1 {
                baseMetadatas[baseMetadatas.first!.key] = ""
            }
            for (metadataUUID, index) in baseMetadatas.sorted(by: { $0.value < $1.value }) {
                print("BASE\(index) Metadata")
                print("----------------")
                baseSaveFile.metadatas[metadataUUID]!.print()
            }

            for baseRun in baseSaveFile.runs {
                baseResults.merge(Dictionary(grouping: baseRun.results.map { ($0, baseRun.metadataUUID) }, by: { $0.0.id }),
                                  uniquingKeysWith: { $0 + $1 })
            }
        }

        let title = "\(selectedBenchmark.titleName) Benchmark\n"
        print(String(repeating: "=", count: title.count))
        print(title)

        var newResults = [BenchmarkResult]()

        for input in inputs {
            print("Input: \(input)")
            let benchmark = selectedBenchmark.initialized(input)
            let iterationCount = iterationCount ?? benchmark.defaultIterationCount

            if !noWarmup {
                print("Warmup iteration...")
                // Zeroth (excluded) iteration.
                benchmark.warmupIteration()
            }

            var sum = 0.0
            var squareSum = 0.0

            print("Iterations: ", terminator: "")
            #if !os(Linux)
                fflush(__stdoutp)
            #endif
            for i in 1 ... iterationCount {
                if i > 1 {
                    print(", ", terminator: "")
                }
                let speed = benchmark.measure()
                print(benchmark.format(speed), terminator: "")
                #if !os(Linux)
                    fflush(__stdoutp)
                #endif
                sum += speed
                squareSum += speed * speed
            }

            let avg = sum / Double(iterationCount)
            let std = sqrt(squareSum / Double(iterationCount) - sum * sum / Double(iterationCount * iterationCount))
            let result = BenchmarkResult(name: selectedBenchmark.rawValue, input: input, iterCount: iterationCount,
                                         avg: avg, std: std)

            if let baseResults = baseResults[result.id] {
                print("\nNEW:  average = \(benchmark.format(avg)), standard deviation = \(benchmark.format(std))")
                for (other, baseUUID) in baseResults {
                    print("BASE\(baseMetadatas[baseUUID]!): average = \(benchmark.format(other.avg)), standard deviation = \(benchmark.format(other.std))")
                    result.printComparison(with: other)
                }
            } else {
                print("\nAverage = \(benchmark.format(avg)), standard deviation = \(benchmark.format(std))")
            }
            newResults.append(result)

            print()
        }

        if let savePath = savePath {
            let metadata = try BenchmarkMetadata(description, preserveTimestamp)
            var saveFile: SaveFile

            var isDir = ObjCBool(false)
            let saveFileExists = FileManager.default.fileExists(atPath: savePath, isDirectory: &isDir)

            if append, saveFileExists {
                if isDir.boolValue {
                    swcompExit(.benchmarkCannotAppendToDirectory)
                }
                saveFile = try SaveFile.load(from: savePath)
                var uuid: UUID
                if let foundUUID = saveFile.metadatas.first(where: { $0.value == metadata })?.key {
                    uuid = foundUUID
                } else {
                    repeat {
                        uuid = UUID()
                    } while saveFile.metadatas[uuid] != nil
                    saveFile.metadatas[uuid] = metadata
                }
                saveFile.runs.append(SaveFile.Run(metadataUUID: uuid, results: newResults))
            } else {
                let uuid = UUID()
                saveFile = SaveFile(metadatas: [uuid: metadata], runs: [SaveFile.Run(metadataUUID: uuid, results: newResults)])
            }

            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted

            let data = try encoder.encode(saveFile)
            try data.write(to: URL(fileURLWithPath: savePath))
        }
    }
}
