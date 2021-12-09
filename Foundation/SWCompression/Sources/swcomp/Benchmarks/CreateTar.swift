// Copyright (c) 2021 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation
import SWCompression
import SwiftCLI

class CreateTar: BenchmarkCommand {
    let name = "create-tar"
    let shortDescription = "Tar container creation"

    @CollectedParam(minCount: 1) var inputs: [String]

    let benchmarkName = "TAR Create"
    let benchmarkFunction: ([TarEntry]) throws -> Any = TarContainer.create

    func loadInput(_ input: String) throws -> ([TarEntry], Double) {
        return try (TarEntry.createEntries(input, false), Double(URL(fileURLWithPath: input).directorySize()))
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
