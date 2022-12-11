// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation
import SWCompression
import SwiftCLI

// This extension allows to use BZip2.BlockSize as a Key option.
// The extension is empty because there is a default implementation for a ConvertibleFromString when the RawValue type
// of the enum (Int, in this case) is ConvertibleFromString itself.
extension BZip2.BlockSize: ConvertibleFromString {}

final class BZip2Command: Command {
    let name = "bz2"
    let shortDescription = "Creates or extracts a BZip2 archive"

    @Flag("-c", "--compress", description: "Compress an input file into a BZip2 archive")
    var compress: Bool

    @Flag("-d", "--decompress", description: "Decompress a BZip2 archive")
    var decompress: Bool

    @Key("-b", "--block-size", description: "Set the block size for compression to a multiple of 100k bytes; possible " +
        "values are from '1' (default) to '9'")
    var blockSize: BZip2.BlockSize?

    var optionGroups: [OptionGroup] {
        [.exactlyOne($compress, $decompress)]
    }

    @Param var input: String
    @Param var output: String?

    func execute() throws {
        if decompress {
            let inputURL = URL(fileURLWithPath: input)

            let outputURL: URL
            if let outputPath = output {
                outputURL = URL(fileURLWithPath: outputPath)
            } else if inputURL.pathExtension == "bz2" {
                outputURL = inputURL.deletingPathExtension()
            } else {
                swcompExit(.noOutputPath)
            }

            let fileData = try Data(contentsOf: inputURL, options: .mappedIfSafe)
            let decompressedData = try BZip2.decompress(data: fileData)
            try decompressedData.write(to: outputURL)
        } else if compress {
            let inputURL = URL(fileURLWithPath: input)

            let outputURL: URL
            if let outputPath = output {
                outputURL = URL(fileURLWithPath: outputPath)
            } else {
                outputURL = inputURL.appendingPathExtension("bz2")
            }

            let fileData = try Data(contentsOf: inputURL, options: .mappedIfSafe)

            let compressedData = BZip2.compress(data: fileData, blockSize: blockSize ?? .one)
            try compressedData.write(to: outputURL)
        }
    }
}
