// Copyright (c) 2021 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation
import SWCompression
import SwiftCLI

class UnXz: BenchmarkCommand {
    let name = "un-xz"
    let shortDescription = "XZ unarchiving"

    let files = CollectedParameter()

    let benchmarkName = "XZ Unarchive"
    let benchmarkFunction: (Data) throws -> Any = XZArchive.unarchive
}
