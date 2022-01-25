// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import BitByteData
import Foundation

class SevenZipStreamInfo {
    var packInfo: SevenZipPackInfo?
    var coderInfo: SevenZipCoderInfo
    var substreamInfo: SevenZipSubstreamInfo?

    init(_ bitReader: MsbBitReader) throws {
        var type = bitReader.byte()

        if type == 0x06 {
            packInfo = try SevenZipPackInfo(bitReader)
            type = bitReader.byte()
        }

        if type == 0x07 {
            coderInfo = try SevenZipCoderInfo(bitReader)
            type = bitReader.byte()
        } else {
            coderInfo = SevenZipCoderInfo()
        }

        if type == 0x08 {
            substreamInfo = try SevenZipSubstreamInfo(bitReader, coderInfo)
            type = bitReader.byte()
        }

        guard type == 0x00
        else { throw SevenZipError.internalStructureError }
    }
}
