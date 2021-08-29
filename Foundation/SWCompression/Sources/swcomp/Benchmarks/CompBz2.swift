// Copyright (c) 2021 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation
import SWCompression
import SwiftCLI

class CompBz2: BenchmarkCommand {
    let name = "comp-bz2"
    let shortDescription = "BZip2 compression"

    let files = CollectedParameter()

    let benchmarkName = "BZip2 Compression"
    let benchmarkFunction: (Data) throws -> Any = BZip2.compress
}
