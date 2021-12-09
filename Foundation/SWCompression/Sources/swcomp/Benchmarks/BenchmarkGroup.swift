// Copyright (c) 2021 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation
import SWCompression
import SwiftCLI

class BenchmarkGroup: CommandGroup {
    let name = "benchmark"
    let shortDescription = "Run the specified benchmark using external files"

    let children: [Routable] = [
        UnGzip(), UnXz(), UnBz2(), UnLZ4(),
        InfoTar(), InfoZip(), Info7z(),
        CompDeflate(), CompBz2(), CompLZ4(), CompLZ4BD(),
        CreateTar(),
    ]
}

class CompBz2: BenchmarkCommand {
    let name = "comp-bz2"
    let shortDescription = "BZip2 compression"

    @CollectedParam(minCount: 1) var inputs: [String]

    let benchmarkName = "BZip2 Compression"
    let benchmarkFunction: (Data) throws -> Any = BZip2.compress

    let calculateCompressionRatio = true
}

class CompDeflate: BenchmarkCommand {
    let name = "comp-deflate"
    let shortDescription = "Deflate compression"

    @CollectedParam(minCount: 1) var inputs: [String]

    let benchmarkName = "Deflate Compression"
    let benchmarkFunction: (Data) throws -> Any = Deflate.compress

    let calculateCompressionRatio = true
}

class CompLZ4: BenchmarkCommand {
    let name = "comp-lz4"
    let shortDescription = "LZ4 compression (independent blocks)"

    @CollectedParam(minCount: 1) var inputs: [String]

    let benchmarkName = "LZ4 Compression with independent blocks"
    let benchmarkFunction: (Data) throws -> Any = LZ4.compress

    let calculateCompressionRatio = true
}

class CompLZ4BD: BenchmarkCommand {
    let name = "comp-lz4-bd"
    let shortDescription = "LZ4 compression (dependent blocks)"

    @CollectedParam(minCount: 1) var inputs: [String]

    let benchmarkName = "LZ4 Compression with dependent blocks"
    let benchmarkFunction: (Data) throws -> Any = {
        LZ4.compress(data: $0, independentBlocks: false, blockChecksums: false, contentChecksum: true,
                     contentSize: false, blockSize: 4 * 1024 * 1024, dictionary: nil, dictionaryID: nil)
    }

    let calculateCompressionRatio = true
}

class Info7z: BenchmarkCommand {
    let name = "info-7z"
    let shortDescription = "7-Zip info function"

    @CollectedParam(minCount: 1) var inputs: [String]

    let benchmarkName = "7-Zip info function"
    let benchmarkFunction: (Data) throws -> Any = SevenZipContainer.info
}

class InfoTar: BenchmarkCommand {
    let name = "info-tar"
    let shortDescription = "TAR info function"

    @CollectedParam(minCount: 1) var inputs: [String]

    let benchmarkName = "TAR info function"
    let benchmarkFunction: (Data) throws -> Any = TarContainer.info
}

class InfoZip: BenchmarkCommand {
    let name = "info-zip"
    let shortDescription = "ZIP info function"

    @CollectedParam(minCount: 1) var inputs: [String]

    let benchmarkName = "ZIP info function"
    let benchmarkFunction: (Data) throws -> Any = ZipContainer.info
}

class UnBz2: BenchmarkCommand {
    let name = "un-bz2"
    let shortDescription = "BZip2 unarchiving"

    @CollectedParam(minCount: 1) var inputs: [String]

    let benchmarkName = "BZip2 Unarchive"
    let benchmarkFunction: (Data) throws -> Any = BZip2.decompress
}

class UnGzip: BenchmarkCommand {
    let name = "un-gzip"
    let shortDescription = "GZip unarchiving"

    @CollectedParam(minCount: 1) var inputs: [String]

    let benchmarkName = "GZip Unarchive"
    let benchmarkFunction: (Data) throws -> Any = GzipArchive.unarchive
}

class UnLZ4: BenchmarkCommand {
    let name = "un-lz4"
    let shortDescription = "LZ4 unarchiving"

    @CollectedParam(minCount: 1) var inputs: [String]

    let benchmarkName = "LZ4 Unarchive"
    let benchmarkFunction: (Data) throws -> Any = LZ4.decompress
}

class UnXz: BenchmarkCommand {
    let name = "un-xz"
    let shortDescription = "XZ unarchiving"

    @CollectedParam(minCount: 1) var inputs: [String]

    let benchmarkName = "XZ Unarchive"
    let benchmarkFunction: (Data) throws -> Any = XZArchive.unarchive
}
