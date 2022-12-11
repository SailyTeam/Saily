// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

protocol Benchmark {
    var defaultIterationCount: Int { get }

    init(_ input: String)

    func warmupIteration()

    func measure() -> Double

    func format(_ value: Double) -> String
}

extension Benchmark {
    var defaultIterationCount: Int {
        10
    }

    func warmupIteration() {
        _ = measure()
    }

    func format(_ value: Double) -> String {
        SpeedFormatter.default.string(from: value)
    }
}
