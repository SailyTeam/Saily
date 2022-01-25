// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation
import SWCompression

extension GzipHeader: CustomStringConvertible {
    public var description: String {
        var output = """
        File name: \(fileName ?? "")
        File system type: \(osType)
        Compression method: \(compressionMethod)

        """
        if let mtime = modificationTime {
            output += "Modification time: \(mtime)\n"
        }
        if let comment = comment {
            output += "Comment: \(comment)\n"
        }
        output += "Is text file: \(isTextFile)"
        return output
    }
}
