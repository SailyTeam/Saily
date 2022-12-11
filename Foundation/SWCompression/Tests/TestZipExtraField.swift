// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import BitByteData
import Foundation
import SWCompression

struct TestZipExtraField: ZipExtraField {
    static let id: UInt16 = 0x0646

    let size: Int
    let location: ZipExtraFieldLocation

    var helloString: String?

    init(_ byteReader: LittleEndianByteReader, _ size: Int, location: ZipExtraFieldLocation) {
        self.size = size
        self.location = location
        helloString = String(data: Data(byteReader.bytes(count: size)), encoding: .utf8)
    }
}
