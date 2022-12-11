// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation
import SWCompression
import SwiftCLI

final class LZ4Command: Command {
    let name = "lz4"
    let shortDescription = "Creates or extracts a LZ4 archive"

    @Flag("-c", "--compress", description: "Compress an input file into a LZ4 archive")
    var compress: Bool

    @Flag("-d", "--decompress", description: "Decompress a LZ4 archive")
    var decompress: Bool

    @Flag("--dependent-blocks", description: "(Compression only) Use dependent blocks")
    var dependentBlocks: Bool

    @Flag("--block-checksums", description: "(Compression only) Save checksums for compressed blocks")
    var blockChecksums: Bool

    @Flag("--no-content-checksum", description: "(Compression only) Don't save the checksum of the uncompressed data")
    var noContentChecksum: Bool

    @Flag("--content-size", description: "(Compression only) Save the size of the uncompressed data")
    var contentSize: Bool

    @Key("--block-size", description: "(Compression only) Use specified block size (in bytes; default and max: 4194304)")
    var blockSize: Int?

    @Key("-D", "--dict", description: "Path to a dictionary to use in decompression or compression")
    var dictionary: String?

    @Key("--dictID", description: "Optional dictionary ID (max: 4294967295)")
    var dictionaryID: Int?

    var optionGroups: [OptionGroup] {
        [.exactlyOne($compress, $decompress)]
    }

    @Param var input: String
    @Param var output: String?

    func execute() throws {
        let dictID: UInt32?
        if let dictionaryID = dictionaryID {
            guard dictionaryID <= UInt32.max
            else { swcompExit(.lz4BigDictId) }
            dictID = UInt32(truncatingIfNeeded: dictionaryID)
        } else {
            dictID = nil
        }

        let dictData: Data?
        if let dictionary = dictionary {
            dictData = try Data(contentsOf: URL(fileURLWithPath: dictionary), options: .mappedIfSafe)
        } else {
            dictData = nil
        }

        guard dictID == nil || dictData != nil
        else { swcompExit(.lz4NoDict) }

        if decompress {
            let inputURL = URL(fileURLWithPath: input)

            let outputURL: URL
            if let outputPath = output {
                outputURL = URL(fileURLWithPath: outputPath)
            } else if inputURL.pathExtension == "lz4" {
                outputURL = inputURL.deletingPathExtension()
            } else {
                swcompExit(.noOutputPath)
            }

            let fileData = try Data(contentsOf: inputURL, options: .mappedIfSafe)
            let decompressedData = try LZ4.decompress(data: fileData, dictionary: dictData, dictionaryID: dictID)
            try decompressedData.write(to: outputURL)
        } else if compress {
            let inputURL = URL(fileURLWithPath: input)

            let outputURL: URL
            if let outputPath = output {
                outputURL = URL(fileURLWithPath: outputPath)
            } else {
                outputURL = inputURL.appendingPathExtension("lz4")
            }

            let bs: Int
            if let blockSize = blockSize {
                guard blockSize < 4_194_304
                else { swcompExit(.lz4BigBlockSize) }
                bs = blockSize
            } else {
                bs = 4 * 1024 * 1024
            }

            let fileData = try Data(contentsOf: inputURL, options: .mappedIfSafe)
            let compressedData = LZ4.compress(data: fileData, independentBlocks: !dependentBlocks,
                                              blockChecksums: blockChecksums, contentChecksum: !noContentChecksum,
                                              contentSize: contentSize, blockSize: bs, dictionary: dictData, dictionaryID: dictID)
            try compressedData.write(to: outputURL)
        }
    }
}
