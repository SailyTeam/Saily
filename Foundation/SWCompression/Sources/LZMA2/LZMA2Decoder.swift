// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import BitByteData
import Foundation

struct LZMA2Decoder {
    private let byteReader: LittleEndianByteReader
    private var decoder: LZMADecoder

    var out: [UInt8] {
        decoder.out
    }

    init(_ byteReader: LittleEndianByteReader, _ dictSizeByte: UInt8) throws {
        self.byteReader = byteReader
        decoder = LZMADecoder(byteReader)

        guard dictSizeByte & 0xC0 == 0
        else { throw LZMA2Error.wrongDictionarySize }
        let bits = (dictSizeByte & 0x3F).toInt()
        guard bits < 40
        else { throw LZMA2Error.wrongDictionarySize }

        let dictSize = bits == 40 ? UInt32.max :
            (UInt32(truncatingIfNeeded: 2 | (bits & 1)) << UInt32(truncatingIfNeeded: bits / 2 + 11))

        decoder.properties.dictionarySize = dictSize.toInt()
    }

    /// Main LZMA2 decoder function.
    mutating func decode() throws {
        mainLoop: while true {
            let controlByte = byteReader.byte()
            switch controlByte {
            case 0:
                break mainLoop
            case 1:
                decoder.resetDictionary()
                decodeUncompressed()
            case 2:
                decodeUncompressed()
            case 3 ... 0x7F:
                throw LZMA2Error.wrongControlByte
            case 0x80 ... 0xFF:
                try dispatch(controlByte)
            default:
                fatalError("Incorrect control byte.") // This statement is never executed.
            }
        }
    }

    /// Function which dispatches LZMA2 decoding process based on `controlByte`.
    private mutating func dispatch(_ controlByte: UInt8) throws {
        let uncompressedSizeBits = controlByte & 0x1F
        let reset = (controlByte & 0x60) >> 5
        let unpackSize = (uncompressedSizeBits.toInt() << 16) +
            byteReader.byte().toInt() << 8 + byteReader.byte().toInt() + 1
        let compressedSize = byteReader.byte().toInt() << 8 + byteReader.byte().toInt() + 1
        switch reset {
        case 0:
            break
        case 1:
            decoder.resetStateAndDecoders()
        case 2:
            try updateProperties()
        case 3:
            try updateProperties()
            decoder.resetDictionary()
        default:
            throw LZMA2Error.wrongReset
        }
        decoder.uncompressedSize = unpackSize
        let outStartIndex = decoder.out.count
        let inStartIndex = byteReader.offset
        try decoder.decode()
        guard unpackSize == decoder.out.count - outStartIndex,
              byteReader.offset - inStartIndex == compressedSize
        else { throw LZMA2Error.wrongSizes }
    }

    private mutating func decodeUncompressed() {
        let dataSize = byteReader.byte().toInt() << 8 + byteReader.byte().toInt() + 1
        for _ in 0 ..< dataSize {
            decoder.put(byteReader.byte())
        }
    }

    /**
     Sets `lc`, `pb` and `lp` properties of LZMA decoder with a single `byte` using standard LZMA properties encoding
     scheme and resets decoder's state and sub-decoders.
     */
    private mutating func updateProperties() throws {
        decoder.properties = try LZMAProperties(lzmaByte: byteReader.byte(),
                                                decoder.properties.dictionarySize)
        decoder.resetStateAndDecoders()
    }
}
