// Copyright (c) 2021 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation
import SWCompression
import SwiftCLI

class InfoZip: BenchmarkCommand {
    let name = "info-zip"
    let shortDescription = "ZIP info function"

    let files = CollectedParameter()

    let benchmarkName = "ZIP info function"
    let benchmarkFunction: (Data) throws -> Any = ZipContainer.info
}
