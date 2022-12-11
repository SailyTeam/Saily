// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation
import SWCompression
import SwiftCLI

final class GZipCommand: Command {
    let name = "gz"
    let shortDescription = "Creates or extracts a GZip archive"

    @Flag("-c", "--compress", description: "Compress an input file into a GZip archive")
    var compress: Bool

    @Flag("-d", "--decompress", description: "Decompress a GZip archive")
    var decompress: Bool

    @Flag("-i", "--info", description: "Print information from a GZip header")
    var info: Bool

    @Flag("-n", "--use-gzip-name", description: "Use the name saved inside a GZip archive as an output path, if possible")
    var useGZipName: Bool

    var optionGroups: [OptionGroup] {
        [.exactlyOne($compress, $decompress, $info)]
    }

    @Param var input: String
    @Param var output: String?

    func execute() throws {
        if decompress {
            let inputURL = URL(fileURLWithPath: input)

            var outputURL: URL?
            if let outputPath = output {
                outputURL = URL(fileURLWithPath: outputPath)
            } else if inputURL.pathExtension == "gz" {
                outputURL = inputURL.deletingPathExtension()
            }

            let fileData = try Data(contentsOf: inputURL, options: .mappedIfSafe)

            if useGZipName {
                let header = try GzipHeader(archive: fileData)
                if let fileName = header.fileName {
                    outputURL = inputURL.deletingLastPathComponent()
                        .appendingPathComponent(fileName, isDirectory: false)
                }
            }

            guard outputURL != nil
            else { swcompExit(.noOutputPath) }

            let decompressedData = try GzipArchive.unarchive(archive: fileData)
            try decompressedData.write(to: outputURL!)
        } else if compress {
            let inputURL = URL(fileURLWithPath: input)
            let fileName = inputURL.lastPathComponent

            let outputURL: URL
            if let outputPath = output {
                outputURL = URL(fileURLWithPath: outputPath)
            } else {
                outputURL = inputURL.appendingPathExtension("gz")
            }

            let fileData = try Data(contentsOf: inputURL, options: .mappedIfSafe)
            let compressedData = try GzipArchive.archive(data: fileData,
                                                         fileName: fileName.isEmpty ? nil : fileName,
                                                         writeHeaderCRC: true)
            try compressedData.write(to: outputURL)
        } else if info {
            let inputURL = URL(fileURLWithPath: input)
            let fileData = try Data(contentsOf: inputURL, options: .mappedIfSafe)

            let header = try GzipHeader(archive: fileData)
            print(header)
        }
    }
}
