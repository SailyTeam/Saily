// Copyright (c) 2021 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation
import SWCompression
import SwiftCLI

class XZCommand: Command {
    let name = "xz"
    let shortDescription = "Extracts a XZ archive"

    @Param var input: String
    @Param var output: String?

    func execute() throws {
        let inputURL = URL(fileURLWithPath: input)

        let outputURL: URL
        if let outputPath = output {
            outputURL = URL(fileURLWithPath: outputPath)
        } else if inputURL.pathExtension == "xz" {
            outputURL = inputURL.deletingPathExtension()
        } else {
            print("""
            ERROR: Unable to get output path. \
            No output parameter was specified. \
            Extension was: \(inputURL.pathExtension)
            """)
            exit(1)
        }

        let fileData = try Data(contentsOf: inputURL, options: .mappedIfSafe)
        let decompressedData = try XZArchive.unarchive(archive: fileData)
        try decompressedData.write(to: outputURL)
    }
}
