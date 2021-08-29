// Copyright (c) 2021 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation
import SWCompression
import SwiftCLI

class CompDeflate: BenchmarkCommand {
    let name = "comp-deflate"
    let shortDescription = "Deflate compression"

    let files = CollectedParameter()

    let benchmarkName = "Deflate Compression"
    let benchmarkFunction: (Data) throws -> Any = Deflate.compress
}
