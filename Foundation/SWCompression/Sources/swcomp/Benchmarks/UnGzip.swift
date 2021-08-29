// Copyright (c) 2021 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation
import SWCompression
import SwiftCLI

class UnGzip: BenchmarkCommand {
    let name = "un-gzip"
    let shortDescription = "GZip unarchiving"

    let files = CollectedParameter()

    let benchmarkName = "GZip Unarchive"
    let benchmarkFunction: (Data) throws -> Any = GzipArchive.unarchive
}
