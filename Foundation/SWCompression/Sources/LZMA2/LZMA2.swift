// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import BitByteData
import Foundation

/// Provides decompression function for LZMA2 algorithm.
public class LZMA2: DecompressionAlgorithm {
    /**
     Decompresses `data` using LZMA2 algortihm.

     - Note: It is assumed that the first byte of `data` is a dictionary size encoded with standard encoding scheme of
     LZMA2 format.

     - Parameter data: Data compressed with LZMA2.

     - Throws: `LZMAError` or `LZMA2Error` if unexpected byte (bit) sequence was encountered in `data`.
     It may indicate that either data is damaged or it might not be compressed with LZMA2 at all.

     - Returns: Decompressed data.
     */
    public static func decompress(data: Data) throws -> Data {
        let byteReader = LittleEndianByteReader(data: data)
        guard byteReader.bytesLeft >= 1
        else { throw LZMAError.rangeDecoderInitError }
        return try decompress(byteReader, byteReader.byte())
    }

    static func decompress(_ byteReader: LittleEndianByteReader, _ dictSizeByte: UInt8) throws -> Data {
        var decoder = try LZMA2Decoder(byteReader, dictSizeByte)
        try decoder.decode()
        return Data(decoder.out)
    }
}
