// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation

struct SaveFile: Codable {
    struct Run: Codable {
        var metadataUUID: UUID
        var results: [BenchmarkResult]
    }

    var metadatas: [UUID: BenchmarkMetadata]

    var runs: [Run]

    static func load(from path: String) throws -> SaveFile {
        let decoder = JSONDecoder()
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try decoder.decode(SaveFile.self, from: data)
    }
}
