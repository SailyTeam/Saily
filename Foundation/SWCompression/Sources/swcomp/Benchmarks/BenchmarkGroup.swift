// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation
import SWCompression
import SwiftCLI

final class BenchmarkGroup: CommandGroup {
    let name = "benchmark"
    let shortDescription = "Run the specified benchmark using external files"

    let children: [Routable] = [
        UnGzip(), UnXz(), UnBz2(), UnLZ4(),
        InfoTar(), InfoZip(), Info7z(),
        CompDeflate(), CompBz2(), CompLZ4(), CompLZ4BD(),
        CreateTar(), ReaderTar(), WriterTar(),
    ]
}

final class CompBz2: BenchmarkCommand {
    let name = "comp-bz2"
    let shortDescription = "BZip2 compression"

    @CollectedParam(minCount: 1) var inputs: [String]

    let benchmarkName = "BZip2 Compression"

    var benchmarkInput: Data?
    var benchmarkInputSize: Double?

    let calculateCompressionRatio = true

    func benchmark() -> Data {
        BZip2.compress(data: benchmarkInput!)
    }
}

final class CompDeflate: BenchmarkCommand {
    let name = "comp-deflate"
    let shortDescription = "Deflate compression"

    @CollectedParam(minCount: 1) var inputs: [String]

    let benchmarkName = "Deflate Compression"

    var benchmarkInput: Data?
    var benchmarkInputSize: Double?

    let calculateCompressionRatio = true

    func benchmark() -> Data {
        Deflate.compress(data: benchmarkInput!)
    }
}

final class CompLZ4: BenchmarkCommand {
    let name = "comp-lz4"
    let shortDescription = "LZ4 compression (independent blocks)"

    @CollectedParam(minCount: 1) var inputs: [String]

    let benchmarkName = "LZ4 Compression with independent blocks"

    var benchmarkInput: Data?
    var benchmarkInputSize: Double?

    let calculateCompressionRatio = true

    func benchmark() -> Data {
        LZ4.compress(data: benchmarkInput!)
    }
}

final class CompLZ4BD: BenchmarkCommand {
    let name = "comp-lz4-bd"
    let shortDescription = "LZ4 compression (dependent blocks)"

    @CollectedParam(minCount: 1) var inputs: [String]

    let benchmarkName = "LZ4 Compression with dependent blocks"

    var benchmarkInput: Data?
    var benchmarkInputSize: Double?

    let calculateCompressionRatio = true

    func benchmark() -> Data {
        LZ4.compress(
            data: benchmarkInput!, independentBlocks: false, blockChecksums: false,
            contentChecksum: true, contentSize: false, blockSize: 4 * 1024 * 1024, dictionary: nil,
            dictionaryID: nil
        )
    }
}

final class Info7z: BenchmarkCommand {
    let name = "info-7z"
    let shortDescription = "7-Zip info function"

    @CollectedParam(minCount: 1) var inputs: [String]

    let benchmarkName = "7-Zip info function"

    var benchmarkInput: Data?
    var benchmarkInputSize: Double?

    func benchmark() -> [SevenZipEntryInfo] {
        do {
            return try SevenZipContainer.info(container: benchmarkInput!)
        } catch {
            print("\nERROR: Unable to perform benchmark: error=\(error).")
            exit(1)
        }
    }
}

final class InfoTar: BenchmarkCommand {
    let name = "info-tar"
    let shortDescription = "TAR info function"

    @CollectedParam(minCount: 1) var inputs: [String]

    let benchmarkName = "TAR info function"

    var benchmarkInput: Data?
    var benchmarkInputSize: Double?

    func benchmark() -> [TarEntryInfo] {
        do {
            return try TarContainer.info(container: benchmarkInput!)
        } catch {
            print("\nERROR: Unable to perform benchmark: error=\(error).")
            exit(1)
        }
    }
}

final class InfoZip: BenchmarkCommand {
    let name = "info-zip"
    let shortDescription = "ZIP info function"

    @CollectedParam(minCount: 1) var inputs: [String]

    let benchmarkName = "ZIP info function"

    var benchmarkInput: Data?
    var benchmarkInputSize: Double?

    func benchmark() -> [ZipEntryInfo] {
        do {
            return try ZipContainer.info(container: benchmarkInput!)
        } catch {
            print("\nERROR: Unable to perform benchmark: error=\(error).")
            exit(1)
        }
    }
}

final class UnBz2: BenchmarkCommand {
    let name = "un-bz2"
    let shortDescription = "BZip2 unarchiving"

    @CollectedParam(minCount: 1) var inputs: [String]

    let benchmarkName = "BZip2 Unarchive"

    var benchmarkInput: Data?
    var benchmarkInputSize: Double?

    func benchmark() -> Data {
        do {
            return try BZip2.decompress(data: benchmarkInput!)
        } catch {
            print("\nERROR: Unable to perform benchmark: error=\(error).")
            exit(1)
        }
    }
}

final class UnGzip: BenchmarkCommand {
    let name = "un-gzip"
    let shortDescription = "GZip unarchiving"

    @CollectedParam(minCount: 1) var inputs: [String]

    let benchmarkName = "GZip Unarchive"

    var benchmarkInput: Data?
    var benchmarkInputSize: Double?

    func benchmark() -> Data {
        do {
            return try GzipArchive.unarchive(archive: benchmarkInput!)
        } catch {
            print("\nERROR: Unable to perform benchmark: error=\(error).")
            exit(1)
        }
    }
}

final class UnLZ4: BenchmarkCommand {
    let name = "un-lz4"
    let shortDescription = "LZ4 unarchiving"

    @CollectedParam(minCount: 1) var inputs: [String]

