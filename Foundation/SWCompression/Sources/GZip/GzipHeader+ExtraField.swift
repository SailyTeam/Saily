// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

public extension GzipHeader {
    /// Represents an extra field in the header of a GZip archive.
    struct ExtraField {
        /// First byte of the extra field (subfield) ID.
        public let si1: UInt8

        /// Second byte of the extra field (subfield) ID.
        public let si2: UInt8

        /// Binary content of the extra field.
        public var bytes: [UInt8]

        /// Initializes and extra field with the specified extra field (subfield) ID bytes and its binary content.
        public init(_ si1: UInt8, _ si2: UInt8, _ bytes: [UInt8]) {
            self.si1 = si1
            self.si2 = si2
            self.bytes = bytes
        }
    }
}
