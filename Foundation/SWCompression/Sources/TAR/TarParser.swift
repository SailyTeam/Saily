// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import BitByteData
import Foundation

// While it is tempting to make Provider conform to `IteratorProtocol` and `Sequence` protocols, it is in fact
// impossible to do so, since `TarHeader.init(...)` is throwing and `IteratorProtocol.next()` cannot be throwing.
struct TarParser {
    enum ParsingResult {
        case truncated
        case eofMarker
        case finished
        case specialEntry(TarHeader.SpecialEntryType)
        case entryInfo(TarEntryInfo, Int, TarContainer.Format)
    }

    private let reader: LittleEndianByteReader
    private var lastGlobalExtendedHeader: TarExtendedHeader?
    private var lastLocalExtendedHeader: TarExtendedHeader?
    private var longLinkName: String?
    private var longName: String?

    init(_ data: Data) {
        reader = LittleEndianByteReader(data: data)
        lastGlobalExtendedHeader = nil
        lastLocalExtendedHeader = nil
        longLinkName = nil
        longName = nil
    }

    mutating func next() throws -> ParsingResult {
        if reader.isFinished {
            return .finished
        } else if reader.bytesLeft >= 1024, reader.data[reader.offset ..< reader.offset + 1024] == Data(count: 1024) {
            return .eofMarker
        } else if reader.bytesLeft < 512 {
            return .truncated
        }

        let header = try TarHeader(reader)
        // For header we read at most 512 bytes.
        assert(reader.offset - header.blockStartIndex <= 512)
        // Check, just in case, since we use blockStartIndex = -1 when creating TAR containers.
        assert(header.blockStartIndex >= 0)
        let dataStartIndex = header.blockStartIndex + 512

        if case let .special(specialEntryType) = header.type {
            switch specialEntryType {
            case .globalExtendedHeader:
                let dataEndIndex = dataStartIndex + header.size
                lastGlobalExtendedHeader = try TarExtendedHeader(reader.data[dataStartIndex ..< dataEndIndex])
            case .sunExtendedHeader:
                fallthrough
            case .localExtendedHeader:
                let dataEndIndex = dataStartIndex + header.size
                lastLocalExtendedHeader = try TarExtendedHeader(reader.data[dataStartIndex ..< dataEndIndex])
            case .longLinkName:
                reader.offset = dataStartIndex
                longLinkName = reader.tarCString(maxLength: header.size)
            case .longName:
                reader.offset = dataStartIndex
                longName = reader.tarCString(maxLength: header.size)
            }
            reader.offset = dataStartIndex + header.size.roundTo512()
            return .specialEntry(specialEntryType)
        } else {
            let info = TarEntryInfo(header, lastGlobalExtendedHeader, lastLocalExtendedHeader, longName, longLinkName)
            // Skip file data.
            reader.offset = dataStartIndex + header.size.roundTo512()
            lastLocalExtendedHeader = nil
            longName = nil
            longLinkName = nil
            return .entryInfo(info, header.blockStartIndex, header.format)
        }
    }
}