    let benchmarkName = "LZ4 Unarchive"

    var benchmarkInput: Data?
    var benchmarkInputSize: Double?

    func benchmark() -> Data {
        do {
            return try LZ4.decompress(data: benchmarkInput!)
        } catch {
            print("\nERROR: Unable to perform benchmark: error=\(error).")
            exit(1)
        }
    }
}

final class UnXz: BenchmarkCommand {
    let name = "un-xz"
    let shortDescription = "XZ unarchiving"

    @CollectedParam(minCount: 1) var inputs: [String]

    let benchmarkName = "XZ Unarchive"

    var benchmarkInput: Data?
    var benchmarkInputSize: Double?

    func benchmark() -> Data {
        do {
            return try XZArchive.unarchive(archive: benchmarkInput!)
        } catch {
            print("\nERROR: Unable to perform benchmark: error=\(error).")
            exit(1)
        }
    }
}

final class CreateTar: BenchmarkCommand {
    let name = "create-tar"
    let shortDescription = "Tar container creation using TarContainer"

    @CollectedParam(minCount: 1) var inputs: [String]

    let benchmarkName = "TAR Create"

    var benchmarkInput: [TarEntry]?
    var benchmarkInputSize: Double?

    func benchmarkSetUp(_ input: String) {
        do {
            benchmarkInput = try TarEntry.createEntries(input, false)
            benchmarkInputSize = try Double(URL(fileURLWithPath: input).directorySize())
        } catch {
            print("\nERROR: Unable to set up benchmark: input=\(input), error=\(error).")
            exit(1)
        }
    }

    func benchmark() -> Data {
        TarContainer.create(from: benchmarkInput!)
    }
}

final class ReaderTar: BenchmarkCommand {
    let name = "reader-tar"
    let shortDescription = "Tar container reading using TarReader"

    @CollectedParam(minCount: 1) var inputs: [String]

    let benchmarkName = "TAR Reader"

    var benchmarkInput: URL?
    var benchmarkInputSize: Double?

    private var handle: FileHandle?

    func benchmarkSetUp(_ input: String) {
        benchmarkInput = URL(fileURLWithPath: input)
        do {
            let resourceValues = try benchmarkInput!.resourceValues(forKeys: [.fileSizeKey])
            if let fileSize = resourceValues.fileSize {
                benchmarkInputSize = Double(fileSize)
            } else {
                print("\nERROR: ReaderTAR.benchmarkSetUp(): file size is not available for input=\(input).")
                exit(1)
            }
        } catch {
            print("\nERROR: Unable to set up benchmark: input=\(input), error=\(error).")
            exit(1)
        }
    }

    func iterationSetUp() {
        do {
            handle = try FileHandle(forReadingFrom: benchmarkInput!)
        } catch {
            print("\nERROR: Unable to set up iteration: \(error).")
            exit(1)
        }
    }

    func benchmark() -> [TarEntryInfo] {
        do {
            var reader = TarReader(fileHandle: handle!)
            var isFinished = false
            var infos = [TarEntryInfo]()
            while !isFinished {
                isFinished = try reader.process { (entry: TarEntry?) -> Bool in
                    guard entry != nil
                    else { return true }
                    infos.append(entry!.info)
                    return false
                }
            }
            try handle!.closeCompat()
            return infos
        } catch {
            print("\nERROR: Unable to perform benchmark: error=\(error).")
            exit(1)
        }
    }

    func iterationTearDown() {
        do {
            try handle!.closeCompat()
            handle = nil
        } catch {
            print("\nERROR: Unable to tear down iteration: \(error).")
            exit(1)
        }
    }
}

final class WriterTar: BenchmarkCommand {
    let name = "writer-tar"
    let shortDescription = "Tar container creation using TarWriter"

    @CollectedParam(minCount: 1) var inputs: [String]

    let benchmarkName = "TAR Writer"

    var benchmarkInput: [TarEntry]?
    var benchmarkInputSize: Double?

    private var handle: FileHandle?
    private var outputURL: URL?

    func benchmarkSetUp(_ input: String) {
        do {
            benchmarkInput = try TarEntry.createEntries(input, false)
            benchmarkInputSize = try Double(URL(fileURLWithPath: input).directorySize())
        } catch {
            print("\nERROR: Unable to set up benchmark: input=\(input), error=\(error).")
            exit(1)
        }
    }

    func iterationSetUp() {
        do {
            outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString, isDirectory: false)
            try "".write(to: outputURL!, atomically: true, encoding: .utf8)
            handle = try FileHandle(forWritingTo: outputURL!)
        } catch {
            print("\nERROR: Unable to set up iteration: \(error).")
            exit(1)
        }
    }

    func benchmark() {
        do {
            var writer = TarWriter(fileHandle: handle!)
            for entry in benchmarkInput! {
                try writer.append(entry)
            }
            try writer.finalize()
        } catch {
            print("\nERROR: Unable to perform benchmark: error=\(error).")
            exit(1)
        }
    }

    func iterationTearDown() {
        do {
            try handle!.closeCompat()
            try FileManager.default.removeItem(at: outputURL!)
            handle = nil
            outputURL = nil
        } catch {
            print("\nERROR: Unable to tear down iteration: \(error).")
            exit(1)
        }
    }
}

private extension URL {
    func directorySize() throws -> Int {
        let urls = FileManager.default.enumerator(at: self, includingPropertiesForKeys: nil)?.allObjects as! [URL]
        return try urls.lazy.reduce(0) {
            (try $1.resourceValues(forKeys: [.totalFileAllocatedSizeKey]).totalFileAllocatedSize ?? 0) + $0
        }
    }
}
