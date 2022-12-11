// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation
import SWCompression
import SwiftCLI

final class BenchmarkGroup: CommandGroup {
    let name = "benchmark"
    let shortDescription = "Benchmark-related commands"

    let children: [Routable] = [
        RunBenchmarkCommand(),
        ShowBenchmarkCommand(),
    ]
}
