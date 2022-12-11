// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import BitByteData
import Foundation

/**
 A type that allows to iteratively read TAR entries from a container provided by a `FileHandle`.

 The `TarReader` may be helpful in reducing the peak memory usage on certain platforms. However, to achieve this either
 the `TarReader.process(_:)` function should be used or both the call to `TarReader.read()` and the processing of the
 returned entry should be wrapped inside the `autoreleasepool`. Since the `autoreleasepool` is available only on Darwin
 platforms, the memory reducing effect may be not as significant on non-Darwin platforms (such as Linux or Windows).

 The following code demonstrates an example usage of the `TarReader`:
 ```swift
    let handle: FileHandle = ...
    let reader = TarReader(fileHandle: handle)
    try reader.process { ... }
    ...
    try handle.close()
 ```
 Note that closing the `FileHandle` remains the responsibility of the caller.

 - Important: Due to the API availability limitations of Foundation's `FileHandle`, on certain platforms errors in
 `FileHandle` operations may result in unrecoverable runtime failures due to unhandled Objective-C exceptions (which are
 impossible to correctly handle in Swift code). As such, it is not recommended to use `TarReader` on those platforms.
 The following platforms are _unaffected_ by this issue: macOS 10.15.4+, iOS 13.4+, watchOS 6.2+, tvOS 13.4+, and any
 other platforms without Objective-C runtime.
 */
public struct TarReader {
    private let handle: FileHandle
    private var lastGlobalExtendedHeader: TarExtendedHeader?
    private var lastLocalExtendedHeader: TarExtendedHeader?
    private var longLinkName: String?
    private var longName: String?

    /**
     Creates a new instance for reading TAR entries from the provided `fileHandle`.

     - Parameter fileHandle: A handle from which the entries will be read. Note that the `TarReader` does not close the
     `fileHandle` and this remains the responsibility of the caller.
     */
    public init(fileHandle: FileHandle) {
        handle = fileHandle
        lastGlobalExtendedHeader = nil
        lastLocalExtendedHeader = nil
        longLinkName = nil
        longName = nil
    }

    /**
     Processes the next TAR entry by reading it from the container and calling the provided closure on the result.

     On Darwin platforms both the reading and the call to the closure are performed inside the `autoreleasepool` which
     allows to reduce the peak memory usage.

     If the argument supplied to the closure is `nil` this indicates that the end of the input was reached. After that
     the repeated `TarReader.process(_:)` or `TarReader.read()` calls will result in the `DataError.truncated` being
     thrown.

     - Throws: `DataError.truncated` if the input is truncated. `TarError` is thrown in case of malformed input. Errors
     thrown by `FileHandle` operations are also propagated.
     */
    public mutating func process<T>(_ transform: (TarEntry?) throws -> T) throws -> T {
        try autoreleasepool {
            let entry = try read()
            return try transform(entry)
        }
    }

    /**
     Reads the next TAR entry from the container.

     On Darwin platforms it is recommended to wrap both the call to this function and the follow-up processing inside
     the `autoreleasepool` in order to reduce the peak memory usage.

     - Throws: `DataError.truncated` if the input is truncated. `TarError` is thrown in case of malformed input. Errors
     thrown by `FileHandle` operations are also propagated.

     - Returns: The next entry from the container or `nil` if the end of the input has been reached. After that the
     repeated `TarReader.process(_:)` or `TarReader.read()` calls will result in the `DataError.truncated` being thrown.
     */
    public mutating func read() throws -> TarEntry? {
        let headerData = try getData(size: 512)
        if headerData.count == 0 {
            return nil
        } else if headerData == Data(count: 512) {
            // EOF marker case.
            let offset = try getOffset()
            if try getData(size: 512) == Data(count: 512) {
                return nil
            } else {
                try set(offset: offset)
            }
        } else if headerData.count < 512 {
            throw DataError.truncated
        }
        assert(headerData.count == 512)

        let header = try TarHeader(LittleEndianByteReader(data: headerData))
        // Since we explicitly initialize the header from 512 bytes-long Data, we don't have to check that we processed
        // at most 512 bytes.
        // Check, just in case, since we use blockStartIndex = -1 when creating TAR containers.
        assert(header.blockStartIndex >= 0)
        let dataStartOffset = try getOffset()

        let entryData = try getData(size: header.size)
        guard entryData.count == header.size
        else { throw DataError.truncated }

        if case let .special(specialEntryType) = header.type {
            switch specialEntryType {
            case .globalExtendedHeader:
                lastGlobalExtendedHeader = try TarExtendedHeader(entryData)
            case .sunExtendedHeader:
                fallthrough
            case .localExtendedHeader:
                lastLocalExtendedHeader = try TarExtendedHeader(entryData)
            case .longLinkName:
                longLinkName = LittleEndianByteReader(data: entryData).tarCString(maxLength: header.size)
            case .longName:
                longName = LittleEndianByteReader(data: entryData).tarCString(maxLength: header.size)
            }
            try set(offset: dataStartOffset + UInt64(truncatingIfNeeded: header.size.roundTo512()))
            return try read()
        } else {
            let info = TarEntryInfo(header, lastGlobalExtendedHeader, lastLocalExtendedHeader, longName, longLinkName)
            try set(offset: dataStartOffset + UInt64(truncatingIfNeeded: header.size.roundTo512()))
            lastLocalExtendedHeader = nil
            longName = nil
            longLinkName = nil
            if info.type == .directory {
                // For directories TarEntry.data is set to nil.
                var entry = TarEntry(info: info, data: nil)
                entry.info.size = 0
                return entry
            } else {
                return TarEntry(info: info, data: entryData)
            }
        }
    }

    private func getOffset() throws -> UInt64 {
        if #available(macOS 10.15.4, iOS 13.4, watchOS 6.2, tvOS 13.4, *) {
            return try handle.offset()
        } else {
            return handle.offsetInFile
        }
    }

    private func set(offset: UInt64) throws {
        if #available(macOS 10.15.4, iOS 13.4, watchOS 6.2, tvOS 13.4, *) {
            try handle.seek(toOffset: offset)
        } else {
            handle.seek(toFileOffset: offset)
        }
    }

    private func getData(size: Int) throws -> Data {
        assert(size >= 0, "TarReader.getData(size:): negative size.")
        guard size > 0
        else { return Data() }
        if #available(macOS 10.15.4, iOS 13.4, watchOS 6.2, tvOS 13.4, *) {
            guard let chunkData = try handle.read(upToCount: size)
            else { throw DataError.truncated }
            return chunkData
        } else {
            // Technically, this can throw NSException, but since it is ObjC exception we cannot handle it in Swift.
            return handle.readData(ofLength: size)
        }
    }
}

#if os(Linux) || os(Windows)
    @discardableResult
    fileprivate func autoreleasepool<T>(_ block: () throws -> T) rethrows -> T {
        try block()
    }
#endif
