// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation

/**
 A type that allows to iteratively create TAR containers with the output being written into a `FileHandle`.

 The `TarWriter` may be helpful in reducing the peak memory usage on certain platforms. However, to achieve this both
 the creation of TAR entries and the calls to `TarWriter` should be wrapped inside the `autoreleasepool`. Since the
 `autoreleasepool` is available only on Darwin platforms, the memory reducing effect may be not as significant on
 non-Darwin platforms (such as Linux or Windows).

 The following code demonstrates an example usage of the `TarWriter`:
 ```swift
    let handle: FileHandle = ...
    let writer = TarWriter(fileHandle: handle)
    try autoreleasepool {
        let entry: TarEntry = ...
        try writer.append(entry)
    }
    try writer.finalize()
    try handle.close()
 ```
 Note that `TarWriter.finalize()` must be called after finishing appending entries to the container. In addition,
 closing the `FileHandle` remains the responsibility of the caller.

 - Important: Due to the API availability limitations of Foundation's `FileHandle`, on certain platforms errors in
 `FileHandle` operations may result in unrecoverable runtime failures due to unhandled Objective-C exceptions (which are
 impossible to correctly handle in Swift code). As such, it is not recommended to use `TarWriter` on those platforms.
 The following platforms are _unaffected_ by this issue: macOS 10.15.4+, iOS 13.4+, watchOS 6.2+, tvOS 13.4+, and any
 other platforms without Objective-C runtime.
 */
public struct TarWriter {
    private let format: TarContainer.Format
    private let handle: FileHandle
    private var longNameCounter: UInt
    private var longLinkNameCounter: UInt
    private var localPaxHeaderCounter: UInt

    /**
     Creates a new instance for writing TAR entries using the specified `format` into the provided `fileHandle`.

     The `TarWriter` will be forced to use the provided `format`, meaning that certain properties of the `entries` may
     be missing from the output data if the chosen format does not support corresponding features. The default `.pax`
     format supports the largest set of features. Other (non-PAX) formats should only be used if you have a specific
     need for them and you understand limitations of those formats.

     - Parameter fileHandle: A handle into which the output will be written. Note that the `TarWriter` does not
     close the `fileHandle` and this remains the responsibility of the caller.
     - Parameter force: Force the usage of the specified format.

     - Important: `TarWriter.finalize()` must be called after all entries have been appended.
     */
    public init(fileHandle: FileHandle, force format: TarContainer.Format = .pax) {
        handle = fileHandle
        self.format = format
        longNameCounter = 0
        longLinkNameCounter = 0
        localPaxHeaderCounter = 0
    }

    /**
     Adds a new TAR entry at the end of the TAR container.

     On Darwin platforms it is recommended to wrap both the initialization of a `TarEntry` and the call to this
     function inside the `autoreleasepool` in order to reduce the peak memory usage.

     - Throws: Errors from the `FileHandle` operations.
     */
    public mutating func append(_ entry: TarEntry) throws {
        var out = Data()
        if format == .gnu {
            if entry.info.name.utf8.count > 100 {
                let nameData = Data(entry.info.name.utf8)
                let longNameHeader = TarHeader(specialName: "SWC_LongName_\(longNameCounter)",
                                               specialType: .longName, size: nameData.count,
                                               uid: entry.info.ownerID, gid: entry.info.groupID)
                out.append(longNameHeader.generateContainerData(.gnu))
                assert(out.count % 512 == 0)
                out.appendAsTarBlock(nameData)
                longNameCounter &+= 1
            }

            if entry.info.linkName.utf8.count > 100 {
                let linkNameData = Data(entry.info.linkName.utf8)
                let longLinkNameHeader = TarHeader(specialName: "SWC_LongLinkName_\(longLinkNameCounter)",
                                                   specialType: .longLinkName, size: linkNameData.count,
                                                   uid: entry.info.ownerID, gid: entry.info.groupID)
                out.append(longLinkNameHeader.generateContainerData(.gnu))
                assert(out.count % 512 == 0)
                out.appendAsTarBlock(linkNameData)
                longLinkNameCounter &+= 1
            }
        } else if format == .pax {
            let extHeader = TarExtendedHeader(entry.info)
            let extHeaderData = extHeader.generateContainerData()
            if !extHeaderData.isEmpty {
                let extHeaderHeader = TarHeader(specialName: "SWC_LocalPaxHeader_\(localPaxHeaderCounter)",
                                                specialType: .localExtendedHeader, size: extHeaderData.count,
                                                uid: entry.info.ownerID, gid: entry.info.groupID)
                out.append(extHeaderHeader.generateContainerData(.pax))
                assert(out.count % 512 == 0)
                out.appendAsTarBlock(extHeaderData)
                localPaxHeaderCounter &+= 1
            }
        }

        let header = TarHeader(entry.info)
        out.append(header.generateContainerData(format))
        assert(out.count % 512 == 0)
        try write(out)
        if let data = entry.data {
            try write(data)
            let paddingSize = data.count.roundTo512() - data.count
            try write(Data(count: paddingSize))
        }
    }

    /**
     Finalizes the TAR container by adding an EOF marker.

     - Throws: Errors from the `FileHandle` operations.
     */
    public func finalize() throws {
        // First, we append two 512-byte blocks consisting of zeros as an EOF marker.
        try write(Data(count: 1024))
        // The synchronization is performed by the write(_:) function automatically.
    }

    private func write(_ data: Data) throws {
        if #available(macOS 10.15.4, iOS 13.4, watchOS 6.2, tvOS 13.4, *) {
            try handle.write(contentsOf: data)
            try handle.synchronize()
        } else {
            handle.write(data)
            handle.synchronizeFile()
        }
    }
}
