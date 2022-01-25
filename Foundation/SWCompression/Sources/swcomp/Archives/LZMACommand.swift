// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation
import SWCompression
import SwiftCLI

final class LZMACommand: Command {
    let name = "lzma"
    let shortDescription = "Extracts a LZMA archive"

    @Param var input: String
    @Param var output: String?

    func execute() throws {
        let fileData = try Data(contentsOf: URL(fileURLWithPath: input),
                                options: .mappedIfSafe)
        let outputPath = output ?? FileManager.default.currentDirectoryPath
        let decompressedData = try LZMA.decompress(data: fileData)
        try decompressedData.write(to: URL(fileURLWithPath: outputPath))
    }
}
