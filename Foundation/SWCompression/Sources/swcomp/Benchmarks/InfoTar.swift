// Copyright (c) 2021 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation
import SWCompression
import SwiftCLI

class InfoTar: BenchmarkCommand {
    let name = "info-tar"
    let shortDescription = "TAR info function"

    let files = CollectedParameter()

    let benchmarkName = "TAR info function"
    let benchmarkFunction: (Data) throws -> Any = TarContainer.info
}
