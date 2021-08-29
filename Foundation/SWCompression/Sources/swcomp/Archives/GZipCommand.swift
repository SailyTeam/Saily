// Copyright (c) 2021 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation
import SWCompression
import SwiftCLI

class GZipCommand: Command {
    let name = "gz"
    let shortDescription = "Creates or extracts a GZip archive"

    let compress = Flag("-c", "--compress", description: "Compress an input file into a GZip archive")
    let decompress = Flag("-d", "--decompress", description: "Decompress a GZip archive")
    let info = Flag("-i", "--info", description: "Print information from a GZip header")

    let useGZipName = Flag("-n", "--use-gzip-name",
                           description: "Use the name saved inside a GZip archive as an output path, if possible")

    var optionGroups: [OptionGroup] {
        let actions = OptionGroup(options: [compress, decompress, info], restriction: .exactlyOne)
        return [actions]
    }

    let input = Parameter()
    let output = OptionalParameter()

    func execute() throws {
        if decompress.value {
            let inputURL = URL(fileURLWithPath: input.value)

            var outputURL: URL?
            if let outputPath = output.value {
                outputURL = URL(fileURLWithPath: outputPath)
            } else if inputURL.pathExtension == "gz" {
                outputURL = inputURL.deletingPathExtension()
            }

            let fileData = try Data(contentsOf: inputURL, options: .mappedIfSafe)

            if useGZipName.value {
                let header = try GzipHeader(archive: fileData)
                if let fileName = header.fileName {
                    outputURL = inputURL.deletingLastPathComponent()
                        .appendingPathComponent(fileName, isDirectory: false)
                }
            }

            guard outputURL != nil else {
                print("""
                ERROR: Unable to get output path. \
                No output parameter was specified. \
                Extension was: \(inputURL.pathExtension)
                """)
                exit(1)
            }

            let decompressedData = try GzipArchive.unarchive(archive: fileData)
            try decompressedData.write(to: outputURL!)
        } else if compress.value {
            let inputURL = URL(fileURLWithPath: input.value)
            let fileName = inputURL.lastPathComponent

            let outputURL: URL
            if let outputPath = output.value {
                outputURL = URL(fileURLWithPath: outputPath)
            } else {
                outputURL = inputURL.appendingPathExtension("gz")
            }

            let fileData = try Data(contentsOf: inputURL, options: .mappedIfSafe)
            let compressedData = try GzipArchive.archive(data: fileData,
                                                         fileName: fileName.isEmpty ? nil : fileName,
                                                         writeHeaderCRC: true)
            try compressedData.write(to: outputURL)
        } else if info.value {
            let inputURL = URL(fileURLWithPath: input.value)
            let fileData = try Data(contentsOf: inputURL, options: .mappedIfSafe)

            let header = try GzipHeader(archive: fileData)
            print(header)
        }
    }
}
